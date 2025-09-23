class SearchResult {
  final String symbol;
  final String name;
  final String type;        // original field (e.g. STOCK, ETF)
  final String? exchange;   // NEW optional
  final String? assetType;  // NEW optional (can mirror `type`)

  SearchResult({
    required this.symbol,
    required this.name,
    required this.type,
    this.exchange,
    this.assetType,
  });

  factory SearchResult.fromJson(Map<String, dynamic> j) => SearchResult(
        symbol: (j['symbol'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        type: (j['type'] ?? j['assetType'] ?? 'STOCK') as String,
        exchange: j['exchange'] as String?,
        assetType: j['assetType'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'name': name,
        'type': type,
        if (exchange != null) 'exchange': exchange,
        if (assetType != null) 'assetType': assetType,
      };
}