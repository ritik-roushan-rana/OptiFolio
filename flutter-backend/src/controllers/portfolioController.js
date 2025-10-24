import xlsx from 'xlsx';
import Portfolio from '../models/portfolioModel.js';

// Empty response shape
function emptyPortfolio() {
  return {
    totalValue: 0,
    valueChange: 0,
    valueChangePercent: 0,
    riskScore: 0,
    performanceHistory: { '1M': [], '3M': [], '1Y': [] },
    holdings: []
  };
}

// GET /api/portfolio/me
export async function getMyPortfolio(req, res) {
  const p = await Portfolio.findOne({ userId: req.user.id });
  res.json(p ? { id: p._id } : null);
}

// GET /api/portfolio/data
export async function getPortfolioData(req, res) {
  const p = await Portfolio.findOne({ userId: req.user.id });
  if (!p || !p.positions || !p.positions.length) {
    return res.json(emptyPortfolio());
  }

  const holdingsRaw = p.positions.map((pos, idx) => {
    let symbol = (pos.symbol || '').toString().trim().toUpperCase();
    let name = (pos.name || '').toString().trim();

    // Fallback derivations
    if (!symbol && name) {
      const first = name.split(/[^A-Za-z0-9]+/)[0];
      if (first) symbol = first.substring(0, 8).toUpperCase();
    }
    if (!name && symbol) name = symbol;
    if (!symbol && !name) {
      symbol = `ASSET${idx + 1}`;
      name = symbol;
    }

    const value = (pos.quantity || 0) * (pos.avgPrice || 0);
    const changePercent = Number(((Math.random() - 0.5) * 6).toFixed(2));

    return {
      // core
      symbol,
      name,
      // aliases for frontend models that may look for these:
      ticker: symbol,
      displaySymbol: symbol,
      displayName: name,
      label: name || symbol,
      value,
      changePercent,
      iconUrl: `https://logo.clearbit.com/${symbol.toLowerCase()}.com`
    };
  });

  const totalValue = holdingsRaw.reduce((s, h) => s + h.value, 0);
  const holdings = holdingsRaw.map(h => ({
    ...h,
    percentage: totalValue ? Number(((h.value / totalValue) * 100).toFixed(2)) : 0
  }));

  // Simple synthetic performance history
  function makeSeries(points, start) {
    let base = start;
    return Array.from({ length: points }, () => {
      base *= 1 + (Math.random() - 0.5) * 0.01;
      return Number(base.toFixed(2));
    });
  }

  const performanceHistory = {
    '1M': makeSeries(30, totalValue || 10000),
    '3M': makeSeries(13, (totalValue || 10000) * 0.95),
    '6M': makeSeries(26, (totalValue || 10000) * 0.9),
    '1Y': makeSeries(52, (totalValue || 10000) * 0.8)
  };

  const valueChange = Number((holdings.reduce((s, h) => s + (h.value * h.changePercent / 100), 0)).toFixed(2));
  const valueChangePercent = totalValue
    ? Number(((valueChange / (totalValue - valueChange)) * 100).toFixed(2))
    : 0;

  res.json({
    totalValue,
    valueChange,
    valueChangePercent,
    riskScore: 5,
    performanceHistory,
    holdings
  });
}

// POST /api/portfolio  (create or update)
export async function upsertPortfolio(req, res) {
  try {
    const { portfolioName = 'My Portfolio', description = '' } = req.body;
    let positions = [];

    if (req.file) {
      const wb = xlsx.read(req.file.buffer, { type: 'buffer', raw: true });
      const sheet = wb.Sheets[wb.SheetNames[0]];
      const rows = xlsx.utils.sheet_to_json(sheet, { defval: null });

      const pick = (o, keys) => {
        for (const k of keys) {
          if (o[k] !== undefined && o[k] !== null && o[k] !== '') return o[k];
          // also try lowercase key if not already
          const kl = k.toLowerCase();
          if (o[kl] !== undefined && o[kl] !== null && o[kl] !== '') return o[kl];
        }
        return undefined;
      };

      positions = rows
        .filter(r => {
          const ent = (r.entity || r.Entity || '').toString().toLowerCase();
          return !r.entity || !ent || ent === 'holding';
        })
        .map((r, idx) => {
          // Improved pick function to support lowercase and alternate names
          const pick = (o, keys) => {
            for (const k of keys) {
              if (o[k] !== undefined && o[k] !== null && o[k] !== '') return o[k];
              const kl = k.toLowerCase();
              if (o[kl] !== undefined && o[kl] !== null && o[kl] !== '') return o[kl];
            }
            return undefined;
          };

          let symbol = (pick(r, ['Symbol','symbol','Ticker','Asset','Security','Instrument']) || '')
            .toString()
            .trim()
            .toUpperCase();

          let name = (pick(r, ['Name','name','SecurityName','Description']) || '').toString().trim();

          // Derive symbol if missing
          if (!symbol && name) {
            const first = name.split(/[^A-Za-z0-9]+/)[0];
            if (first.length >= 1 && first.length <= 8) symbol = first.toUpperCase();
          }
          if (!name && symbol) name = symbol;

          const quantity = Number(pick(r, ['Quantity','quantity','Shares','shares','Units','Qty'])) || 0;
          let avgPrice = Number(pick(r, ['AvgPrice','avgPrice','Price','price','CostBasisPerShare'])) || 0;
          if (!avgPrice) {
            const totalValue = Number(pick(r, ['Value','value','MarketValue','CurrentValue'])) || 0;
            if (totalValue && quantity) avgPrice = totalValue / quantity;
          }
          const targetAllocation = Number(pick(r, ['TargetAllocation','Allocation','Weight'])) || 0;

          // Always sanitize symbol before storing
          symbol = symbol.trim().toUpperCase();

          return {
            symbol,
            name,
            quantity,
            avgPrice: Number(avgPrice.toFixed(2)),
            targetAllocation,
            currentAllocation: 0
          };
        })
        .filter(p => (p.symbol || p.name)) // keep if at least name present
        .map((p, idx) => {
          if (!p.symbol && p.name) {
            const first = p.name.split(/[^A-Za-z0-9]+/)[0];
            if (first) p.symbol = first.substring(0, 8).toUpperCase();
          }
          if (!p.symbol && !p.name) {
            p.symbol = `ASSET${idx + 1}`;
            p.name = p.symbol;
          }
          p.quantity = p.quantity || 0;
          p.avgPrice = p.avgPrice || 0;
          return p;
        });

    if (positions.length) {
      console.log('Imported positions (sanitized):', positions.map(x => ({ symbol: x.symbol, quantity: x.quantity, avgPrice: x.avgPrice, name: x.name })));
    }

    let p = await Portfolio.findOne({ userId: req.user.id });
    if (p) {
      if (positions.length) p.positions = positions;
      p.portfolioName = portfolioName;
      p.description = description;
      await p.save();
      return res.status(200).json({ message: 'Updated', id: p._id, imported: positions.length });
    }
    p = await Portfolio.create({
      userId: req.user.id,
      portfolioName,
      description,
      positions
    });
    res.status(201).json({ message: 'Created', id: p._id, imported: positions.length });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}