import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/backtest_result_model.dart';
import 'auth_service.dart';
import 'api_client.dart';
import 'portfolio_csv_loader.dart'; // for seed fallback

class BacktestService {
  late final ApiClient _api;
  BacktestService(AuthService auth) {
    _api = ApiClient(auth);
  }

  Future<List<BacktestResultModel>> fetchBacktestResults() async {
    final list = await _api.getJson('/api/backtests') as List;
    return list.map((j) => BacktestResultModel(
      period: j['period'],
      returnPercent: (j['returnPercent'] ?? 0).toDouble(),
      sharpeRatio: (j['sharpeRatio'] ?? 0).toDouble(),
      maxDrawdown: (j['maxDrawdown'] ?? 0).toDouble(),
      volatility: (j['volatility'] ?? 0).toDouble(),
    )).toList();
  }

  Future<BacktestResultModel> runBacktest(String period) async {
    final j = await _api.postJson('/api/backtests/run', {'period': period});
    return BacktestResultModel(
      period: j['period'],
      returnPercent: (j['returnPercent'] ?? 0).toDouble(),
      sharpeRatio: (j['sharpeRatio'] ?? 0).toDouble(),
      maxDrawdown: (j['maxDrawdown'] ?? 0).toDouble(),
      volatility: (j['volatility'] ?? 0).toDouble(),
    );
  }
}