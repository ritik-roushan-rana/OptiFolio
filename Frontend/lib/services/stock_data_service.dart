import 'api_client.dart';
import 'auth_service.dart';
import '../models/stock_data_model.dart';

class StockDataService {
  final ApiClient _api;
  StockDataService(AuthService auth) : _api = ApiClient(auth);

  Future<Map<String, dynamic>> fetchQuote(String symbol) async {
    final j = await _api.getJson('/api/quotes/$symbol');
    return j as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchHistoricalData(String symbol, String resolution) async {
    final list = await _api.getJson('/api/quotes/$symbol/history', query: {
      'resolution': resolution,
    }) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> fetchCompanyProfile(String symbol) async {
    final j = await _api.getJson('/api/companies/$symbol/profile');
    return j as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchFundamentals(String symbol) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'qualityRating': 4, 'qualityDescription': 'Good Quality', 'valuationRating': 2, 'valuationDescription': 'Expensive Valuation',
      'financeRating': 1, 'financeDescription': 'Negative Finance Trends', 'oneYearReturn': -8.59,
      'sectorReturn': 6.64, 'marketReturn': -0.35, 'peRatio': 13.53, 'priceToBookValue': 1.91,
    };
  }

  Future<Map<String, dynamic>> fetchTechnicalData(String symbol) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'rsi': 65.45,
      'macd': 2.15,
      'trend': 'Bullish',
    };
  }

  Future<Map<String, dynamic>> fetchDerivativesData(String symbol) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'openInterest': 1234567,
      'volume': 543210,
      'contractType': 'Futures',
    };
  }
}