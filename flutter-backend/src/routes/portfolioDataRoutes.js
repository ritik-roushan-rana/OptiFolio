import { Router } from 'express';
import { authGuard } from '../middleware/auth.js';
import { getPortfolioData, upsertHoldings } from '../controllers/portfolioDataController.js';

const router = Router();
router.get('/', authGuard, getPortfolioData);
router.put('/holdings', authGuard, upsertHoldings);

export default router;