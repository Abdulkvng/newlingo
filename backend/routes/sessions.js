import { Router } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { getDb, updateSkillProfile, updateStreak, updateVocabulary, getWeakSkills, getWordsForReview } from '../database/db.js';
import { getChallengeWords, evaluateSpeech } from '../services/gemini.js';
import { getAdaptivePrompt } from '../services/adaptive.js';

const router = Router();

// Get an adaptive prompt for the user
router.get('/prompt', (req, res) => {
    try {
        const result = getAdaptivePrompt(req.userId);
        res.json(result);
    } catch (err) {
        console.error('Prompt error:', err);
        res.status(500).json({ error: 'Failed to generate prompt.' });
    }
});

// Get challenge words for a prompt
router.post('/challenge-words', async (req, res) => {
    try {
        const { prompt, targetLanguage, proficiencyLevel } = req.body;
        const weakSkills = getWeakSkills(req.userId);
        const reviewWords = getWordsForReview(req.userId, targetLanguage);

        const words = await getChallengeWords(prompt, targetLanguage, proficiencyLevel, weakSkills, reviewWords);
        res.json({ words });
    } catch (err) {
        console.error('Challenge words error:', err);
        res.status(500).json({ error: 'Failed to generate challenge words.' });
    }
});

// Submit audio for evaluation
router.post('/evaluate', async (req, res) => {
    try {
        const { audioBase64, targetLanguage, proficiencyLevel, prompt, challengeWords } = req.body;

        if (!audioBase64 || !prompt) {
            return res.status(400).json({ error: 'Audio data and prompt are required.' });
        }

        const result = await evaluateSpeech(audioBase64, targetLanguage, proficiencyLevel, prompt, challengeWords);
        const { transcription, feedback } = result;

        // Calculate XP
        const baseXp = Math.round(feedback.overallScore);
        const bonusXp = feedback.challengeWordsUsed.filter(w => w.used).length * 5;
        const totalXp = baseXp + bonusXp;

        // Save session to database
        const db = getDb();
        const sessionId = uuidv4();

        db.prepare(`
            INSERT INTO sessions (
                id, user_id, prompt, transcription, target_language, proficiency_level,
                grammar_score, grammar_feedback,
                pronunciation_score, pronunciation_feedback,
                fluency_score, fluency_feedback,
                vocabulary_score, vocabulary_feedback,
                clarity_score, clarity_feedback,
                overall_score, xp_earned
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).run(
            sessionId, req.userId, prompt, transcription, targetLanguage, proficiencyLevel,
            feedback.grammar.score, feedback.grammar.feedback,
            feedback.pronunciation.score, feedback.pronunciation.feedback,
            feedback.fluency.score, feedback.fluency.feedback,
            feedback.vocabulary.score, feedback.vocabulary.feedback,
            feedback.clarity.score, feedback.clarity.feedback,
            feedback.overallScore, totalXp
        );

        // Save challenge words
        const insertWord = db.prepare(
            'INSERT INTO challenge_words (session_id, word, used, feedback) VALUES (?, ?, ?, ?)'
        );
        for (const cw of feedback.challengeWordsUsed) {
            insertWord.run(sessionId, cw.word, cw.used ? 1 : 0, cw.feedback);
        }

        // Update skill profile (adaptive learning)
        updateSkillProfile(req.userId, feedback);

        // Update streak
        const streak = updateStreak(req.userId);

        // Update vocabulary bank (spaced repetition)
        updateVocabulary(req.userId, targetLanguage, feedback.challengeWordsUsed);

        res.json({
            sessionId,
            transcription,
            feedback,
            xp: { base: baseXp, bonus: bonusXp, total: totalXp },
            streak
        });
    } catch (err) {
        console.error('Evaluation error:', err);
        res.status(500).json({ error: `Failed to evaluate speech: ${err.message}` });
    }
});

// Get session history
router.get('/history', (req, res) => {
    try {
        const db = getDb();
        const limit = parseInt(req.query.limit) || 50;
        const offset = parseInt(req.query.offset) || 0;

        const sessions = db.prepare(`
            SELECT * FROM sessions
            WHERE user_id = ?
            ORDER BY created_at DESC
            LIMIT ? OFFSET ?
        `).all(req.userId, limit, offset);

        // Attach challenge words to each session
        const getWords = db.prepare('SELECT word, used, feedback FROM challenge_words WHERE session_id = ?');

        const enriched = sessions.map(s => ({
            id: s.id,
            prompt: s.prompt,
            transcription: s.transcription,
            targetLanguage: s.target_language,
            proficiencyLevel: s.proficiency_level,
            feedback: {
                grammar: { score: s.grammar_score, feedback: s.grammar_feedback },
                pronunciation: { score: s.pronunciation_score, feedback: s.pronunciation_feedback },
                fluency: { score: s.fluency_score, feedback: s.fluency_feedback },
                vocabulary: { score: s.vocabulary_score, feedback: s.vocabulary_feedback },
                clarity: { score: s.clarity_score, feedback: s.clarity_feedback },
                overallScore: s.overall_score,
                challengeWordsUsed: getWords.all(s.id).map(w => ({ ...w, used: !!w.used }))
            },
            xpEarned: s.xp_earned,
            date: s.created_at
        }));

        res.json({ sessions: enriched });
    } catch (err) {
        console.error('History error:', err);
        res.status(500).json({ error: 'Failed to fetch history.' });
    }
});

// Get single session detail
router.get('/:sessionId', (req, res) => {
    try {
        const db = getDb();
        const s = db.prepare('SELECT * FROM sessions WHERE id = ? AND user_id = ?').get(req.params.sessionId, req.userId);

        if (!s) return res.status(404).json({ error: 'Session not found.' });

        const words = db.prepare('SELECT word, used, feedback FROM challenge_words WHERE session_id = ?').all(s.id);

        res.json({
            id: s.id,
            prompt: s.prompt,
            transcription: s.transcription,
            targetLanguage: s.target_language,
            proficiencyLevel: s.proficiency_level,
            feedback: {
                grammar: { score: s.grammar_score, feedback: s.grammar_feedback },
                pronunciation: { score: s.pronunciation_score, feedback: s.pronunciation_feedback },
                fluency: { score: s.fluency_score, feedback: s.fluency_feedback },
                vocabulary: { score: s.vocabulary_score, feedback: s.vocabulary_feedback },
                clarity: { score: s.clarity_score, feedback: s.clarity_feedback },
                overallScore: s.overall_score,
                challengeWordsUsed: words.map(w => ({ ...w, used: !!w.used }))
            },
            xpEarned: s.xp_earned,
            date: s.created_at
        });
    } catch (err) {
        console.error('Session detail error:', err);
        res.status(500).json({ error: 'Failed to fetch session.' });
    }
});

export default router;
