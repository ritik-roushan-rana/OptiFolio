import Portfolio from '../models/portfolioModel.js';

/**
 * Shape returned (matches Frontend PortfolioData / AssetData models):
 * {
 *   totalValue: Number,
 *   valueChange: Number,
 *   valueChangePercent: Number,
 *   riskScore: Number (0-100),
 *   performanceHistory: {
 *      "1D": [ ... ],
 *      "1W": [ ... ],
 *      "1M": [ ... ],
 *      "3M": [ ... ],
 *      "1Y": [ ... ]
 *   },
 *   holdings: [
 *     {
 *       symbol, name, value, percentage, changePercent, iconUrl
 *     }
 *   ]
 * }
 */
export async function getPortfolioData(req, res) {
  try {
    const portfolio = await Portfolio.findOne({ userId: req.user.id });
    if (!portfolio || !portfolio.positions || portfolio.positions.length === 0) {
      return res.json(emptyResponse());
    }

    // Derive holdings
    const holdingsRaw = portfolio.positions.map(p => {
      const value = (p.quantity || 0) * (p.avgPrice || 0);
      // Mock daily change percent between -3% and +3%
      const changePercent = Number(((Math.random() - 0.5) * 6).toFixed(2));
      return {
        symbol: p.symbol || '',
        name: p.name || p.symbol || '',
        value,
        changePercent,
        iconUrl: `https://logo.clearbit.com/${(p.symbol || 'example').toLowerCase()}.com`
      };
    });

    const totalValue = holdingsRaw.reduce((s, h) => s + h.value, 0);
    // Assign percentage
    const holdings = holdingsRaw.map(h => ({
      ...h,
      percentage: totalValue > 0 ? Number(((h.value / totalValue) * 100).toFixed(2)) : 0
    }));

    // Mock P/L (valueChange) as sum(value * changePercent/100)
    const valueChange = holdings.reduce((s, h) => s + h.value * (h.changePercent / 100), 0);
    const valueChangePercent = totalValue > 0 ? (valueChange / (totalValue - valueChange)) * 100 : 0;

    // Risk score heuristic: higher dispersion & avg abs change => higher risk
    const avgAbsChange = holdings.length
      ? holdings.reduce((s, h) => s + Math.abs(h.changePercent), 0) / holdings.length
      : 0;
    const weightVariance = variance(holdings.map(h => h.percentage || 0));
    let riskScore = Math.min(
      100,
      Math.round(avgAbsChange * 8 + Math.sqrt(weightVariance) * 2)
    );
    if (Number.isNaN(riskScore)) riskScore = 0;

    const performanceHistory = mockPerformanceHistory(totalValue || 10000);

    res.json({
      totalValue: Number(totalValue.toFixed(2)),
      valueChange: Number(valueChange.toFixed(2)),
      valueChangePercent: Number(valueChangePercent.toFixed(2)),
      riskScore,
      performanceHistory,
      holdings
    });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}

/**
 * Optional: PUT /api/portfolio/data/holdings
 * Body: { holdings: [{ symbol, name, quantity, avgPrice, targetAllocation }] }
 * Updates underlying Portfolio.positions, recalculations will appear in GET.
 */
export async function upsertHoldings(req, res) {
  try {
    const { holdings = [], portfolioName = 'Main Portfolio', description = '' } = req.body;
    if (!Array.isArray(holdings)) {
      return res.status(400).json({ message: 'holdings must be an array' });
    }

    let portfolio = await Portfolio.findOne({ userId: req.user.id });
    if (!portfolio) {
      portfolio = await Portfolio.create({
        userId: req.user.id,
        portfolioName,
        description,
        positions: []
      });
    }

    portfolio.portfolioName = portfolioName || portfolio.portfolioName;
    portfolio.description = description || portfolio.description;
    portfolio.positions = holdings.map(h => ({
      symbol: h.symbol,
      name: h.name || h.symbol,
      quantity: Number(h.quantity || 0),
      avgPrice: Number(h.avgPrice || 0),
      targetAllocation: Number(h.targetAllocation || 0),
      currentAllocation: 0
    }));
    await portfolio.save();

    res.status(200).json({ message: 'Holdings updated' });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}

/**
 * Utility functions
 */
function emptyResponse() {
  return {
    totalValue: 0,
    valueChange: 0,
    valueChangePercent: 0,
    riskScore: 0,
    performanceHistory: {
      '1D': [],
      '1W': [],
      '1M': [],
      '3M': [],
      '1Y': []
    },
    holdings: []
  };
}

function mockPerformanceHistory(base) {
  // Generates simple upward-ish sequences
  return {
    '1D': series(base, 6, 0.001),
    '1W': series(base, 7, 0.004),
    '1M': series(base, 30, 0.006),
    '3M': series(base, 13, 0.01),
    '1Y': series(base, 12, 0.015)
  };
}

function series(start, points, drift) {
  let v = start;
  return Array.from({ length: points }).map(() => {
    const change = v * ((Math.random() - 0.5) * drift);
    v += change;
    return Number(v.toFixed(2));
  });
}

function variance(arr) {
  if (arr.length === 0) return 0;
  const mean = arr.reduce((s, v) => s + v, 0) / arr.length;
  return arr.reduce((s, v) => s + Math.pow(v - mean, 2), 0) / arr.length;
}

export const getPortfolioExists = async (req, res) => {
  // TODO: real check
  res.json({ exists: true });
};

export const getPortfolioData = async (req, res) => {
  const performanceHistory = {
    '1D': [10000, 10020, 10010, 10040, 10080],
    '1W': [9600, 9700, 9800, 9900, 10020, 10050, 10080],
    '1M': [9000, 9200, 9400, 9600, 9800, 10000, 10080],
  };
  res.json({
    totalValue: 10080,
    valueChange: 80,
    valueChangePercent: 0.8,
    riskScore: 5,
    performanceHistory,
    assetSummary: [],
    allocation: [],
    holdings: [] // add if frontend expects it
  });
};