import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum TawkStatus { loading, ready, failed }

class TawkChatScreen extends StatefulWidget {
  final String? whatsappNumber; // fallback if chat fails
  const TawkChatScreen({super.key, this.whatsappNumber});

  static const String chatUrl =
      'https://tawk.to/chat/6ac917abe6d88534c75f2b13/1k4go8u24?layout=modern';

  // Kept alive between screens so the chat can load in the background.
  static WebViewController? _controller;
  static final ValueNotifier<TawkStatus> status = ValueNotifier<TawkStatus>(
    TawkStatus.loading,
  );

  /// Call this when the Help screen opens. It starts loading the chat
  /// in the background, so it is already ready when the user taps Live Chat.
  static WebViewController preload() {
    if (_controller != null) return _controller!;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => status.value = TawkStatus.ready,
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              status.value = TawkStatus.failed;
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(chatUrl));

    _controller = controller;
    return controller;
  }

  static void retry() {
    status.value = TawkStatus.loading;
    final controller = _controller ?? preload();
    controller.loadRequest(Uri.parse(chatUrl));
  }

  @override
  State<TawkChatScreen> createState() => _TawkChatScreenState();
}

class _TawkChatScreenState extends State<TawkChatScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    // Reuses the preloaded controller if it exists, otherwise starts loading now.
    _controller = TawkChatScreen.preload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Chat')),
      body: ValueListenableBuilder<TawkStatus>(
        valueListenable: TawkChatScreen.status,
        builder: (context, status, _) {
          return Stack(
            children: [
              if (status != TawkStatus.failed)
                WebViewWidget(controller: _controller),
              if (status == TawkStatus.loading)
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Connecting you to support...'),
                      ],
                    ),
                  ),
                ),
              if (status == TawkStatus.failed)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Couldn't connect to chat. Check your internet and try again, or message us on WhatsApp.",
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: TawkChatScreen.retry,
                          child: const Text('Try again'),
                        ),
                        if (widget.whatsappNumber != null)
                          TextButton(
                            onPressed: () => launchUrl(
                              Uri.parse(
                                'https://wa.me/${widget.whatsappNumber}',
                              ),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: const Text('Chat on WhatsApp'),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
