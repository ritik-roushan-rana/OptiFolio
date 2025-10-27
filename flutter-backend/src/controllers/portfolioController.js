import xlsx from 'xlsx';
import Portfolio from '../models/portfolioModel.js';

// Empty response shape
function emptyPortfolio() {
  return {
    totalValue: 0,
    valueChange: 0,
    valueChangePercent: 0,
    riskScore: 0,
    performanceHistory: { '1D': [], '1W': [], '1M': [], '3M': [], '6M': [], '1Y': [] },
    holdings: []
  };
}

// --- helpers to generate realistic history and risk ---
function series(start, points, drift) {
  let v = start || 10000;
  return Array.from({ length: points }).map(() => {
    const change = v * ((Math.random() - 0.5) * drift);
    v += change;
    return Number(v.toFixed(2));
  });
}
function mockPerformanceHistory(base) {
  const b = base || 10000;
  return {
    '1D': series(b, 6, 0.001),
    '1W': series(b, 7, 0.004),
    '1M': series(b, 30, 0.006),
    '3M': series(b, 13, 0.01),
    '6M': series(b, 26, 0.012),
    '1Y': series(b, 52, 0.015),
  };
}
function variance(arr) {
  if (!arr || !arr.length) return 0;
  const mean = arr.reduce((s, v) => s + v, 0) / arr.length;
  return arr.reduce((s, v) => s + Math.pow(v - mean, 2), 0) / arr.length;
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
    // Prefer actual daily change percent if provided, else generate a realistic mock (-3%..+3%)
    const changePercent = (typeof pos.dayChangePct === 'number' && !Number.isNaN(pos.dayChangePct))
      ? Number(pos.dayChangePct)
      : Number(((Math.random() - 0.5) * 6).toFixed(2));

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

  // Non-flat performance: use saved history if present else mock based on total value
  const hasHistory = p.performanceHistory && Object.keys(p.performanceHistory || {}).length > 0;
  const performanceHistory = hasHistory ? p.performanceHistory : mockPerformanceHistory(totalValue || 10000);

  // Aggregate P/L
  const valueChangeRaw = holdings.reduce((s, h) => s + (h.value * h.changePercent / 100), 0);
  const valueChange = Number(valueChangeRaw.toFixed(2));
  const denom = (totalValue - valueChange);
  const valueChangePercent = denom !== 0 ? Number(((valueChange / denom) * 100).toFixed(2)) : 0;

  // Simple risk score from dispersion and average abs change
  const avgAbsChange = holdings.length
    ? holdings.reduce((s, h) => s + Math.abs(h.changePercent), 0) / holdings.length
    : 0;
  const weightVariance = variance(holdings.map(h => h.percentage || 0));
  // Scale to 0-10 range to match frontend (was 0-100)
  let riskScore = Math.min(10, Math.max(0, Math.round(avgAbsChange * 0.8 + Math.sqrt(weightVariance) * 0.2)));
  if (Number.isNaN(riskScore)) riskScore = 0;

  res.json({
    totalValue: Number(totalValue.toFixed(2)),
    valueChange,
    valueChangePercent,
    riskScore,
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

      // Improved pick function to support lowercase and alternate names
      const pick = (o, keys) => {
        for (const k of keys) {
          if (o[k] !== undefined && o[k] !== null && o[k] !== '') return o[k];
          const kl = k.toLowerCase();
          if (o[kl] !== undefined && o[kl] !== null && o[kl] !== '') return o[kl];
        }
        // Try fuzzy match: find first key containing the search string
        for (const k of Object.keys(o)) {
          for (const search of keys) {
            if (k.toLowerCase().includes(search.toLowerCase()) && o[k] !== undefined && o[k] !== null && o[k] !== '') {
              return o[k];
            }
          }
        }
        return undefined;
      };

      positions = rows
        .map((r, idx) => {
          // Debug log raw row
          console.log('Raw portfolio row:', r);
          let symbol = (pick(r, ['Symbol','symbol','Ticker','Asset','Security','Instrument']) || '').toString().trim().toUpperCase();
          let name = (pick(r, ['Name','name','SecurityName','Description']) || '').toString().trim();

          // Derive symbol if missing
          if (!symbol && name) {
            // Use first alphanumeric substring up to 8 chars
            const match = name.match(/[A-Za-z0-9]{1,8}/);
            if (match) symbol = match[0].toUpperCase();
          }
          if (!name && symbol) name = symbol;

          let quantity = Number(pick(r, ['Quantity','quantity','Shares','shares','Units','Qty']));
          if (isNaN(quantity)) quantity = 0;
          let avgPrice = Number(pick(r, ['AvgPrice','avgPrice','Price','price','CostBasisPerShare']));
          if (isNaN(avgPrice)) avgPrice = 0;
          if (!avgPrice) {
            const totalValue = Number(pick(r, ['Value','value','MarketValue','CurrentValue']));
            if (totalValue && quantity) avgPrice = totalValue / quantity;
          }
          const targetAllocation = Number(pick(r, ['TargetAllocation','Allocation','Weight']));

          // Always sanitize symbol and name before storing
          symbol = symbol.replace(/[^A-Z0-9]/g, '').trim().toUpperCase();
          name = name.replace(/[^A-Za-z0-9 ]/g, '').trim();

          // Debug log sanitized row
          console.log('Sanitized portfolio row:', { symbol, name, quantity, avgPrice, targetAllocation });

          return {
            symbol,
            name,
            quantity,
            avgPrice: Number(avgPrice.toFixed(2)),
            targetAllocation: isNaN(targetAllocation) ? 0 : targetAllocation,
            currentAllocation: 0
          };
        })
        .filter(r => {
          const ent = (r.entity || r.Entity || '').toString().toLowerCase();
          return !r.entity || !ent || ent === 'holding';
        })
        .filter(p => (p.symbol || p.name)) // keep if at least name present
        .map((p, idx) => {
          if (!p.symbol && p.name) {
            const match = p.name.match(/[A-Za-z0-9]{1,8}/);
            if (match) p.symbol = match[0].toUpperCase();
          }
          if (!p.symbol && !p.name) {
            p.symbol = `ASSET${idx + 1}`;
            p.name = p.symbol;
          }
          p.quantity = p.quantity || 0;
          p.avgPrice = p.avgPrice || 0;
          return p;
        });
    }

    if (positions.length) {
      console.log('Imported positions (sanitized):', positions.map(x => ({ symbol: x.symbol, quantity: x.quantity, avgPrice: x.avgPrice, name: x.name })));
    }

    let p = await Portfolio.findOne({ userId: req.user.id });
    if (p) {
      // Always update positions, even if empty (to allow clearing)
      p.positions = positions;
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
    console.error('Portfolio upsert error:', e);
    res.status(500).json({ message: e.message });
  }
}