import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../widgets/elevated_card.dart';
import '../models/backtest_result_model.dart';
import '../services/backtest_service.dart';
import '../services/auth_service.dart';

class BacktestingScreen extends StatefulWidget {
  const BacktestingScreen({super.key});

  @override
  State<BacktestingScreen> createState() => _BacktestingScreenState();
}

class _BacktestingScreenState extends State<BacktestingScreen> {
  late BacktestService _service;
  Future<List<BacktestResultModel>>? _future;
  String _selectedPeriod = '1Y';
  List<String> _periods = [];
  bool _running = false;

  @override
  void initState() {
    super.initState();
    // Service injected after first build via addPostFrameCallback
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthService>(context);
    _service = BacktestService(auth);
    _future ??= _load();
  }

  Future<List<BacktestResultModel>> _load() async {
    final data = await _service.fetchBacktestResults();
    if (!data.any((r) => r.period == _selectedPeriod) && data.isNotEmpty) {
      _selectedPeriod = data.first.period;
    }
    return data;
  }

  Future<void> _runNew(String period) async {
    if (_running) return;
    setState(() => _running = true);
    try {
      await _service.runBacktest(period);
      setState(() {
        _future = _load();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backtest completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BacktestResultModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.inter(color: Colors.white)));
        }
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return Center(
            child: Text('No backtest data yet', style: GoogleFonts.inter(color: Colors.white70)),
          );
        }
        _periods = results.map((e) => e.period).toList();
        final currentResult = results.firstWhere(
          (r) => r.period == _selectedPeriod,
          orElse: () => results.first,
        );

        return RefreshIndicator(
          color: AppColors.primary,
            onRefresh: () async {
              setState(() => _future = _load());
              await _future;
            },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildPeriodSelector(),
                const SizedBox(height: 24),
                _buildPerformanceMetrics(currentResult),
                const SizedBox(height: 24),
                _buildBacktestChart(results),
                const SizedBox(height: 24),
                _buildStrategyComparison(currentResult),
                const SizedBox(height: 24),
                _buildRunBacktestButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.timeline, color: AppColors.info, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Strategy Backtesting',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            Text('RL-optimized portfolio performance',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400])),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return ElevatedCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          children: _periods.map((period) {
            final isSelected = period == _selectedPeriod;
            return GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[600]!),
                ),
                child: Text(period,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[400])),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics(BacktestResultModel result) {
    return ElevatedCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance Metrics ($_selectedPeriod)',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _metric('Total Return', result.formattedReturn, AppColors.success)),
                Expanded(child: _metric('Sharpe Ratio', result.formattedSharpeRatio, AppColors.info)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _metric('Max Drawdown', result.formattedMaxDrawdown, AppColors.error)),
                Expanded(child: _metric('Volatility', result.formattedVolatility, AppColors.warning)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400])),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  Widget _buildBacktestChart(List<BacktestResultModel> results) {
    // Simple overlay; could map equityCurve if added to model
    return ElevatedCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: true, drawHorizontalLine: true),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(12, (i) => FlSpot(i.toDouble(), 10000 + i * 240)),
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.1)),
                ),
                LineChartBarData(
                  spots: List.generate(12, (i) => FlSpot(i.toDouble(), 10000 + i * 180)),
                  isCurved: true,
                  color: Colors.grey[400]!,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  dashArray: [4, 4],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStrategyComparison(BacktestResultModel result) {
    return ElevatedCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Strategy Comparison',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 16),
          _compRow('Portfolio Return', result.formattedReturn, '+18.7%'),
          _compRow('Sharpe Ratio', result.formattedSharpeRatio, '1.23'),
            _compRow('Max Drawdown', result.formattedMaxDrawdown, '-15.6%'),
            _compRow('Win Rate', '67%', '58%'),
        ]),
      ),
    );
  }

  Widget _compRow(String metric, String portfolioValue, String benchmarkValue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(metric, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]))),
          Expanded(
              child: Text(portfolioValue,
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.success),
                  textAlign: TextAlign.center)),
          Expanded(
              child: Text(benchmarkValue,
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[300]),
                  textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildRunBacktestButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _running ? null : () => _runNew(_selectedPeriod),
        icon: _running
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.play_arrow),
        label: Text(
          _running ? 'Running...' : 'Run New Backtest',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}