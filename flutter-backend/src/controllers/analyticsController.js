import Analytics from '../models/analyticsModel.js';

async function ensureDoc(userId) {
  let doc = await Analytics.findOne({ userId });
  if (!doc) {
    doc = await Analytics.create({
      userId,
      earningsTimeline: [
        { period: 'W', amount: 2800 },
        { period: 'M', amount: 4200 },
        { period: '3M', amount: 6800 },
        { period: '6M', amount: 8900 },
        { period: 'Y', amount: 12045 }
      ],
      allocation: [
        { assetClass: 'Equities', weight: 60 },
        { assetClass: 'Bonds', weight: 25 },
        { assetClass: 'Cash', weight: 15 }
      ],
      riskMetrics: { beta: 0.92, var95: -7.4, maxDrawdown: -12.5 },
      performanceSeries: Array.from({ length: 30 }, (_, i) => 10000 + i * 240)
    });
  }
  return doc;
}

export async function getAnalytics(req, res) {
  const doc = await ensureDoc(req.user.id);
  res.json(doc);
}

export async function getEarnings(req, res) {
  const doc = await ensureDoc(req.user.id);
  res.json(doc.earningsTimeline || []);
}

export async function getPerformance(req, res) {
  const doc = await ensureDoc(req.user.id);
  res.json({ series: doc.performanceSeries || [] });
}