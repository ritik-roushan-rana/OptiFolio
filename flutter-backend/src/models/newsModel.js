

import mongoose from 'mongoose';

const newsSchema = new mongoose.Schema({
  title: String,
  source: String,
  url: String,
  summary: String,
  publishedAt: Date,
  tickers: [String]
});

export default mongoose.model('NewsItem', newsSchema);