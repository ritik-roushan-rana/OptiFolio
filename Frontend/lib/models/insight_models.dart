class RiskReturnPoint {
  final String asset;
  final double risk;
  final double returnRate;
  RiskReturnPoint({
    required this.asset,
    required this.risk,
    required this.returnRate,
  });
  factory RiskReturnPoint.fromJson(Map<String, dynamic> j) => RiskReturnPoint(
        asset: j['asset'] ?? '',
        risk: (j['risk'] ?? 0).toDouble(),
        returnRate: (j['returnRate'] ?? j['return'] ?? 0).toDouble(),
      );
}

class CorrelationData {
  final String asset1;
  final String asset2;
  final double correlation;
  CorrelationData({
    required this.asset1,
    required this.asset2,
    required this.correlation,
  });
  factory CorrelationData.fromJson(Map<String, dynamic> j) => CorrelationData(
        asset1: j['asset1'] ?? '',
        asset2: j['asset2'] ?? '',
        correlation: (j['correlation'] ?? 0).toDouble(),
      );
}

class FeeReturnData {
  final String fund;
  final double fee;          // expense ratio / fee %
  final double annualReturn; // annualized return %
  FeeReturnData({
    required this.fund,
    required this.fee,
    required this.annualReturn,
  });
  factory FeeReturnData.fromJson(Map<String, dynamic> j) => FeeReturnData(
        fund: j['fund'] ?? j['symbol'] ?? j['name'] ?? '',
        fee: (j['fee'] ?? j['expenseRatio'] ?? 0).toDouble(),
        annualReturn: (j['annualReturn'] ?? j['return'] ?? 0).toDouble(),
      );
}

class WhatIfScenario {
  final String scenario;
  final double impactPercent;
  final String notes;
  WhatIfScenario({
    required this.scenario,
    required this.impactPercent,
    required this.notes,
  });
  factory WhatIfScenario.fromJson(Map<String, dynamic> j) => WhatIfScenario(
        scenario: j['scenario'] ?? '',
        impactPercent: (j['impactPercent'] ?? j['impact'] ?? 0).toDouble(),
        notes: j['notes'] ?? '',
      );
}