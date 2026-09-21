import 'package:flutter/material.dart';

import '../widgets/app_theme.dart';

class SetupRequiredScreen extends StatelessWidget {
  const SetupRequiredScreen({super.key, this.startupError});

  final String? startupError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 64, color: AppTheme.blue),
                      const SizedBox(height: 16),
                      const Text(
                        'Online Setup Required',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.navy),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'The final app uses real online accounts and data. Add your Supabase URL and anon key to the GitHub build secrets, then rebuild the APK.',
                        textAlign: TextAlign.center,
                      ),
                      if (startupError != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            startupError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Once the online backend is connected, login, daily questions, leaderboard, check-ins and anti-cheat will become active.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
