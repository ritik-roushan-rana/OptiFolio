import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import '../services/portfolio_setup_service.dart';
import '../models/portfolio_data.dart';
import '../models/rebalance_model.dart';
import '../models/news_model.dart';
import '../models/search_result_model.dart';
import '../models/backtest_result_model.dart';

import '../services/auth_service.dart';
import '../services/portfolio_service.dart';
import '../services/backtest_service.dart';
import '../services/analytics_service.dart';
import '../services/rebalancing_service.dart';
import '../services/news_service.dart';
import '../services/search_service.dart';
import '../services/alerts_service.dart';
import '../services/portfolio_csv_loader.dart';
import '../services/settings_service.dart';

class AppStateProvider extends ChangeNotifier {
  int _currentTabIndex = 0;
  bool _showSettings = false;
  bool _showSearch = false;
  bool _showAccountSettings = false;
  bool _showNotificationsSettings = false;
  bool _showPrivacySettings = false;
  bool _showAppearanceSettings = false;

  PortfolioData _portfolioData = const PortfolioData(
    totalValue: 0.0,
    valueChange: 0.0,
    valueChangePercent: 0.0,
    riskScore: 0,
    performanceHistory: {},
    holdings: [],
  );

  String _selectedTimeframe = '1M';

  late final PortfolioService _portfolioService;
  late final BacktestService _backtestService;
  late final AnalyticsService _analyticsService;
  late final RebalancingService _rebalancingService;
  late final NewsService _newsService;
  late final SearchService _searchService;
  late final AlertsService _alertsService;
  late SettingsService _settingsService;

  final PortfolioSetupService _portfolioSetupService;
  final AuthService _authService;

  List<RebalanceRecommendation> _rebalancingSuggestions = [];
  List<RebalanceRecommendation> get rebalancingSuggestions => _rebalancingSuggestions;

  bool _isLoggedIn = false;

  String? _userName;
  String? _email;
  String? _phone;

  bool _isDisposed = false;

  List<NewsItem> _newsItems = [];
  List<NewsItem> get newsItems => _newsItems;

  final List<SearchResult> _wishlistedStocks = [];
  List<SearchResult> get wishlistedStocks => _wishlistedStocks;

  List<BacktestResultModel> _backtests = [];
  List<BacktestResultModel> get backtests => _backtests;

  List<SettingItem> _settings = [];
  List<SettingItem> get settings => _settings;

  int get currentTabIndex => _currentTabIndex;
  bool get showSettings => _showSettings;
  bool get showSearch => _showSearch;
  bool get showAccountSettings => _showAccountSettings;
  bool get showNotificationsSettings => _showNotificationsSettings;
  bool get showPrivacySettings => _showPrivacySettings;
  bool get showAppearanceSettings => _showAppearanceSettings;
  PortfolioData get portfolioData => _portfolioData;
  bool get isLoggedIn => _isLoggedIn;

  String get userName => _userName ?? 'Unknown User';
  String get email => _email ?? 'No Email';
  String get phone => _phone ?? '';
  String get selectedTimeframe => _selectedTimeframe;
  List<double> get performanceChartData =>
      _portfolioData.performanceHistory[_selectedTimeframe] ?? [];

  String get formattedTotalValue => _portfolioData.formattedTotalValue;
  String get formattedValueChange => _portfolioData.formattedValueChange;
  String get formattedValueChangePercent => _portfolioData.formattedValueChangePercent;
  bool get isPositiveChange => _portfolioData.isPositiveChange;

