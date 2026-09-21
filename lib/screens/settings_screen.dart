import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../widgets/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings? _settings;

  @override
  void initState() {
    super.initState();
    SettingsService.instance.load().then((value) {
      if (mounted) setState(() => _settings = value);
    });
  }

  void _replace({bool? sound, bool? vibration, bool? reminder}) {
    final s = _settings!;
    setState(() {
      _settings = AppSettings(
        sound: sound ?? s.sound,
        vibration: vibration ?? s.vibration,
        reminder: reminder ?? s.reminder,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = _settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: s.sound,
                        secondary: const Icon(Icons.volume_up_rounded, color: AppTheme.blue),
                        title: const Text('Sound', style: TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: const Text('Play light system feedback when answering.'),
                        onChanged: (v) async {
                          _replace(sound: v);
                          await SettingsService.instance.setSound(v);
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: s.vibration,
                        secondary: const Icon(Icons.vibration_rounded, color: AppTheme.blue),
                        title: const Text('Vibration', style: TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: const Text('Use light haptic feedback on answers.'),
                        onChanged: (v) async {
                          _replace(vibration: v);
                          await SettingsService.instance.setVibration(v);
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: s.reminder,
                        secondary: const Icon(Icons.notifications_active_rounded, color: AppTheme.blue),
                        title: const Text('Daily Quiz Reminder', style: TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: const Text('Save your preference for daily quiz reminders.'),
                        onChanged: (v) async {
                          _replace(reminder: v);
                          await SettingsService.instance.setReminder(v);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Reminder preference is stored on this device. Push-notification delivery can be connected later without changing your quiz data.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
    );
  }
}
