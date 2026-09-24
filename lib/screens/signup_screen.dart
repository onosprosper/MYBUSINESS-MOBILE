import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'services_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final business = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  String type = 'products';
  bool busy = false;
  String? error;

  @override
  void dispose() {
    name.dispose(); business.dispose(); email.dispose(); password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() { busy = true; error = null; });
    try {
      final response = await ApiService.instance.signup(
        name: name.text.trim(), businessName: business.text.trim(),
        email: email.text.trim(), password: password.text, businessType: type,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
        builder: (_) => response['next_step'] == 'services'
            ? const ServicesScreen(afterSignup: true) : const HomeScreen(),
      ), (_) => false);
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create business account')),
    body: SafeArea(child: Form(key: formKey, child: ListView(
      padding: const EdgeInsets.all(20), children: [
        TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Your name'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your name' : null),
        const SizedBox(height: 16),
        TextFormField(controller: business, decoration: const InputDecoration(labelText: 'Business name'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your business name' : null),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(initialValue: type, decoration: const InputDecoration(labelText: 'What does your business offer?'),
          items: const [DropdownMenuItem(value: 'products', child: Text('Products or general business')),
            DropdownMenuItem(value: 'services', child: Text('Services and appointments')),
            DropdownMenuItem(value: 'both', child: Text('Both products and services'))],
          onChanged: (v) => setState(() => type = v ?? 'products')),
        const SizedBox(height: 16),
        TextFormField(controller: email, keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
          validator: (v) => (v ?? '').contains('@') ? null : 'Enter a valid email'),
        const SizedBox(height: 16),
        TextFormField(controller: password, obscureText: true,
          decoration: const InputDecoration(labelText: 'Password (8 characters minimum)'),
          validator: (v) => (v ?? '').length >= 8 ? null : 'Use at least 8 characters'),
        const SizedBox(height: 16),
        if (error != null) Text(error!, style: const TextStyle(color: Colors.redAccent)),
        FilledButton(onPressed: busy ? null : submit,
          child: Text(busy ? 'Creating account…' : 'Create account')),
      ],
    ))),
  );
}

