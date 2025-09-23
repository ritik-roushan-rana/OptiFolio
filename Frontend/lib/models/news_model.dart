class NewsItem {
  final String title;
  final String description;
  final String category;
  final DateTime date;

  NewsItem({
    required this.title,
    required this.description,
    required this.category,
    required this.date,
  });

  factory NewsItem.fromJson(Map<String, dynamic> j) => NewsItem(
        title: j['title'] ?? (j['headline'] ?? ''),
        description: j['description'] ?? j['summary'] ?? '',
        category: j['category'] ?? j['type'] ?? '',
        date: DateTime.tryParse(
              j['publishedAt'] ??
                  j['date'] ??
                  j['createdAt'] ??
                  '',
            ) ??
            DateTime.now(),
      );
}

