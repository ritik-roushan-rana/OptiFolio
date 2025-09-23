import { Router } from 'express';
import { authGuard } from '../middleware/auth.js';
import { listBacktestResults, runBacktest, getBacktestResult } from '../controllers/backtestResultController.js';

const router = Router();

// List (and seed if empty)
router.get('/', authGuard, listBacktestResults);

// Run new backtest
router.post('/run', authGuard, runBacktest);

// Single result
router.get('/:id', authGuard, getBacktestResult);

export default router;