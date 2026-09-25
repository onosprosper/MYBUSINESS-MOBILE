import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'list_screen.dart';
import 'reports_screen.dart';
import 'services_screen.dart';
import 'web_dashboard_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? data;
  String? error;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final d = await ApiService.instance.getMap('/api/v1/overview');
      if (mounted) setState(() => data = d);
    } catch (e) {
      if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> logout() async {
    await ApiService.instance.logout();
    await WebViewCookieManager().clearCookies();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _openList(String title, String endpoint, String fallbackKey, List<String> keys) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApiListScreen(
          title: title,
          endpoint: endpoint,
          dataKey: fallbackKey,
          possibleKeys: keys,
        ),
      ),
    );
  }

  void _openModuleInfo({
    required String title,
    required IconData icon,
    required String description,
    required String webPath,

  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebDashboardScreen(title: title, path: webPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = (data?['stats'] as Map<String, dynamic>?) ?? data ?? {};
    final business = (data?['business'] as Map<String, dynamic>?) ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('MYBUSINESS', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              business['name']?.toString() ?? 'Ruthelyncollections',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (loading) const LinearProgressIndicator(),
            if (error != null)
              Card(
                color: const Color(0xFF3A1111),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(error!, style: const TextStyle(color: Colors.redAccent)),
                ),
              ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.12,
              children: [
                _stat(
                  'Products',
                  stats['products'] ?? stats['product_count'] ?? 0,
                  Icons.inventory_2,
                  () => _openList('Products & Inventory', '/api/v1/products', 'products', ['products', 'data']),
                ),
                _stat(
                  'Customers',
                  stats['customers'] ?? stats['customer_count'] ?? 0,
                  Icons.people,
                  () => _openList('Customers', '/api/v1/customers', 'customers', ['customers', 'data']),
                ),
                _stat(
                  'Orders',
                  stats['orders'] ?? stats['order_count'] ?? 0,
                  Icons.receipt_long,
                  () => _openList('Orders', '/api/v1/orders', 'orders', ['orders', 'data']),
                ),
                _stat(
                  'Unread',
                  stats['unread_conversations'] ?? stats['unread'] ?? 0,
                  Icons.chat,
                  () => _openList('Conversations', '/api/v1/conversations', 'conversations', ['conversations', 'data']),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _nav('Full business dashboard', 'Use every web feature on your phone', Icons.dashboard_outlined, () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const WebDashboardScreen(title: 'Business dashboard', path: '/dashboard')));
            }),
            Card(child: ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text('Set up services'),
              subtitle: const Text('Add treatments, prices and durations for online bookings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ServicesScreen())),
            )),
            _nav('Bookings', 'Manage requests, payment status and appointments', Icons.calendar_month_outlined, () {
              _openModuleInfo(title: 'Bookings', icon: Icons.calendar_month_outlined,
                description: 'Manage service bookings.', webPath: '/dashboard/bookings');
            }),
            _nav('Shop photos and service menu', 'Upload shop photos and manage your public services', Icons.photo_library_outlined, () {
              _openModuleInfo(title: 'Shop photos and service menu', icon: Icons.photo_library_outlined,
                description: 'Manage your shop gallery and services.', webPath: '/dashboard/services');
            }),
            const _SectionTitle('Business'),
            _nav('Sales', 'Revenue, payments and customer order status', Icons.point_of_sale, () {
              _openList('Sales', '/api/v1/orders', 'orders', ['orders', 'data']);
            }),
            _nav('Products & Inventory', 'Products, cost price, profit and stock', Icons.inventory_2_outlined, () {
              _openList('Products & Inventory', '/api/v1/products', 'products', ['products', 'data']);
            }),
            _nav('Stock Control', 'View product stock and low-stock items', Icons.warehouse_outlined, () {
              _openList('Stock Control', '/api/v1/products', 'products', ['products', 'data']);
            }),
            _nav('Negotiation Rules', 'AI lowest price and counter-offer settings', Icons.handshake_outlined, () {
              _openModuleInfo(
                title: 'Negotiation Rules',
                icon: Icons.handshake_outlined,
                description: 'Control whether the AI can negotiate each product and set the lowest acceptable price.',
                webPath: '/dashboard/product-negotiation',
              );
            }),
            _nav('Orders', 'Customer orders and payments', Icons.shopping_bag_outlined, () {
              _openList('Orders', '/api/v1/orders', 'orders', ['orders', 'data']);
            }),
            _nav('Invoices & Receipts', 'View receipts and invoice records', Icons.receipt_outlined, () {
              _openModuleInfo(
                title: 'Invoices & Receipts',
                icon: Icons.receipt_outlined,
                description: 'Receipts and invoices are available on the web dashboard. Mobile receipt download will be added after launch.',
                webPath: '/dashboard/invoices',
              );
            }),
            const SizedBox(height: 18),
            const _SectionTitle('Customers & Communication'),
            _nav('Conversations', 'WhatsApp customers and AI replies', Icons.chat_bubble_outline, () {
              _openList('Conversations', '/api/v1/conversations', 'conversations', ['conversations', 'data']);
            }),
            _nav('Customers', 'Customer CRM and phone records', Icons.people_outline, () {
              _openList('Customers', '/api/v1/customers', 'customers', ['customers', 'data']);
            }),
            _nav('Customer Cleanup', 'Merge duplicate customers and phone numbers', Icons.cleaning_services_outlined, () {
              _openModuleInfo(
                title: 'Customer Cleanup',
                icon: Icons.cleaning_services_outlined,
                description: 'Clean duplicate customer records, especially repeated WhatsApp phone numbers.',
                webPath: '/dashboard/customers/duplicates',
              );
            }),
            _nav('AI Assistant', 'Assistant settings and automation status', Icons.smart_toy_outlined, () {
              _openModuleInfo(
                title: 'AI Assistant',
                icon: Icons.smart_toy_outlined,
                description: 'Manage AI assistant settings, automation and customer reply behaviour.',
                webPath: '/dashboard/assistant',
              );
            }),
            const SizedBox(height: 18),
            const _SectionTitle('Finance'),
            _nav('Expenses', 'Record and track business spending', Icons.account_balance_wallet_outlined, () {
              _openModuleInfo(
                title: 'Expenses',
                icon: Icons.account_balance_wallet_outlined,
                description: 'Expense recording is available on the web dashboard. Mobile expense entry will be added in the next phase.',
                webPath: '/dashboard/expenses',
              );
            }),
            Card(
              child: ListTile(
                leading: const Icon(Icons.bar_chart, color: Color(0xFF22C55E)),
                title: const Text('Reports', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Revenue, profit, expenses and business performance'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
              ),
            ),
            _nav('Customer Debts', 'Outstanding balances and payment follow-up', Icons.credit_card_off_outlined, () {
              _openList('Customer Debts', '/api/v1/debts', 'debts', ['debts', 'data']);
            }),
            _nav('Follow-Ups', 'Overdue and due customer debt reminders', Icons.notification_important_outlined, () {
              _openList('Follow-Ups', '/api/v1/debts', 'debts', ['debts', 'data']);
            }),
            _nav('Payments', 'Manual payments and payment status', Icons.payments_outlined, () {
              _openList('Payments', '/api/v1/orders', 'orders', ['orders', 'data']);
            }),
            _nav('Payment Settings', 'Cash, transfer, POS and bank instructions', Icons.settings_applications_outlined, () {
              _openModuleInfo(
                title: 'Payment Settings',
                icon: Icons.settings_applications_outlined,
                description: 'Control how product payments are paid directly to the business owner.',
                webPath: '/dashboard/payment-settings',
              );
            }),
            const SizedBox(height: 18),
            const _SectionTitle('Launch Tools'),
            _nav('Order Cleanup', 'Fix old order and payment status records', Icons.rule_folder_outlined, () {
              _openModuleInfo(
                title: 'Order Cleanup',
                icon: Icons.rule_folder_outlined,
                description: 'Review old orders where order status and payment status do not match.',
                webPath: '/dashboard/orders/status-cleanup',
              );
            }),
            _nav('Subscription', 'MYBUSINESS plan and subscription payment', Icons.workspace_premium_outlined, () {
              _openModuleInfo(
                title: 'Subscription',
                icon: Icons.workspace_premium_outlined,
                description: 'Manage MYBUSINESS subscription plan and platform payment.',
                webPath: '/dashboard/subscription',
              );
            }),
            _nav('Settings', 'Business profile and general settings', Icons.settings_outlined, () {
              _openModuleInfo(
                title: 'Settings',
                icon: Icons.settings_outlined,
                description: 'Manage business profile and dashboard settings.',
                webPath: '/dashboard/settings',
              );
            }),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, dynamic value, IconData icon, VoidCallback onTap) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: const Color(0xFF22C55E), size: 28),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$value',
                    maxLines: 1,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _nav(String title, String subtitle, IconData icon, VoidCallback onTap) => Card(
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF22C55E)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}

class ModuleInfoScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final String webPath;
  final String status;

  const ModuleInfoScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    required this.webPath,
    required this.status,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 42, color: const Color(0xFF22C55E)),
                    const SizedBox(height: 16),
                    Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    Text(description, style: const TextStyle(color: Colors.white70, fontSize: 15)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1220),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(status, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 16),
                    const Text('Web dashboard path', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    SelectableText('https://mybusiness-ng.onrender.com$webPath'),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
      );
}

