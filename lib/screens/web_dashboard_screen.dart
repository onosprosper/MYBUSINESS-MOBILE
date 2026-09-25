import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Opens the existing full dashboard inside the app. Browser sessions are
/// separate from native API tokens, so users sign in on the first visit.
class WebDashboardScreen extends StatefulWidget {
  final String title;
  final String path;
  const WebDashboardScreen({super.key, required this.title, required this.path});

  @override
  State<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  late final WebViewController controller;
  bool loading = true;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    final path = widget.path.startsWith('/dashboard') ? widget.path : '/dashboard';
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) { if (mounted) setState(() { loading = true; failed = false; }); },
        onPageFinished: (_) { if (mounted) setState(() => loading = false); },
        onWebResourceError: (error) {
          if (error.isForMainFrame == true && mounted) {
            setState(() { failed = true; loading = false; });
          }
        },
      ))
      ..loadRequest(Uri.parse('https://mybusiness-ng.onrender.com$path'));
  }

  Future<void> back() async {
    if (await controller.canGoBack()) {
      await controller.goBack();
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(widget.title), leading: IconButton(
        tooltip: 'Back', icon: const Icon(Icons.arrow_back), onPressed: back), actions: [
        IconButton(tooltip: 'Reload', icon: const Icon(Icons.refresh),
          onPressed: () => controller.reload()),
      ]),
      body: Column(children: [
        if (loading) const LinearProgressIndicator(minHeight: 2),
        if (failed) Padding(padding: const EdgeInsets.all(12), child: TextButton(
          onPressed: () => controller.reload(), child: const Text('Page could not load. Tap to retry.'))),
        Expanded(child: WebViewWidget(controller: controller)),
      ]),
  );
}
