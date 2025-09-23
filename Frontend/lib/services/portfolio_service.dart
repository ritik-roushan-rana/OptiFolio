import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/portfolio_data.dart';
import 'auth_service.dart';
import 'api_client.dart';

class PortfolioService {
  late final ApiClient _api;
  PortfolioService(AuthService auth) {
    _api = ApiClient(auth);
  }

  Future<PortfolioData> fetchPortfolioData() async {
    // If you mounted portfolioDataRoutes at /api/portfolio/data
    final data = await _api.getJson('/api/portfolio/data');
    return PortfolioData(
      totalValue: (data['totalValue'] ?? 0).toDouble(),
      valueChange: (data['valueChange'] ?? 0).toDouble(),
      valueChangePercent: (data['valueChangePercent'] ?? 0).toDouble(),
      riskScore: data['riskScore'] ?? 0,
      performanceHistory: Map<String, List<double>>.from(
        (data['performanceHistory'] ?? {}).map((k, v) => MapEntry(
              k,
              (v as List).map((e) => (e as num).toDouble()).toList(),
            )),
      ),
      holdings: (data['holdings'] as List)
          .map((h) => AssetData(
                symbol: h['symbol'] ?? '',
                name: h['name'] ?? '',
                value: (h['value'] ?? 0).toDouble(),
                percentage: (h['percentage'] ?? 0).toDouble(),
                changePercent: (h['changePercent'] ?? 0).toDouble(),
                iconUrl: h['iconUrl'],
              ))
          .toList(),
    );
  }
}
