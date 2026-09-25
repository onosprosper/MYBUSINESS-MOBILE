import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'list_screen.dart';
import 'reports_screen.dart';
import 'services_screen.dart';
import 'web_dashboard_screen.dart';
import 'account_deletion_screen.dart';
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
  int selectedTab = 0;
  String toolSearch = '';

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
        title: Text(['MYBUSINESS', 'All tools', 'Services', 'Account'][selectedTab], style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: selectedTab == 0 ? _compactHome(stats, business)
        : selectedTab == 1 ? _allToolsTab()
        : selectedTab == 2 ? _servicesTab() : _accountTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) => setState(() => selectedTab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), label: 'All tools'),
          NavigationDestination(icon: Icon(Icons.design_services_outlined), label: 'Services'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }

  Widget _compactHome(Map<String, dynamic> stats, Map<String, dynamic> business) =>
    RefreshIndicator(onRefresh: load, child: ListView(
      padding: const EdgeInsets.all(16), children: [
        Text(business['name']?.toString() ?? 'Your business',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const Text('Your business at a glance', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        if (loading) const LinearProgressIndicator(minHeight: 2),
        if (error != null) Padding(padding: const EdgeInsets.all(8),
          child: Text(error!, style: const TextStyle(color: Colors.redAccent))),
        Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            _smallStat('Products', stats['products'] ?? stats['product_count'] ?? 0,
              Icons.inventory_2_outlined, () => _openList('Products', '/api/v1/products', 'products', ['products', 'data'])),
            _smallStat('Customers', stats['customers'] ?? stats['customer_count'] ?? 0,
              Icons.people_outline, () => _openList('Customers', '/api/v1/customers', 'customers', ['customers', 'data'])),
            _smallStat('Orders', stats['orders'] ?? stats['order_count'] ?? 0,
              Icons.shopping_bag_outlined, () => _openList('Orders', '/api/v1/orders', 'orders', ['orders', 'data'])),
            _smallStat('Unread', stats['unread_conversations'] ?? stats['unread'] ?? 0,
              Icons.chat_outlined, () => _openList('Conversations', '/api/v1/conversations', 'conversations', ['conversations', 'data'])),
          ]))),
        const SizedBox(height: 12),
        _compactSection('Quick actions', _toolGrid([
          _tool('Services', Icons.design_services_outlined, () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ServicesScreen()))),
          _tool('Bookings', Icons.calendar_month_outlined, () => _openModuleInfo(title: 'Bookings',
            icon: Icons.calendar_month_outlined, description: '', webPath: '/dashboard/bookings')),
          _tool('Products', Icons.inventory_2_outlined, () => _openList('Products', '/api/v1/products', 'products', ['products', 'data'])),
          _tool('Orders', Icons.shopping_bag_outlined, () => _openList('Orders', '/api/v1/orders', 'orders', ['orders', 'data'])),
          _tool('Customers', Icons.people_outline, () => _openList('Customers', '/api/v1/customers', 'customers', ['customers', 'data'])),
          _tool('Sales', Icons.point_of_sale_outlined, () => _openModuleInfo(title: 'Sales', icon: Icons.point_of_sale_outlined,
            description: '', webPath: '/dashboard/sales')),
          _tool('Reports', Icons.bar_chart_outlined, () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ReportsScreen()))),
          _tool('All tools', Icons.grid_view, () => setState(() => selectedTab = 1)),
        ])),
        _compactSection('Your shop', ListTile(
          leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF22C55E)),
          title: const Text('Shop photos and service menu'),
          subtitle: const Text('What customers see when booking'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openModuleInfo(title: 'Shop photos and service menu',
            icon: Icons.photo_library_outlined, description: '', webPath: '/dashboard/services'))),
        TextButton.icon(icon: const Icon(Icons.dashboard_outlined),
          label: const Text('Open full business dashboard'),
          onPressed: () => _openModuleInfo(title: 'Business dashboard',
            icon: Icons.dashboard_outlined, description: '', webPath: '/dashboard')),
      ]));

  Widget _smallStat(String label, dynamic value, IconData icon, VoidCallback onTap) =>
    Expanded(child: InkWell(onTap: onTap, child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: const Color(0xFF22C55E)),
        const SizedBox(height: 7),
        Text('$value', maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ]))));

  Widget _compactSection(String title, Widget content) => Card(
    margin: const EdgeInsets.only(bottom: 12), child: Padding(
      padding: const EdgeInsets.all(12), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8), content,
        ])));

  Widget _toolGrid(List<Widget> children) => GridView.count(
    crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    childAspectRatio: .73, children: children);

  Widget _tool(String label, IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(height: 44, width: 44, decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: .14),
        borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, size: 22, color: const Color(0xFF22C55E))),
      const SizedBox(height: 7),
      Text(label, textAlign: TextAlign.center, maxLines: 2,
        overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
    ]));

  Widget _servicesTab() => Center(child: Column(mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.design_services_outlined, size: 48, color: Color(0xFF22C55E)),
      const SizedBox(height: 12),
      const Text('Manage treatments, prices and booking'),
      const SizedBox(height: 12),
      FilledButton(onPressed: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ServicesScreen())),
        child: const Text('Manage services')),
      TextButton(onPressed: () => _openModuleInfo(title: 'Bookings',
        icon: Icons.calendar_month_outlined, description: '', webPath: '/dashboard/bookings'),
        child: const Text('View bookings')),
    ]));

  Widget _accountTab() => ListView(padding: const EdgeInsets.all(16), children: [
    _nav('Full dashboard', 'All your web features', Icons.dashboard_outlined,
      () => _openModuleInfo(title: 'Business dashboard', icon: Icons.dashboard_outlined,
        description: '', webPath: '/dashboard')),
    _nav('Settings', 'Your business settings', Icons.settings_outlined,
      () => _openModuleInfo(title: 'Settings', icon: Icons.settings_outlined,
        description: '', webPath: '/dashboard/settings')),
    _nav('Subscription', 'Your MYBUSINESS plan', Icons.workspace_premium_outlined,
      () => _openModuleInfo(title: 'Subscription', icon: Icons.workspace_premium_outlined,
        description: '', webPath: '/dashboard/subscription')),
    _nav('Request account deletion', 'Request deletion of your account and associated data',
      Icons.person_remove_outlined, () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const AccountDeletionScreen()))),
    OutlinedButton.icon(onPressed: logout, icon: const Icon(Icons.logout),
      label: const Text('Sign out')),
  ]);

  Widget _toolCategory(String title, List<(String, IconData, VoidCallback)> items) {
    final visible = items.where((item) => item.$1.toLowerCase()
      .contains(toolSearch.toLowerCase())).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return _compactSection(title, _toolGrid([
      for (final item in visible) _tool(item.$1, item.$2, item.$3),
    ]));
  }

  Widget _allToolsTab() => ListView(padding: const EdgeInsets.all(16), children: [
    TextField(onChanged: (text) => setState(() => toolSearch = text),
      decoration: const InputDecoration(prefixIcon: Icon(Icons.search),
        hintText: 'Search tools', isDense: true)),
    const SizedBox(height: 14),
    _toolCategory('Services & bookings', [
      ('Service setup', Icons.design_services_outlined, () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ServicesScreen()))),
      ('Bookings', Icons.calendar_month_outlined, () => _openModuleInfo(title: 'Bookings',
        icon: Icons.calendar_month_outlined, description: '', webPath: '/dashboard/bookings')),
      ('Shop gallery', Icons.photo_library_outlined, () => _openModuleInfo(title: 'Shop gallery',
        icon: Icons.photo_library_outlined, description: '', webPath: '/dashboard/services')),
    ]),
    _toolCategory('Sales & stock', [
      ('Products', Icons.inventory_2_outlined, () => _openList('Products', '/api/v1/products', 'products', ['products', 'data'])),
      ('Inventory', Icons.warehouse_outlined, () => _openModuleInfo(title: 'Inventory', icon: Icons.warehouse_outlined,
        description: '', webPath: '/dashboard/inventory')),
      ('Orders', Icons.shopping_bag_outlined, () => _openList('Orders', '/api/v1/orders', 'orders', ['orders', 'data'])),
      ('Sales', Icons.point_of_sale_outlined, () => _openModuleInfo(title: 'Sales', icon: Icons.point_of_sale_outlined,
        description: '', webPath: '/dashboard/sales')),
      ('Invoices', Icons.receipt_long_outlined, () => _openModuleInfo(title: 'Invoices', icon: Icons.receipt_long_outlined,
        description: '', webPath: '/dashboard/invoices')),
      ('Negotiation', Icons.handshake_outlined, () => _openModuleInfo(title: 'Negotiation Rules', icon: Icons.handshake_outlined,
        description: '', webPath: '/dashboard/product-negotiation')),
    ]),
    _toolCategory('Customers & communication', [
      ('Customers', Icons.people_outline, () => _openList('Customers', '/api/v1/customers', 'customers', ['customers', 'data'])),
      ('Conversations', Icons.chat_bubble_outline, () => _openList('Conversations', '/api/v1/conversations', 'conversations', ['conversations', 'data'])),
      ('Customer cleanup', Icons.cleaning_services_outlined, () => _openModuleInfo(title: 'Customer Cleanup',
        icon: Icons.cleaning_services_outlined, description: '', webPath: '/dashboard/customers/duplicates')),
      ('AI assistant', Icons.smart_toy_outlined, () => _openModuleInfo(title: 'AI Assistant',
        icon: Icons.smart_toy_outlined, description: '', webPath: '/dashboard/assistant')),
      ('Follow-ups', Icons.notifications_outlined, () => _openList('Follow-Ups', '/api/v1/debts', 'debts', ['debts', 'data'])),
    ]),
    _toolCategory('Finance & reports', [
      ('Reports', Icons.bar_chart_outlined, () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ReportsScreen()))),
      ('Expenses', Icons.account_balance_wallet_outlined, () => _openModuleInfo(title: 'Expenses',
        icon: Icons.account_balance_wallet_outlined, description: '', webPath: '/dashboard/expenses')),
      ('Debts', Icons.credit_card_off_outlined, () => _openList('Customer Debts', '/api/v1/debts', 'debts', ['debts', 'data'])),
      ('Payments', Icons.payments_outlined, () => _openModuleInfo(title: 'Payment Settings',
        icon: Icons.payments_outlined, description: '', webPath: '/dashboard/payment-settings')),
    ]),
    _toolCategory('Account', [
      ('Dashboard', Icons.dashboard_outlined, () => _openModuleInfo(title: 'Business dashboard',
        icon: Icons.dashboard_outlined, description: '', webPath: '/dashboard')),
      ('Subscription', Icons.workspace_premium_outlined, () => _openModuleInfo(title: 'Subscription',
        icon: Icons.workspace_premium_outlined, description: '', webPath: '/dashboard/subscription')),
      ('Settings', Icons.settings_outlined, () => _openModuleInfo(title: 'Settings',
        icon: Icons.settings_outlined, description: '', webPath: '/dashboard/settings')),
    ]),
  ]);

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
