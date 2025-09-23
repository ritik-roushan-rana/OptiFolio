// Endpoints for company profile, technical, derivatives, fundamentals (placeholders).
export async function getCompanyProfile(req, res) {
  const { symbol } = req.params;
  res.json({
    ticker: symbol.toUpperCase(),
    name: `${symbol.toUpperCase()} Corp`,
    exchange: 'NASDAQ',
    ipo: '2015-06-18',
    marketCapitalization: 125_000.5,
    shareOutstanding: 1500.2,
    country: 'USA'
  });
}

export async function getCompanyFundamentals(req, res) {
  // Shape expected by StockFundamentals.fromJson
  res.json({
    qualityRating: 7,
    qualityDescription: 'Above average profitability',
    valuationRating: 5,
    valuationDescription: 'Fairly valued',
    financeRating: 6,
    financeDescription: 'Solid balance sheet',
    oneYearReturn: 14.2,
    sectorReturn: 9.8,
    marketReturn: 11.3,
    peRatio: 22.4,
    priceToBookValue: 4.1
  });
}

export async function getCompanyTechnical(req, res) {
  res.json({
    rsi: Number((40 + Math.random() * 20).toFixed(2)),
    macd: Number((Math.random() * 2 - 1).toFixed(2)),
    trend: Math.random() > 0.5 ? 'Bullish' : 'Neutral'
  });
}

export async function getCompanyDerivatives(req, res) {
  res.json({
    openInterest: Math.floor(10000 + Math.random() * 5000),
    volume: Math.floor(5000 + Math.random() * 5000),
    contractType: 'CALL'
  });
}