import Portfolio from '../models/portfolioModel.js';

// Compute rebalance recommendations on the fly
export async function getRecommendations(req, res) {
  try {
    const portfolio = await Portfolio.findOne({ userId: req.user.id });
    if (!portfolio || !portfolio.positions || !portfolio.positions.length) {
      return res.json([]);
    }

    const positions = portfolio.positions.filter(p => (p.quantity || 0) > 0 && (p.avgPrice || 0) >= 0);
    const totalValue = positions.reduce((s, p) => s + (p.quantity || 0) * (p.avgPrice || 0), 0) || 0;

    // Derive current weights
    const enriched = positions.map(p => {
      const value = (p.quantity || 0) * (p.avgPrice || 0);
      const currentWeight = totalValue ? (value / totalValue) * 100 : 0;
      // Use provided targetAllocation (%) if present, else equal-weight baseline
      const fallbackTarget = 100 / positions.length;
      const targetWeight = (p.targetAllocation && p.targetAllocation > 0)
        ? p.targetAllocation
        : fallbackTarget;

      const diff = currentWeight - targetWeight; // + overweight, - underweight
      let action = 'HOLD';
      if (diff > 2) action = 'SELL';
      else if (diff < -2) action = 'BUY';

      const amount = Math.abs(diff) / 100 * totalValue;

      return {
        symbol: p.symbol,
        name: p.name || p.symbol,
        currentWeight: Number(currentWeight.toFixed(2)),
        targetWeight: Number(targetWeight.toFixed(2)),
        amount: Number(amount.toFixed(2)),
        action,
        reason:
          action === 'HOLD'
            ? 'Within tolerance'
            : action === 'SELL'
              ? 'Over target allocation'
              : 'Below target allocation'
      };
    });

    res.json(enriched);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}

export async function applyRebalance(req, res) {
  // Stub: in a real system you would execute trades / update positions.
  res.json({ message: 'Rebalance actions acknowledged', count: (req.body?.actions || []).length });
}