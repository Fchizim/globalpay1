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

  final PageController _controller = PageController();
  Timer? _timer;
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Send Money Anytime",
      "desc": "Instant transfer.",
      "image": "assets/images/png/c.PNG",
    },
    {
      "title": "Buy Airtime/Data",
      "desc": "Buy airtime & data at cheaper rates.",
      "image": "assets/images/png/e.PNG",
    },
    {
      "title": "G-Drop",
      "desc":
          "Send money by generating QR Codes. Receive money by scanning QR Codes.",
      "image": "assets/images/png/a.PNG",
    },
    {
      "title": "GlobalBiz",
      "desc": "Buy and sell products at ease.",
      "image": "assets/images/png/b.PNG",
    },
    {
      "title": "24/7 Support/Customer Care",
      "desc": "Get help anytime, anywhere.",
      "image": "assets/images/png/d.PNG",
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
                // 🔹 Skip button (top right)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(top: 8 * scale, right: 16 * scale),
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
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20 * scale,
                                  vertical: 10 * scale,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      onboardingData[index]["image"]!,
                                      // Image height adapts to available space
                                      height: constraints.maxHeight * 0.5,
                                      fit: BoxFit.contain,
                                    ),
                                    SizedBox(height: 30 * scale),
                                    Text(
                                      onboardingData[index]["title"]!,
                                      style: TextStyle(
                                        fontSize: 24 * scale,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 10 * scale),
                                    Text(
                                      onboardingData[index]["desc"]!,
                                      style: TextStyle(
                                        fontSize: 16 * scale,
                                        color: Colors.grey,
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
                        horizontal: 5 * scale,
                        vertical: 16 * scale,
                      ),
                      width: (_currentPage == index ? 20 : 8) * scale,
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
                    20 * scale,
                    0,
                    20 * scale,
                    20 * scale,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      minimumSize: Size(double.infinity, 50 * scale),
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
