import 'api_client.dart';
import 'auth_service.dart';
import '../models/insight_models.dart';

class InsightService {
  final ApiClient _api;
  InsightService(AuthService auth) : _api = ApiClient(auth);

  Future<List<RiskReturnPoint>> getRiskReturnScatter() async {
    final list = await _api.getJson('/api/insights/risk-return') as List;
    return list.map((e) => RiskReturnPoint(
      asset: e['asset'] ?? '',
      risk: (e['risk'] ?? 0).toDouble(),
      returnRate: (e['returnRate'] ?? e['return'] ?? 0).toDouble(),
    )).toList();
  }

  Future<List<CorrelationData>> getCorrelationHeatmap() async {
    final list = await _api.getJson('/api/insights/correlation') as List;
    return list.map((e) => CorrelationData(
      asset1: e['asset1'] ?? '',
      asset2: e['asset2'] ?? '',
      correlation: (e['correlation'] ?? 0).toDouble(),
    )).toList();
  }

  Future<List<FeeReturnData>> getFeesVsReturn() async {
    final list = await _api.getJson('/api/insights/fees-return') as List;
    return list.map((e) => FeeReturnData(
      fund: e['fund'] ?? '',
      fee: (e['fee'] ?? e['expenseRatio'] ?? 0).toDouble(),
      annualReturn: (e['annualReturn'] ?? e['return'] ?? 0).toDouble(),
    )).toList();
  }

  Future<List<WhatIfScenario>> getWhatIfScenarios() async {
    final list = await _api.getJson('/api/insights/what-if') as List;
    return list.map((e) => WhatIfScenario(
      scenario: e['scenario'] ?? '',
      impactPercent: (e['impactPercent'] ?? e['impact'] ?? 0).toDouble(),
      notes: e['notes'] ?? '',
    )).toList();
  }
}