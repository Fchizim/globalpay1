import 'package:flutter/material.dart';

import 'auto_choice_page.dart';


class OnboardingPage extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const OnboardingPage({super.key, required this.onToggleTheme});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Send Money Anywhere",
      "desc": "Instantly transfer funds locally and internationally.",
      "image": "assets/images/png/currency2.png",
    },
    {
      "title": "Multi-Currency Wallet",
      "desc": "Hold, convert and use different currencies easily.",
      "image": "assets/images/png/multi.png",
    },
    {
      "title": "Business Payments",
      "desc": "Manage payroll, invoices and QR payments.",
      "image": "assets/images/png/business1.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: onboardingData.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (_, index) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(onboardingData[index]["image"]!, height: 250),
                      const SizedBox(height: 30),
                      Text(
                        onboardingData[index]["title"]!,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        onboardingData[index]["desc"]!,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 🔹 Dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              onboardingData.length,
                  (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
                width: _currentPage == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Colors.deepOrange
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                if (_currentPage == onboardingData.length - 1) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AuthChoicePage(onToggleTheme: widget.onToggleTheme),
                    ),
                  );
                } else {
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Text(
                _currentPage == onboardingData.length - 1
                    ? "Get Started"
                    : "Next",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
