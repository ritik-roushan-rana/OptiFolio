import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Finnhub API configuration
  static String get finnhubApiKey {
    final key = dotenv.env['FINNHUB_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('FINNHUB_API_KEY not configured in .env file');
    }
    return key;
  }
  static const String finnhubBaseUrl = 'https://finnhub.io/api/v1';
  
  // Rate limiting - Finnhub free tier allows 60 calls/minute
  static const int maxCallsPerMinute = 60;
  static const Duration rateLimitWindow = Duration(minutes: 1);
}
