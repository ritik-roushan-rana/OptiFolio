import { Router } from 'express';
const router = Router();
router.get('/', (req, res) => {
  const q = (req.query.q || '').toString().toUpperCase();
  if (!q) return res.json([]);
  res.json([
    { symbol: q, name: `${q} Corp`, type: 'EQUITY' }
  ]);
});
export default router;