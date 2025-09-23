import BacktestResult from '../models/backtestResultModel.js';

/**
 * GET /api/backtests
 * Returns (and auto-seeds if empty) the set of backtest results for the user.
 */
export async function listBacktestResults(req, res) {
  try {
    console.log('listBacktestResults userId=', req.user?.id);
    let docs = await BacktestResult.find({ userId: req.user.id }).sort({ period: 1 });
    console.log('found docs len', docs.length);
    if (docs.length === 0) {
      docs = await BacktestResult.insertMany(seedResults(req.user.id));
      console.log('seeded docs len', docs.length);
    }
    return res.json(docs);
  } catch (e) {
    console.error('listBacktestResults error', e);
    return res.status(500).json({ message: e.message });
  }
}

/**
 * POST /api/backtests/run
 * Body: { period?: string }
 * Creates a new synthetic backtest for the requested period.
 */
export async function runBacktest(req, res) {
  try {
    const { period = '1Y' } = req.body;
    const metrics = synthMetrics(period);
    const doc = await BacktestResult.create({
      userId: req.user.id,
      period,
      ...metrics,
      equityCurve: buildEquityCurve()
    });
    res.status(201).json(doc);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}

/**
 * GET /api/backtests/:id
 */
export async function getBacktestResult(req, res) {
  try {
    const doc = await BacktestResult.findOne({ _id: req.params.id, userId: req.user.id });
    if (!doc) return res.status(404).json({ message: 'Not found' });
    res.json(doc);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}

/* ----------------- Helpers ----------------- */

function seedResults(userId) {
  const periods = ['1M','3M','6M','1Y','3Y','5Y'];
  return periods.map(p => ({
    userId,
    period: p,
    ...synthMetrics(p),
    equityCurve: buildEquityCurve()
  }));
}

function synthMetrics(period) {
  // Simple synthetic logic varying by period length
  const scale = ({
    '1M': 0.02,
    '3M': 0.05,
    '6M': 0.10,
    '1Y': 0.20,
    '3Y': 0.60,
    '5Y': 1.00
  })[period] ?? 0.15;

  const returnPercent = +(randRange(scale * 0.5, scale * 1.4) * 100).toFixed(2);
  const volatility = +(randRange(0.10, 0.40) * Math.min(1, scale + 0.2)).toFixed(3);
  const maxDrawdown = +(-randRange(0.05, 0.35) * Math.min(1, scale + 0.3) * 100).toFixed(2);
  const sharpeRatio = +(randRange(0.4, 2.0) * Math.min(1.2, scale + 0.5)).toFixed(2);

  return { returnPercent, volatility, maxDrawdown, sharpeRatio };
}

function buildEquityCurve(points = 30, start = 10000) {
  const curve = [];
  let value = start;
  for (let i = 0; i < points; i++) {
    const drift = randRange(-0.01, 0.02); // small step
    value *= (1 + drift);
    curve.push({ t: i, v: +value.toFixed(2) });
  }
  return curve;
}

function randRange(min, max) {
  return Math.random() * (max - min) + min;
}