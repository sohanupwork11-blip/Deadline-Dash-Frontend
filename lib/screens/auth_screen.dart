import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({required this.api, required this.onAuthenticated, super.key});

  final ApiClient api;
  final VoidCallback onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registering = false;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_registering) {
        await widget.api.register(
          username: _username.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await widget.api.signIn(_username.text.trim(), _password.text);
      }
      if (mounted) widget.onAuthenticated();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (wide) const Expanded(flex: 11, child: _WelcomePanel()),
            Expanded(
              flex: wide ? 9 : 1,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 410),
                    child: _form(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form() => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (MediaQuery.sizeOf(context).width < 800) ...[
              const _BrandMark(),
              const SizedBox(height: 40),
            ],
            Text(
              _registering ? 'Create your account' : 'Welcome back',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: ink),
            ),
            const SizedBox(height: 8),
            Text(
              _registering
                  ? 'Set up your workspace and get moving.'
                  : 'Sign in to pick up where your team left off.',
              style: const TextStyle(color: Color(0xFF66736A), fontSize: 15),
            ),
            const SizedBox(height: 28),
            _label('Username'),
            TextFormField(
              controller: _username,
              textInputAction: _registering ? TextInputAction.next : TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              validator: (value) => value == null || value.trim().isEmpty ? 'Enter your username.' : null,
              decoration: const InputDecoration(hintText: 'Your username'),
            ),
            if (_registering) ...[
              const SizedBox(height: 18),
              _label('Email'),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email.' : null,
                decoration: const InputDecoration(hintText: 'you@company.com'),
              ),
            ],
            const SizedBox(height: 18),
            _label('Password'),
            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: [_registering ? AutofillHints.newPassword : AutofillHints.password],
              validator: (value) => value == null || value.length < 8 ? 'Use at least 8 characters.' : null,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'At least 8 characters',
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Color(0xFFB44839))),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: forest,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _busy
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_registering ? 'Create account' : 'Sign in', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 22),
            Center(
              child: TextButton(
                onPressed: _busy ? null : () => setState(() {
                  _registering = !_registering;
                  _error = null;
                }),
                child: Text(_registering ? 'Already have an account? Sign in' : 'New to Deadline Dash? Create an account'),
              ),
            ),
          ],
        ),
      );

  Widget _label(String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(value, style: const TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 13)),
      );
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(44),
        decoration: BoxDecoration(color: forest, borderRadius: BorderRadius.circular(22)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BrandMark(light: true),
            const Spacer(),
            const Icon(Icons.track_changes_rounded, size: 54, color: leaf),
            const SizedBox(height: 28),
            const Text(
              'Make the date.\nMake it count.',
              style: TextStyle(fontSize: 48, height: 1.08, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 18),
            const Text(
              'Bring projects, priorities, and due dates into one clear view.',
              style: TextStyle(color: Color(0xFFD4E0D6), fontSize: 17, height: 1.5),
            ),
            const Spacer(),
            const Row(
              children: [
                _ProofDot(),
                SizedBox(width: 10),
                Text('Less chasing. More finishing.', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ],
        ),
      );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: leaf, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.bolt_rounded, color: forest, size: 22),
          ),
          const SizedBox(width: 10),
          Text(
            'Deadline Dash',
            style: TextStyle(color: light ? Colors.white : ink, fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ],
      );
}

class _ProofDot extends StatelessWidget {
  const _ProofDot();

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(color: leaf, shape: BoxShape.circle),
      );
}