import 'package:flutter/material.dart';

class EarningsData {
  final String period;
  final double amount;
  EarningsData({required this.period, required this.amount});
}

class AllocationData {
  final String assetClass;
  final double weight; // percentage (0-100)
  AllocationData({required this.assetClass, required this.weight});
}

class RiskMetrics {
  final double beta;
  final double var95;       // Value at Risk 95%
  final double maxDrawdown; // %
  RiskMetrics({required this.beta, required this.var95, required this.maxDrawdown});
}

class AllocationSlice {
  final String label;
  final double percent;
  AllocationSlice({required this.label, required this.percent});
  factory AllocationSlice.fromJson(Map<String, dynamic> j) => AllocationSlice(
        label: (j['label'] ?? j['sector'] ?? j['assetClass'] ?? '') as String,
        percent: (j['percent'] ?? j['weight'] ?? 0).toDouble(),
      );
}
