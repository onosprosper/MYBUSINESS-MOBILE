import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'web_dashboard_screen.dart';

class AccountDeletionScreen extends StatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  final password = TextEditingController();
  bool sending = false;
  String? message;
  String? error;

  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (password.text.isEmpty || sending) return;
    setState(() { sending = true; error = null; });
    try {
      final result = await ApiService.instance.postJson(
        '/api/v1/account/deletion-request', {'password': password.text});
      if (mounted) setState(() => message = result['message']?.toString() ??
        'Your deletion request was received.');
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      password.clear();
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Request account deletion')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('You can request deletion of your MYBUSINESS account and associated data. '
        'The team will review your request, including records that may need to be retained '
        'for legal or transaction purposes.'),
      const SizedBox(height: 18),
      if (message != null) Text(message!, style: const TextStyle(color: Colors.greenAccent)),
      if (error != null) Text(error!, style: const TextStyle(color: Colors.redAccent)),
      if (message == null) ...[
        TextField(controller: password, obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: const InputDecoration(labelText: 'Confirm your password')),
        const SizedBox(height: 16),
        FilledButton(onPressed: sending ? null : submit,
          child: Text(sending ? 'Submitting…' : 'Submit deletion request')),
      ],
      const SizedBox(height: 18),
      TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => const WebDashboardScreen(
          title: 'Data deletion information', path: '/data-deletion'))),
        child: const Text('Read how deletion requests are handled')),
    ]),
  );
}
