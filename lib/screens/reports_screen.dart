import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic>? data;
  String period = 'monthly';
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => error = null);
    try {
      final d = await ApiService.instance.getMap('/api/v1/reports/summary?period=$period');
      if (mounted) setState(() => data = d);
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  String money(dynamic value) {
    final n = num.tryParse('${value ?? 0}') ?? 0;
    return '₦${n.toStringAsFixed(0)}';
  }

  dynamic pick(Map<String, dynamic> d, List<String> keys) {
    for (final key in keys) {
      if (d.containsKey(key)) return d[key];
    }
    final summary = d['summary'];
    if (summary is Map<String, dynamic>) {
      for (final key in keys) {
        if (summary.containsKey(key)) return summary[key];
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final d = data ?? {};
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'daily', label: Text('Daily')),
                ButtonSegment(value: 'weekly', label: Text('Weekly')),
                ButtonSegment(value: 'monthly', label: Text('Monthly')),
              ],
              selected: {period},
              onSelectionChanged: (value) {
                setState(() => period = value.first);
                load();
              },
            ),
            const SizedBox(height: 14),
            if (error != null) Text(error!, style: const TextStyle(color: Colors.redAccent)),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                _card('Revenue', money(pick(d, ['revenue', 'total_revenue']))),
                _card('Gross Profit', money(pick(d, ['gross_profit']))),
                _card('Expenses', money(pick(d, ['expenses', 'total_expenses']))),
                _card('Net Profit', money(pick(d, ['net_profit']))),
                _card('Outstanding Debt', money(pick(d, ['outstanding_debt', 'debt_balance']))),
                _card('Sales Count', '${pick(d, ['sales_count', 'sales'])}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, String value) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
}
