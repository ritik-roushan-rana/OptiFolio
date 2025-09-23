import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import '../models/portfolio_data.dart';
import '../models/backtest_result_model.dart';

class PortfolioSeedBundle {
  final PortfolioData portfolio;
  final List<BacktestResultModel> backtests;
  PortfolioSeedBundle(this.portfolio, this.backtests);
}

Future<PortfolioSeedBundle> loadPortfolioSeed() async {
  final raw = await rootBundle.loadString('assets/data/portfolio_full_seed.csv');

  final lines = const LineSplitter()
      .convert(raw)
      .where((l) =>
          l.trim().isNotEmpty &&
          !l.startsWith('//') &&
          l.trim() != '150')
      .toList();

  if (lines.length < 2) throw StateError('CSV empty');

  double totalValue = 0;
  double valueChange = 0;
  double valueChangePercent = 0;
  int riskScore = 0;

  final backtests = <BacktestResultModel>[];
  final performance = <String, List<double>>{};
  final tmpHoldings = <_HoldingRow>[];

  for (final line in lines.skip(1)) {
    final cols = _split(line); // now preserves empty columns
    if (cols.isEmpty) continue;

    if (cols[0] == 'holding' && cols.length >= 10) {
      debugPrint('HOLDING ROW RAW => ${cols.take(10).toList()}');
    }

    switch (cols[0]) {
      case 'portfolio':
        // Adjust indexes only if portfolio line present
        if (cols.length > 22) {
          totalValue = _d(cols[18]);
          valueChange = _d(cols[19]);
          valueChangePercent = _d(cols[20]);
          riskScore = int.tryParse(cols[21]) ?? 0;
        }
        break;
      case 'holding':
        // Expect: holding, (key maybe blank), symbol (idx2), name (idx3) ...
        if (cols.length < 10) continue;
        final symbol = _clean(cols[2]);
        if (symbol.isEmpty) continue;
        final rawName = _clean(cols[3]);
        final value = _d(cols[6]);
        final changePct = _d(cols[9]); // gain_loss_pc column
        tmpHoldings.add(_HoldingRow(
          symbol: symbol,
          name: rawName.isEmpty ? symbol : rawName,
          value: value,
          changePercent: changePct,
        ));
        break;
      case 'backtest':
        if (cols.length > 14) {
          final period = _clean(cols[10]);
            backtests.add(BacktestResultModel(
              period: period,
              returnPercent: _d(cols[11]),
              sharpeRatio: _d(cols[12]),
              maxDrawdown: _d(cols[13]),
              volatility: _d(cols[14]),
            ));
        }
        break;
      case 'performance':
        if (cols.length > 18) {
          final timeframe = _clean(cols[15]);
          final idx = int.tryParse(cols[16]) ?? 0;
          final v = _d(cols[17]);
          final list = performance.putIfAbsent(timeframe, () => []);
          if (list.length <= idx) list.length = idx + 1;
          list[idx] = v;
        }
        break;
      default:
        break;
    }
  }

  if (totalValue == 0) {
    totalValue = tmpHoldings.fold(0.0, (a, h) => a + h.value);
  }

  final holdings = tmpHoldings.map((h) {
    final pct = totalValue == 0 ? 0.0 : (h.value / totalValue) * 100.0;
    return AssetData(
      symbol: h.symbol,
      name: h.name,
      value: h.value,
      percentage: pct,
      changePercent: h.changePercent,
      iconUrl: 'assets/icons/${h.symbol.toLowerCase()}.png',
    );
  }).toList();

  for (final h in holdings) {
    debugPrint('ASSET => ${h.symbol} | ${h.name} | value=${h.value} | pct=${h.percentage.toStringAsFixed(2)} | change=${h.changePercent}');
  }
  debugPrint('Loaded ${holdings.length} holdings, ${backtests.length} backtests.');

  final portfolio = PortfolioData(
    totalValue: totalValue,
    valueChange: valueChange,
    valueChangePercent: valueChangePercent,
    riskScore: riskScore,
    performanceHistory: performance,
    holdings: holdings,
  );

  return PortfolioSeedBundle(portfolio, backtests);
}

// Robust number parser
double _d(String s) {
  if (s.isEmpty) return 0.0;
  final cleaned = s
      .replaceAll('"', '')
      .replaceAll('%', '')
      .replaceAll(',', '')
      .trim();
  return double.tryParse(cleaned) ?? 0.0;
}

// Preserve empty columns (do NOT remove consecutive commas)
List<String> _split(String line) {
  final result = <String>[];
  final sb = StringBuffer();
  bool inQuotes = false;
  for (int i = 0; i < line.length; i++) {
    final c = line[i];
    if (c == '"') {
      inQuotes = !inQuotes;
    } else if (c == ',' && !inQuotes) {
      result.add(sb.toString());
      sb.clear();
      continue;
    }
    sb.write(c);
  }
  result.add(sb.toString());
  return result;
}

String _clean(String s) => s.replaceAll('"', '').trim();

class _HoldingRow {
  final String symbol;
  final String name;
  final double value;
  final double changePercent;
  _HoldingRow({
    required this.symbol,
    required this.name,
    required this.value,
    required this.changePercent,
  });
}