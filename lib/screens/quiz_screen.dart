import 'package:flutter/material.dart';

import '../app_config.dart';
import '../models/quiz_models.dart';
import '../services/ad_service.dart';
import '../services/backend_service.dart';
import '../services/settings_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final QuizSession initialSession;

  const QuizScreen({super.key, required this.initialSession});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late int _position;
  late int _correct;
  late int _wrong;
  late int _points;
  int _hints = 0;
  bool _busy = false;
  int? _selectedIndex;
  int? _correctIndex;
  String? _hint;

  @override
  void initState() {
    super.initState();
    _position = widget.initialSession.currentPosition.clamp(1, AppConfig.questionsPerDay).toInt();
    _correct = widget.initialSession.correctCount;
    _wrong = widget.initialSession.wrongCount;
    _points = widget.initialSession.pointsEarned;
    _refreshHints();
  }

  QuizQuestion get _question => widget.initialSession.questions[_position - 1];

  Future<void> _refreshHints() async {
    try {
      final dashboard = await BackendService.instance.dashboard();
      if (mounted) setState(() => _hints = ((dashboard['hint_balance'] ?? 0) as num).toInt());
    } catch (_) {}
  }

  Future<void> _requestHint() async {
    if (_busy || _hint != null) return;
    setState(() => _busy = true);
    try {
      final data = await BackendService.instance.useHint(_question.id);
      if (mounted) {
        setState(() {
          _hint = (data['hint'] ?? '').toString();
          _hints = ((data['hint_balance'] ?? _hints) as num).toInt();
        });
      }
    } catch (e) {
      if (cleanError(e) == 'No hints available.') {
        if (mounted) await _offerRewardedHint();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cleanError(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _offerRewardedHint() async {
    final watch = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Need a hint?'),
            content: const Text('Your free hints are finished. Watch an optional rewarded ad to unlock 1 hint.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not Now')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Watch Ad')),
            ],
          ),
        ) ??
        false;
    if (!watch) return;

    final earned = await AdService.instance.showRewarded();
    if (!mounted) return;
    if (!earned) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rewarded ad is not available right now.')));
      return;
    }

    try {
      _hints = await BackendService.instance.claimRewardedHint();
      final data = await BackendService.instance.useHint(_question.id);
      if (mounted) {
        setState(() {
          _hint = (data['hint'] ?? '').toString();
          _hints = ((data['hint_balance'] ?? _hints) as num).toInt();
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cleanError(e))));
    }
  }

  Future<void> _answer(int selected) async {
    if (_busy || _selectedIndex != null) return;
    setState(() => _busy = true);
    try {
      final result = await BackendService.instance.submitAnswer(
        questionId: _question.id,
        selectedIndex: selected,
      );
      await SettingsService.instance.answerFeedback();
      if (!mounted) return;
      setState(() {
        _selectedIndex = selected;
        _correctIndex = result.correctIndex;
        _correct = result.correctCount;
        _wrong = result.wrongCount;
        _points = result.pointsEarned;
      });

      await Future<void>.delayed(const Duration(milliseconds: 850));
      final answeredPosition = _position;
      if (answeredPosition % AppConfig.questionsPerInterstitial == 0) {
        await AdService.instance.showInterstitial();
      }
      if (!mounted) return;

      if (result.completed) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              correct: result.correctCount,
              wrong: result.wrongCount,
              pointsEarned: result.pointsEarned,
              flagged: result.flagged,
            ),
          ),
        );
        return;
      }

      setState(() {
        _position = result.nextPosition;
        _selectedIndex = null;
        _correctIndex = null;
        _hint = null;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cleanError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Color? _optionColor(int index) {
    if (_selectedIndex == null) return null;
    if (index == _correctIndex) return Colors.green.withValues(alpha: .14);
    if (index == _selectedIndex) return Colors.red.withValues(alpha: .12);
    return null;
  }

  Color _optionBorder(int index) {
    if (_selectedIndex == null) return Colors.black12;
    if (index == _correctIndex) return Colors.green;
    if (index == _selectedIndex) return Colors.redAccent;
    return Colors.black12;
  }

  @override
  Widget build(BuildContext context) {
    final q = _question;
    final progress = _position / AppConfig.questionsPerDay;
    return Scaffold(
      appBar: AppBar(
        title: Text('Question $_position / ${AppConfig.questionsPerDay}'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              children: [
                Expanded(child: LinearProgressIndicator(value: progress, minHeight: 9, borderRadius: BorderRadius.circular(20))),
                const SizedBox(width: 12),
                Text('${(progress * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MetricChip(icon: Icons.check_circle_rounded, label: '$_correct Correct', color: Colors.green),
                MetricChip(icon: Icons.stars_rounded, label: '$_points Points', color: AppTheme.gold),
                MetricChip(icon: Icons.lightbulb_rounded, label: '$_hints Hints', color: AppTheme.blue),
              ],
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(q.question, style: const TextStyle(fontSize: 22, height: 1.35, fontWeight: FontWeight.w900, color: AppTheme.navy)),
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < q.options.length; i++) ...[
              Material(
                color: _optionColor(i) ?? Colors.white,
                borderRadius: BorderRadius.circular(17),
                child: InkWell(
                  borderRadius: BorderRadius.circular(17),
                  onTap: _busy ? null : () => _answer(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
                    decoration: BoxDecoration(
                      border: Border.all(color: _optionBorder(i), width: _selectedIndex == null ? 1 : 1.5),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: AppTheme.blue.withValues(alpha: .10),
                          child: Text(String.fromCharCode(65 + i), style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.blue)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(q.options[i], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (_hint != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppTheme.gold.withValues(alpha: .15), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: Color(0xFFC38F00)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_hint!, style: const TextStyle(fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy || _hint != null ? null : _requestHint,
              icon: const Icon(Icons.lightbulb_outline_rounded),
              label: Text(_hint != null ? 'Hint Unlocked' : _hints > 0 ? 'Use Hint • $_hints Available' : 'Get Hint • Watch Rewarded Ad'),
            ),
            const SizedBox(height: 8),
            const Text('Your progress is saved online after every answer. You can go back and continue later.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}
