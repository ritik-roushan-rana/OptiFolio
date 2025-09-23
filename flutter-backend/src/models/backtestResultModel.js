import mongoose from 'mongoose';

const backtestResultSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  period: String,
  returnPercent: Number,
  sharpeRatio: Number,
  maxDrawdown: Number,
  volatility: Number,
  equityCurve: [{ t: Date, value: Number }]
});

export default mongoose.model('BacktestResult', backtestResultSchema);