class NewsItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime date;
  final String source;
  final String url;
  final String imageUrl;

  NewsItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    this.source = '',
    this.url = '',
    this.imageUrl = '',
  });

  factory NewsItem.fromJson(Map<String, dynamic> j) {
    // Handle Finnhub API response format
    DateTime parseDate() {
      // Handle Unix timestamp (seconds or milliseconds)
      if (j['datetime'] != null) {
        final timestamp = j['datetime'];
        if (timestamp is int) {
          // Finnhub uses Unix timestamp in seconds
          return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        }
      }
      
      // Handle string dates
      final dateString = j['publishedAt'] ?? j['date'] ?? j['createdAt'] ?? j['published_at'];
      if (dateString != null && dateString.toString().isNotEmpty) {
        final parsed = DateTime.tryParse(dateString.toString());
        if (parsed != null) return parsed;
      }
      
      // Last resort fallback
      return DateTime.now();
    }

    return NewsItem(
      id: j['id']?.toString() ?? 
          j['uuid']?.toString() ?? 
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: j['title']?.toString() ?? 
              j['headline']?.toString() ?? 
              'No title',
      description: j['description']?.toString() ?? 
                   j['summary']?.toString() ?? 
                   j['content']?.toString() ?? 
                   'No description available',
      category: j['category']?.toString() ?? 
                j['type']?.toString() ?? 
                'general',
      date: parseDate(),
      source: j['source']?.toString() ?? 
              j['publisher']?.toString() ?? 
              'Unknown',
      url: j['url']?.toString() ?? 
           j['link']?.toString() ?? 
           '',
      imageUrl: j['image']?.toString() ?? 
                j['imageUrl']?.toString() ?? 
                j['thumbnail']?.toString() ?? 
                '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'date': date.toIso8601String(),
      'source': source,
      'url': url,
      'image': imageUrl,
    };
  }
}

