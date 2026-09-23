import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ApiListScreen extends StatefulWidget {
  final String title;
  final String endpoint;
  final String dataKey;
  final List<String> possibleKeys;

  const ApiListScreen({
    super.key,
    required this.title,
    required this.endpoint,
    required this.dataKey,
    this.possibleKeys = const [],
  });

  @override
  State<ApiListScreen> createState() => _ApiListScreenState();
}

class _ApiListScreenState extends State<ApiListScreen> {
  List<dynamic>? rows;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => error = null);
    try {
      final data = await ApiService.instance.getJson(widget.endpoint);
      final keys = widget.possibleKeys.isEmpty ? [widget.dataKey, 'data'] : widget.possibleKeys;
      if (mounted) setState(() => rows = ApiService.instance.extractList(data, keys));
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  String titleFor(Map<String, dynamic> x) {
    return '${x['name'] ?? x['customer_name'] ?? x['product_name'] ?? x['phone'] ?? x['sale_number'] ?? x['order_number'] ?? 'Record'}';
  }

  String money(dynamic value) {
    final n = num.tryParse('${value ?? 0}') ?? 0;
    return '₦${n.toStringAsFixed(0)}';
  }

  String subtitleFor(Map<String, dynamic> x) {
    final key = widget.dataKey;
    if (key == 'orders') {
      return 'Order #${x['id'] ?? '-'} • ${money(x['total'] ?? x['amount'])} • ${x['status'] ?? x['order_status'] ?? '-'} • ${x['payment_status'] ?? '-'}';
    }
    if (key == 'products') {
      return '${money(x['price'])} • Stock ${x['stock'] ?? '-'} • ${x['category'] ?? ''}';
    }
    if (key == 'customers') {
      return '${x['phone'] ?? ''} • ${x['status'] ?? ''}';
    }
    if (key == 'conversations') {
      return '${x['lead_status'] ?? x['status'] ?? ''} • ${x['last_message'] ?? x['message'] ?? ''}';
    }
    if (key == 'debts') {
      return 'Balance ${money(x['balance'])} • Paid ${money(x['amount_paid'])} • ${x['status'] ?? ''}';
    }
    if (key == 'payments') {
      return 'Order #${x['order_id'] ?? '-'} • ${money(x['amount_paid'] ?? x['amount'])} • ${x['payment_status'] ?? x['status']} • ${x['channel'] ?? x['method'] ?? ''}';
    }
    return x.entries.take(4).map((e) => '${e.key}: ${e.value}').join(' • ');
  }

  String _cleanLabel(String key) {
    return key.replaceAll('_', ' ').split(' ').map((part) {
      if (part.isEmpty) return part;
      return part[0].toUpperCase() + part.substring(1);
    }).join(' ');
  }

  String _formatValue(String key, dynamic value) {
    if (value == null) return '—';
    final k = key.toLowerCase();
    if (k.contains('amount') || k.contains('price') || k.contains('total') || k.contains('balance') || k.contains('paid')) {
      final n = num.tryParse('$value');
      if (n != null) return money(n);
    }
    return '$value';
  }

  void _openDetails(Map<String, dynamic> x) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111B14),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        final entries = x.entries.toList();
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  titleFor(x),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitleFor(x),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ...entries.map((entry) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1220),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _cleanLabel(entry.key),
                            style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatValue(entry.key, entry.value),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: RefreshIndicator(
          onRefresh: load,
          child: rows == null
              ? ListView(
                  children: [
                    SizedBox(height: MediaQuery.sizeOf(context).height * .32),
                    Center(child: error == null ? const CircularProgressIndicator() : Text(error!, style: const TextStyle(color: Colors.redAccent))),
                  ],
                )
              : rows!.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 220),
                        Center(child: Text(error ?? 'No records yet.')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: rows!.length,
                      itemBuilder: (context, index) {
                        final record = rows![index];
                        final x = record is Map ? Map<String, dynamic>.from(record) : {'value': record};
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            title: Text(titleFor(x), style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(subtitleFor(x), maxLines: 4, overflow: TextOverflow.ellipsis),
                            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                            onTap: () => _openDetails(x),
                          ),
                        );
                      },
                    ),
        ),
      );
}
