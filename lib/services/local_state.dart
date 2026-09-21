import 'package:shared_preferences/shared_preferences.dart';

class LocalState {
  static const _checkInDateKey = 'check_in_date';
  static const _quizCompleteDateKey = 'quiz_complete_date';
  static const _pointsKey = 'total_points';

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static Future<bool> hasCheckedInToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_checkInDateKey) == _todayKey();
  }

  static Future<void> checkIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_checkInDateKey, _todayKey());
  }

  static Future<bool> isQuizCompleteToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_quizCompleteDateKey) == _todayKey();
  }

  static Future<void> markQuizComplete(int earnedPoints) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quizCompleteDateKey, _todayKey());
    await prefs.setInt(_pointsKey, (prefs.getInt(_pointsKey) ?? 0) + earnedPoints);
  }

  static Future<int> totalPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pointsKey) ?? 0;
  }

  static Future<void> resetDemo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_checkInDateKey);
    await prefs.remove(_quizCompleteDateKey);
  }
}
