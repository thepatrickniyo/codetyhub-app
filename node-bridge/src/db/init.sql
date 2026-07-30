-- CodetyHub PostgreSQL Schema Initialization

CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_progress (
    user_id VARCHAR(64) PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    xp INTEGER DEFAULT 0,
    streak INTEGER DEFAULT 1,
    vss_score FLOAT DEFAULT 0.0,
    completed_lessons JSONB DEFAULT '[]'::jsonb,
    completed_quizzes JSONB DEFAULT '[]'::jsonb,
    ikp_scores JSONB DEFAULT '{}'::jsonb,
    badges JSONB DEFAULT '[]'::jsonb,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE user_progress ADD COLUMN IF NOT EXISTS vss_score FLOAT DEFAULT 0.0;

-- ── 3. CodeBERT Code Submissions History ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS code_submissions (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(64) REFERENCES users(id) ON DELETE CASCADE,
    skill_node VARCHAR(128) NOT NULL,
    code_text TEXT NOT NULL,
    vss_score FLOAT NOT NULL,
    dimension_scores JSONB DEFAULT '{}'::jsonb,
    feedback JSONB DEFAULT '{}'::jsonb,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Common SHA-256 hash for password 'password123'
-- hash = 'ef92b778ba7158759a4011a344fe8038e8dcd644798157e93072296db9679654'

-- ── 1. Sarah Chen ─────────────────────────────────────────────────────────────
INSERT INTO users (id, name, email, password_hash)
VALUES ('usr-seed-001', 'Sarah Chen', 'sarah.chen@codetyhub.com', 'ef92b778ba7158759a4011a344fe8038e8dcd644798157e93072296db9679654')
ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO user_progress (user_id, xp, streak, vss_score, completed_lessons, ikp_scores, badges)
VALUES (
    'usr-seed-001',
    4850,
    14,
    94.5,
    '["python_intro:0", "python_intro:1", "python_intro:2", "variables:0", "functions:0", "oop_basics:0"]'::jsonb,
    '{"python_basics": 0.95, "linear_regression": 0.88, "data_structures": 0.92}'::jsonb,
    '["first_lesson", "five_lessons", "streak_7", "xp_1000"]'::jsonb
)
ON CONFLICT (user_id) DO UPDATE SET xp = EXCLUDED.xp, streak = EXCLUDED.streak, vss_score = EXCLUDED.vss_score;

-- ── 2. Marcus Vance ───────────────────────────────────────────────────────────
INSERT INTO users (id, name, email, password_hash)
VALUES ('usr-seed-002', 'Marcus Vance', 'marcus.vance@codetyhub.com', 'ef92b778ba7158759a4011a344fe8038e8dcd644798157e93072296db9679654')
ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO user_progress (user_id, xp, streak, vss_score, completed_lessons, ikp_scores, badges)
VALUES (
    'usr-seed-002',
    3720,
    9,
    88.2,
    '["python_intro:0", "python_intro:1", "variables:0", "functions:0"]'::jsonb,
    '{"python_basics": 0.88, "linear_regression": 0.75}'::jsonb,
    '["first_lesson", "five_lessons", "streak_7", "xp_1000"]'::jsonb
)
ON CONFLICT (user_id) DO UPDATE SET xp = EXCLUDED.xp, streak = EXCLUDED.streak, vss_score = EXCLUDED.vss_score;

-- ── 3. Amina Diallo ───────────────────────────────────────────────────────────
INSERT INTO users (id, name, email, password_hash)
VALUES ('usr-seed-003', 'Amina Diallo', 'amina.diallo@codetyhub.com', 'ef92b778ba7158759a4011a344fe8038e8dcd644798157e93072296db9679654')
ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO user_progress (user_id, xp, streak, vss_score, completed_lessons, ikp_scores, badges)
VALUES (
    'usr-seed-003',
    2940,
    6,
    82.0,
    '["python_intro:0", "python_intro:1", "variables:0"]'::jsonb,
    '{"python_basics": 0.82, "functions": 0.70}'::jsonb,
    '["first_lesson", "xp_1000"]'::jsonb
)
ON CONFLICT (user_id) DO UPDATE SET xp = EXCLUDED.xp, streak = EXCLUDED.streak, vss_score = EXCLUDED.vss_score;

-- ── 4. Patrick Niyogitare ──────────────────────────────────────────────────────
INSERT INTO users (id, name, email, password_hash)
VALUES ('usr-seed-004', 'Patrick Niyogitare', 'patrick@codetyhub.com', 'ef92b778ba7158759a4011a344fe8038e8dcd644798157e93072296db9679654')
ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO user_progress (user_id, xp, streak, vss_score, completed_lessons, ikp_scores, badges)
VALUES (
    'usr-seed-004',
    2340,
    7,
    78.5,
    '["python_intro:0", "variables:0"]'::jsonb,
    '{"python_basics": 0.78}'::jsonb,
    '["first_lesson", "streak_7", "xp_1000"]'::jsonb
)
ON CONFLICT (user_id) DO UPDATE SET xp = EXCLUDED.xp, streak = EXCLUDED.streak, vss_score = EXCLUDED.vss_score;

-- ── 5. Elena Rostova ──────────────────────────────────────────────────────────
INSERT INTO users (id, name, email, password_hash)
VALUES ('usr-seed-005', 'Elena Rostova', 'elena.rostova@codetyhub.com', 'ef92b778ba7158759a4011a344fe8038e8dcd644798157e93072296db9679654')
ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO user_progress (user_id, xp, streak, vss_score, completed_lessons, ikp_scores, badges)
VALUES (
    'usr-seed-005',
    1450,
    4,
    71.0,
    '["python_intro:0"]'::jsonb,
    '{"python_basics": 0.65}'::jsonb,
    '["first_lesson", "xp_1000"]'::jsonb
)
ON CONFLICT (user_id) DO UPDATE SET xp = EXCLUDED.xp, streak = EXCLUDED.streak, vss_score = EXCLUDED.vss_score;

-- ── 6. Seed CodeBERT Submissions History ──────────────────────────────────────
INSERT INTO code_submissions (user_id, skill_node, code_text, vss_score, dimension_scores, feedback)
VALUES (
    'usr-seed-001',
    'linear_regression',
    'import numpy as np\ndef fit_linear_regression(X, y):\n    return np.linalg.inv(X.T @ X) @ X.T @ y',
    94.5,
    '{"code_correctness": 0.96, "structural_elegance": 0.94, "contextual_alignment": 0.95, "documentation": 0.91}'::jsonb,
    '{"general": "Excellent modular implementation using matrix inversion techniques."}'::jsonb
);

INSERT INTO code_submissions (user_id, skill_node, code_text, vss_score, dimension_scores, feedback)
VALUES (
    'usr-seed-004',
    'python_basics',
    'def calculate_mean(numbers):\n    return sum(numbers) / len(numbers) if numbers else 0.0',
    78.5,
    '{"code_correctness": 0.80, "structural_elegance": 0.78, "contextual_alignment": 0.82, "documentation": 0.70}'::jsonb,
    '{"general": "Good functional solution. Adding docstrings will improve documentation score."}'::jsonb
);
