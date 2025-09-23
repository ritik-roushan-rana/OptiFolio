
import mongoose from 'mongoose';

const analyticsSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  earningsTimeline: [{ period: String, amount: Number }],
  allocation: [{ assetClass: String, weight: Number }],
  riskMetrics: {
    beta: Number,
    var95: Number,
    maxDrawdown: Number
  },
  updatedAt: { type: Date, default: Date.now }
});

export default mongoose.model('Analytics', analyticsSchema);