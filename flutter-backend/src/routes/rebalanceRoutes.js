import { Router } from 'express';
import { getRecommendations, applyRebalance } from '../controllers/rebalanceController.js';
import { authGuard } from '../middleware/auth.js';

const router = Router();

router.get('/', authGuard, getRecommendations);
router.post('/', authGuard, getRecommendations);
router.post('/apply', authGuard, applyRebalance);

export default router;