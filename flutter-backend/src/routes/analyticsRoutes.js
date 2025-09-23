import { Router } from 'express';
import { authGuard } from '../middleware/auth.js';
import { getAnalytics, getEarnings, getPerformance } from '../controllers/analyticsController.js';

const router = Router();

router.use(authGuard);

router.get('/', getAnalytics);
router.get('/earnings', getEarnings);
router.get('/performance', getPerformance);

export default router;