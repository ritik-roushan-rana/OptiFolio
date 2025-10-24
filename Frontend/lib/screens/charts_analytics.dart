import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/analytics_models.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';

class ChartsAnalytics extends StatefulWidget {
  const ChartsAnalytics({super.key});

  @override
  State<ChartsAnalytics> createState() => _ChartsAnalyticsState();
}

class _ChartsAnalyticsState extends State<ChartsAnalytics> {
  String selectedPeriod = '1Y';
  String selectedChart = 'Performance';
  late AnalyticsService _analytics;
  Future<List<double>>? _performanceFuture;
  Future<List<AllocationSlice>>? _allocationFuture;
  Future<RiskMetrics>? _riskMetricsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      _analytics = AnalyticsService(auth);
      setState(() {
        _performanceFuture = _analytics.getPortfolioPerformanceData();
        _allocationFuture = _analytics.getSectorAllocations();
        _riskMetricsFuture = _analytics.getRiskMetrics();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildControls(),
          const SizedBox(height: 24),
          _buildMainChart(),
          const SizedBox(height: 24),
          _buildAllocationChart(),
          const SizedBox(height: 24),
          _buildPerformanceMetrics(),
          const SizedBox(height: 24),
          _buildRiskAnalytics(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Portfolio Analytics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Advanced performance insights',
          style: TextStyle(
            color: AppTheme.gray400,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        Row(
          children: ['1M', '3M', '6M', '1Y', '2Y', 'ALL'].map((period) {
            final isSelected = selectedPeriod == period;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedPeriod = period),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.blue500 : AppTheme.gray800,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppTheme.blue500 : AppTheme.gray700,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      period,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.gray400,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: ['Performance', 'Risk', 'Volatility'].map((chart) {
            final isSelected = selectedChart == chart;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedChart = chart),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.gray700 : AppTheme.gray800,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppTheme.gray600 : AppTheme.gray700,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      chart,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.gray400,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMainChart() {
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
          return Text('Error: ${snap.error}', style: const TextStyle(color: Colors.red));
        }
        final data = snap.data ?? [];
        if (data.isEmpty) {
          return const Center(child: Text('No performance data', style: TextStyle(color: Colors.grey)));
        }
        final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
        final maxY = spots.map((s) => s.y).fold<double>(0, (p, c) => c > p ? c : p) * 1.15;
        return Card(
          child: Container(
            padding: const EdgeInsets.all(16),
            height: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$selectedChart Chart ($selectedPeriod)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) {
                        return const FlLine(color: AppTheme.gray700, strokeWidth: 1);
                      }),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: maxY == 0 ? 100 : maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppTheme.blue500,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllocationChart() {
    if (_allocationFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return FutureBuilder<List<AllocationSlice>>(
      future: _allocationFuture,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Text('Error: ${snap.error}', style: const TextStyle(color: Colors.red));
        }
        final slices = snap.data ?? [];
        if (slices.isEmpty) {
          return const Center(child: Text('No allocation data', style: TextStyle(color: Colors.grey)));
        }
        final pieSections = slices.map((slice) {
          return PieChartSectionData(
            color: AppTheme.blue500,
            value: slice.percent,
            title: '${slice.label}\n${slice.percent.toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();
        return Card(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Asset Allocation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: pieSections,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: slices.map((slice) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppTheme.blue500,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${slice.label} ${slice.percent.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: AppTheme.gray300,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPerformanceMetrics() {
    if (_riskMetricsFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return FutureBuilder<RiskMetrics>(
      future: _riskMetricsFuture,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Text('Error: ${snap.error}', style: const TextStyle(color: Colors.red));
        }
        final metrics = snap.data;
        if (metrics == null) {
          return const Center(child: Text('No metrics data', style: TextStyle(color: Colors.grey)));
        }
        return Card(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Performance Metrics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem('Beta', metrics.beta.toStringAsFixed(2), AppTheme.blue500),
                    ),
                    Expanded(
                      child: _buildMetricItem('VaR 95%', metrics.var95.toStringAsFixed(2), AppTheme.yellow500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem('Max Drawdown', metrics.maxDrawdown.toStringAsFixed(2), AppTheme.red500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRiskAnalytics() {
    if (_riskMetricsFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return FutureBuilder<RiskMetrics>(
      future: _riskMetricsFuture,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Text('Error: ${snap.error}', style: const TextStyle(color: Colors.red));
        }
        final metrics = snap.data;
        if (metrics == null) {
          return const Center(child: Text('No risk data', style: TextStyle(color: Colors.grey)));
        }
        return Card(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Risk Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem('Beta', metrics.beta.toStringAsFixed(2), AppTheme.blue500),
                    ),
                    Expanded(
                      child: _buildMetricItem('VaR 95%', metrics.var95.toStringAsFixed(2), AppTheme.yellow500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem('Max Drawdown', metrics.maxDrawdown.toStringAsFixed(2), AppTheme.red500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.gray400,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}