import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'api.dart';

void main() {
  runApp(const ZkLoginApp());
}

class ZkLoginApp extends StatelessWidget {
  const ZkLoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZK Login',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo)),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final baseUrlCtrl = TextEditingController(text: '');
  late ApiClient api = ApiClient('');
  String? token;
  String? status;

  @override
  void initState() {
    super.initState();
    // Default backend URL: allow override via --dart-define=BACKEND_URL, else choose per platform.
    final envUrl = const String.fromEnvironment('BACKEND_URL');
    final defaultUrl = envUrl.isNotEmpty
        ? envUrl
        : (Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000');
    baseUrlCtrl.text = defaultUrl;
    api = ApiClient(defaultUrl);
    baseUrlCtrl.addListener(() => setState(() => api.baseUrl = baseUrlCtrl.text));
  }

  @override
  void dispose() {
    baseUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ZK Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: baseUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'Backend URL',
                helperText: 'Android emulator: http://10.0.2.2:3000 • iOS sim: http://localhost:3000 • Real device: http://<your-computer-LAN-IP>:3000',
              ),
            ),
            const SizedBox(height: 12),
            if (status != null) Text(status!, style: const TextStyle(color: Colors.teal)),
            if (token != null)
              SelectableText('JWT: $token', style: const TextStyle(fontSize: 12)),
            const Divider(height: 24),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: const [
                    TabBar(tabs: [Tab(text: 'Register'), Tab(text: 'Login')]),
                    Expanded(child: TabBarView(children: [RegisterForm(), LoginForm()])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});
  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _salt = TextEditingController();

  String _generatedCommitment = '';

  @override
  Widget build(BuildContext context) {
    final api = (context.findAncestorStateOfType<_HomeScreenState>()!).api;
    final setStatus = (String s) => context.findAncestorStateOfType<_HomeScreenState>()!.setState(() { context.findAncestorStateOfType<_HomeScreenState>()!.status = s; });
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(controller: _username, decoration: const InputDecoration(labelText: 'Username')),
          TextField(
            controller: _password,
            decoration: const InputDecoration(labelText: 'Password (numeric for demo)') ,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          TextField(
            controller: _salt,
            decoration: const InputDecoration(labelText: 'Salt (decimal, optional)'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 8),
          Row(children: [
            FilledButton.tonal(
              onPressed: () async {
                // generate a random 128-bit salt
                final rnd = (DateTime.now().microsecondsSinceEpoch ^ _username.text.hashCode) & 0xFFFFFFFF;
                // simple pseudo-random; for production use secure random
                final salt = (BigInt.from(rnd) << 96) | BigInt.from(rnd) | (BigInt.from(rnd) << 32);
                _salt.text = salt.toString();
                setState(() {});
              },
              child: const Text('Generate salt'),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(
              onPressed: () async {
                try {
                  final salt = _salt.text.trim();
                  if (salt.isEmpty) return;
                  final password = _password.text.trim();
                  final commitment = await api.commitment(password: password, salt: salt);
                  _generatedCommitment = commitment;
                  setStatus('Computed commitment');
                  setState(() {});
                } catch (e) {
                  setStatus('Commitment error: $e');
                }
              },
              child: const Text('Compute commitment'),
            ),
          ]),
          if (_generatedCommitment.isNotEmpty) SelectableText('Commitment: $_generatedCommitment', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              try {
                final commitment = _generatedCommitment.isNotEmpty ? _generatedCommitment : await api.commitment(password: _password.text.trim(), salt: _salt.text.trim());
                await api.register(username: _username.text.trim(), commitment: commitment, salt: _salt.text.trim().isEmpty ? null : _salt.text.trim());
                setStatus('Registered ${_username.text.trim()}');
              } catch (e) {
                setStatus('Register error: $e');
              }
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final home = context.findAncestorStateOfType<_HomeScreenState>()!;
    final api = home.api;
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(controller: _username, decoration: const InputDecoration(labelText: 'Username')),
          TextField(
            controller: _password,
            decoration: const InputDecoration(labelText: 'Password (numeric for demo)'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              try {
                // Request nonce (to ensure one exists) then login; pass salt returned by nonce if provided
                final n = await api.nonce(username: _username.text.trim());
                final salt = (n['salt'] as String?) ?? '';
                final res = await api.login(username: _username.text.trim(), password: _password.text.trim(), salt: salt);
                home.setState(() { home.token = res['token'] as String?; home.status = 'Login OK'; });
              } catch (e) {
                home.setState(() { home.status = 'Login error: $e'; });
              }
            },
            child: const Text('Login (server-assisted)'),
          ),
        ],
      ),
    );
  }
}
