import { Router } from 'express';
import { search, addSearchResult, trending, getTrending } from '../controllers/searchResultController.js';
import { authGuard } from '../middleware/auth.js';

const router = Router();

// Public search (GET /api/search)
router.get('/', search);

// Protected add (POST /api/search)
router.post('/', authGuard, addSearchResult);

// Remove redundant nested /search paths and define clean trending route
router.get('/trending', getTrending);

export default router;