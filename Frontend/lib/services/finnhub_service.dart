import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class FinnhubService {
  static const String _baseUrl = ApiConfig.finnhubBaseUrl;
  static String get _apiKey => ApiConfig.finnhubApiKey;
  
  // Rate limiting tracking
  static DateTime? _lastRequestTime;
  static int _requestCount = 0;
  
  // Popular stock symbols for testing by exchange
  static const Map<String, List<String>> popularSymbolsByExchange = {
    'US': ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA', 'META', 'NVDA', 'NFLX'],
    'NSE': ['RELIANCE.NS', 'TCS.NS', 'HDFCBANK.NS', 'INFY.NS', 'HINDUNILVR.NS'],
    'BSE': ['500325.BO', '532540.BO', '500180.BO'], // Reliance, TCS, HDFC Bank on BSE
    'Crypto': ['BTC-USD', 'ETH-USD'],
    'Forex': ['EUR/USD', 'GBP/USD', 'USD/JPY']
  };

  // Symbol transformation for different exchanges
  static String _formatSymbolForExchange(String symbol) {
    // Convert common Indian stock symbols to NSE format
    final indianStockMappings = {
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
    
    final upperSymbol = symbol.toUpperCase();
    
    // Handle cryptocurrency symbols
    final cryptoMappings = {
      'BTC': 'BINANCE:BTCUSDT',
      'BITCOIN': 'BINANCE:BTCUSDT',
      'ETH': 'BINANCE:ETHUSDT',
      'ETHEREUM': 'BINANCE:ETHUSDT',
    };
    
    if (cryptoMappings.containsKey(upperSymbol)) {
      return cryptoMappings[upperSymbol]!;
    }
    
    // Check if it's a known Indian stock
    if (indianStockMappings.containsKey(upperSymbol)) {
      return indianStockMappings[upperSymbol]!;
    }
    
    // If already has exchange suffix, return as is
    if (upperSymbol.contains('.NS') || 
        upperSymbol.contains('.BO') || 
        upperSymbol.contains('-USD') ||
        upperSymbol.contains('BINANCE:') ||
        upperSymbol.contains('/')) {
      return upperSymbol;
    }
    
    // For other symbols, assume US market
    return upperSymbol;
  }



  // Format the response data consistently
  Map<String, dynamic> _formatQuoteResponse(String originalSymbol, Map<String, dynamic> data) {
    return {
      'symbol': originalSymbol,
      'currentPrice': data['c'], // Current price
      'change': data['d'],       // Change
      'changePercent': data['dp'], // Percent change
      'previousClose': data['pc'], // Previous close
      'open': data['o'],          // Open price
      'high': data['h'],          // High price
      'low': data['l'],           // Low price
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Simple rate limiting
  Future<void> _checkRateLimit() async {
    final now = DateTime.now();
    
    if (_lastRequestTime == null || 
        now.difference(_lastRequestTime!).inMinutes >= 1) {
      _requestCount = 0;
      _lastRequestTime = now;
    }
    
    if (_requestCount >= ApiConfig.maxCallsPerMinute) {
      // Wait until next minute
      final waitTime = 60 - now.difference(_lastRequestTime!).inSeconds;
      if (waitTime > 0) {
        await Future.delayed(Duration(seconds: waitTime));
        _requestCount = 0;
        _lastRequestTime = DateTime.now();
      }
    }
    
    _requestCount++;
  }

  // Fetch real-time quote for a symbol
  Future<Map<String, dynamic>> fetchQuote(String symbol) async {
    await _checkRateLimit();
    
    final formattedSymbol = _formatSymbolForExchange(symbol);
    final apiKey = _apiKey;
    final url = '$_baseUrl/quote?symbol=$formattedSymbol&token=$apiKey';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Check if the response contains valid data
        if (data['c'] == null || data['c'] == 0) {
          throw Exception('No quote data available for $symbol. This symbol may not be supported by the free tier or market may be closed.');
        }
        
        return _formatQuoteResponse(symbol, data);
      } else if (response.statusCode == 403) {
        throw Exception('Symbol "$formattedSymbol" requires a premium Finnhub subscription. This symbol is not available with the free tier.');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error'] ?? 'Unknown error';
        throw Exception('Failed to fetch quote: $errorMessage (HTTP ${response.statusCode})');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Fetch historical candle data
  Future<List<Map<String, dynamic>>> fetchHistoricalData(
      String symbol, String resolution) async {
    final formattedSymbol = _formatSymbolForExchange(symbol);
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 365)).millisecondsSinceEpoch ~/ 1000;
    final to = now.millisecondsSinceEpoch ~/ 1000;
    
    final url = '$_baseUrl/stock/candle?symbol=$formattedSymbol&resolution=$resolution&from=$from&to=$to&token=$_apiKey';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['s'] == 'ok') {
          final List<double> timestamps = (data['t'] as List).cast<double>();
          final List<double> closes = (data['c'] as List).cast<double>();
          final List<double> opens = (data['o'] as List).cast<double>();
          final List<double> highs = (data['h'] as List).cast<double>();
          final List<double> lows = (data['l'] as List).cast<double>();
          final List<double> volumes = (data['v'] as List).cast<double>();
          
          List<Map<String, dynamic>> historicalData = [];
          
          for (int i = 0; i < timestamps.length; i++) {
            historicalData.add({
              'timestamp': (timestamps[i] * 1000).toInt(), // Convert to milliseconds
              'open': opens[i],
              'high': highs[i],
              'low': lows[i],
              'close': closes[i],
              'volume': volumes[i],
            });
          }
          
          return historicalData;
        } else {
          throw Exception('No data available for $symbol');
        }
      } else {
        throw Exception('Failed to fetch historical data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching historical data for $symbol: $e');
    }
  }

  // Fetch company profile
  Future<Map<String, dynamic>> fetchCompanyProfile(String symbol) async {
    final formattedSymbol = _formatSymbolForExchange(symbol);
    final url = '$_baseUrl/stock/profile2?symbol=$formattedSymbol&token=$_apiKey';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        return {
          'name': data['name'] ?? symbol,
          'ticker': data['ticker'] ?? symbol,
          'exchange': data['exchange'] ?? '',
          'industry': data['finnhubIndustry'] ?? '',
          'country': data['country'] ?? '',
          'currency': data['currency'] ?? 'USD',
          'marketCapitalization': data['marketCapitalization'] ?? 0,
          'shareOutstanding': data['shareOutstanding'] ?? 0,
          'logo': data['logo'] ?? '',
          'weburl': data['weburl'] ?? '',
          'phone': data['phone'] ?? '',
          'ipo': data['ipo'] ?? '',
        };
      } else {
        throw Exception('Failed to fetch company profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching company profile for $symbol: $e');
    }
  }

  // Fetch basic financials
  Future<Map<String, dynamic>> fetchBasicFinancials(String symbol) async {
    final formattedSymbol = _formatSymbolForExchange(symbol);
    final url = '$_baseUrl/stock/metric?symbol=$formattedSymbol&metric=all&token=$_apiKey';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final metric = data['metric'] ?? {};
        
        return {
          'peRatio': metric['peBasicExclExtraTTM'] ?? 0.0,
          'priceToBookValue': metric['pbAnnual'] ?? 0.0,
          'dividendYield': metric['dividendYieldIndicatedAnnual'] ?? 0.0,
          'eps': metric['epsBasicExclExtraordinaryItemsTTM'] ?? 0.0,
          'beta': metric['beta'] ?? 0.0,
          'marketCap': metric['marketCapitalization'] ?? 0.0,
          'revenueGrowth': metric['revenueGrowthTTMYoy'] ?? 0.0,
          'profitMargin': metric['netProfitMarginTTM'] ?? 0.0,
          'roe': metric['roeTTM'] ?? 0.0,
          'roa': metric['roaTTM'] ?? 0.0,
          'debtToEquity': metric['totalDebt/totalEquityAnnual'] ?? 0.0,
        };
      } else {
        throw Exception('Failed to fetch basic financials: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching basic financials for $symbol: $e');
    }
  }

  // Fetch technical indicators (RSI, MACD, etc.)
  Future<Map<String, dynamic>> fetchTechnicalIndicators(String symbol) async {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 100)).millisecondsSinceEpoch ~/ 1000;
    final to = now.millisecondsSinceEpoch ~/ 1000;
    
    // Fetch RSI
    final rsiUrl = '$_baseUrl/indicator?symbol=$symbol&resolution=D&from=$from&to=$to&indicator=rsi&timeperiod=14&token=$_apiKey';
    
    try {
      final rsiResponse = await http.get(Uri.parse(rsiUrl));
      
      Map<String, dynamic> result = {
        'rsi': 50.0, // Default value
        'macd': 0.0, // Default value
        'trend': 'Neutral', // Default value
      };
      
      if (rsiResponse.statusCode == 200) {
        final rsiData = jsonDecode(rsiResponse.body);
        if (rsiData['s'] == 'ok' && rsiData['rsi'] != null && rsiData['rsi'].isNotEmpty) {
          final rsiValues = (rsiData['rsi'] as List).cast<double>();
          result['rsi'] = rsiValues.last;
          
          // Determine trend based on RSI
          if (rsiValues.last > 70) {
            result['trend'] = 'Overbought';
          } else if (rsiValues.last < 30) {
            result['trend'] = 'Oversold';
          } else if (rsiValues.last > 50) {
            result['trend'] = 'Bullish';
          } else {
            result['trend'] = 'Bearish';
          }
        }
      }
      
      return result;
    } catch (e) {
      // Return default values if technical indicators fail
      return {
        'rsi': 50.0,
        'macd': 0.0,
        'trend': 'Neutral',
      };
    }
  }

  // Search for symbols
  Future<List<Map<String, dynamic>>> searchSymbols(String query) async {
    final url = '$_baseUrl/search?q=$query&token=$_apiKey';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = (data['result'] as List?) ?? [];
        
        return results.map<Map<String, dynamic>>((item) => {
          'symbol': item['symbol'] ?? '',
          'description': item['description'] ?? '',
          'displaySymbol': item['displaySymbol'] ?? '',
          'type': item['type'] ?? '',
        }).toList();
      } else {
        throw Exception('Failed to search symbols: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching symbols: $e');
    }
  }

}
