import 'package:flutter/material.dart';

import 'app_theme.dart';

class MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const MetricChip({super.key, required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: c)),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SectionTitle(this.title, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.navy)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: const TextStyle(color: Colors.black54)),
        ],
      ],
    );
  }
}

class AsyncErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AsyncErrorCard({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 34),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try Again')),
            ],
          ],
        ),
      ),
    );
  }
}

String cleanError(Object error) {
  var text = error.toString();
  text = text.replaceFirst('Exception: ', '');
  if (text.contains('Invalid login credentials')) return 'Email or password is incorrect.';
  if (text.contains('Email not confirmed')) return 'Please confirm your email first.';
  if (text.contains('TODAY_QUIZ_NOT_READY')) return "Today's quiz is being prepared. Try again in a moment.";
  if (text.contains('NO_HINTS')) return 'No hints available.';
  if (text.contains('USER_BANNED')) return 'This account is currently restricted.';
  return text;
}
