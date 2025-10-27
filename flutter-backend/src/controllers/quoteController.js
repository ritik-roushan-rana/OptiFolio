import { Router } from 'express';
import fetch from 'node-fetch';

const router = Router();

// Finnhub API configuration
const FINNHUB_API_KEY = process.env.FINNHUB_API_KEY;
const FINNHUB_BASE_URL = 'https://finnhub.io/api/v1';

// Symbol transformation for different exchanges
function formatSymbolForExchange(symbol) {
  const upperSymbol = symbol.toUpperCase();
  
  // Convert common Indian stock symbols to NSE format
  const indianStockMappings = {
    'HDFC': 'HDFCBANK.NS',
    'HDFCBANK': 'HDFCBANK.NS',
    'RELIANCE': 'RELIANCE.NS',
    'TCS': 'TCS.NS',
    'INFY': 'INFY.NS',
    'INFOSYS': 'INFY.NS',
    'ICICIBANK': 'ICICIBANK.NS',
    'KOTAKBANK': 'KOTAKBANK.NS',
    'SBIN': 'SBIN.NS',
    'BHARTIARTL': 'BHARTIARTL.NS',
    'HINDUNILVR': 'HINDUNILVR.NS',
    'ITC': 'ITC.NS',
    'LT': 'LT.NS',
    'HCLTECH': 'HCLTECH.NS',
    'WIPRO': 'WIPRO.NS',
  };
  
  // Handle cryptocurrency symbols
  const cryptoMappings = {
    'BTC': 'BINANCE:BTCUSDT',
    'BITCOIN': 'BINANCE:BTCUSDT',
    'ETH': 'BINANCE:ETHUSDT',
    'ETHEREUM': 'BINANCE:ETHUSDT',
  };
  
  if (cryptoMappings[upperSymbol]) {
    return cryptoMappings[upperSymbol];
  }
  
  if (indianStockMappings[upperSymbol]) {
    return indianStockMappings[upperSymbol];
  }
  
  // If already has exchange suffix, return as is
  if (upperSymbol.includes('.NS') || 
      upperSymbol.includes('.BO') || 
      upperSymbol.includes('-USD') ||
      upperSymbol.includes('BINANCE:') ||
      upperSymbol.includes('/')) {
    return upperSymbol;
  }
  
  // For other symbols, assume US market
  return upperSymbol;
}

// Generate realistic mock data for premium symbols or fallback
function generateMockData(symbol) {
  const basePrice = Math.random() * 900 + 100; // Random price between 100-1000
  const changePercent = (Math.random() - 0.5) * 10; // Random change between -5% to +5%
  const change = (basePrice * changePercent) / 100;
  const previousClose = basePrice - change;
  
  return {
    c: Number(basePrice.toFixed(2)),
    d: Number(change.toFixed(2)),
    dp: Number(changePercent.toFixed(2)),
    h: Number((basePrice + Math.random() * 10).toFixed(2)),
    l: Number((basePrice - Math.random() * 10).toFixed(2)),
    o: Number((previousClose + (Math.random() - 0.5) * 5).toFixed(2)),
    pc: Number(previousClose.toFixed(2))
  };
}

export async function getQuote(req, res) {
  const { symbol } = req.params;
  if (!symbol) return res.status(400).json({ message: 'Missing symbol' });

  if (!FINNHUB_API_KEY) {
    console.warn('FINNHUB_API_KEY not configured, using mock data');
    return res.json(generateMockData(symbol));
  }

  try {
    const formattedSymbol = formatSymbolForExchange(symbol);
    const url = `${FINNHUB_BASE_URL}/quote?symbol=${formattedSymbol}&token=${FINNHUB_API_KEY}`;
    
    const response = await fetch(url);
    
    if (!response.ok) {
      if (response.status === 403) {
        // Premium symbol, return mock data
        console.log(`Symbol ${symbol} requires premium subscription, using mock data`);
        return res.json(generateMockData(symbol));
      }
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    const data = await response.json();
    
    // Check if the response contains valid data
    if (!data.c || data.c === 0) {
      console.log(`No valid data for ${symbol}, using mock data`);
      return res.json(generateMockData(symbol));
    }
    
    // Shape expected by StockQuote.fromJson (c,d,dp,h,l,o,pc)
    res.json({
      c: data.c,
      d: data.d,
      dp: data.dp,
      h: data.h,
      l: data.l,
      o: data.o,
      pc: data.pc
    });
    
  } catch (error) {
    console.error(`Error fetching quote for ${symbol}:`, error.message);
    // Fallback to mock data
    res.json(generateMockData(symbol));
  }
}

export async function getQuoteHistory(req, res) {
  const { symbol } = req.params;
  const { resolution = 'D' } = req.query;
  if (!symbol) return res.status(400).json({ message: 'Missing symbol' });

  if (!FINNHUB_API_KEY) {
    console.warn('FINNHUB_API_KEY not configured, using mock historical data');
    return res.json(generateMockHistoricalData());
  }

  try {
    const formattedSymbol = formatSymbolForExchange(symbol);
    const from = Math.floor((Date.now() - 365 * 24 * 60 * 60 * 1000) / 1000); // 1 year ago
    const to = Math.floor(Date.now() / 1000); // Now
    
    const url = `${FINNHUB_BASE_URL}/stock/candle?symbol=${formattedSymbol}&resolution=${resolution}&from=${from}&to=${to}&token=${FINNHUB_API_KEY}`;
    
    const response = await fetch(url);
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    const data = await response.json();
    
    // Check if the response contains valid data
    if (!data.c || data.c.length === 0 || data.s === 'no_data') {
      console.log(`No historical data for ${symbol}, using mock data`);
      return res.json(generateMockHistoricalData());
    }
    
    // Transform Finnhub data to expected format
    const transformedData = data.t.map((timestamp, index) => ({
      t: timestamp,
      o: data.o[index],
      h: data.h[index],
      l: data.l[index],
      c: data.c[index],
      v: data.v[index]
    }));
    
    res.json(transformedData);
    
  } catch (error) {
    console.error(`Error fetching historical data for ${symbol}:`, error.message);
    res.json(generateMockHistoricalData());
  }
}

function generateMockHistoricalData() {
  const points = 60; // 60 data points
  let base = Math.random() * 900 + 100; // Random starting price
  const baseTimestamp = Math.floor((Date.now() - 60 * 24 * 60 * 60 * 1000) / 1000); // 60 days ago
  
  return Array.from({ length: points }).map((_, i) => {
    base *= 1 + (Math.random() - 0.5) * 0.02; // More realistic price movement
    const o = Number(base.toFixed(2));
    const h = Number((o + Math.random() * (o * 0.03)).toFixed(2)); // High up to 3% above open
    const l = Number((o - Math.random() * (o * 0.03)).toFixed(2)); // Low up to 3% below open
    const c = Number((l + Math.random() * (h - l)).toFixed(2)); // Close between low and high
    const v = Math.floor(50000 + Math.random() * 200000); // Random volume
    const t = baseTimestamp + (i * 24 * 60 * 60); // Daily intervals
    
    return { t, o, h, l, c, v };
  });
}

router.get('/:symbol', getQuote);

export default router;