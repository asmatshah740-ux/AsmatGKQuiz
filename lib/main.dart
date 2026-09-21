import 'package:flutter/material.dart';
import 'data/questions.dart';
import 'services/local_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AsmatQuizApp());
}

class AsmatQuizApp extends StatelessWidget {
  const AsmatQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF071B3D);
    const blue = Color(0xFF0B73FF);
    const gold = Color(0xFFFFC928);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Asmat's World - GK Quiz",
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: blue, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF6F9FF),
        appBarTheme: const AppBarTheme(backgroundColor: navy, foregroundColor: Colors.white, centerTitle: true),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
        cardTheme: CardThemeData(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
      ),
      home: const SplashScreen(navy: navy, gold: gold),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final Color navy;
  final Color gold;
  const SplashScreen({super.key, required this.navy, required this.gold});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [widget.navy, const Color(0xFF0A3A73)]),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Welcome To', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text("Asmat's World", style: TextStyle(color: widget.gold, fontSize: 38, fontWeight: FontWeight.w900)),
              const SizedBox(height: 42),
              Container(
                width: 124,
                height: 124,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .08), border: Border.all(color: widget.gold, width: 2)),
                child: Icon(Icons.lightbulb_rounded, size: 76, color: widget.gold),
              ),
              const SizedBox(height: 24),
              const Text('GK QUIZ', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const Text('Think • Learn • Grow', style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 50),
              const SizedBox(width: 170, child: LinearProgressIndicator(minHeight: 7, borderRadius: BorderRadius.all(Radius.circular(20)))),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school_rounded, size: 82, color: Color(0xFF0B73FF)),
              const SizedBox(height: 12),
              const Text('GK QUIZ', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF071B3D))),
              const SizedBox(height: 8),
              const Text('Login to continue your quiz journey', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 32),
              TextField(decoration: _field('Email or Username', Icons.person_outline)),
              const SizedBox(height: 14),
              TextField(obscureText: true, decoration: _field('Password', Icons.lock_outline)),
              const SizedBox(height: 22),
              FilledButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())), child: const Text('Login')),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
                child: const Text('Continue as Demo User'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static InputDecoration _field(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool checkedIn = false;
  bool complete = false;
  int points = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    checkedIn = await LocalState.hasCheckedInToday();
    complete = await LocalState.isQuizCompleteToday();
    points = await LocalState.totalPoints();
    if (mounted) setState(() {});
  }

  Future<void> _checkIn() async {
    if (checkedIn) return;
    await LocalState.checkIn();
    setState(() => checkedIn = true);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Daily check-in complete: 1 free hint unlocked!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Asmat's World"),
        actions: [Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Text('⭐ $points', style: const TextStyle(fontWeight: FontWeight.w800))))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0B73FF), Color(0xFF0747A6)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Text('A', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
                  SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Hello, Asmat!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)), Text('Ready for today’s GK challenge?', style: TextStyle(color: Colors.white70))])),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFFE9FFF1),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [Icon(Icons.calendar_month_rounded, color: Colors.green), SizedBox(width: 8), Text('Daily GK Quiz', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))]),
                  const SizedBox(height: 8),
                  const Text('60 new General Knowledge questions every day'),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: complete ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompletedScreen())) : () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(hasFreeHint: checkedIn))).then((_) => _load()),
                    child: Text(complete ? 'Today’s Quiz Completed' : 'Start Quiz'),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _menuCard(Icons.card_giftcard_rounded, checkedIn ? 'Checked In' : 'Daily Check-in', checkedIn ? Colors.green : Colors.orange, _checkIn)),
              const SizedBox(width: 12),
              Expanded(child: _menuCard(Icons.emoji_events_rounded, 'Leaderboard', Colors.amber.shade700, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _menuCard(Icons.person_rounded, 'My Profile', Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(points: points))))),
              const SizedBox(width: 12),
              Expanded(child: _menuCard(Icons.refresh_rounded, 'Reset Demo', Colors.redAccent, () async { await LocalState.resetDemo(); await _load(); })),
            ]),
            const SizedBox(height: 20),
            const Card(
              color: Color(0xFFFFF8DF),
              child: const Padding(padding: EdgeInsets.all(22), child: Row(children: [Icon(Icons.auto_awesome, color: Color(0xFFFFA000)), SizedBox(width: 14), Expanded(child: Text('Knowledge is power. Come back daily for a fresh 60-question challenge!', style: TextStyle(fontWeight: FontWeight.w700)))])),
            )
          ],
        ),
      ),
    );
  }

  Widget _menuCard(IconData icon, String label, Color color, VoidCallback onTap) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 10), child: Column(children: [Icon(icon, color: color, size: 34), const SizedBox(height: 8), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))]))),
      );
}

