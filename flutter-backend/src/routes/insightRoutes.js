import express from 'express';
import {
  listInsights,
  getInsight,
  createInsight,
  updateInsight,
  deleteInsight,
  riskReturnData,
  correlationData,
  feesReturnData,
  whatIfData,
} from '../controllers/insightController.js';

const router = express.Router();

router.get('/', listInsights);
router.get('/risk-return', riskReturnData);
router.get('/correlation', correlationData);
router.get('/fees-return', feesReturnData);
router.get('/what-if', whatIfData);
router.get('/:id', getInsight);
router.post('/', createInsight);
router.put('/:id', updateInsight);
router.delete('/:id', deleteInsight);

export default router;