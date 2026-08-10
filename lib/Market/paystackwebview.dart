import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Opens a hosted checkout page (Paystack, Flutterwave, etc.) in a WebView
/// and pops with the payment reference once the redirect to
/// [callbackUrlPrefix] is detected. Pops with `null` if the user closes the
/// sheet before paying.
class PaystackWebView extends StatefulWidget {
  final String checkoutUrl;
  final String callbackUrlPrefix;
  final String title;

  const PaystackWebView({
    super.key,
    required this.checkoutUrl,
    required this.callbackUrlPrefix,
    this.title = 'Pay with Paystack',
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
              // Paystack uses `reference` (or the legacy `trxref`);
              // Flutterwave uses `tx_ref` for the same purpose — check both
              // so this WebView works for either provider unmodified.
              final reference = uri.queryParameters['reference'] ??
                  uri.queryParameters['trxref'] ??
                  uri.queryParameters['tx_ref'];
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
        title: Text(widget.title),
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