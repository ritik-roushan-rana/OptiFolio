import mongoose from 'mongoose';

const SettingSchema = new mongoose.Schema({
  key: { type: String, required: true },
  title: String,
  description: String,
  type: { type: String, enum: ['toggle','navigation','info','action'], default: 'toggle' },
  valueBool: Boolean,
  valueString: String,
  order: { type: Number, default: 0 },
  group: { type: String, default: 'general' }
}, { _id: false });

const UserSettingsSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, index: true, unique: true },
  settings: [SettingSchema],
  updatedAt: { type: Date, default: Date.now }
});

export default mongoose.model('UserSettings', UserSettingsSchema);