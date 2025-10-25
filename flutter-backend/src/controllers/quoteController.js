import { Router } from 'express';

const router = Router();

// Quote + history controller returning shapes expected by Flutter StockQuote & HistoricalDataPoint.
function randomWithin(base, pct) {
  const delta = base * pct * (Math.random() - 0.5);
  return Number((base + delta).toFixed(2));
}

export async function getQuote(req, res) {
  const { symbol } = req.params;
  if (!symbol) return res.status(400).json({ message: 'Missing symbol' });

  // Increase the random delta for more visible price changes
  const previousClose = randomWithin(100, 0.10); // 10% range
  const current = randomWithin(previousClose, 0.10); // 10% range
  const change = Number((current - previousClose).toFixed(2));
  const percent = Number(((change / previousClose) * 100).toFixed(2));
  const high = Math.max(current, previousClose) + Number((Math.random() * 3).toFixed(2));
  const low = Math.min(current, previousClose) - Number((Math.random() * 3).toFixed(2));
  const open = randomWithin(previousClose, 0.05); // 5% range

  // Shape expected by StockQuote.fromJson (c,d,dp,h,l,o,pc)
  res.json({
    c: current,
    d: change,
    dp: percent,
    h: Number(high.toFixed(2)),
    l: Number(low.toFixed(2)),
    o: open,
    pc: previousClose
  });
}

export async function getQuoteHistory(req, res) {
  const { symbol } = req.params;
  const { resolution = 'D' } = req.query;
  if (!symbol) return res.status(400).json({ message: 'Missing symbol' });

  const points = 60; // 60 data points
  const now = Date.now();
  let base = 100;
  const out = Array.from({ length: points }).map((_, i) => {
    base *= 1 + (Math.random() - 0.5) * 0.01;
    const o = Number(base.toFixed(2));
    const h = Number((o + Math.random() * 1.2).toFixed(2));
    const l = Number((o - Math.random() * 1.2).toFixed(2));
    const c = Number(((h + l) / 2).toFixed(2));
    const v = Math.floor(80000 + Math.random() * 40000);
    // Use small sequential timestamp (index) to keep chart x-axis compact
    return { t: i, o, h, l, c, v };
  });

  res.json(out);
}

router.get('/:symbol', getQuote);

export default router;