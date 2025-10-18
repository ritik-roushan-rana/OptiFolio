import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/app_state_provider.dart';
import 'services/auth_service.dart';
import 'services/portfolio_setup_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/LoginScreen.dart';
import 'screens/SignUpScreen.dart';
import 'screens/main_screen.dart';
import 'screens/chatbot_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(
          create: (context) =>
              PortfolioSetupService(Provider.of<AuthService>(context, listen: false)),
        ),
        ChangeNotifierProvider(
          create: (context) {
            final authService = Provider.of<AuthService>(context, listen: false);
            final portfolioSetupService =
                Provider.of<PortfolioSetupService>(context, listen: false);
            return AppStateProvider(
              authService: authService,
              portfolioSetupService: portfolioSetupService,
            );
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Portfolio Rebalancer',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignUpScreen(),
              '/main': (context) => const MainScreen(),
              '/chatbot': (context) => const ChatbotScreen(),
            },
          );
        },
      ),
    );
  }
}