import { Router } from 'express';
import multer from 'multer';
import { authGuard } from '../middleware/auth.js';
import { getMyPortfolio, getPortfolioData, upsertPortfolio } from '../controllers/portfolioController.js';

const upload = multer({ storage: multer.memoryStorage() });
const router = Router();

// Root endpoint
router.get('/', (req, res) => res.json({ message: 'Portfolio API' }));

// Check existence
// GET /api/portfolio/me
router.get('/me', authGuard, getMyPortfolio);

// Portfolio data (shape for app)
// GET /api/portfolio/data
router.get('/data', authGuard, getPortfolioData);

// Create / update via Excel upload (field name: file)
// POST /api/portfolio
router.post('/', authGuard, upload.single('file'), upsertPortfolio);

export default router;