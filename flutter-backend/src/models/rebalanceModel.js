import mongoose from 'mongoose';

const searchResultSchema = new mongoose.Schema({
  symbol: { type: String, index: true },
  name: String,
  type: { type: String, default: 'EQUITY' },
  sector: String,
  exchange: String,
  updatedAt: { type: Date, default: Date.now }
});

const rebalanceRecSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
  symbol: String,
  action: { type: String, enum: ['BUY', 'SELL', 'HOLD'], default: 'HOLD' },
  quantity: Number,
  reason: String,
  createdAt: { type: Date, default: Date.now }
});

export default mongoose.model('RebalanceRecommendation', rebalanceRecSchema);