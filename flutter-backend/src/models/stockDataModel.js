import mongoose from 'mongoose';

const pricePointSchema = new mongoose.Schema({
  t: Date,
  open: Number,
  high: Number,
  low: Number,
  close: Number,
  volume: Number
}, { _id: false });

const stockDataSchema = new mongoose.Schema({
  symbol: { type: String, index: true },
  profile: {
    name: String,
    sector: String,
    description: String
  },
  fundamentals: {
    pe: Number,
    eps: Number,
    marketCap: Number
  },
  technical: {
    rsi: Number,
    sma50: Number,
    sma200: Number
  },
  history: [pricePointSchema],
  updatedAt: { type: Date, default: Date.now }
});

export default mongoose.model('StockData', stockDataSchema);