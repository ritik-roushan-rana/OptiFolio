import Portfolio from '../models/portfolioModel.js';
import xlsx from 'xlsx';

export async function createPortfolio(req, res) {
  try {
    const { portfolioName, description } = req.body;
    let positions = [];
    if (req.file) {
      const wb = xlsx.read(req.file.buffer, { type: 'buffer' });
      const sheet = wb.Sheets[wb.SheetNames[0]];
      const rows = xlsx.utils.sheet_to_json(sheet);
      positions = rows.map(r => ({
        symbol: r.Symbol,
        name: r.Name,
        quantity: Number(r.Quantity || 0),
        avgPrice: Number(r.AvgPrice || 0),
        targetAllocation: Number(r.TargetAllocation || 0),
        currentAllocation: 0
      }));
    }
    const portfolio = await Portfolio.create({
      userId: req.user.id,
      portfolioName,
      description,
      positions
    });
    res.status(201).json(portfolio);
  } catch (e) {
    res.status(500).json({ message: e.message });
  }
}

export async function getMyPortfolio(req, res) {
  const p = await Portfolio.findOne({ userId: req.user.id });
  res.json(p || null);
}