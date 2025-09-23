import UserSettings from '../models/userSettingsModel.js';

function defaultSettings() {
  return [
    { key: 'twoFactor', title: 'Two-Factor Authentication', description: 'Extra login security', type: 'toggle', valueBool: true, order: 1, group: 'security' },
    { key: 'priceAlerts', title: 'Price Alerts', description: 'Receive price movement alerts', type: 'toggle', valueBool: true, order: 2, group: 'notifications' },
    { key: 'newsUpdates', title: 'News Updates', description: 'Curated market news', type: 'toggle', valueBool: true, order: 3, group: 'notifications' },
    { key: 'darkMode', title: 'Dark Mode', description: 'Enable dark theme', type: 'toggle', valueBool: true, order: 1, group: 'appearance' },
    { key: 'account', title: 'Account', description: 'Profile & account settings', type: 'navigation', order: 1, group: 'navigation' },
    { key: 'privacy', title: 'Privacy & Security', description: 'Data & security options', type: 'navigation', order: 2, group: 'navigation' },
    { key: 'appearance', title: 'Appearance', description: 'Theme & display', type: 'navigation', order: 3, group: 'navigation' },
    { key: 'about', title: 'About App', description: 'Version & info', type: 'info', valueString: 'v1.0.0', order: 99, group: 'info' }
  ];
}

async function ensureUserSettings(userId) {
  let doc = await UserSettings.findOne({ userId });
  if (!doc) {
    doc = await UserSettings.create({ userId, settings: defaultSettings() });
  }
  return doc;
}

export async function getSettings(req, res) {
  try {
    const doc = await ensureUserSettings(req.user.id);
    res.json({ settings: doc.settings });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}

export async function upsertSettings(req, res) {
  try {
    const { settings } = req.body;
    if (!Array.isArray(settings)) return res.status(400).json({ message: 'settings[] required' });
    const doc = await UserSettings.findOneAndUpdate(
      { userId: req.user.id },
      { settings, updatedAt: new Date() },
      { upsert: true, new: true }
    );
    res.json({ settings: doc.settings });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}

export async function patchSetting(req, res) {
  try {
    const { key } = req.params;
    const { valueBool, valueString } = req.body;
    const doc = await ensureUserSettings(req.user.id);
    const s = doc.settings.find(s => s.key === key);
    if (!s) return res.status(404).json({ message: 'Not found' });
    if (typeof valueBool === 'boolean') s.valueBool = valueBool;
    if (typeof valueString === 'string') s.valueString = valueString;
    doc.updatedAt = new Date();
    await doc.save();
    res.json({ setting: s });
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}