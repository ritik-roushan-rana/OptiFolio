import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../widgets/elevated_card.dart';
import '../widgets/gradient_background.dart';
import '../services/search_service.dart';
import '../services/auth_service.dart';
import '../models/search_result_model.dart';
import '../screens/stock_detail_screen.dart';

class SearchOverlay extends StatefulWidget {
  final VoidCallback onClose;
  const SearchOverlay({super.key, required this.onClose});

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay>
    with SingleTickerProviderStateMixin {
  late SearchService _searchService;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // State
  List<String> _recentSearches = [];
  List<SearchResult> _trendingResults = [];
  List<SearchResult> _filteredResults = [];
  Timer? _debounce;
  bool _loading = false;
  Future<List<SearchResult>>? _trendingFuture;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward();

    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthService>();
      _searchService = SearchService(auth);
      await _loadRecents();
      await _loadTrending();
      if (mounted) {
        setState(() => _filteredResults = _trendingResults);
        _focusNode.requestFocus();
      }
    });
  }

  Future<void> _loadRecents() async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches = prefs.getStringList('recent_searches') ?? [];
  }

  Future<void> _saveRecents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  Future<void> _loadTrending() async {
    setState(() => _loading = true);
    try {
      final results = await _searchService.trending();
      setState(() {
        _trendingResults = results;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim();
    if (q.isEmpty) {
      setState(() {
        _filteredResults = _trendingResults;
      });
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _loading = true);
      try {
        final results = await _searchService.search(q);
        if (mounted) {
          setState(() {
            _filteredResults = results;
          });
        }
      } catch (_) {
        // silently ignore
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  void _addRecent(String symbol) {
    _recentSearches.remove(symbol);
    _recentSearches.insert(0, symbol);
    if (_recentSearches.length > 12) {
      _recentSearches = _recentSearches.sublist(0, 12);
    }
    _saveRecents();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _animationController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _animationController.reverse();
    widget.onClose();
  }

  void _openResult(SearchResult result) {
    _addRecent(result.symbol);
    _close();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockDetailScreen(stock: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              const GradientBackground(),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    if (_searchController.text.isEmpty) ...[
                      if (_recentSearches.isNotEmpty)
                        _buildSectionTitle('Recent Searches', Icons.access_time),
                      if (_recentSearches.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: _recentSearches
                                .map((symbol) => _buildPill(symbol, onTap: () {
                                      _searchController.text = symbol;
                                      _onSearchChanged();
                                    }))
                                .toList(),
                          ),
                        ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Trending', Icons.trending_up),
                    ],
                    Expanded(
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredResults.length,
                              itemBuilder: (context, index) =>
                                  _buildResultItem(_filteredResults[index]),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        style: GoogleFonts.inter(color: Colors.black, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search stocks, ETFs, or crypto...',
            hintStyle: GoogleFonts.inter(color: Colors.black45),
          prefixIcon: const Icon(Icons.search, color: Colors.black54),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, color: Colors.black54),
            onPressed: _close,
          ),
          filled: true,
          fillColor: const Color.fromARGB(255, 240, 237, 237),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.mutedText, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem(SearchResult result) {
    return GestureDetector(
      onTap: () => _openResult(result),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ElevatedCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.darkSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      result.symbol.isNotEmpty ? result.symbol[0] : '?',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.symbol,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        result.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildPill(result.type),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingSection() {
    return FutureBuilder<List<SearchResult>>(
      future: _trendingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: SizedBox(
              height: 60,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Failed to load trending: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          );
        }
        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return const SizedBox.shrink();
        }
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: data.map((r) {
            return GestureDetector(
              onTap: () => _openResult(r),
              child: Chip(
                backgroundColor: AppColors.darkCard,
                label: Text(
                  r.symbol,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}