class QuizScreen extends StatefulWidget {
  final bool hasFreeHint;
  const QuizScreen({super.key, required this.hasFreeHint});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int index = 0;
  int correct = 0;
  int? selected;
  bool answered = false;
  bool hintVisible = false;
  late bool freeHintAvailable;

  @override
  void initState() {
    super.initState();
    freeHintAvailable = widget.hasFreeHint;
  }

  void _select(int choice) {
    if (answered) return;
    setState(() {
      selected = choice;
      answered = true;
      if (choice == demoQuestions[index].correctIndex) correct++;
    });
  }

  Future<void> _next() async {
    if (!answered) return;
    final numberCompleted = index + 1;
    if (numberCompleted % 3 == 0) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => AdBreakScreen(adNumber: numberCompleted ~/ 3)));
    }
    if (index == demoQuestions.length - 1) {
      final points = correct * 10;
      await LocalState.markQuizComplete(points);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResultScreen(correct: correct, total: demoQuestions.length, points: points)));
      return;
    }
    setState(() {
      index++;
      selected = null;
      answered = false;
      hintVisible = false;
    });
  }

  Future<void> _hint() async {
    if (hintVisible) return;
    if (freeHintAvailable) {
      setState(() {
        freeHintAvailable = false;
        hintVisible = true;
      });
      return;
    }
    final watched = await showModalBottomSheet<bool>(
          context: context,
          showDragHandle: true,
          builder: (_) => Padding(
            padding: const EdgeInsets.all(22),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lightbulb_rounded, size: 54, color: Colors.amber),
              const SizedBox(height: 10),
              const Text('Need a hint?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Your free daily hint is used. Watch a rewarded ad to unlock this hint.', textAlign: TextAlign.center),
              const SizedBox(height: 18),
              FilledButton.icon(onPressed: () => Navigator.pop(context, true), icon: const Icon(Icons.play_circle_fill_rounded), label: const Text('Simulate Rewarded Ad')),
            ]),
          ),
        ) ??
        false;
    if (watched) setState(() => hintVisible = true);
  }

  @override
  Widget build(BuildContext context) {
    final q = demoQuestions[index];
    return Scaffold(
      appBar: AppBar(title: Text('Question ${index + 1} of ${demoQuestions.length}')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(children: [Expanded(child: LinearProgressIndicator(value: (index + 1) / demoQuestions.length, minHeight: 10, borderRadius: BorderRadius.circular(10))), const SizedBox(width: 14), Text('⭐ ${correct * 10}', style: const TextStyle(fontWeight: FontWeight.w900))]),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: const Color(0xFFE8F0FF), borderRadius: BorderRadius.circular(30)), child: const Text('General Knowledge', style: TextStyle(color: Color(0xFF0B73FF), fontWeight: FontWeight.w800))),
                const SizedBox(height: 18),
                Text(q.text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 25, height: 1.25, fontWeight: FontWeight.w900)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(4, (i) => _option(i, q.options[i], q.correctIndex)),
          if (hintVisible) ...[
            const SizedBox(height: 8),
            Card(color: const Color(0xFFFFF7D6), child: Padding(padding: const EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.lightbulb_rounded, color: Colors.amber), const SizedBox(width: 10), Expanded(child: Text(q.hint, style: const TextStyle(fontWeight: FontWeight.w700)))]))),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: _hint, icon: const Icon(Icons.lightbulb_outline), label: Text(freeHintAvailable ? 'Free Hint' : 'Get Hint'))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(onPressed: answered ? _next : null, child: Text(index == demoQuestions.length - 1 ? 'Finish' : 'Next'))),
          ]),
        ],
      ),
    );
  }

  Widget _option(int i, String text, int correctIndex) {
    Color? color;
    Color border = const Color(0xFFDDE5F2);
    if (answered) {
      if (i == correctIndex) {
        color = const Color(0xFFDDF8E7);
        border = Colors.green;
      } else if (i == selected) {
        color = const Color(0xFFFFE3E3);
        border = Colors.red;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _select(i),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: color ?? Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border, width: 1.4)),
          child: Row(children: [CircleAvatar(radius: 17, backgroundColor: const Color(0xFF1B3D6D), child: Text(String.fromCharCode(65 + i), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))), const SizedBox(width: 12), Expanded(child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))]),
        ),
      ),
    );
  }
}

