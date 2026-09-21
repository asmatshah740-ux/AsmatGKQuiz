import 'package:flutter/material.dart';

import '../services/backend_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _stats;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await BackendService.instance.stats();
      if (mounted) setState(() => _stats = data);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  int _v(String key) => ((_stats?[key] ?? 0) as num).toInt();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Stats')),
      body: _stats == null && _error == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ListView(padding: const EdgeInsets.all(18), children: [AsyncErrorCard(message: cleanError(_error!), onRetry: _load)])
              : ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    const SectionTitle('Your Quiz Performance'),
                    const SizedBox(height: 14),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.25,
                      children: [
                        _card(Icons.stars_rounded, 'Total Points', '${_v('total_points')}', AppTheme.gold),
                        _card(Icons.quiz_rounded, 'Quizzes', '${_v('quizzes_completed')}', AppTheme.blue),
                        _card(Icons.check_circle_rounded, 'Correct', '${_v('total_correct')}', Colors.green),
                        _card(Icons.cancel_rounded, 'Wrong', '${_v('total_wrong')}', Colors.redAccent),
                        _card(Icons.workspace_premium_rounded, 'Best Score', '${_v('best_score')}/60', Colors.purple),
                        _card(Icons.lightbulb_rounded, 'Hints Available', '${_v('hint_balance')}', Colors.orange),
                      ],
                    ),
                  ],
                ),
    );
  }

  Widget _card(IconData icon, String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 7),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 3),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
