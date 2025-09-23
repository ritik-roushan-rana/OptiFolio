import mongoose from 'mongoose';

const insightSchema = new mongoose.Schema(
  {
    asset: String,
    symbol: String,
    risk: Number,
    volatility: Number,
    returnRate: Number,
    avgReturn: Number,
    notes: String,
  },
  { timestamps: true }
);

export default mongoose.model('Insight', insightSchema);