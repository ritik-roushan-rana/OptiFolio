class BacktestResultModel {
  final String period;
  final double returnPercent;
  final double sharpeRatio;
  final double maxDrawdown;
  final double volatility;

  BacktestResultModel({
    required this.period,
    required this.returnPercent,
    required this.sharpeRatio,
    required this.maxDrawdown,
    required this.volatility, // required (current design)
  });

  String get formattedReturn => '${returnPercent.toStringAsFixed(2)}%';
  String get formattedSharpeRatio => sharpeRatio.toStringAsFixed(2);
  String get formattedMaxDrawdown => '${maxDrawdown.toStringAsFixed(2)}%';
  String get formattedVolatility => '${volatility.toStringAsFixed(2)}%';

  factory BacktestResultModel.fromJson(Map<String, dynamic> json) {
    return BacktestResultModel(
      period: json['period'],
      returnPercent: (json['returnPercent'] ?? 0).toDouble(),
      sharpeRatio: (json['sharpeRatio'] ?? 0).toDouble(),
      maxDrawdown: (json['maxDrawdown'] ?? 0).toDouble(),
      volatility: (json['volatility'] ?? 0).toDouble(),
    );
  }
}

// Removed stray example instantiation. If needed, add as a comment:
// final example = BacktestResultModel(period: '1Y', returnPercent: 12.3, sharpeRatio: 0.85, maxDrawdown: -18.2, volatility: 14.6);