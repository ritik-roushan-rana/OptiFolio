import 'api_client.dart';
import 'auth_service.dart';
import '../models/alert_model.dart';

class AlertsService {
  late final ApiClient _api;
  AlertsService(AuthService auth) {
    _api = ApiClient(auth);
  }

  Future<List<AlertItem>> listAlerts() async {
    final list = await _api.getJson('/api/alerts') as List;
    return list
        .map((a) => AlertItem(
              title: a['title'] ?? (a['symbol'] ?? ''),
              description: a['description'] ?? a['condition'] ?? '',
              isPositive: (a['isPositive'] ?? true) as bool,
              timestamp: DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now(),
            ))
        .toList();
  }

  Future<void> createAlert({String? title, String? description, String? symbol, String? condition}) async {
    await _api.postJson('/api/alerts', {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (symbol != null) 'symbol': symbol,
      if (condition != null) 'condition': condition,
    });
  }
}