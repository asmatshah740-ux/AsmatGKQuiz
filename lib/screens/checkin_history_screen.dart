import 'package:flutter/material.dart';

import '../services/backend_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';

class CheckInHistoryScreen extends StatefulWidget {
  const CheckInHistoryScreen({super.key});

  @override
  State<CheckInHistoryScreen> createState() => _CheckInHistoryScreenState();
}

class _CheckInHistoryScreenState extends State<CheckInHistoryScreen> {
  List<String>? _dates;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dates = await BackendService.instance.checkInHistory();
      if (mounted) setState(() => _dates = dates);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in History')),
      body: _dates == null && _error == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ListView(padding: const EdgeInsets.all(18), children: [AsyncErrorCard(message: cleanError(_error!), onRetry: _load)])
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_dates!.isEmpty)
                        const Card(child: Padding(padding: EdgeInsets.all(22), child: Text('No check-ins yet.', textAlign: TextAlign.center))),
                      for (var i = 0; i < _dates!.length; i++)
                        Card(
                          child: ListTile(
                            leading: const CircleAvatar(backgroundColor: AppTheme.gold, child: Icon(Icons.check_rounded, color: AppTheme.navy)),
                            title: Text(_dates![i], style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: const Text('Daily check-in reward'),
                            trailing: const Text('+1 Hint', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.blue)),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
