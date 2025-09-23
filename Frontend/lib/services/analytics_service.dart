import '../models/analytics_models.dart';
import '../utils/app_colors.dart';
import '../models/portfolio_data.dart'; // Import the correct AssetData class
import 'api_client.dart';
import 'auth_service.dart';

class AnalyticsService {
  final ApiClient _api;
  AnalyticsService(AuthService auth) : _api = ApiClient(auth);

  Future<List<EarningsData>> getEarningsData() async {
    final j = await _api.getJson('/api/analytics/earnings');
    List list = (j is List) ? j : (j['earningsTimeline'] as List? ?? []);
    if (list.isEmpty) {
      // seed by calling full analytics (which auto-creates on backend if patched)
      final full = await _api.getJson('/api/analytics');
      list = (full is Map) ? (full['earningsTimeline'] as List? ?? []) : list;
    }
    return list.map((e) => EarningsData(
      period: e['period'] ?? '',
      amount: (e['amount'] ?? 0).toDouble(),
    )).toList();
  }

  Future<List<double>> getPortfolioPerformanceData() async {
    final j = await _api.getJson('/api/analytics/performance');
    final list = (j['series'] ?? j['data'] ?? []) as List;
    return list.map((e) => (e as num).toDouble()).toList();
  }

  Future<List<AllocationSlice>> getSectorAllocations() async {
    final list = await _api.getJson('/api/analytics/allocations/sector') as List;
    return list.map((e) => AllocationSlice.fromJson(e)).toList();
  }

  Future<List<AllocationSlice>> getAssetClassAllocations() async {
    final list = await _api.getJson('/api/analytics/allocations/asset-class') as List;
    return list.map((e) => AllocationSlice.fromJson(e)).toList();
  }

  // Example featured assets (local mock)
  List<AssetData> getFeaturedAssets() => [
        AssetData(
          symbol: 'ETH',
          name: 'Ethereum',
          value: 3646.5,
          percentage: 15.2,
          changePercent: 9.23,
          iconUrl: '',
        ),
        AssetData(
          symbol: 'USDT',
          name: 'Tether',
            value: 2969.69,
          percentage: 12.4,
          changePercent: 0.96,
          iconUrl: '',
        ),
        AssetData(
          symbol: 'BNB',
          name: 'Binance Coin',
          value: 6185.3,
          percentage: 25.8,
          changePercent: -2.14,
          iconUrl: '',
        ),
      ];

  Future<List<AllocationData>> getAllocationData() async {
    final j = await _api.getJson('/api/analytics');
    final list = (j['allocation'] as List?) ?? [];
    return list
        .map((e) => AllocationData(
              assetClass: e['assetClass'] ?? '',
              weight: (e['weight'] ?? 0).toDouble(),
            ))
        .toList();
  }

  Future<RiskMetrics> getRiskMetrics() async {
    final j = await _api.getJson('/api/analytics');
    final r = (j['riskMetrics'] as Map?) ?? {};
    return RiskMetrics(
      beta: (r['beta'] ?? 0).toDouble(),
      var95: (r['var95'] ?? 0).toDouble(),
      maxDrawdown: (r['maxDrawdown'] ?? 0).toDouble(),
    );
  }
}