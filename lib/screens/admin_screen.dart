import 'package:flutter/material.dart';

import '../services/backend_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _checking = true;
  bool _allowed = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _check();
  }

  Future<void> _check() async {
    try {
      final ok = await BackendService.instance.isAdmin();
      if (mounted) setState(() => _allowed = ok);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_allowed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Panel')),
        body: const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Admin access required.'))),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.gold,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppTheme.gold,
          tabs: const [Tab(text: 'Questions'), Tab(text: 'Users')],
        ),
      ),
      body: TabBarView(controller: _tabs, children: const [_AdminQuestions(), _AdminUsers()]),
    );
  }
}

class _AdminQuestions extends StatefulWidget {
  const _AdminQuestions();

  @override
  State<_AdminQuestions> createState() => _AdminQuestionsState();
}

class _AdminQuestionsState extends State<_AdminQuestions> {
  List<Map<String, dynamic>>? _items;
  Object? _error;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await BackendService.instance.adminTodayQuestions();
      if (mounted) setState(() {
        _items = data;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _regenerate() async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Regenerate Today’s Quiz?'),
            content: const Text('This replaces today’s AI-generated question set. Do this before users start answering.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Regenerate')),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    setState(() => _working = true);
    try {
      await BackendService.instance.adminRegenerateToday();
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Today’s quiz regenerated.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cleanError(e))));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _edit(Map<String, dynamic> item) async {
    final question = TextEditingController(text: (item['question_text'] ?? '').toString());
    final hint = TextEditingController(text: (item['hint'] ?? '').toString());
    final rawOptions = (item['options'] as List? ?? const []).map((e) => e.toString()).toList();
    while (rawOptions.length < 4) rawOptions.add('');
    final optionControllers = List.generate(4, (i) => TextEditingController(text: rawOptions[i]));
    var correct = ((item['correct_index'] ?? 0) as num).toInt().clamp(0, 3).toInt();

    final save = await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: Text('Edit Q${item['position']}'),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(controller: question, maxLines: 3, decoration: const InputDecoration(labelText: 'Question')),
                      const SizedBox(height: 10),
                      for (var i = 0; i < 4; i++) ...[
                        TextField(controller: optionControllers[i], decoration: InputDecoration(labelText: 'Option ${String.fromCharCode(65 + i)}')),
                        const SizedBox(height: 8),
                      ],
                      DropdownButtonFormField<int>(
                        initialValue: correct,
                        decoration: const InputDecoration(labelText: 'Correct Option'),
                        items: List.generate(4, (i) => DropdownMenuItem(value: i, child: Text('Option ${String.fromCharCode(65 + i)}'))),
                        onChanged: (v) => setDialogState(() => correct = v ?? 0),
                      ),
                      const SizedBox(height: 10),
                      TextField(controller: hint, maxLines: 2, decoration: const InputDecoration(labelText: 'Hint')),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
              ],
            ),
          ),
        ) ??
        false;

    if (save) {
      try {
        await BackendService.instance.adminUpdateQuestion(
          id: (item['id'] as num).toInt(),
          question: question.text,
          options: optionControllers.map((e) => e.text.trim()).toList(growable: false),
          correctIndex: correct,
          hint: hint.text,
        );
        await _load();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cleanError(e))));
      }
    }
    question.dispose();
    hint.dispose();
    for (final c in optionControllers) c.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_items == null && _error == null) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ListView(padding: const EdgeInsets.all(18), children: [AsyncErrorCard(message: cleanError(_error!), onRetry: _load)]);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          FilledButton.icon(
            onPressed: _working ? null : _regenerate,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(_working ? 'Generating…' : 'Regenerate Today’s 60 GK Questions with AI'),
          ),
          const SizedBox(height: 12),
          Text('${_items!.length} questions loaded', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          for (final q in _items!)
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${q['position']}')),
                title: Text((q['question_text'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('Correct: ${String.fromCharCode(65 + ((q['correct_index'] ?? 0) as num).toInt())}'),
                trailing: IconButton(onPressed: () => _edit(q), icon: const Icon(Icons.edit_rounded)),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdminUsers extends StatefulWidget {
  const _AdminUsers();

  @override
  State<_AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<_AdminUsers> {
  List<Map<String, dynamic>>? _items;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await BackendService.instance.adminUsers();
      if (mounted) setState(() {
        _items = data;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _toggle(Map<String, dynamic> user) async {
    final banned = user['is_banned'] == true;
    try {
      await BackendService.instance.adminSetUserBanned(user['id'].toString(), !banned);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cleanError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items == null && _error == null) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ListView(padding: const EdgeInsets.all(18), children: [AsyncErrorCard(message: cleanError(_error!), onRetry: _load)]);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text('Flagged attempts are automatically excluded from leaderboards. You can restrict suspicious accounts here.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          for (final u in _items!)
            Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: (u['is_banned'] == true) ? Colors.red.withValues(alpha: .14) : AppTheme.blue.withValues(alpha: .10), child: Icon(Icons.person_rounded, color: (u['is_banned'] == true) ? Colors.red : AppTheme.blue)),
                title: Text((u['username'] ?? 'Player').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${u['total_points'] ?? 0} pts • flagged attempts: ${u['flagged_attempts'] ?? 0}'),
                trailing: TextButton(onPressed: () => _toggle(u), child: Text(u['is_banned'] == true ? 'Unban' : 'Ban')),
              ),
            ),
        ],
      ),
    );
  }
}
