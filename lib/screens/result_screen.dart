import 'package:flutter/material.dart';

import '../app_config.dart';
import '../services/backend_service.dart';
import '../widgets/app_theme.dart';
import 'leaderboard_screen.dart';

class ResultScreen extends StatefulWidget {
  final int correct;
  final int wrong;
  final int pointsEarned;
  final bool flagged;

  const ResultScreen({
    super.key,
    required this.correct,
    required this.wrong,
    required this.pointsEarned,
    required this.flagged,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int? _rank;

  @override
  void initState() {
    super.initState();
    _loadRank();
  }

  Future<void> _loadRank() async {
    try {
      final data = await BackendService.instance.leaderboard('daily');
      final me = data['me'];
      if (me is Map && mounted) setState(() => _rank = ((me['rank'] ?? 0) as num).toInt());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final percentage = widget.correct / AppConfig.questionsPerDay * 100;
    return Scaffold(
      appBar: AppBar(title: const Text('Today’s Result'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 10),
          const Icon(Icons.emoji_events_rounded, size: 92, color: AppTheme.gold),
          const SizedBox(height: 12),
          const Text('Daily Quiz Completed!', textAlign: TextAlign.center, style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: AppTheme.navy)),
          const SizedBox(height: 8),
          Text('${percentage.toStringAsFixed(1)}%', textAlign: TextAlign.center, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: AppTheme.blue)),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Wrap(
                alignment: WrapAlignment.spaceAround,
                runSpacing: 16,
                children: [
                  _metric('Correct', '${widget.correct}', Colors.green),
                  _metric('Wrong', '${widget.wrong}', Colors.redAccent),
                  _metric('Points', '${widget.pointsEarned}', AppTheme.gold),
                  _metric('Daily Rank', _rank == null || _rank == 0 ? '—' : '#$_rank', AppTheme.blue),
                ],
              ),
            ),
          ),
          if (widget.flagged) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: .12), borderRadius: BorderRadius.circular(16)),
              child: const Text('This attempt was automatically flagged for review by the anti-cheat system, so it may be excluded from rankings until reviewed.', textAlign: TextAlign.center),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
            icon: const Icon(Icons.emoji_events_rounded),
            label: const Text('View Leaderboard'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            icon: const Icon(Icons.home_rounded),
            label: const Text('Back to Home'),
          ),
          const SizedBox(height: 10),
          const Text('Daily limit reached • New 60-question GK quiz unlocks on the next app day.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return SizedBox(
      width: 125,
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
