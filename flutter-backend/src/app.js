import express from 'express';
import 'dotenv/config';
import cors from 'cors';
import morgan from 'morgan';
import { connectDB } from './db.js';

// Debug environment 
console.log('Environment variables loaded:');
console.log('JWT_SECRET:', process.env.JWT_SECRET ? `${process.env.JWT_SECRET.slice(0, 10)}...` : 'NOT SET');
console.log('MONGODB_URI:', process.env.MONGODB_URI ? 'SET' : 'NOT SET');
console.log('GEMINI_API_KEY:', process.env.GEMINI_API_KEY ? 'SET' : 'NOT SET');
console.log('FINNHUB_API_KEY:', process.env.FINNHUB_API_KEY ? 'SET' : 'NOT SET');

import authRoutes from './routes/authRoutes.js';
import portfolioRoutes from './routes/portfolioRoutes.js';
import insightRoutes from './routes/insightRoutes.js';
import newsRoutes from './routes/newsRoutes.js';
// import backtestResultRoutes from './routes/backtestResultRoutes.js';
import rebalanceRoutes from './routes/rebalanceRoutes.js';
import alertRoutes from './routes/alertRoutes.js';
import searchResultRoutes from './routes/searchResultRoutes.js';
import stockDataRoutes from './routes/stockDataRoutes.js';
import analyticsRoutes from './routes/analyticsRoutes.js';
import quoteRoutes from './routes/quoteRoutes.js';
import companyRoutes from './routes/companyRoutes.js';
import searchRoutes from './routes/searchRoutes.js';
import backtestRoutes from './routes/backtestRoutes.js';
import settingsRoutes from './routes/settingsRoutes.js';
import chatbotRoutes from './routes/chatbotRoutes.js';

const app = express();
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true
}));
app.use(express.json({ limit: '2mb' }));
app.use(morgan('dev'));

app.use((req, res, next) => {
  if (!req.originalUrl) {
    console.log('EMPTY originalUrl detected');
  }
  console.log('REQ', req.method, `[${req.originalUrl}] len=${req.originalUrl.length}`);
  next();
});

app.get('/', (req, res) => {
  res.json({ status: 'ok', message: 'API root' });
});

app.get('/api', (_req, res) => res.json({ status: 'ok', message: 'API base' }));

app.get('/api/health', (_req, res) => res.json({ status: 'ok' }));

app.use('/api/auth', authRoutes);
app.use('/api/portfolio', portfolioRoutes);
app.use('/api/insights', insightRoutes);
app.use('/api/news', newsRoutes);
// app.use('/api/backtests', backtestResultRoutes);
app.use('/api/rebalance', rebalanceRoutes);
app.use('/api/alerts', alertRoutes);
app.use('/api/search', searchResultRoutes);
app.use('/api/stocks', stockDataRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/quotes', quoteRoutes);
app.use('/quotes', quoteRoutes); // optional to support legacy/non-api path
app.use('/api/companies', companyRoutes);
app.use('/api/search', searchRoutes);
app.use('/api/backtests', backtestRoutes);
app.use('/api/settings', settingsRoutes);

// chatbot routes coming last
app.use('/api', chatbotRoutes);

app.use((_, res) => res.status(404).json({ message: 'Not found' }));

const PORT = process.env.PORT || 3000;

(async () => {
  try {
    await connectDB(process.env.MONGODB_URI);
    app.listen(PORT, () => console.log('Server listening on', PORT));
  } catch (e) {
    console.error('Failed to start server:', e);
    process.exit(1);
  }
})();