  AppStateProvider({
    required AuthService authService,
    required PortfolioSetupService portfolioSetupService,
  })  : _authService = authService,
        _portfolioSetupService = portfolioSetupService {
    _portfolioService = PortfolioService(_authService);
    _backtestService = BacktestService(_authService);
    _analyticsService = AnalyticsService(_authService);
    _rebalancingService = RebalancingService(_authService);
    _newsService = NewsService(_authService);
    _searchService = SearchService(_authService);
    _alertsService = AlertsService(_authService);
    _settingsService = SettingsService(_authService);

    _authService.onAuthStateChange.listen((logged) {
      _isLoggedIn = logged;
      if (logged) {
        final u = _authService.currentUser;
        if (u != null) {
          updateUserInfo(
            userName: u.fullName ?? 'User',
            email: u.email,
            phone: '',
          );
        }
        loadAll();
        loadSettings();
      } else {
        _resetState();
      }
    });

    // If already restored & logged in when provider created
    if (_authService.currentUser != null) {
      _isLoggedIn = true;
      final u = _authService.currentUser!;
      updateUserInfo(
        userName: u.fullName ?? 'User',
        email: u.email,
        phone: '',
      );
      loadAll();
    }
  }

  Future<void> loadAll() async {
    await Future.wait([
      loadPortfolio(),
      loadNews(),
      loadBacktests(),
      loadAnalytics(),
      loadAlerts(),
      loadSettings(),
    ]);
  }

  void _resetState() {
    _portfolioData = const PortfolioData(
      totalValue: 0.0,
      valueChange: 0.0,
      valueChangePercent: 0.0,
      riskScore: 0,
      performanceHistory: {},
      holdings: [],
    );
    _rebalancingSuggestions = [];
    _newsItems = [];
    _userName = null;
    _email = null;
    _phone = null;
    safeNotifyListeners();
  }

  void safeNotifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void setCurrentTab(int index) {
    _currentTabIndex = index;
    safeNotifyListeners();
  }

  // Settings toggles
  void showSettingsPage() { _showSettings = true; safeNotifyListeners(); }
  void hideSettingsPage() { _showSettings = false; safeNotifyListeners(); }
  void showSearchOverlay() { _showSearch = true; safeNotifyListeners(); }
  void hideSearchOverlay() { _showSearch = false; safeNotifyListeners(); }
  void showAccountSettingsPage() { _showAccountSettings = true; safeNotifyListeners(); }
  void hideAccountSettingsPage() { _showAccountSettings = false; safeNotifyListeners(); }
  void showNotificationsSettingsPage() { _showNotificationsSettings = true; safeNotifyListeners(); }
  void hideNotificationsSettingsPage() { _showNotificationsSettings = false; safeNotifyListeners(); }
  void showPrivacySettingsPage() { _showPrivacySettings = true; safeNotifyListeners(); }
  void hidePrivacySettingsPage() { _showPrivacySettings = false; safeNotifyListeners(); }
  void showAppearanceSettingsPage() { _showAppearanceSettings = true; safeNotifyListeners(); }
  void hideAppearanceSettingsPage() { _showAppearanceSettings = false; safeNotifyListeners(); }

  // Portfolio
  void updatePortfolioData(PortfolioData newData) {
    _portfolioData = newData;
    _selectedTimeframe = _portfolioData.performanceHistory.containsKey(_selectedTimeframe)
        ? _selectedTimeframe
        : (_portfolioData.performanceHistory.isNotEmpty
            ? _portfolioData.performanceHistory.keys.first
            : '1M');
    safeNotifyListeners();
  }

  void updateUserInfo({
    required String userName,
    required String email,
    String? phone,
  }) {
    _userName = userName;
    _email = email;
    _phone = phone;
    safeNotifyListeners();
  }

  void setSelectedTimeframe(String timeframe) {
    _selectedTimeframe = _portfolioData.performanceHistory.containsKey(timeframe)
        ? timeframe
        : (_portfolioData.performanceHistory.isNotEmpty
            ? _portfolioData.performanceHistory.keys.first
            : '1M');
    safeNotifyListeners();
  }

