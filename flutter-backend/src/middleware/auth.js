import jwt from 'jsonwebtoken';
export function authGuard(req, res, next) {
  const auth = req.headers.authorization || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
  
  if (!token) {
    console.log('No token provided');
    return res.status(401).json({ error: 'Authentication token required' });
  }
  
  console.log('Token:', token);
  console.log('JWT_SECRET:', process.env.JWT_SECRET ? 'Set' : 'Not set');
  
  try {
    const userDoc = jwt.verify(token, process.env.JWT_SECRET);
    req.user = {
      ...userDoc.toObject?.() ?? userDoc,
      id: userDoc.id || userDoc._id?.toString()
    };
    console.log('Token verified successfully for user:', req.user.id);
    next();
  } catch (error) {
    console.log('Invalid token:', error.message);
    return res.status(401).json({ error: 'Invalid authentication token' });
  }
}