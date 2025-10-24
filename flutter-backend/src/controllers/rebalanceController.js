import Portfolio from '../models/portfolioModel.js';
import axios from 'axios';
import dotenv from 'dotenv';
dotenv.config();

// Compute rebalance recommendations on the fly
export async function getRecommendations(req, res) {
  try {
    const portfolio = await Portfolio.findOne({ userId: req.user.id });
    if (!portfolio || !portfolio.positions || !portfolio.positions.length) {
      return res.json([]);
    }

    // Calculate total portfolio value
    const totalValue = portfolio.positions.reduce((sum, p) => sum + ((p.quantity || 0) * (p.avgPrice || 0)), 0);

    // Extract asset symbols from positions
    const assets = portfolio.positions
      .filter(p => (p.quantity || 0) > 0 && (p.avgPrice || 0) >= 0)
      .map(p => p.symbol);

    // Use RL API URL from .env
    const rlApiUrl = process.env.RL_API_URL || 'http://127.0.0.1:8001';
    const rlResponse = await axios.post(`${rlApiUrl}/rl-rebalance`, { assets });
    const weights = rlResponse.data.weights || {};

    // Map weights to frontend recommendation format
    const recommendations = Object.entries(weights).map(([symbol, targetWeight]) => {
      // Find the position for this symbol
      const position = portfolio.positions.find(p => p.symbol === symbol);
      // Calculate current weight
      const currentWeight = position && totalValue > 0 ? ((position.quantity * position.avgPrice) / totalValue) * 100 : 0;
      return {
        symbol,
        name: symbol,
        currentWeight: parseFloat(currentWeight.toFixed(2)),
        targetWeight,
        amount: 0, // You can fetch actual amount if available
        action: targetWeight > 0 ? 'buy' : 'sell', // Simple logic, adjust as needed
        reason: 'RL recommendation'
      };
    });

    res.json(recommendations);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}

export async function applyRebalance(req, res) {
  // Stub: in a real system you would execute trades / update positions.
  res.json({ message: 'Rebalance actions acknowledged', count: (req.body?.actions || []).length });
}