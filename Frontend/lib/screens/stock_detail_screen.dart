import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/search_result_model.dart';
import '../models/stock_data_model.dart';
import '../models/news_model.dart';
import '../utils/app_colors.dart';
import '../widgets/gradient_background.dart';
import '../services/stock_data_service.dart';
import '../services/news_service.dart';
import '../widgets/elevated_card.dart';
import '../widgets/stock_chart_widget.dart';
import '../providers/app_state_provider.dart';
import '../services/auth_service.dart';
import '../screens/NewsDetailScreen.dart';

class StockDetailScreen extends StatefulWidget {
  final SearchResult stock;

  const StockDetailScreen({super.key, required this.stock});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen>
    with SingleTickerProviderStateMixin {
  late StockDataService _stockDataService;
  late NewsService _newsService;
  late TabController _tabController;

  StockQuote? _stockQuote;
  CompanyProfile? _companyProfile;
  List<HistoricalDataPoint>? _historicalData;
  StockFundamentals? _stockFundamentals;
  TechnicalData? _technicalData;
  DerivativesData? _derivativesData;
  List<NewsItem>? _companyNews;
  bool _isLoading = true;
  bool _isLoadingSecondaryData = true;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _stockDataService = StockDataService(auth);
    _newsService = NewsService(auth);
    _tabController = TabController(length: 5, vsync: this); // Changed to 5 tabs
    _fetchEssentialData();
    _fetchSecondaryData();
  }

