import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../widgets/elevated_card.dart';
import '../models/portfolio_data.dart';
import '../providers/app_state_provider.dart';
import '../models/analytics_models.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';

class ChartsAnalyticsScreen extends StatefulWidget {
  const ChartsAnalyticsScreen({super.key});

  @override
  State<ChartsAnalyticsScreen> createState() => _ChartsAnalyticsScreenState();
}

class _ChartsAnalyticsScreenState extends State<ChartsAnalyticsScreen> {
  late AnalyticsService _analytics;
  Future<List<EarningsData>>? _earningsFuture;
  Future<List<double>>? _performanceFuture;

  @override
  void initState() {
    super.initState();
    // Defer service setup to next frame to ensure Provider context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      _analytics = AnalyticsService(auth);
      setState(() {
        _earningsFuture = _analytics.getEarningsData();
        _performanceFuture = _analytics.getPortfolioPerformanceData();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final portfolioData = appState.portfolioData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
            _buildTotalEarnings(portfolioData),
          const SizedBox(height: 24),
          _buildEarningsChartSection(),
          const SizedBox(height: 24),
          _buildPerformanceChartSection(),
          const SizedBox(height: 24),
          _buildFeaturedEarnings(portfolioData.holdings),
        ],
      ),
    );
  }

  Widget _buildEarningsChartSection() {
    if (_earningsFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return FutureBuilder<List<EarningsData>>(
      future: _earningsFuture,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Text('Error: ${snap.error}', style: const TextStyle(color: Colors.red));
        }
        final data = snap.data ?? [];
        if (data.isEmpty) {
          return const Center(child: Text('No earnings data', style: TextStyle(color: Colors.grey)));
        }
        final spots = data.asMap().entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.amount))
            .toList();
        final maxY = spots.map((s) => s.y).fold<double>(0, (p, c) => c > p ? c : p) * 1.2;

        return ElevatedCard(
          child: SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: maxY == 0 ? 100 : maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.success,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPerformanceChartSection() {
    if (_performanceFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return FutureBuilder<List<double>>(
      future: _performanceFuture,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Text('Error: ${snap.error}', style: const TextStyle(color: Colors.red));
        }
        final series = snap.data ?? [];
        if (series.isEmpty) {
          return const Center(child: Text('No performance data', style: TextStyle(color: Colors.grey)));
        }
        final spots = series.asMap().entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList();
        final maxY = spots.map((s) => s.y).fold<double>(0, (p, c) => c > p ? c : p) * 1.15;

        return ElevatedCard(
          child: SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: maxY == 0 ? 100 : maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------- Header ----------------
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'My Earn',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Text(
          'Discover',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  // ---------------- Total Earnings ----------------
  Widget _buildTotalEarnings(PortfolioData data) {
    return Center(
      child: Column(
        children: [
          Text(
            data.formattedTotalValue,
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data.formattedValueChange,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: data.isPositiveChange ? AppColors.success : AppColors.error,
                ),
              ),
              Text(
                ' • ',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              Text(
                '${data.formattedValueChangePercent} this month',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: data.isPositiveChange ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Featured Earnings ----------------
  Widget _buildFeaturedEarnings(List<AssetData> featuredAssets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Featured Earnings',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...featuredAssets.map((asset) => _buildAssetCard(asset)),
      ],
    );
  }

  Widget _buildAssetCard(AssetData asset) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // FIX: show full symbol (no truncation) and auto size to fit circle
              _symbolAvatar(asset.symbol),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${asset.value.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    asset.changePercent >= 0
                        ? '+${asset.changePercent.toStringAsFixed(2)}%'
                        : '${asset.changePercent.toStringAsFixed(2)}%',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: asset.changePercent >= 0
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NEW helper to render full symbol without cropping
  Widget _symbolAvatar(String symbol) {
    final upper = symbol.toUpperCase();
    // Adjust font size based on length so 4–6 chars still fit
    double baseSize;
    switch (upper.length) {
      case 1:
      case 2:
        baseSize = 18;
        break;
      case 3:
        baseSize = 16;
        break;
      case 4:
        baseSize = 14;
        break;
      case 5:
        baseSize = 12;
        break;
      default:
        baseSize = 11;
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.primary.withOpacity(0.18),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          upper,
          style: GoogleFonts.inter(
            fontSize: baseSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}