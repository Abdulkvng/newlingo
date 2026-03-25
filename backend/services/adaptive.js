import { getDb, getWeakSkills, getWordsForReview } from '../database/db.js';

// Prompt pools categorized by skill focus
const PROMPT_POOLS = {
    grammar: [
        "Explain the rules of a game or sport you enjoy. Use complete sentences with varied tenses.",
        "Describe what you did yesterday from morning to night.",
        "If you could change one thing about your city, what would it be and why?",
        "Compare two different types of transportation and explain which is better.",
        "Describe a process you know well, step by step."
    ],
    pronunciation: [
        "Read this tongue twister slowly and clearly: 'She sells seashells by the seashore.'",
        "Describe your favorite season and what makes it special.",
        "Talk about the sounds you hear in your neighborhood.",
        "Describe a musical instrument and how it sounds.",
        "Explain the differences between similar-sounding words you find tricky."
    ],
    fluency: [
        "Tell a story about a funny or unexpected experience you had.",
        "Describe a movie plot without stopping or repeating yourself.",
        "Talk continuously for one minute about your morning routine.",
        "Describe everything you see around you right now.",
        "Explain how to cook your favorite dish from start to finish."
    ],
    vocabulary: [
        "Describe your dream house in as much detail as possible.",
        "Talk about a profession you admire and why it interests you.",
        "Describe the weather patterns in different seasons where you live.",
        "Explain the differences between various types of cuisine.",
        "Describe a painting or piece of art using rich, descriptive language."
    ],
    clarity: [
        "Give clear directions from your home to the nearest grocery store.",
        "Explain a concept from your field of work or study to a beginner.",
        "Describe an object without naming it — see if a listener could guess what it is.",
        "Summarize a news story you recently heard about.",
        "Explain why education is important in three clear points."
    ],
    general: [
        "Describe your perfect weekend getaway.",
        "What is your favorite food and why? Describe how to make it.",
        "Talk about a movie you recently watched and whether you would recommend it.",
        "Describe your dream vacation.",
        "What are your career goals for the next five years?",
        "Tell me about a person who has influenced your life.",
        "What would you do if you won the lottery?",
        "Describe your hometown and what makes it unique.",
        "Talk about a skill you'd like to learn and why.",
        "If you could travel anywhere in the world, where would you go?"
    ]
};

// Select the best prompt for a user based on their weak areas
export function getAdaptivePrompt(userId) {
    const db = getDb();

    // Get user's weak skills
    const weakSkills = getWeakSkills(userId, 2);

    // Get recently used prompts to avoid repetition
    const recentPrompts = db.prepare(`
        SELECT prompt FROM prompt_history
        WHERE user_id = ?
        ORDER BY used_at DESC
        LIMIT 10
    `).all(userId).map(r => r.prompt);

    let candidatePool;

    if (weakSkills.length > 0 && weakSkills[0].rolling_avg < 65) {
        // Focus on the weakest skill
        const weakestSkill = weakSkills[0].skill;
        candidatePool = [...PROMPT_POOLS[weakestSkill], ...PROMPT_POOLS.general];
    } else {
        // User is doing well — give general prompts
        candidatePool = PROMPT_POOLS.general;
    }

    // Filter out recently used prompts
    const available = candidatePool.filter(p => !recentPrompts.includes(p));
    const pool = available.length > 0 ? available : candidatePool;

    // Pick randomly from available pool
    const prompt = pool[Math.floor(Math.random() * pool.length)];

    // Record prompt usage
    db.prepare('INSERT INTO prompt_history (user_id, prompt) VALUES (?, ?)').run(userId, prompt);

    return {
        prompt,
        weakSkills,
        focusArea: weakSkills.length > 0 && weakSkills[0].rolling_avg < 65
            ? weakSkills[0].skill
            : null
    };
}

// Get learning insights for a user
export function getLearningInsights(userId) {
    const db = getDb();

    // Overall stats
    const stats = db.prepare(`
        SELECT
            COUNT(*) as total_sessions,
            COALESCE(AVG(overall_score), 0) as avg_score,
            COALESCE(SUM(xp_earned), 0) as total_xp,
            COALESCE(MAX(overall_score), 0) as best_score
        FROM sessions WHERE user_id = ?
    `).get(userId);

    // Skill profile
    const skills = db.prepare(`
        SELECT skill, rolling_avg, total_assessments
        FROM skill_profile WHERE user_id = ?
        ORDER BY rolling_avg ASC
    `).all(userId);

    // Streak
    const streak = db.prepare('SELECT * FROM streaks WHERE user_id = ?').get(userId);

    // Recent score trend (last 10 sessions)
    const recentScores = db.prepare(`
        SELECT overall_score, created_at
        FROM sessions WHERE user_id = ?
        ORDER BY created_at DESC
        LIMIT 10
    `).all(userId).reverse();

    // Improvement rate (compare first 5 vs last 5 sessions)
    let improvementRate = 0;
    if (recentScores.length >= 6) {
        const mid = Math.floor(recentScores.length / 2);
        const earlyAvg = recentScores.slice(0, mid).reduce((a, b) => a + b.overall_score, 0) / mid;
        const lateAvg = recentScores.slice(mid).reduce((a, b) => a + b.overall_score, 0) / (recentScores.length - mid);
        improvementRate = Math.round(lateAvg - earlyAvg);
    }

    // Vocabulary mastery
    const vocabStats = db.prepare(`
        SELECT
            COUNT(*) as total_words,
            SUM(CASE WHEN mastery_level >= 0.7 THEN 1 ELSE 0 END) as mastered_words,
            AVG(mastery_level) as avg_mastery
        FROM vocabulary_bank WHERE user_id = ?
    `).get(userId);

    // Sessions per day of week (practice patterns)
    const practicePatterns = db.prepare(`
        SELECT
            CASE CAST(strftime('%w', created_at) AS INTEGER)
                WHEN 0 THEN 'Sun' WHEN 1 THEN 'Mon' WHEN 2 THEN 'Tue'
                WHEN 3 THEN 'Wed' WHEN 4 THEN 'Thu' WHEN 5 THEN 'Fri' WHEN 6 THEN 'Sat'
            END as day,
            COUNT(*) as count
        FROM sessions WHERE user_id = ?
        GROUP BY strftime('%w', created_at)
        ORDER BY CAST(strftime('%w', created_at) AS INTEGER)
    `).all(userId);

    return {
        totalSessions: stats.total_sessions,
        avgScore: Math.round(stats.avg_score),
        totalXp: Math.round(stats.total_xp),
        bestScore: stats.best_score,
        skills,
        streak: streak || { current_streak: 0, longest_streak: 0 },
        recentScores,
        improvementRate,
        vocabulary: {
            totalWords: vocabStats.total_words,
            masteredWords: vocabStats.mastered_words,
            avgMastery: Math.round((vocabStats.avg_mastery || 0) * 100)
        },
        practicePatterns
    };
}
