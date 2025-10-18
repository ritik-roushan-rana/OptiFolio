import jwt from 'jsonwebtoken';

const payload = { id: '68d410a2ea11a41416995b2f' };
const secret = 'a_very_strong_and_long_random_secret_string'; // Replace with your actual JWT_SECRET
const token = jwt.sign(payload, secret, { expiresIn: '1h' });

console.log('Generated Token:', token);
