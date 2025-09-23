import SearchResult from '../models/searchResultModel.js';

/**
 * GET /api/search?q=...
 * Fuzzy prefix search on symbol or name.
 * Seeds a placeholder if nothing found (so frontend always gets at least one item for a new symbol).
 */
export async function search(req, res) {
  try {
    const q = (req.query.q || '').trim();
    if (!q) return res.json([]);

    const rxPrefix = new RegExp('^' + q, 'i');
    const results = await SearchResult.find({
      $or: [{ symbol: rxPrefix }, { name: rxPrefix }]
    }).limit(15);

    if (results.length > 0) return res.json(results);

    // Seed minimal placeholder
    const seeded = await SearchResult.create({
      symbol: q.toUpperCase(),
      name: q.toUpperCase() + ' Corp',
      type: 'EQUITY',
      sector: 'Tech',
      exchange: 'NSE'
    });
    return res.json([seeded]);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}

/**
 * Optional: POST /api/search (admin/seed)
 * Body: { symbol, name, type, sector, exchange }
 */
export async function addSearchResult(req, res) {
  try {
    const { symbol, name, type = 'EQUITY', sector, exchange } = req.body;
    if (!symbol || !name) {
      return res.status(400).json({ message: 'symbol and name required' });
    }
    const existing = await SearchResult.findOne({ symbol });
    if (existing) return res.status(409).json({ message: 'Symbol already exists' });
    const doc = await SearchResult.create({ symbol, name, type, sector, exchange });
    res.status(201).json(doc);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}

export async function trending(req, res) {
  try {
    const defaults = ['AAPL','MSFT','GOOGL','AMZN','TSLA','NVDA'];
    let list = await SearchResult.find({}).limit(12);
    if (!list.length) {
      // seed minimal defaults (reuse existing search logic style)
      const created = [];
      for (const sym of defaults) {
        let doc = await SearchResult.findOne({ symbol: sym });
        if (!doc) {
          doc = await SearchResult.create({
            symbol: sym,
            name: sym + ' Corp',
            type: 'EQUITY',
            sector: 'Tech',
            exchange: 'NSE'
          });
        }
        created.push(doc);
      }
      list = created;
    }
    res.json(list);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}

export async function getTrending(req, res) {
  try {
    const limit = Math.min(parseInt(req.query.limit || '10', 10), 25);
    // If you have a real collection, query it here. Placeholder static list:
    const sample = [
      { symbol: 'XOM', name: 'Exxon Mobil', exchange: 'NYSE', assetType: 'Stock' },
      { symbol: 'LLY', name: 'Eli Lilly & Co', exchange: 'NYSE', assetType: 'Stock' },
      { symbol: 'AMD', name: 'Advanced Micro Devices', exchange: 'NASDAQ', assetType: 'Stock' },
      { symbol: 'CRM', name: 'Salesforce Inc', exchange: 'NYSE', assetType: 'Stock' },
      { symbol: 'ORCL', name: 'Oracle Corp', exchange: 'NYSE', assetType: 'Stock' },
      { symbol: 'KO', name: 'Coca-Cola Co', exchange: 'NYSE', assetType: 'Stock' },
      { symbol: 'COST', name: 'Costco Wholesale', exchange: 'NASDAQ', assetType: 'Stock' },
      { symbol: 'BAC', name: 'Bank of America', exchange: 'NYSE', assetType: 'Stock' },
      { symbol: 'JNJ', name: 'Johnson & Johnson', exchange: 'NYSE', assetType: 'Stock' },
      { symbol: 'DIS', name: 'Walt Disney Co', exchange: 'NYSE', assetType: 'Stock' },
    ];
    res.json(sample.slice(0, limit));
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}