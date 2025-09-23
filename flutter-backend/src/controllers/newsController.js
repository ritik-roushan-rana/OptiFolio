import NewsItem from '../models/newsModel.js';

export async function latestNews(req, res) {
  const news = await NewsItem.find().sort({ publishedAt: -1 }).limit(25);
  res.json(news);
}

// Alias expected by routes (listNews)
export const listNews = latestNews;

export async function getCuratedNews(req, res) {
  // TODO: replace static with real feed
  res.json([
    { id: 1, symbol: 'AAPL', title: 'Apple launches new product', ts: Date.now() },
    { id: 2, symbol: 'MSFT', title: 'Microsoft AI update', ts: Date.now() }
  ]);
}

export async function getNewsAlerts(req, res) {
  res.json([
    { id: 'al1', type: 'price', symbol: 'TSLA', message: 'TSLA moved +5%' },
    { id: 'al2', type: 'earnings', symbol: 'NVDA', message: 'Earnings tomorrow' }
  ]);
}