class AdBreakScreen extends StatefulWidget {
  final int adNumber;
  const AdBreakScreen({super.key, required this.adNumber});

  @override
  State<AdBreakScreen> createState() => _AdBreakScreenState();
}

class _AdBreakScreenState extends State<AdBreakScreen> {
  int seconds = 2;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  Future<void> _tick() async {
    while (seconds > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => seconds--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.movie_filter_rounded, size: 100, color: Color(0xFF0B73FF)),
            const SizedBox(height: 18),
            Text('Ad Break ${widget.adNumber}/20', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Demo placeholder for a real interstitial ad.', textAlign: TextAlign.center),
            const SizedBox(height: 26),
            FilledButton(onPressed: seconds == 0 ? () => Navigator.pop(context) : null, child: Text(seconds == 0 ? 'Continue Quiz' : 'Continue in $seconds')),
          ]),
        ),
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final int correct;
  final int total;
  final int points;
  const ResultScreen({super.key, required this.correct, required this.total, required this.points});

  @override
  Widget build(BuildContext context) {
    final wrong = total - correct;
    final percent = (correct / total * 100).round();
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Completed')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Icon(Icons.emoji_events_rounded, size: 100, color: Colors.amber),
        const SizedBox(height: 10),
        const Text('Great Job!', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [Text('$correct / $total', style: const TextStyle(fontSize: 42, color: Color(0xFF0B73FF), fontWeight: FontWeight.w900)), Text('$percent%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 20), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_stat(Icons.check_circle, '$correct', 'Correct', Colors.green), _stat(Icons.cancel, '$wrong', 'Wrong', Colors.red), _stat(Icons.star, '$points', 'Points', Colors.amber)])]))),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())), child: const Text('View Leaderboard')),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false), child: const Text('Back to Home')),
      ]),
    );
  }

  static Widget _stat(IconData icon, String value, String label, Color color) => Column(children: [Icon(icon, color: color), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text(label)]);
}

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const users = [('Ahmed K.', 580), ('Ayesha R.', 560), ('Bilal S.', 540), ('Sara M.', 520), ('Usman A.', 500), ('Hira N.', 480), ('Zain F.', 460)];
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        SegmentedButton<String>(segments: const [ButtonSegment(value: 'Daily', label: Text('Daily')), ButtonSegment(value: 'Weekly', label: Text('Weekly')), ButtonSegment(value: 'All Time', label: Text('All Time'))], selected: const {'Daily'}, onSelectionChanged: (_) {}),
        const SizedBox(height: 16),
        ...List.generate(users.length, (i) => Card(child: ListTile(leading: CircleAvatar(backgroundColor: i < 3 ? Colors.amber.shade100 : Colors.blue.shade50, child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w900))), title: Text(users[i].$1, style: const TextStyle(fontWeight: FontWeight.w800)), trailing: Text('${users[i].$2}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))))),
        const Card(color: Color(0xFFE8F2FF), child: ListTile(leading: CircleAvatar(child: Text('15')), title: Text('You', style: TextStyle(fontWeight: FontWeight.w900)), trailing: Text('—', style: TextStyle(fontWeight: FontWeight.w900)))),
      ]),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final int points;
  const ProfileScreen({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        const CircleAvatar(radius: 48, child: Text('A', style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold))),
        const SizedBox(height: 12),
        const Text('Asmat', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        Text('$points total points', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 20),
        const Card(child: Column(children: [ListTile(leading: Icon(Icons.bar_chart_rounded), title: Text('My Stats'), trailing: Icon(Icons.chevron_right)), Divider(height: 1), ListTile(leading: Icon(Icons.calendar_today_rounded), title: Text('Check-in History'), trailing: Icon(Icons.chevron_right)), Divider(height: 1), ListTile(leading: Icon(Icons.settings_rounded), title: Text('Settings'), trailing: Icon(Icons.chevron_right))])),
      ]),
    );
  }
}

class CompletedScreen extends StatelessWidget {
  const CompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Limit')),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.event_available_rounded, size: 100, color: Color(0xFF0B73FF)),
          const SizedBox(height: 20),
          const Text('Today’s Quiz Completed!', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          const Text('You have finished all 60 questions for today. Come back tomorrow for a fresh set of GK questions.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, height: 1.5)),
          const SizedBox(height: 26),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Home')),
        ]),
      ),
    );
  }
}
