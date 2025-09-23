import { Router } from 'express';
import { getCuratedNews, getNewsAlerts } from '../controllers/newsController.js';
import { authGuard } from '../middleware/auth.js';

const router = Router();

// /api/news/curated
router.get('/curated', authGuard, getCuratedNews);

// /api/news/alerts
router.get('/alerts', authGuard, getNewsAlerts);

export default router;