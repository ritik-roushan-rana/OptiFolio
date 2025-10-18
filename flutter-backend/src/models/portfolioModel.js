import mongoose from 'mongoose';

const positionSchema = new mongoose.Schema({
  symbol: String,
  name: String,
  quantity: Number,
  avgPrice: Number,
  targetAllocation: Number,
  currentAllocation: Number
});

const portfolioSchema = new mongoose.Schema({
  userId: { type: String, index: true },
  portfolioName: String,
  description: String,
  positions: [positionSchema],
  createdAt: { type: Date, default: Date.now }
});

export default mongoose.model('Portfolio', portfolioSchema);