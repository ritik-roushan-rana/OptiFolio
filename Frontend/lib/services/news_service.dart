import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'auth_service.dart';
import '../models/news_model.dart';
import '../config/api_config.dart';

class NewsService {
  final ApiClient _api;
  static const String _finnhubBaseUrl = ApiConfig.finnhubBaseUrl;
  static String get _finnhubApiKey => ApiConfig.finnhubApiKey;

  NewsService(AuthService auth) : _api = ApiClient(auth);

  // Fetch general market news from Finnhub
  Future<List<NewsItem>> getLatestNews({String? category}) async {
    try {
      final newsCategory = category?.toLowerCase() ?? 'general';
      final url = '$_finnhubBaseUrl/news?category=$newsCategory&token=$_finnhubApiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        return data.map((newsJson) => NewsItem(
          id: newsJson['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: newsJson['headline'] ?? 'No title',
          description: newsJson['summary'] ?? 'No description available',
          category: newsJson['category'] ?? newsCategory,
          date: DateTime.fromMillisecondsSinceEpoch((newsJson['datetime'] ?? 0) * 1000),
          source: newsJson['source'] ?? 'Finnhub',
          url: newsJson['url'] ?? '',
          imageUrl: newsJson['image'] ?? '',
        )).toList();
      } else {
        throw Exception('Failed to fetch news: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to backend API if Finnhub fails
      try {
        final data = await _api.getJson('/api/news', query: {
          if (category != null) 'category': category,
        });
        final list = (data is List) ? data : (data['items'] as List? ?? []);
        return list.map((e) => NewsItem.fromJson(e)).toList();
      } catch (backendError) {
        throw Exception('Error fetching news: $e');
      }
    }
  }

  // Fetch company-specific news from Finnhub
  Future<List<NewsItem>> getCompanyNews(String symbol, {DateTime? from, DateTime? to}) async {
    try {
      final fromDate = from ?? DateTime.now().subtract(const Duration(days: 7));
      final toDate = to ?? DateTime.now();
      
      final fromFormatted = _formatDate(fromDate);
      final toFormatted = _formatDate(toDate);
      
      final url = '$_finnhubBaseUrl/company-news?symbol=$symbol&from=$fromFormatted&to=$toFormatted&token=$_finnhubApiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        return data.map((newsJson) => NewsItem(
          id: newsJson['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: newsJson['headline'] ?? 'No title',
          description: newsJson['summary'] ?? 'No description available',
          category: newsJson['category'] ?? 'company',
          date: DateTime.fromMillisecondsSinceEpoch((newsJson['datetime'] ?? 0) * 1000),
          source: newsJson['source'] ?? 'Finnhub',
          url: newsJson['url'] ?? '',
          imageUrl: newsJson['image'] ?? '',
        )).toList();
      } else if (response.statusCode == 403) {
        // Company news requires premium subscription - fallback to general news
        final generalNews = await getLatestNews(category: 'general');
        // Filter for news that might be related to the company
        return generalNews.where((news) {
          final title = news.title.toLowerCase();
          final description = news.description.toLowerCase();
          final symbolLower = symbol.toLowerCase();
          return title.contains(symbolLower) || description.contains(symbolLower);
        }).take(10).toList();
      } else {
        throw Exception('Failed to fetch company news: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to general news if company news fails
      try {
        final generalNews = await getLatestNews(category: 'general');
        return generalNews.take(5).toList(); // Return fewer items as fallback
      } catch (fallbackError) {
        return []; // Return empty list if all fails
      }
    }
  }

  // Get curated news (general + technology + business)
  Future<List<NewsItem>> getCuratedNews() async {
    try {
      final futures = [
        getLatestNews(category: 'general'),
        getLatestNews(category: 'technology'),
        getLatestNews(category: 'business'),
      ];
      
      final results = await Future.wait(futures);
      final allNews = <NewsItem>[];
      
      for (final newsList in results) {
        allNews.addAll(newsList);
      }
      
      // Sort by date and take top 20
      allNews.sort((a, b) => b.date.compareTo(a.date));
      return allNews.take(20).toList();
      
    } catch (e) {
      // Fallback to backend
      try {
        final list = await _api.getJson('/api/news/curated') as List;
        return list.map((e) => NewsItem.fromJson(e)).toList();
      } catch (backendError) {
        throw Exception('Error fetching curated news: $e');
      }
    }
  }

  // Get smart alerts (market news + forex news)
  Future<List<NewsItem>> getSmartAlerts() async {
    try {
      final futures = [
        getLatestNews(category: 'general'),
        getLatestNews(category: 'forex'),
      ];
      
      final results = await Future.wait(futures);
      final allNews = <NewsItem>[];
      
      for (final newsList in results) {
        allNews.addAll(newsList);
      }
      
      // Filter for important keywords and sort by date
      final alertNews = allNews.where((news) {
        final title = news.title.toLowerCase();
        final description = news.description.toLowerCase();
        return title.contains('alert') || 
               title.contains('breaking') || 
               title.contains('market') ||
               title.contains('stock') ||
               title.contains('economy') ||
               description.contains('market') ||
               description.contains('stock');
      }).toList();
      
      alertNews.sort((a, b) => b.date.compareTo(a.date));
      return alertNews.take(15).toList();
      
    } catch (e) {
      // Fallback to backend
      try {
        final list = await _api.getJson('/api/news/alerts') as List;
        return list.map((e) => NewsItem.fromJson(e)).toList();
      } catch (backendError) {
        throw Exception('Error fetching smart alerts: $e');
      }
    }
  }

  // Helper method to format date for API
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}