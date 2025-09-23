import 'api_client.dart';
import 'auth_service.dart';
import '../models/search_result_model.dart';

class SearchService {
  final ApiClient _api;
  SearchService(AuthService auth) : _api = ApiClient(auth);

  Future<List<SearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final list = await _api.getJson('/api/search', query: {'q': query}) as List;
    return list.map((e) => SearchResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<SearchResult>> trending() => getTrending();

  Future<List<SearchResult>> getTrending({int limit = 10}) async {
    final raw = await _api.getJson('/api/search/trending', query: {'limit': '$limit'});
    final list = (raw is List)
        ? raw
        : (raw is Map ? (raw['results'] as List? ?? []) : <dynamic>[]);
    return list
        .whereType<Map>()
        .map((e) => SearchResult.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}