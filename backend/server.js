import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { authMiddleware } from './middleware/auth.js';
import authRoutes from './routes/auth.js';
import sessionRoutes from './routes/sessions.js';
import analyticsRoutes from './routes/analytics.js';

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' })); // Large limit for audio data

// Public routes
app.use('/api/auth', authRoutes);

// Protected routes
app.use('/api/auth', authMiddleware, authRoutes); // /me and /me PUT
app.use('/api/sessions', authMiddleware, sessionRoutes);
app.use('/api/analytics', authMiddleware, analyticsRoutes);

// Health check
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', version: '1.0.0' });
});

app.listen(PORT, () => {
    console.log(`Lingo backend running on port ${PORT}`);
});
