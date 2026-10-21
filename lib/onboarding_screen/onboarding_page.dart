import 'dart:async';

import 'package:flutter/material.dart';

import 'auto_choice_page.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const OnboardingPage({super.key, required this.onToggleTheme});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  // Change this to control how long each page stays before auto-advancing.
  static const Duration _autoScrollDelay = Duration(seconds: 4);

  // Base image size controls: fraction of the available page height, and a hard cap.
  static const double _imageHeightFactor = 0.36;
  static const double _imageMaxHeight = 260;
  static const double _imageMinHeight = 120;

  final PageController _controller = PageController();
  Timer? _timer;
  int _currentPage = 0;

  // "imageScale" shrinks or grows that page's image relative to the base size.
  // 1.0 = base size, 0.75 = 25% smaller, 0.6 = 40% smaller, etc.
  final List<Map<String, dynamic>> onboardingData = [
    {
      "title": "Send Money Anytime",
      "desc": "Instant transfer.",
      "image": "assets/images/png/c.PNG",
      "imageScale": 0.7,
    },
    {
      "title": "Buy Airtime/Data",
      "desc": "Buy airtime & data at cheaper rates.",
      "image": "assets/images/png/e.PNG",
      "imageScale": 0.7,
    },
    {
      "title": "G-Drop",
      "desc":
          "Send money by generating QR Codes. Receive money by scanning QR Codes.",
      "image": "assets/images/png/a.PNG",
      "imageScale": 1.0,
    },
    {
      "title": "GlobalBiz",
      "desc": "Buy and sell products at ease.",
      "image": "assets/images/png/b.PNG",
      "imageScale": 0.7,
    },
    {
      "title": "24/7 Support/Customer Care",
      "desc": "Get help anytime, anywhere.",
      "image": "assets/images/png/d.PNG",
      "imageScale": 1.0,
    },
  ];

  bool get _isLastPage => _currentPage == onboardingData.length - 1;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Starts (or restarts) a one-shot timer that moves to the next page.
  /// It is restarted every time the page changes, so each page stays
  /// visible for [_autoScrollDelay], even after a manual swipe.
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(_autoScrollDelay, () {
      if (!mounted || !_controller.hasClients) return;
      if (_currentPage < onboardingData.length - 1) {
        _controller.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
      // On the last page we stop and wait for the user to tap "Get Started".
    });
  }

  void _goToAuth() {
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AuthChoicePage(onToggleTheme: widget.onToggleTheme),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Scale factor based on screen width (375 = typical phone design width).
    final double scale = (size.width / 375).clamp(0.85, 1.3);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Keeps things tidy on tablets / very wide screens.
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // 🔹 Skip button (top right) - hidden on the last page
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(top: 8 * scale, right: 16 * scale),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: _isLastPage ? 0 : 1,
                      child: IgnorePointer(
                        ignoring: _isLastPage,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _goToAuth,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16 * scale,
                              vertical: 8 * scale,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.deepOrange),
                            ),
                            child: Text(
                              "Skip",
                              style: TextStyle(
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 🔹 Pages
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: onboardingData.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      _startTimer();
                    },
                    itemBuilder: (_, index) {
                      final item = onboardingData[index];
                      final double imageScale =
                          (item["imageScale"] as double?) ?? 1.0;

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final double baseHeight =
                              (constraints.maxHeight * _imageHeightFactor)
                                  .clamp(
                                    _imageMinHeight,
                                    _imageMaxHeight * scale,
                                  )
                                  .toDouble();
                          final double imageHeight = baseHeight * imageScale;

                          return SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 28 * scale,
                                  vertical: 10 * scale,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      item["image"] as String,
                                      height: imageHeight,
                                      fit: BoxFit.contain,
                                    ),
                                    SizedBox(height: 32 * scale),
                                    Text(
                                      item["title"] as String,
                                      style: TextStyle(
                                        fontSize: 24 * scale,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 12 * scale),
                                    Text(
                                      item["desc"] as String,
                                      style: TextStyle(
                                        fontSize: 16 * scale,
                                        height: 1.45,
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // 🔹 Dots indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    onboardingData.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: EdgeInsets.symmetric(
                        horizontal: 4 * scale,
                        vertical: 16 * scale,
                      ),
                      width: (_currentPage == index ? 24 : 8) * scale,
                      height: 8 * scale,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.deepOrange
                            : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                // 🔹 Next / Get Started button
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    24 * scale,
                    0,
                    24 * scale,
                    24 * scale,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      elevation: 0,
                      minimumSize: Size(double.infinity, 54 * scale),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      if (_isLastPage) {
                        _goToAuth();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(
                      _isLastPage ? "Get Started" : "Next",
                      style: TextStyle(
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
