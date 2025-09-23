import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../widgets/gradient_background.dart';
import '../widgets/elevated_card.dart';
import '../models/alert_model.dart';
import '../services/alerts_service.dart';
import '../services/auth_service.dart';

class SmartAlertsScreen extends StatefulWidget {
  const SmartAlertsScreen({super.key});

  @override
  State<SmartAlertsScreen> createState() => _SmartAlertsScreenState();
}

class _SmartAlertsScreenState extends State<SmartAlertsScreen>
    with SingleTickerProviderStateMixin {
  late AlertsService _alertsService;
  late Future<List<AlertItem>> _alertsFuture;
  late AnimationController _iconController;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final auth = Provider.of<AuthService>(context);
    _alertsService = AlertsService(auth); // constructor now expects AuthService
    _alertsFuture = _alertsService.listAlerts(); // renamed from getSmartAlerts
    _initialized = true;
  }

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _refreshAlerts() async {
    setState(() {
      _alertsFuture = _alertsService.listAlerts();
    });
    await _alertsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          "Smart Alerts",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const GradientBackground(),
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshAlerts,
            child: FutureBuilder<List<AlertItem>>(
              future: _alertsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }
                final alerts = snapshot.data ?? [];
                if (alerts.isEmpty) {
                  return const Center(
                    child: Text(
                      "No alerts available",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }
                return Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 440),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: ListView.separated(
                      itemCount: alerts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) =>
                          _buildAlertCard(alerts[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(AlertItem alert) {
    return ElevatedCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _iconController,
            builder: (context, _) {
              final glowScale = 1 + 0.08 * _iconController.value;
              final shadowOpacity = 0.3 + 0.2 * _iconController.value;
              return Transform.scale(
                scale: glowScale,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: alert.isPositive
                          ? [
                              Colors.greenAccent.withOpacity(0.6),
                              Colors.green.withOpacity(0.15)
                            ]
                          : [
                              Colors.redAccent.withOpacity(0.6),
                              Colors.red.withOpacity(0.15)
                            ],
                      center: Alignment.center,
                      radius: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (alert.isPositive
                                ? Colors.greenAccent
                                : Colors.redAccent)
                            .withOpacity(shadowOpacity),
                        blurRadius: 14,
                        spreadRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    alert.isPositive ? Icons.trending_up : Icons.trending_down,
                    color: alert.isPositive
                        ? Colors.greenAccent.shade400
                        : Colors.redAccent.shade400,
                    size: 28,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                alert.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                alert.description,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                "${alert.timestamp.hour.toString().padLeft(2, '0')}:${alert.timestamp.minute.toString().padLeft(2, '0')}, "
                "${alert.timestamp.day}/${alert.timestamp.month}",
                style:
                    const TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward_ios,
              color: Colors.white24, size: 16),
        ],
      ),
    );
  }
}