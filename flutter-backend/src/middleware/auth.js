import jwt from 'jsonwebtoken';
export function authGuard(req, res, next) {
  const auth = req.headers.authorization || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
  if (!token) return res.status(401).json({ message: 'No token' });
  console.log('Token:', token);
  console.log('JWT_SECRET:', process.env.JWT_SECRET || 'dev_secret');
  try {
    const userDoc = jwt.verify(token, process.env.JWT_SECRET || 'dev_secret');
    req.user = {
      ...userDoc.toObject?.() ?? userDoc,
      id: userDoc.id || userDoc._id?.toString()
    };
    next();
  } catch {
    res.status(401).json({ message: 'Invalid token' });
  }
}