  // Fetch essential data first (quote + profile) to show basic info quickly
  Future<void> _fetchEssentialData() async {
    try {
      // Fetch essential data concurrently for faster loading
      final results = await Future.wait([
        _stockDataService.fetchQuote(widget.stock.symbol),
        _stockDataService.fetchCompanyProfile(widget.stock.symbol),
      ]);

      if (mounted) {
        setState(() {
          _stockQuote = StockQuote.fromJson(results[0]);
          _companyProfile = CompanyProfile.fromJson(results[1]);
          _isLoading = false; // Show basic UI immediately
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fetch secondary data in background
  Future<void> _fetchSecondaryData() async {
    try {
      // Fetch all secondary data concurrently
      final results = await Future.wait([
        _stockDataService.fetchHistoricalData(widget.stock.symbol, 'D'),
        _stockDataService.fetchFundamentals(widget.stock.symbol),
        _stockDataService.fetchTechnicalData(widget.stock.symbol),
        _stockDataService.fetchDerivativesData(widget.stock.symbol),
        _newsService.getCompanyNews(widget.stock.symbol),
      ]);

      if (mounted) {
        setState(() {
          _historicalData = (results[0] as List)
              .map((json) => HistoricalDataPoint.fromJson(json as Map<String, dynamic>))
              .toList();
          _stockFundamentals = StockFundamentals.fromJson(results[1] as Map<String, dynamic>);
          _technicalData = TechnicalData.fromJson(results[2] as Map<String, dynamic>);
          _derivativesData = DerivativesData.fromJson(results[3] as Map<String, dynamic>);
          _companyNews = results[4] as List<NewsItem>;
          _isLoadingSecondaryData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSecondaryData = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          _buildPriceAndChange(),
                          const SizedBox(height: 24),
                          _buildTabBar(),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildOverviewTab(),
                                _buildTechnicalTab(),
                                _buildDerivativesTab(),
                                _buildFundamentalsTab(),
                                _buildNewsTab(),
                              ],
                            ),
                          ),
                     
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(color: AppColors.mutedText, fontSize: 16),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _companyProfile?.ticker ?? '',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                _companyProfile?.name ?? '',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
        // ✅ Add the wishlist icon here
        Consumer<AppStateProvider>(
          builder: (context, appState, child) {
            final isWishlisted = appState.isStockWishlisted(widget.stock.symbol);
            return IconButton(
              icon: Icon(
                isWishlisted ? Icons.favorite : Icons.favorite_border,
                color: isWishlisted ? AppColors.error : AppColors.mutedText,
              ),
              onPressed: () {
                if (isWishlisted) {
                  appState.removeFromWishlist(widget.stock);
                } else {
                  appState.addToWishlist(widget.stock);
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriceAndChange() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_stockQuote != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${_stockQuote!.currentPrice.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_stockQuote!.change.toStringAsFixed(2)} (${_stockQuote!.percentChange.toStringAsFixed(2)}%)',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: _stockQuote!.change >= 0
                      ? AppColors.positiveGreen
                      : AppColors.negativeRed,
                ),
              ),
            ],
          ),
      ],
    );
  }

Widget _buildTabBar() {
  return ElevatedCard(
    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
    child: TabBar(
      controller: _tabController,
      labelColor: Colors.white,
      unselectedLabelColor: AppColors.mutedText,
      // ✅ Set the divider color to transparent to remove the white line
      dividerColor: Colors.transparent,
      indicator: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 10),
      unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.normal, fontSize: 10),
      indicatorSize: TabBarIndicatorSize.tab,
      tabs: const [
        Tab(text: 'Overview'),
        Tab(text: 'Technical'),
        Tab(text: 'Derivative'),
        Tab(text: 'Fundamentals'),
        Tab(text: 'News'),
      ],
    ),
  );
}

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Performance Chart',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: _isLoadingSecondaryData
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : StockChartWidget(historicalData: _historicalData ?? []),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalTab() {
    if (_isLoadingSecondaryData || _technicalData == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          ElevatedCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Technical Indicators',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatRow(
                    'RSI (14)', _technicalData!.rsi.toStringAsFixed(2)),
                _buildStatRow('MACD', _technicalData!.macd.toStringAsFixed(2)),
                _buildStatRow('Trend', _technicalData!.trend),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDerivativesTab() {
    if (_derivativesData == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          ElevatedCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Derivatives Data',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatRow(
                    'Open Interest', _derivativesData!.openInterest.toString()),
                _buildStatRow('Volume', _derivativesData!.volume.toString()),
                _buildStatRow('Contract Type', _derivativesData!.contractType),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundamentalsTab() {
    if (_isLoadingSecondaryData || _stockFundamentals == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Know Your Stock',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRatingCard(
                  _stockFundamentals!.qualityRating,
                  _stockFundamentals!.qualityDescription,
                  AppColors.positiveGreen),
              const SizedBox(width: 12),
              _buildRatingCard(
                  _stockFundamentals!.valuationRating,
                  _stockFundamentals!.valuationDescription,
                  AppColors.negativeRed),
              const SizedBox(width: 12),
              _buildRatingCard(_stockFundamentals!.financeRating,
                  _stockFundamentals!.financeDescription, AppColors.primary),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildReturnCard(
                  '1 Year Return', _stockFundamentals!.oneYearReturn),
              const SizedBox(width: 12),
              _buildReturnCard(
                  'Sector Return', _stockFundamentals!.sectorReturn),
              const SizedBox(width: 12),
              _buildReturnCard(
                  'Market Return', _stockFundamentals!.marketReturn),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Fundamental Ratios',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRatioCard('PE Ratio', _stockFundamentals!.peRatio),
              const SizedBox(width: 12),
              _buildRatioCard(
                  'Price to Book Value', _stockFundamentals!.priceToBookValue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(int rating, String description, Color color) {
    return Expanded(
      child: ElevatedCard(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: rating / 5.0,
                    strokeWidth: 4,
                    color: color,
                    backgroundColor: AppColors.mutedText.withOpacity(0.3),
                  ),
                  Text(
                    '$rating/5',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnCard(String label, double value) {
    final bool isPositive = value >= 0;
    return Expanded(
      child: ElevatedCard(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${value.toStringAsFixed(2)}%',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isPositive ? AppColors.positiveGreen : AppColors.negativeRed,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatioCard(String label, double value) {
    return Expanded(
      child: ElevatedCard(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(color: AppColors.mutedText, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              value.toStringAsFixed(2),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsTab() {
    if (_isLoadingSecondaryData || _companyNews == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_companyNews!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: AppColors.mutedText,
            ),
            const SizedBox(height: 16),
            Text(
              'No recent news available',
              style: GoogleFonts.inter(
                color: AppColors.mutedText,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'for ${widget.stock.symbol}',
              style: GoogleFonts.inter(
                color: AppColors.mutedText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            '${widget.stock.symbol} News',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...(_companyNews!.map((news) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: ElevatedCard(
              padding: const EdgeInsets.all(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewsDetailScreen(newsItem: news),
                  ),
                ); 
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (news.imageUrl.isNotEmpty)
                    Container(
                      height: 150,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
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
                  Text(
                    news.title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news.description,
                    style: GoogleFonts.inter(
                      color: AppColors.mutedText,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            news.source.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            news.category.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: AppColors.mutedText,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatNewsTime(news.date),
                        style: GoogleFonts.inter(
                          color: AppColors.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ))).toList(),
        ],
      ),
    );
  }

  String _formatNewsTime(DateTime date) {
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

  
}