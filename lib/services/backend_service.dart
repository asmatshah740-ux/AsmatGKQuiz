import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/quiz_models.dart';

class BackendService {
  BackendService._();
  static final BackendService instance = BackendService._();

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email.trim(), password: password);
  }

  Future<bool> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'username': username.trim()},
    );
    return response.session != null;
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> ensureDailyQuiz() async {
    Object? lastError;
    for (var attempt = 0; attempt < 4; attempt++) {
      try {
        final response = await _client.functions.invoke('generate-daily-quiz');
        final data = response.data;
        if (data is Map && data['status'] == 'generating') {
          await Future<void>.delayed(Duration(seconds: 2 + attempt));
          continue;
        }
        return;
      } catch (e) {
        lastError = e;
        if (attempt < 3) {
          await Future<void>.delayed(Duration(seconds: 2 + attempt));
        }
      }
    }
    throw Exception('Daily quiz is not ready yet. ${lastError ?? ''}'.trim());
  }

  Future<Map<String, dynamic>> dashboard() async {
    final data = await _client.rpc('get_dashboard');
    return _asMap(data);
  }

  Future<Map<String, dynamic>> checkIn() async {
    final data = await _client.rpc('daily_check_in');
    return _asMap(data);
  }

  Future<QuizSession> startOrResumeQuiz() async {
    final data = await _client.rpc('start_or_resume_quiz');
    return QuizSession.fromMap(_asMap(data));
  }

  Future<AnswerResult> submitAnswer({
    required int questionId,
    required int selectedIndex,
  }) async {
    final data = await _client.rpc(
      'submit_answer',
      params: {
        'p_question_id': questionId,
        'p_selected_index': selectedIndex,
      },
    );
    return AnswerResult.fromMap(_asMap(data));
  }

  Future<Map<String, dynamic>> useHint(int questionId) async {
    final data = await _client.rpc('use_hint', params: {'p_question_id': questionId});
    return _asMap(data);
  }

  Future<int> claimRewardedHint() async {
    final response = await _client.functions.invoke('claim-rewarded-hint');
    final data = _asMap(response.data);
    return ((data['hint_balance'] ?? 0) as num).toInt();
  }

  Future<Map<String, dynamic>> leaderboard(String period) async {
    final data = await _client.rpc('get_leaderboard', params: {'p_period': period});
    return _asMap(data);
  }

  Future<Map<String, dynamic>> stats() async {
    final data = await _client.rpc('get_my_stats');
    return _asMap(data);
  }

  Future<List<String>> checkInHistory() async {
    final data = await _client.rpc('get_checkin_history');
    if (data is List) return data.map((e) => e.toString()).toList(growable: false);
    if (data is Map && data['dates'] is List) {
      return (data['dates'] as List).map((e) => e.toString()).toList(growable: false);
    }
    return const [];
  }

  Future<Map<String, dynamic>> myProfile() async {
    final id = currentUser?.id;
    if (id == null) throw StateError('Not signed in');
    final data = await _client.from('profiles').select().eq('id', id).single();
    return Map<String, dynamic>.from(data);
  }

  Future<void> updateUsername(String username) async {
    await _client.rpc('update_username', params: {'p_username': username.trim()});
  }

  Future<bool> isAdmin() async {
    final profile = await myProfile();
    return profile['role'] == 'admin';
  }

  Future<List<Map<String, dynamic>>> adminTodayQuestions() async {
    final data = await _client.rpc('admin_get_today_questions');
    return _asListOfMaps(data);
  }

  Future<void> adminUpdateQuestion({
    required int id,
    required String question,
    required List<String> options,
    required int correctIndex,
    required String hint,
  }) async {
    await _client.rpc('admin_update_question', params: {
      'p_question_id': id,
      'p_question_text': question.trim(),
      'p_options': options,
      'p_correct_index': correctIndex,
      'p_hint': hint.trim(),
    });
  }

  Future<void> adminRegenerateToday() async {
    await _client.functions.invoke('generate-daily-quiz', body: {'force': true});
  }

  Future<List<Map<String, dynamic>>> adminUsers() async {
    final data = await _client.rpc('admin_list_users');
    return _asListOfMaps(data);
  }

  Future<void> adminSetUserBanned(String userId, bool banned) async {
    await _client.rpc('admin_set_user_banned', params: {
      'p_user_id': userId,
      'p_banned': banned,
    });
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw StateError('Unexpected server response');
  }

  static List<Map<String, dynamic>> _asListOfMaps(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }
}
