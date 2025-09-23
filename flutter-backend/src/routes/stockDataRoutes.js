import { Router } from 'express';

const router = Router();
router.get('/:symbol', (req, res) => {
  const s = req.params.symbol.toUpperCase();
  res.json({
    symbol: s,
    profile: { name: `${s} Corp`, sector: 'Technology', description: 'Stub description' },
    fundamentals: { pe: 22.4, eps: 5.1, marketCap: 1234.56 },
    technical: { rsi: 51.2, sma50: 100, sma200: 95 },
    history: []
  });
});

export default router;