import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/setup_required_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var backendReady = false;
  String? startupError;

  if (AppConfig.backendConfigured) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      backendReady = true;
    } catch (e) {
      startupError = 'Online backend could not start: $e';
    }
  }

  runApp(AsmatQuizApp(
    backendReady: backendReady,
    startupError: startupError,
  ));
}

class AsmatQuizApp extends StatelessWidget {
  const AsmatQuizApp({
    super.key,
    required this.backendReady,
    this.startupError,
  });

  final bool backendReady;
  final String? startupError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Asmat's World - GK Quiz",
      theme: AppTheme.light(),
      home: SplashRouter(
        backendReady: backendReady,
        startupError: startupError,
      ),
    );
  }
}

class SplashRouter extends StatefulWidget {
  const SplashRouter({
    super.key,
    required this.backendReady,
    this.startupError,
  });

  final bool backendReady;
  final String? startupError;

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return const SplashScreen();

    if (!AppConfig.backendConfigured || !widget.backendReady) {
      return SetupRequiredScreen(startupError: widget.startupError);
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, _) {
        final session = Supabase.instance.client.auth.currentSession;
        return session == null ? const AuthScreen() : const HomeScreen();
      },
    );
  }
}
