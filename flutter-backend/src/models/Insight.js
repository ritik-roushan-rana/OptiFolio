import mongoose from 'mongoose';

const InsightSchema = new mongoose.Schema(
  {
    asset: String,
    symbol: String,
    risk: Number,          // std deviation or custom
    volatility: Number,
    returnRate: Number,
    avgReturn: Number,
    notes: String,
  },
  { timestamps: true }
);

export default mongoose.model('Insight', InsightSchema);