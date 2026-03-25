import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'lingo-dev-secret-change-in-production';

export function generateToken(userId) {
    return jwt.sign({ userId }, JWT_SECRET, { expiresIn: '30d' });
}

export function authMiddleware(req, res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Authentication required' });
    }

    const token = authHeader.split(' ')[1];
    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        req.userId = decoded.userId;
        next();
    } catch {
        return res.status(401).json({ error: 'Invalid or expired token' });
    }
}
