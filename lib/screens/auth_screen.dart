import 'package:flutter/material.dart';

import '../services/backend_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _username = TextEditingController();
  bool _signup = false;
  bool _busy = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.length < 6 || (_signup && _username.text.trim().length < 2)) {
      _message('Enter a valid email, a password of at least 6 characters, and a username.');
      return;
    }
    setState(() => _busy = true);
    try {
      if (_signup) {
        final signedIn = await BackendService.instance.signUp(
          username: _username.text,
          email: _email.text,
          password: _password.text,
        );
        if (!signedIn && mounted) {
          _message('Account created. Check your email to confirm it, then log in.');
          setState(() => _signup = false);
        }
      } else {
        await BackendService.instance.signIn(email: _email.text, password: _password.text);
      }
    } catch (e) {
      _message(cleanError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height - 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school_rounded, size: 82, color: AppTheme.blue),
                const SizedBox(height: 12),
                const Text('GK QUIZ', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.navy)),
                const SizedBox(height: 6),
                Text(_signup ? 'Create your Asmat’s World account' : 'Login to continue your daily quiz', style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 30),
                if (_signup) ...[
                  TextField(
                    controller: _username,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  obscureText: _hidePassword,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _hidePassword = !_hidePassword),
                      icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_signup ? 'Create Account' : 'Login'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _busy ? null : () => setState(() => _signup = !_signup),
                  child: Text(_signup ? 'Already have an account? Login' : 'New user? Create account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
