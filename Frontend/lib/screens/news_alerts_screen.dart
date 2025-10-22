// lib/screens/news_alerts_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/news_model.dart'; // unified model import
import '../services/news_service.dart';
import '../services/auth_service.dart';
import '../widgets/elevated_card.dart';
import '../widgets/gradient_background.dart';
import '../utils/app_colors.dart';
import '../screens/NewsDetailScreen.dart';

class NewsAlertsScreen extends StatefulWidget {
  const NewsAlertsScreen({super.key});

  @override
  State<NewsAlertsScreen> createState() => _NewsAlertsScreenState();
}

class _NewsAlertsScreenState extends State<NewsAlertsScreen>
    with SingleTickerProviderStateMixin {
  late NewsService _newsService;
  late Future<List<NewsItem>> curatedNewsFuture;
  late Future<List<NewsItem>> smartAlertsFuture;
  late TabController _tabController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _newsService = NewsService(Provider.of<AuthService>(context, listen: false));
    curatedNewsFuture = _newsService.getCuratedNews();        // fixed
    smartAlertsFuture = _newsService.getSmartAlerts();        // use alerts endpoint
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          "Market News & Alerts",
          style: TextStyle(
            color: AppColors.darkText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.darkText,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: "Curated News"),
            Tab(text: "Smart Alerts"),
          ],
        ),
      ),
      body: Stack(
        children: [
          const GradientBackground(),
          Padding(
            padding: const EdgeInsets.only(top: 155), // Add padding to avoid header overlap
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNewsTab(curatedNewsFuture),
                _buildNewsTab(smartAlertsFuture),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsTab(Future<List<NewsItem>> newsFuture) {
    return FutureBuilder<List<NewsItem>>(
      future: newsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: const TextStyle(color: AppColors.darkText),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "No news available",
              style: TextStyle(color: AppColors.darkText),
            ),
          );
        }

        final newsList = snapshot.data!;
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 428),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: newsList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final news = newsList[index];
                return ElevatedCard(
                  padding: const EdgeInsets.all(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewsDetailScreen(newsItem: news),
                      ),
                    );
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // News Image (if available)
                      if (news.imageUrl.isNotEmpty)
                        Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(news.imageUrl),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {
                                // Handle image loading error silently
                              },
                            ),
                          ),
                        ),
                      
                      // News content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              news.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              news.description,
                              style: const TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 14,
                                height: 1.3,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        news.source.toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        news.category.toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.mutedText,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatTime(news.date),
                                  style: const TextStyle(
                                    color: AppColors.mutedText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

