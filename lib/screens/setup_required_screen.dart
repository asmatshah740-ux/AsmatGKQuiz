import 'package:flutter/material.dart';

import '../widgets/app_theme.dart';

class SetupRequiredScreen extends StatelessWidget {
  const SetupRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 64, color: AppTheme.blue),
                    const SizedBox(height: 16),
                    const Text('Online Setup Required', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.navy)),
                    const SizedBox(height: 10),
                    const Text(
                      'This final build does not use demo login or fake data. Add your Supabase URL and anon key to the GitHub build secrets, then rebuild the APK.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppTheme.gold.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
                      child: const Text('See FINAL_SETUP.md inside the project for the exact mobile setup steps.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
