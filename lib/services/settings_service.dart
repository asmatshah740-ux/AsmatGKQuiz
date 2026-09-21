import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final bool sound;
  final bool vibration;
  final bool reminder;

  const AppSettings({required this.sound, required this.vibration, required this.reminder});
}

class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _sound = 'setting_sound';
  static const _vibration = 'setting_vibration';
  static const _reminder = 'setting_reminder';

  Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return AppSettings(
      sound: p.getBool(_sound) ?? true,
      vibration: p.getBool(_vibration) ?? true,
      reminder: p.getBool(_reminder) ?? true,
    );
  }

  Future<void> setSound(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_sound, value);
  Future<void> setVibration(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_vibration, value);
  Future<void> setReminder(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_reminder, value);

  Future<void> answerFeedback() async {
    final s = await load();
    if (s.sound) await SystemSound.play(SystemSoundType.click);
    if (s.vibration) await HapticFeedback.selectionClick();
  }
}
