import 'package:flutter/material.dart';

import '../services/backend_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'checkin_history_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  Object? _error;

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
      final p = await BackendService.instance.myProfile();
      if (mounted) setState(() => _profile = p);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editUsername() async {
    final controller = TextEditingController(text: (_profile?['username'] ?? '').toString());
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Username'),
        content: TextField(controller: controller, maxLength: 24, decoration: const InputDecoration(labelText: 'Username')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.length < 2) return;
    try {
      await BackendService.instance.updateUsername(value);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cleanError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ListView(padding: const EdgeInsets.all(18), children: [AsyncErrorCard(message: cleanError(_error!), onRetry: _load)])
              : ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const CircleAvatar(radius: 34, backgroundColor: AppTheme.blue, child: Icon(Icons.person_rounded, size: 38, color: Colors.white)),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text((_profile?['username'] ?? 'Player').toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.navy)),
                                  const SizedBox(height: 3),
                                  Text(BackendService.instance.currentUser?.email ?? '', style: const TextStyle(color: Colors.black54)),
                                ],
                              ),
                            ),
                            IconButton(onPressed: _editUsername, icon: const Icon(Icons.edit_rounded)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _tile(Icons.bar_chart_rounded, 'My Stats', 'Points, correct answers, best score and hints', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen()))),
                    _tile(Icons.calendar_month_rounded, 'Check-in History', 'See your recent daily check-ins', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckInHistoryScreen()))),
                    _tile(Icons.settings_rounded, 'Settings', 'Sound, vibration and daily reminder preference', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await BackendService.instance.signOut();
                        if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Logout'),
                    ),
                  ],
                ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(backgroundColor: AppTheme.blue.withValues(alpha: .10), child: Icon(icon, color: AppTheme.blue)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
