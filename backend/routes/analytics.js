import { Router } from 'express';
import { getLearningInsights } from '../services/adaptive.js';

const router = Router();

// Get comprehensive learning analytics
router.get('/insights', (req, res) => {
    try {
        const insights = getLearningInsights(req.userId);
        res.json(insights);
    } catch (err) {
        console.error('Analytics error:', err);
        res.status(500).json({ error: 'Failed to fetch analytics.' });
    }
});

export default router;
