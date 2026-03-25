import Database from 'better-sqlite3';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const DB_PATH = join(__dirname, '..', 'lingo.db');

let db;

export function getDb() {
    if (!db) {
        db = new Database(DB_PATH);
        db.pragma('journal_mode = WAL');
        db.pragma('foreign_keys = ON');

        const schema = readFileSync(join(__dirname, 'schema.sql'), 'utf-8');
        db.exec(schema);
    }
    return db;
}

// Initialize skill profile for a new user
export function initSkillProfile(userId) {
    const db = getDb();
    const skills = ['grammar', 'pronunciation', 'fluency', 'vocabulary', 'clarity'];
    const stmt = db.prepare(
        'INSERT OR IGNORE INTO skill_profile (user_id, skill) VALUES (?, ?)'
    );
    for (const skill of skills) {
        stmt.run(userId, skill);
    }
}

// Update rolling averages after a session
export function updateSkillProfile(userId, feedback) {
    const db = getDb();
    const skills = ['grammar', 'pronunciation', 'fluency', 'vocabulary', 'clarity'];
    const alpha = 0.3; // Exponential moving average weight (recent sessions matter more)

    const update = db.prepare(`
        UPDATE skill_profile
        SET rolling_avg = ? * ? + (1.0 - ?) * rolling_avg,
            total_assessments = total_assessments + 1,
            last_updated = datetime('now')
        WHERE user_id = ? AND skill = ?
    `);

    for (const skill of skills) {
        const score = feedback[skill]?.score ?? 50;
        update.run(alpha, score, alpha, userId, skill);
    }
}

// Get user's weakest skills for adaptive prompt generation
export function getWeakSkills(userId, limit = 2) {
    const db = getDb();
    return db.prepare(`
        SELECT skill, rolling_avg
        FROM skill_profile
        WHERE user_id = ? AND total_assessments > 0
        ORDER BY rolling_avg ASC
        LIMIT ?
    `).all(userId, limit);
}

// Update streak
export function updateStreak(userId) {
    const db = getDb();
    const today = new Date().toISOString().split('T')[0];

    const streak = db.prepare('SELECT * FROM streaks WHERE user_id = ?').get(userId);

    if (!streak) {
        db.prepare(`
            INSERT INTO streaks (user_id, current_streak, longest_streak, last_practice_date)
            VALUES (?, 1, 1, ?)
        `).run(userId, today);
        return { current_streak: 1, longest_streak: 1 };
    }

    if (streak.last_practice_date === today) {
        return streak; // Already practiced today
    }

    const lastDate = new Date(streak.last_practice_date);
    const todayDate = new Date(today);
    const diffDays = Math.floor((todayDate - lastDate) / (1000 * 60 * 60 * 24));

    let newStreak;
    if (diffDays === 1) {
        newStreak = streak.current_streak + 1;
    } else {
        newStreak = 1; // Streak broken
    }

    const longestStreak = Math.max(newStreak, streak.longest_streak);

    db.prepare(`
        UPDATE streaks
        SET current_streak = ?, longest_streak = ?, last_practice_date = ?
        WHERE user_id = ?
    `).run(newStreak, longestStreak, today, userId);

    return { current_streak: newStreak, longest_streak: longestStreak };
}

// Update vocabulary bank with spaced repetition
export function updateVocabulary(userId, language, challengeWords) {
    const db = getDb();

    const upsert = db.prepare(`
        INSERT INTO vocabulary_bank (user_id, word, language, times_used_correctly, mastery_level, next_review_date)
        VALUES (?, ?, ?, ?, ?, ?)
        ON CONFLICT(user_id, word, language) DO UPDATE SET
            times_seen = times_seen + 1,
            times_used_correctly = times_used_correctly + ?,
            mastery_level = MIN(1.0, mastery_level + ?),
            next_review_date = ?
    `);

    for (const cw of challengeWords) {
        const usedCorrectly = cw.used ? 1 : 0;
        const masteryDelta = cw.used ? 0.15 : -0.05;
        // Spaced repetition: review sooner if not mastered
        const daysUntilReview = cw.used ? 3 : 1;
        const nextReview = new Date();
        nextReview.setDate(nextReview.getDate() + daysUntilReview);
        const nextReviewStr = nextReview.toISOString().split('T')[0];

        upsert.run(
            userId, cw.word, language, usedCorrectly, Math.max(0, masteryDelta), nextReviewStr,
            usedCorrectly, Math.max(0, masteryDelta), nextReviewStr
        );
    }
}

// Get words due for review (spaced repetition)
export function getWordsForReview(userId, language, limit = 5) {
    const db = getDb();
    const today = new Date().toISOString().split('T')[0];

    return db.prepare(`
        SELECT word, mastery_level, times_seen, times_used_correctly
        FROM vocabulary_bank
        WHERE user_id = ? AND language = ? AND next_review_date <= ? AND mastery_level < 0.9
        ORDER BY mastery_level ASC, next_review_date ASC
        LIMIT ?
    `).all(userId, language, today, limit);
}
