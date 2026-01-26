import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'dart:math' as math;

import 'fraud.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🌊 Reusable floating animation
  Widget _floating({required Widget child, double offset = 8}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = offset * math.sin((_controller.value * 2 * math.pi));
        return Transform.translate(offset: Offset(0, value), child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.deepOrange,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, -2),
              )
            ],
          ),
          child: Row(
            children: [
              const Icon(IconsaxPlusBold.messages_2, color: Colors.white, size: 26),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Live Chat",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Row(
                children: const [
                  Icon(IconsaxPlusLinear.timer, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    "Avg. 1.2 min",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                scrolledUnderElevation: 0,
                expandedHeight: 100,
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                flexibleSpace: Align(
                  alignment: const Alignment(0, 0.5),
                  child: Text(
                    "Help Center",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: theme.textTheme.headlineMedium?.color,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                                color: isDark ? Colors.black26 : Colors.black12,
                                blurRadius: 6,
                                offset: const Offset(0, 3))
                          ],
                        ),
                        child: Column(
                          children: [
                            _floating(
                              offset: 10,
                              child: ClipPath(
                                clipper: WaveClipperSmall(),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.red.shade400, Colors.orange.shade300],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.shade200.withOpacity(0.5),
                                        blurRadius: 10,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    onTap: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (context)=> ReportFraudPage()));
                                    },
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                              IconsaxPlusBold.warning_2,
                                              color: Colors.red,
                                              size: 28),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            "Report Fraud / Locked Account",
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white),
                                          ),
                                        ),
                                        const Icon(
                                            IconsaxPlusLinear.arrow_right_3,
                                            color: Colors.white),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1,
                              children: [
                                _diamondCard(IconsaxPlusLinear.message, "Chat", theme),
                                _diamondCard(IconsaxPlusLinear.call, "Call", theme),
                                _diamondCard(IconsaxPlusLinear.security, "Account", theme),
                                _diamondCard(IconsaxPlusLinear.refresh, "Transactions", theme),
                                _diamondCard(IconsaxPlusLinear.book, "FAQs", theme),
                                _diamondCard(IconsaxPlusLinear.direct_inbox, "Email", theme),
                                _diamondCard(IconsaxPlusLinear.profile_tick, "KYC Upgrade", theme),
                                _diamondCard(IconsaxPlusLinear.global, "Global Pay Office", theme),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      _faqItem("Why is my transaction pending?",
                          "Sometimes payments take longer due to network delays.", theme),
                      _faqItem("How do I reset my PIN?",
                          "Go to Settings > Security > Reset PIN.", theme),
                      _faqItem("How can I upgrade my account?",
                          "Submit a valid ID and proof of address.", theme),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _diamondCard(IconData icon, String title, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black26
                : Colors.orange.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.deepOrange, size: 28),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: theme.textTheme.bodyMedium?.color)),
        ],
      ),
    );
  }

  Widget _faqItem(String question, String answer, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: isDark ? Colors.black26 : Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3))
        ],
      ),
      child: ExpansionTile(
        title: Text(question,
            style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: theme.textTheme.bodyLarge?.color)),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(answer,
                style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color, height: 1.4)),
          )
        ],
      ),
    );
  }
}

class WaveClipperSmall extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 20);
    var controlPoint = Offset(size.width / 2, size.height + 20);
    var endPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(
        controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
