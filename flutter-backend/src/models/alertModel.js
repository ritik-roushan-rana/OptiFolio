import mongoose from 'mongoose';

const alertSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
  // Frontend alignment
  title: { type: String },
  description: { type: String },
  isPositive: { type: Boolean, default: true },
  // Original fields (keep if used elsewhere)
  symbol: { type: String },
  condition: { type: String },         // e.g. "price > 150"
  triggered: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

export default mongoose.model('Alert', alertSchema);