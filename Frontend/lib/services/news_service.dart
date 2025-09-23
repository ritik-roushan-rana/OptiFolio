import 'api_client.dart';
import 'auth_service.dart';
import '../models/news_model.dart'; // unified

class NewsService {
  final ApiClient _api;
  NewsService(AuthService auth) : _api = ApiClient(auth);

  Future<List<NewsItem>> getLatestNews({String? category}) async {
    final data = await _api.getJson('/api/news', query: {
      if (category != null) 'category': category,
    });
    final list = (data is List) ? data : (data['items'] as List? ?? []);
    return list.map((e) => NewsItem.fromJson(e)).toList();
  }

  Future<List<NewsItem>> getCuratedNews() async {
    final list = await _api.getJson('/api/news/curated') as List;
    return list.map((e) => NewsItem.fromJson(e)).toList();
  }

  Future<List<NewsItem>> getSmartAlerts() async {
    final list = await _api.getJson('/api/news/alerts') as List;
    return list.map((e) => NewsItem.fromJson(e)).toList();
  }
}