  Future<void> loadPortfolio() async {
    try {
      final data = await _portfolioService.fetchPortfolioData();
      updatePortfolioData(data);
      if (_portfolioData.holdings.isEmpty) {
        // fallback seed
        try {
          final seed = await loadPortfolioSeed();
          _portfolioData = seed.portfolio;
          safeNotifyListeners();
        } catch (e) {
          debugPrint('Seed fallback failed: $e');
        }
      }
      await loadRebalancingSuggestions();
    } catch (e) {
      debugPrint('Failed to load portfolio: $e');
      // final fallback if everything failed
      await loadSeedIfEmpty();
    }
  }

  Future<bool> checkForExistingPortfolio() async {
    return _portfolioSetupService.hasUserPortfolio();
  }

  Future<void> createPortfolio(String name, String? description, File excelFile) async {
    try {
      await _portfolioSetupService.createInitialPortfolio(name, description, excelFile);
      await loadPortfolio();
    } catch (e) {
      debugPrint('Failed to create portfolio: $e');
      rethrow;
    }
  }

  Future<void> updateExistingPortfolio(String name, String? description, File excelFile) async {
    try {
      await _portfolioSetupService.updatePortfolio(name, description, excelFile);
      await loadPortfolio();
    } catch (e) {
      debugPrint('Failed to update portfolio: $e');
      rethrow;
    }
  }

  // Rebalancing
  Future<void> loadRebalancingSuggestions() async {
    try {
      final suggestions = await _rebalancingService.fetchSuggestions(_portfolioData);
      _rebalancingSuggestions = suggestions;
      safeNotifyListeners();
    } catch (e) {
      debugPrint('Failed to load rebalancing suggestions: $e');
    }
  }

  void updateRebalancingSuggestions(List<RebalanceRecommendation> newSuggestions) {
    _rebalancingSuggestions = newSuggestions;
    safeNotifyListeners();
  }

  // News
  Future<void> loadNews() async {
    try {
      final data = await _newsService.getLatestNews();
      _newsItems = data;
      safeNotifyListeners();
    } catch (e) {
      debugPrint('Failed to load news: $e');
    }
  }

  // Wishlist
  bool isStockWishlisted(String symbol) =>
      _wishlistedStocks.any((stock) => stock.symbol == symbol);

  void addToWishlist(SearchResult stock) {
    if (!isStockWishlisted(stock.symbol)) {
      _wishlistedStocks.add(stock);
      safeNotifyListeners();
    }
  }

  void removeFromWishlist(SearchResult stock) {
    _wishlistedStocks.removeWhere((item) => item.symbol == stock.symbol);
    safeNotifyListeners();
  }

  // Backtests
  Future<void> loadBacktests() async {
    try {
      final results = await _backtestService.fetchBacktestResults();
      _backtests = results;
      safeNotifyListeners();
    } catch (e) {
      debugPrint('Failed to load backtests: $e');
    }
  }

  // Analytics
  Future<void> loadAnalytics() async {
    try {
      await _analyticsService.getEarningsData();
    } catch (_) {}
  }

  // Alerts
  Future<void> loadAlerts() async {
    try {
      await _alertsService.listAlerts();
    } catch (_) {}
  }

  Future<void> loadSettings() async {
    try {
      _settings = await _settingsService.fetch();
      safeNotifyListeners();
    } catch (_) {}
  }

  Future<void> toggleSetting(String key, bool value) async {
    final idx = _settings.indexWhere((s)=>s.key==key);
    if (idx == -1) return;
    _settings[idx].valueBool = value;
    safeNotifyListeners();
    try {
      await _settingsService.toggle(key, value);
    } catch (_) {
      // revert on failure
      _settings[idx].valueBool = !value;
      safeNotifyListeners();
    }
  }

  Future<void> loadSeedIfEmpty() async {
    if (_portfolioData.holdings.isEmpty) {
      try {
        final seed = await loadPortfolioSeed();
        _portfolioData = seed.portfolio;
        notifyListeners();
      } catch (e) {
        debugPrint('Seed load failed: $e');
      }
    }
  }
}