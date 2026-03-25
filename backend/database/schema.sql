-- Lingo Database Schema
-- Designed for adaptive learning + progress analytics

CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    display_name TEXT NOT NULL,
    proficiency_level TEXT NOT NULL DEFAULT 'Beginner' CHECK(proficiency_level IN ('Beginner', 'Intermediate', 'Expert')),
    target_language TEXT NOT NULL DEFAULT 'English',
    daily_goal INTEGER NOT NULL DEFAULT 3,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    prompt TEXT NOT NULL,
    transcription TEXT,
    target_language TEXT NOT NULL,
    proficiency_level TEXT NOT NULL,
    grammar_score INTEGER,
    grammar_feedback TEXT,
    pronunciation_score INTEGER,
    pronunciation_feedback TEXT,
    fluency_score INTEGER,
    fluency_feedback TEXT,
    vocabulary_score INTEGER,
    vocabulary_feedback TEXT,
    clarity_score INTEGER,
    clarity_feedback TEXT,
    overall_score INTEGER,
    xp_earned INTEGER NOT NULL DEFAULT 0,
    duration_seconds INTEGER,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS challenge_words (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    word TEXT NOT NULL,
    used INTEGER NOT NULL DEFAULT 0,
    feedback TEXT
);

-- Tracks which skill areas a user is weakest in for adaptive prompts
CREATE TABLE IF NOT EXISTS skill_profile (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    skill TEXT NOT NULL CHECK(skill IN ('grammar', 'pronunciation', 'fluency', 'vocabulary', 'clarity')),
    rolling_avg REAL NOT NULL DEFAULT 50.0,
    total_assessments INTEGER NOT NULL DEFAULT 0,
    last_updated TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(user_id, skill)
);

-- Daily streaks
CREATE TABLE IF NOT EXISTS streaks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    current_streak INTEGER NOT NULL DEFAULT 0,
    longest_streak INTEGER NOT NULL DEFAULT 0,
    last_practice_date TEXT
);

-- Vocabulary bank: words the user has encountered
CREATE TABLE IF NOT EXISTS vocabulary_bank (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    word TEXT NOT NULL,
    language TEXT NOT NULL,
    times_seen INTEGER NOT NULL DEFAULT 1,
    times_used_correctly INTEGER NOT NULL DEFAULT 0,
    mastery_level REAL NOT NULL DEFAULT 0.0,
    next_review_date TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(user_id, word, language)
);

-- Prompt history to avoid repeating prompts too soon
CREATE TABLE IF NOT EXISTS prompt_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    prompt TEXT NOT NULL,
    used_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_created ON sessions(created_at);
CREATE INDEX IF NOT EXISTS idx_challenge_words_session ON challenge_words(session_id);
CREATE INDEX IF NOT EXISTS idx_skill_profile_user ON skill_profile(user_id);
CREATE INDEX IF NOT EXISTS idx_vocabulary_user ON vocabulary_bank(user_id);
CREATE INDEX IF NOT EXISTS idx_prompt_history_user ON prompt_history(user_id);
