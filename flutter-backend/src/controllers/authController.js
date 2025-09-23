import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import User from '../models/userModel.js';

function signToken(user) {
  return jwt.sign(
    { id: user._id, email: user.email },
    process.env.JWT_SECRET || 'dev_secret',
    { expiresIn: '7d' }
  );
}

export async function registerUser(req, res) {
  try {
    const { email, password, name } = req.body;
    if (!email || !password || !name)
      return res.status(400).json({ message: 'email, password, name required' });

    const existing = await User.findOne({ email });
    if (existing) return res.status(409).json({ message: 'Email in use' });

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await User.create({ email, name, passwordHash });
    const token = signToken(user);
    res.status(201).json({
      user: { id: user._id, email: user.email, name: user.name },
      token
    });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}

export async function loginUser(req, res) {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(401).json({ message: 'Invalid credentials' });

    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) return res.status(401).json({ message: 'Invalid credentials' });

    const token = signToken(user);
    res.json({
      user: { id: user._id, email: user.email, name: user.name },
      token
    });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}