import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class ServicesScreen extends StatefulWidget {
  final bool afterSignup;
  const ServicesScreen({super.key, this.afterSignup = false});
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<dynamic> services = [];
  String? error;
  bool loading = true;
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final category = TextEditingController();
  final price = TextEditingController();
  final duration = TextEditingController(text: '60');
  final description = TextEditingController();
  bool saving = false;

  @override
  void initState() { super.initState(); load(); }
  @override
  void dispose() {
    name.dispose(); category.dispose(); price.dispose(); duration.dispose(); description.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final response = await ApiService.instance.getMap('/api/v1/services');
      if (mounted) setState(() => services = (response['services'] as List?) ?? []);
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() { saving = true; error = null; });
    try {
      await ApiService.instance.postJson('/api/v1/services', {
        'name': name.text.trim(), 'category': category.text.trim(),
        'price': double.parse(price.text), 'duration_minutes': int.parse(duration.text),
        'description': description.text.trim(),
      });
      name.clear(); price.clear(); description.clear();
      await load();
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service added to your public booking menu'))); }
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Services'), actions: widget.afterSignup ? [
      TextButton(onPressed: () => Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const HomeScreen())),
        child: const Text('Done')),
    ] : null),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Add each treatment separately with its own price and duration. Use the same category to group options, for example Take Down.',
        style: TextStyle(fontSize: 16)),
      const SizedBox(height: 18),
      Form(key: formKey, child: Column(children: [
        TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Treatment or service name'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a service name' : null),
        const SizedBox(height: 12),
        TextFormField(controller: category, decoration: const InputDecoration(labelText: 'Category', hintText: 'Take Down'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a category' : null),
        const SizedBox(height: 12),
        TextFormField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Price in ₦'),
          validator: (v) => (double.tryParse(v ?? '') ?? -1) >= 0 ? null : 'Enter a valid price'),
        const SizedBox(height: 12),
        TextFormField(controller: duration, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Duration in minutes'),
          validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0 ? null : 'Enter duration in minutes'),
        const SizedBox(height: 12),
        TextFormField(controller: description, maxLines: 3,
          decoration: const InputDecoration(labelText: 'Description (optional)')),
        const SizedBox(height: 16),
        if (error != null) Text(error!, style: const TextStyle(color: Colors.redAccent)),
        SizedBox(width: double.infinity, child: FilledButton(
          onPressed: saving ? null : save, child: Text(saving ? 'Saving…' : 'Add service'))),
      ])),
      const SizedBox(height: 24),
      Text('Your services', style: Theme.of(context).textTheme.titleLarge),
      if (loading) const LinearProgressIndicator(),
      if (!loading && services.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('No services yet. Add your first option above.')),
      for (final item in services)
        Card(child: ListTile(title: Text(item['name']?.toString() ?? ''),
          subtitle: Text('${item['category'] ?? ''} · ₦${item['price'] ?? 0} · ${item['duration_minutes'] ?? 60} min'),
          trailing: Icon(item['active'] == true && item['booking_enabled'] == true
              ? Icons.check_circle : Icons.visibility_off))),
    ])),
  );
}

