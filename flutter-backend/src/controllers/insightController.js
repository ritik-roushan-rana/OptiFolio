import Insight from '../models/insightModel.js';

const num = (v, d = 0) => (isNaN(Number(v)) ? d : Number(v));

export const listInsights = async (_req, res) => {
  const docs = await Insight.find().limit(100);
  res.json(docs);
};

export const getInsight = async (req, res) => {
  const doc = await Insight.findById(req.params.id);
  if (!doc) return res.status(404).json({ message: 'Not found' });
  res.json(doc);
};

export const createInsight = async (req, res) => {
  const doc = await Insight.create(req.body);
  res.status(201).json(doc);
};

export const updateInsight = async (req, res) => {
  const doc = await Insight.findByIdAndUpdate(req.params.id, req.body, { new: true });
  if (!doc) return res.status(404).json({ message: 'Not found' });
  res.json(doc);
};

export const deleteInsight = async (req, res) => {
  await Insight.findByIdAndDelete(req.params.id);
  res.status(204).end();
};

// Frontend data endpoints
export const riskReturnData = async (_req, res) => {
  const docs = await Insight.find().limit(50);
  res.json(
    docs.map(d => ({
      asset: d.asset || d.symbol || 'N/A',
      risk: num(d.risk ?? d.volatility ?? Math.random() * 20),
      returnRate: num(d.returnRate ?? d.avgReturn ?? Math.random() * 15),
    }))
  );
};

export const correlationData = async (_req, res) => {
  const assets = ['AAPL', 'MSFT', 'GOOGL', 'AMZN'];
  const out = [];
  for (let i = 0; i < assets.length; i++) {
    for (let j = i + 1; j < assets.length; j++) {
      out.push({
        asset1: assets[i],
        asset2: assets[j],
        correlation: +(Math.random() * 2 - 1).toFixed(2),
      });
    }
  }
  res.json(out);
};

export const feesReturnData = async (_req, res) => {
  res.json([
    { fund: 'FUND_A', fee: 0.65, annualReturn: 8.4 },
    { fund: 'FUND_B', fee: 0.2, annualReturn: 11.2 },
    { fund: 'FUND_C', fee: 1.1, annualReturn: 6.9 },
  ]);
};

export const whatIfData = async (_req, res) => {
  res.json([
    { scenario: 'Rate Cut 50bps', impactPercent: 3.2, notes: 'Growth assets benefit' },
    { scenario: 'Oil +20%', impactPercent: -1.4, notes: 'Energy up, transport down' },
    { scenario: 'USD -5%', impactPercent: 1.1, notes: 'FX tailwind for exporters' },
  ]);
};