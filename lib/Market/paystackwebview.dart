import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Opens Paystack's hosted checkout page in a WebView and pops with the
/// payment reference once the redirect to [callbackUrlPrefix] is detected.
/// Pops with `null` if the user closes the sheet before paying.
class PaystackWebView extends StatefulWidget {
  final String checkoutUrl;
  final String callbackUrlPrefix;

  const PaystackWebView({
    super.key,
    required this.checkoutUrl,
    required this.callbackUrlPrefix,
  });

  @override
  State<PaystackWebView> createState() => _PaystackWebViewState();
}

class _PaystackWebViewState extends State<PaystackWebView> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            if (request.url.startsWith(widget.callbackUrlPrefix)) {
              final uri = Uri.parse(request.url);
              final reference =
                  uri.queryParameters['reference'] ?? uri.queryParameters['trxref'];
              Navigator.pop(context, reference);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay with Paystack'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, null),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            ),
        ],
      ),
    );
  }
}