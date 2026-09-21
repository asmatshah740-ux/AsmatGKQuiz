import 'package:flutter/material.dart';

import '../widgets/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.navy, Color(0xFF0A3A73)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Welcome To', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text("Asmat's World", style: TextStyle(color: AppTheme.gold, fontSize: 38, fontWeight: FontWeight.w900)),
              const SizedBox(height: 42),
              Container(
                width: 124,
                height: 124,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .08),
                  border: Border.all(color: AppTheme.gold, width: 2),
                ),
                child: const Icon(Icons.lightbulb_rounded, size: 76, color: AppTheme.gold),
              ),
              const SizedBox(height: 24),
              const Text('GK QUIZ', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const Text('Think • Learn • Grow', style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 50),
              const SizedBox(width: 170, child: LinearProgressIndicator(minHeight: 7, borderRadius: BorderRadius.all(Radius.circular(20)))),
            ],
          ),
        ),
      ),
    );
  }
}
