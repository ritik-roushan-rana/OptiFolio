import 'api_client.dart';
import 'auth_service.dart';
import '../models/rebalance_model.dart';
import '../models/portfolio_data.dart';

class RebalancingService {
  late final ApiClient _api;
  RebalancingService(AuthService auth) {
    _api = ApiClient(auth);
  }

  /// Fetch rebalance suggestions from backend.
  Future<List<RebalanceRecommendation>> fetchSuggestions(PortfolioData p) async {
    // Prepare asset list from portfolio data
    final assets = p.holdings.map((h) => h.symbol).toList();
    final raw = await _api.postJson('/api/rebalance', {'assets': assets});
    print('Rebalance raw response: $raw');
    if (raw is! List) return [];
    return raw.map<RebalanceRecommendation>((r) {
      final m = (r as Map);
      return RebalanceRecommendation(
        symbol: (m['symbol'] ?? '') as String,
        name: (m['name'] ?? m['symbol'] ?? '') as String,
        currentWeight: _toD(m['currentWeight'] ?? m['currentAllocation'] ?? 0),
        targetWeight: _toD(m['targetWeight'] ?? m['targetAllocation'] ?? 0),
        amount: _toD(m['amount'] ?? m['quantity'] ?? 0),
        action: _parseAction(m['action']),
        reason: (m['reason'] ?? '') as String,
      );
    }).toList();
  }

  /// Apply selected rebalance actions (requires backend endpoint support).
  Future<void> applyRebalance(List<RebalanceRecommendation> recs) async {
    await _api.postJson('/api/rebalance/apply', {
      'actions': recs
          .map((r) => {
                'symbol': r.symbol,
                'action': _actionToString(r.action),
                'targetWeight': r.targetWeight,
                'amount': r.amount,
                'reason': r.reason,
              })
          .toList()
    });
  }

  /// Apply selected rebalance actions and refresh suggestions.
  Future<void> applyAndRefresh(List<RebalanceRecommendation> recs, PortfolioData p) async {
    await applyRebalance(recs);
    await fetchSuggestions(p);
  }

  /// Ignore a rebalance recommendation (requires backend endpoint support).
  Future<void> ignoreRebalance(String symbol) async {
    await _api.postJson('/api/rebalance/ignore', {
      'symbol': symbol,
    });
  }

  /// Ignore a rebalance recommendation and refresh suggestions.
  Future<void> ignoreAndRefresh(String symbol, PortfolioData p) async {
    await ignoreRebalance(symbol);
    await fetchSuggestions(p);
  }

  // ---- Helpers ----

  RebalanceAction _parseAction(Object? v) {
    final s = (v?.toString().toLowerCase() ?? '');
    switch (s) {
      case 'buy':
        return RebalanceAction.buy;
      case 'sell':
        return RebalanceAction.sell;
      case 'hold':
        return RebalanceAction.hold;
    }
    return RebalanceAction.hold;
  }

  String _actionToString(RebalanceAction a) {
    switch (a) {
      case RebalanceAction.buy:
        return 'BUY';
      case RebalanceAction.sell:
        return 'SELL';
      case RebalanceAction.hold:
      default:
        return 'HOLD';
    }
  }

  double _toD(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}