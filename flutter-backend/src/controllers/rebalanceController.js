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

    console.log('Total portfolio value:', totalValue);
    console.log('Portfolio positions:', portfolio.positions);

    // Extract asset symbols from positions
    const assets = portfolio.positions
      .filter(p => (p.quantity || 0) > 0 && (p.avgPrice || 0) >= 0)
      .map(p => p.symbol);

    // Use RL API URL from .env
    const rlApiUrl = process.env.RL_API_URL || 'http://127.0.0.1:8001';
    const rlResponse = await axios.post(`${rlApiUrl}/rl-rebalance`, { assets });
    const weights = rlResponse.data.weights || {};

    console.log('RL weights:', weights);

    // DEBUG: Print RL symbols and all portfolio symbols for troubleshooting
    console.log('RL symbols:', Object.keys(weights));
    console.log('Portfolio symbols:', portfolio.positions.map(p => p.symbol));

    // Map weights to frontend recommendation format
    const recommendations = Object.entries(weights).map(([symbol, targetWeight]) => {
      // Always sanitize RL output symbol before matching
      const sanitizedSymbol = symbol.trim().toUpperCase();
      // Try to match symbol strictly, then fallback to fuzzy match
      let position = portfolio.positions.find(p => (p.symbol || '').trim().toUpperCase() === sanitizedSymbol);
      if (!position) {
        // Fuzzy match: try includes, startsWith, endsWith
        position = portfolio.positions.find(p => (p.symbol || '').toUpperCase().includes(sanitizedSymbol));
      }
      if (!position) {
        position = portfolio.positions.find(p => sanitizedSymbol.includes((p.symbol || '').toUpperCase()));
      }
      if (position) {
        console.log(`MATCHED Symbol: ${sanitizedSymbol}, Quantity: ${position.quantity}, AvgPrice: ${position.avgPrice}`);
      } else {
        console.log(`Symbol: ${sanitizedSymbol} not found in portfolio positions.`);
      }
      // Calculate current weight
      const currentWeight = position && totalValue > 0 ? ((position.quantity * position.avgPrice) / totalValue) * 100 : 0;
      // Calculate rebalance amount (difference in value)
      const amount = position && totalValue > 0 ? Math.abs(((targetWeight - currentWeight) / 100) * totalValue) : 0;
      return {
        symbol: sanitizedSymbol,
        name: sanitizedSymbol,
        currentWeight: parseFloat(currentWeight.toFixed(2)),
        targetWeight,
        amount: parseFloat(amount.toFixed(2)), // Show actual rebalance amount
        action: targetWeight > currentWeight ? 'buy' : 'sell',
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