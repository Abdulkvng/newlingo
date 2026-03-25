import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';
import { getDb, initSkillProfile } from '../database/db.js';
import { generateToken } from '../middleware/auth.js';

const router = Router();

router.post('/register', async (req, res) => {
    try {
        const { email, password, displayName, proficiencyLevel, targetLanguage } = req.body;

        if (!email || !password || !displayName) {
            return res.status(400).json({ error: 'Email, password, and display name are required.' });
        }

        const db = getDb();
        const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email);
        if (existing) {
            return res.status(409).json({ error: 'An account with this email already exists.' });
        }

        const id = uuidv4();
        const passwordHash = await bcrypt.hash(password, 12);

        db.prepare(`
            INSERT INTO users (id, email, password_hash, display_name, proficiency_level, target_language)
            VALUES (?, ?, ?, ?, ?, ?)
        `).run(id, email, passwordHash, displayName, proficiencyLevel || 'Beginner', targetLanguage || 'English');

        initSkillProfile(id);

        // Initialize streak
        db.prepare('INSERT INTO streaks (user_id) VALUES (?)').run(id);

        const token = generateToken(id);

        res.status(201).json({
            token,
            user: { id, email, displayName, proficiencyLevel: proficiencyLevel || 'Beginner', targetLanguage: targetLanguage || 'English' }
        });
    } catch (err) {
        console.error('Registration error:', err);
        res.status(500).json({ error: 'Failed to create account.' });
    }
});

router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password are required.' });
        }

        const db = getDb();
        const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email);

        if (!user) {
            return res.status(401).json({ error: 'Invalid email or password.' });
        }

        const valid = await bcrypt.compare(password, user.password_hash);
        if (!valid) {
            return res.status(401).json({ error: 'Invalid email or password.' });
        }

        const token = generateToken(user.id);

        res.json({
            token,
            user: {
                id: user.id,
                email: user.email,
                displayName: user.display_name,
                proficiencyLevel: user.proficiency_level,
                targetLanguage: user.target_language,
                dailyGoal: user.daily_goal
            }
        });
    } catch (err) {
        console.error('Login error:', err);
        res.status(500).json({ error: 'Failed to log in.' });
    }
});

router.get('/me', (req, res) => {
    // This route requires auth middleware applied at server level
    const db = getDb();
    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.userId);
    if (!user) return res.status(404).json({ error: 'User not found.' });

    res.json({
        id: user.id,
        email: user.email,
        displayName: user.display_name,
        proficiencyLevel: user.proficiency_level,
        targetLanguage: user.target_language,
        dailyGoal: user.daily_goal
    });
});

router.put('/me', (req, res) => {
    const { proficiencyLevel, targetLanguage, displayName, dailyGoal } = req.body;
    const db = getDb();

    const updates = [];
    const values = [];

    if (proficiencyLevel) { updates.push('proficiency_level = ?'); values.push(proficiencyLevel); }
    if (targetLanguage) { updates.push('target_language = ?'); values.push(targetLanguage); }
    if (displayName) { updates.push('display_name = ?'); values.push(displayName); }
    if (dailyGoal) { updates.push('daily_goal = ?'); values.push(dailyGoal); }

    if (updates.length === 0) return res.status(400).json({ error: 'No fields to update.' });

    updates.push("updated_at = datetime('now')");
    values.push(req.userId);

    db.prepare(`UPDATE users SET ${updates.join(', ')} WHERE id = ?`).run(...values);

    res.json({ success: true });
});

export default router;
