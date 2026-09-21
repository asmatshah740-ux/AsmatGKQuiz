import 'package:flutter/material.dart';

import '../models/quiz_models.dart';
import '../services/backend_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _periods = const ['daily', 'weekly', 'all_time'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this)..addListener(() {
        if (!_tabs.indexIsChanging) setState(() {});
      });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.gold,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppTheme.gold,
          tabs: const [Tab(text: 'Daily'), Tab(text: 'Weekly'), Tab(text: 'All-Time')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: _periods.map((period) => _LeaderboardList(period: period)).toList(growable: false),
      ),
    );
  }
}

class _LeaderboardList extends StatefulWidget {
  final String period;
  const _LeaderboardList({required this.period});

  @override
  State<_LeaderboardList> createState() => _LeaderboardListState();
}

class _LeaderboardListState extends State<_LeaderboardList> {
  bool _loading = true;
  Object? _error;
  List<LeaderboardEntry> _entries = const [];
  LeaderboardEntry? _me;

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
      final data = await BackendService.instance.leaderboard(widget.period);
      final top = (data['top'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => LeaderboardEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList(growable: false);
      final meRaw = data['me'];
      if (mounted) {
        setState(() {
          _entries = top;
          _me = meRaw is Map ? LeaderboardEntry.fromMap(Map<String, dynamic>.from(meRaw)) : null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ListView(padding: const EdgeInsets.all(18), children: [AsyncErrorCard(message: cleanError(_error!), onRetry: _load)]);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_me != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.navy, Color(0xFF0B4C8C)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const CircleAvatar(backgroundColor: AppTheme.gold, child: Icon(Icons.person_rounded, color: AppTheme.navy)),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Your Rank • #${_me!.rank}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
                  Text('${_me!.points} pts', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (_entries.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('No ranked scores yet.', textAlign: TextAlign.center))),
          for (final entry in _entries)
            Card(
              color: entry.isCurrentUser ? AppTheme.blue.withValues(alpha: .08) : Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: entry.rank <= 3 ? AppTheme.gold.withValues(alpha: .25) : AppTheme.blue.withValues(alpha: .08),
                  child: Text('#${entry.rank}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.navy)),
                ),
                title: Text(entry.username, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${entry.correct} correct'),
                trailing: Text('${entry.points} pts', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.blue)),
              ),
            ),
        ],
      ),
    );
  }
}
