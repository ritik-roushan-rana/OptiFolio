import { Router } from 'express';
import { getQuote, getQuoteHistory } from '../controllers/quoteController.js';

const router = Router();

router.get('/:symbol/history', getQuoteHistory);
router.get('/:symbol', getQuote);

export default router;