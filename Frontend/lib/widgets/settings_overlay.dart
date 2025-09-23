import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../utils/app_colors.dart';
import 'elevated_card.dart';
import '../providers/app_state_provider.dart';
import '../services/auth_service.dart'; // ✅ Import the AuthService
import '../services/settings_service.dart'; // <-- add to access SettingItem

class SettingsOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onNavigateToAccount;
  final VoidCallback onNavigateToNotifications;
  final VoidCallback onNavigateToPrivacy;
  final VoidCallback onNavigateToAppearance;

  const SettingsOverlay({
    super.key,
    required this.onClose,
    required this.onNavigateToAccount,
    required this.onNavigateToNotifications,
    required this.onNavigateToPrivacy,
    required this.onNavigateToAppearance,
  });

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  // REMOVE static hard‑coded items (keep commented to show change)
  //  final List<Map<String, dynamic>> _settingsItems = [ ... ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();

    // Load dynamic settings from backend (after first frame so Provider is ready)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppStateProvider>();
      if (app.settings.isEmpty) {
        app.loadSettings();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _animationController.reverse();
    widget.onClose();
  }

  void _handleItemClick(String id) {
    switch (id) {
      case 'account':
        widget.onNavigateToAccount();
        break;
      case 'notifications':
        widget.onNavigateToNotifications();
        break;
      case 'privacy':
        widget.onNavigateToPrivacy();
        break;
      case 'appearance':
        widget.onNavigateToAppearance();
        break;
    }
  }

  void _handleLogout() async {
    // ✅ Get the AuthService from the Provider tree
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
    // After signing out, navigate to the login screen
    if (mounted) {
       Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final dynamicSettings = appState.settings; // dynamic list from backend

    return SlideTransition(
      position: _slideAnimation,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _close,
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Settings',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ------------------ User Info Card ------------------
                        ElevatedCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.person,
                                      color: Colors.white, size: 32),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(appState.userName,
                                          style: GoogleFonts.inter(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white)),
                                      const SizedBox(height: 2),
                                      Text(appState.email,
                                          style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: AppColors.mutedText)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _handleItemClick('account'),
                                  icon: const Icon(Icons.edit,
                                      color: AppColors.mutedText, size: 20),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ------------- Dynamic Settings Items -------------
                        if (dynamicSettings.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else
                          ..._buildDynamicSettingCards(dynamicSettings),

                        const SizedBox(height: 16),
                        _buildAboutSection(),

                        const SizedBox(height: 16),

                        // ------------------ Logout ------------------
                        ElevatedCard(
                          onTap: _handleLogout,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.darkCard,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.logout,
                                        color: Colors.redAccent, size: 24),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Logout',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------ Helper Methods ------------------

  /// Build list of setting cards matching ORIGINAL UI (card + icon + arrow / toggle)
  List<Widget> _buildDynamicSettingCards(List<SettingItem> settings) {
    // Maintain order property from backend
    final ordered = [...settings]..sort((a,b)=>a.order.compareTo(b.order));
    return List.generate(ordered.length, (i) {
      final s = ordered[i];
      switch (s.type) {
        case 'toggle':
          return _animatedWrapper(
            index: i,
            child: _toggleCard(
              title: s.title,
              description: s.description,
              icon: Icons.toggle_on_outlined,
              value: s.valueBool ?? false,
              onChanged: (v) =>
                  context.read<AppStateProvider>().toggleSetting(s.key, v),
            ),
          );
        case 'navigation':
          return _animatedWrapper(
            index: i,
            child: _navCard(
              title: s.title,
              description: s.description,
              icon: _iconForKey(s.key),
              onTap: () => _handleItemClick(s.key),
            ),
          );
        case 'info':
          return _animatedWrapper(
            index: i,
            child: _infoCard(
              title: s.title,
              value: s.valueString ?? '',
              description: s.description,
              icon: Icons.info_outline,
            ),
          );
        default:
          return _animatedWrapper(
            index: i,
            child: _navCard(
              title: s.title,
              description: s.description,
              icon: _iconForKey(s.key),
              onTap: () => _handleItemClick(s.key),
            ),
          );
      }
    });
  }

  IconData _iconForKey(String key) {
    switch (key) {
      case 'account': return Icons.person_outline;
      case 'notifications': return Icons.notifications_outlined;
      case 'privacy': return Icons.security_outlined;
      case 'appearance': return Icons.brightness_6_outlined;
      case 'twoFactor': return Icons.verified_user_outlined;
      case 'priceAlerts': return Icons.campaign_outlined;
      case 'newsUpdates': return Icons.article_outlined;
      default: return Icons.settings_outlined;
    }
  }

  Widget _toggleCard({
    required String title,
    required String description,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _leadingIcon(icon),
              const SizedBox(width: 16),
              Expanded(
                child: _titleSubtitle(title, description),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _navCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedCard(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _leadingIcon(icon),
              const SizedBox(width: 16),
              Expanded(child: _titleSubtitle(title, description)),
              const Icon(Icons.arrow_forward_ios,
                  color: AppColors.mutedText, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String value,
    required String description,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _leadingIcon(icon),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      description.isEmpty ? value : '$description $value',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.mutedText,
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

  Widget _leadingIcon(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
    );
  }

  Widget _titleSubtitle(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            )),
        const SizedBox(height: 4),
        Text(
          description,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.mutedText,
          ),
        ),
      ],
    );
  }

  // Wrap each dynamic card with SAME animation pattern used before
  Widget _animatedWrapper({required int index, required Widget child}) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (_, __) {
        final slide = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.2 + index * 0.1, 1.0, curve: Curves.easeInOut),
          ),
        );
        final fade = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.2 + index * 0.1, 1.0, curve: Curves.easeInOut),
          ),
        );
        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: fade, child: child),
        );
      },
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Portfolio Tracker',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAboutItem('Version', '1.0.0'),
                _buildAboutItem('Build', '2024.1.1'),
                _buildAboutItem('Developer', 'FinTech Labs'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.mutedText,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}