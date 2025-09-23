import Alert from '../models/alertModel.js';

export const listAlerts = async (req, res) => {
  if (!req.user || !req.user.id) {
    return res.status(401).json({ message: 'Unauthorized' });
  }
  const docs = await Alert.find({ userId: req.user.id }).sort({ createdAt: -1 });
  res.json(docs);
};

export async function createAlert(req, res) {
  const {
    title,
    description,
    isPositive,
    symbol,
    condition
  } = req.body;

  const doc = await Alert.create({
    userId: req.user.id,
    title,
    description,
    isPositive,
    symbol,
    condition
  });
  res.status(201).json(doc);
}