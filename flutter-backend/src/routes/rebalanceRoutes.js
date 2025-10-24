import { Router } from 'express';
import { getRecommendations, applyRebalance, ignoreRebalance } from '../controllers/rebalanceController.js';
import { authGuard } from '../middleware/auth.js';

const router = Router();

router.get('/', authGuard, getRecommendations);
router.post('/', authGuard, getRecommendations);
router.post('/apply', authGuard, applyRebalance);
router.post('/ignore', authGuard, ignoreRebalance);

export default router;