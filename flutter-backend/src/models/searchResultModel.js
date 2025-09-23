import mongoose from 'mongoose';

const searchResultSchema = new mongoose.Schema({
  symbol: { type: String, index: true },
  name: String,
  type: { type: String, default: 'EQUITY' },
  sector: String,
  exchange: String,
  updatedAt: { type: Date, default: Date.now }
});

export default mongoose.model('SearchResult', searchResultSchema);