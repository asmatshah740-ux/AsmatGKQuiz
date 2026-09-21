import 'package:flutter/material.dart';

import '../app_config.dart';
import '../services/backend_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'admin_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _data;
  Object? _error;
  bool _loading = true;
  bool _checkingIn = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await BackendService.instance.ensureDailyQuiz();
      final data = await BackendService.instance.dashboard();
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkIn() async {
    setState(() => _checkingIn = true);
    try {
      final data = await BackendService.instance.checkIn();
      if (mounted) {
        setState(() => _data = data);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('+1 free hint added for today.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cleanError(e))));
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  Future<void> _openQuiz() async {
    try {
      final session = await BackendService.instance.startOrResumeQuiz();
      if (!mounted) return;
      if (session.isCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Today's 60-question quiz is already completed.")));
        return;
      }
      await Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(initialSession: session)));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cleanError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final username = (data?['username'] ?? 'Player').toString();
    final points = ((data?['total_points'] ?? 0) as num).toInt();
    final hints = ((data?['hint_balance'] ?? 0) as num).toInt();
    final checkedIn = data?['checked_in_today'] == true;
    final status = (data?['attempt_status'] ?? 'not_started').toString();
    final currentPosition = ((data?['current_position'] ?? 1) as num).toInt();
    final isAdmin = data?['role'] == 'admin';

    String quizButton = 'Start Today’s Quiz';
    if (status == 'active' && currentPosition > 1) quizButton = 'Continue Quiz • Q$currentPosition/${AppConfig.questionsPerDay}';
    if (status == 'completed') quizButton = 'Today’s Quiz Completed';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Asmat's World"),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            if (_loading) const LinearProgressIndicator(minHeight: 3),
            if (_error != null) AsyncErrorCard(message: cleanError(_error!), onRetry: _load),
            if (data != null) ...[
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.navy, Color(0xFF0A4D95)]),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hello, $username', style: const TextStyle(color: Colors.white70, fontSize: 15)),
                    const SizedBox(height: 5),
                    const Text('Ready for today’s GK challenge?', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: [
                        MetricChip(icon: Icons.stars_rounded, label: '$points Points', color: AppTheme.gold),
                        MetricChip(icon: Icons.lightbulb_rounded, label: '$hints Hints', color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Daily Check-in', subtitle: 'Check in once a day to receive 1 free hint.'),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: checkedIn || _checkingIn ? null : _checkIn,
                        icon: Icon(checkedIn ? Icons.check_circle : Icons.card_giftcard_rounded),
                        label: Text(checkedIn ? 'Checked In Today • +1 Hint' : 'Check In • Get 1 Free Hint'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Today’s Quiz', subtitle: '60 General Knowledge questions • daily limit 1 quiz'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: LinearProgressIndicator(value: status == 'completed' ? 1 : (currentPosition - 1).clamp(0, 60) / 60, minHeight: 9, borderRadius: BorderRadius.circular(20))),
                          const SizedBox(width: 12),
                          Text(status == 'completed' ? '60/60' : '${(currentPosition - 1).clamp(0, 60)}/60', style: const TextStyle(fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: status == 'completed' ? null : _openQuiz,
                        icon: Icon(status == 'active' && currentPosition > 1 ? Icons.play_arrow_rounded : Icons.quiz_rounded),
                        label: Text(quizButton),
                      ),
                      const SizedBox(height: 8),
                      const Text('Ad opportunity after every 3 answered questions. Extra hints use optional rewarded ads.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _navCard(
                      icon: Icons.emoji_events_rounded,
                      title: 'Leaderboard',
                      subtitle: 'Daily • Weekly • All-Time',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _navCard(
                      icon: Icons.person_rounded,
                      title: 'My Profile',
                      subtitle: 'Stats • History • Settings',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    ),
                  ),
                ],
              ),
              if (isAdmin) ...[
                const SizedBox(height: 14),
                _navCard(
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'Admin Panel',
                  subtitle: 'Questions • Users • Anti-cheat controls',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _navCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.blue, size: 32),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.navy)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
