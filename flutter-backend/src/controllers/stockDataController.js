import StockData from '../models/stockDataModel.js';

export async function getStock(req, res) {
  const { symbol } = req.params;
  let doc = await StockData.findOne({ symbol });
  if (!doc) {
    doc = await StockData.create({
      symbol,
      profile: { name: symbol + ' Corp', sector: 'Tech', description: 'Placeholder profile' },
      fundamentals: { pe: 22.4, eps: 3.1, marketCap: 5500000000 },
      technical: { rsi: 49, sma50: 120, sma200: 112 },
      history: Array.from({ length: 30 }).map((_, i) => ({
        t: new Date(Date.now() - (30 - i) * 86400000),
        open: 100 + i,
        high: 101 + i,
        low: 99 + i,
        close: 100 + i,
        volume: 100000 + i * 500
      }))
    });
  }
  res.json(doc);
}