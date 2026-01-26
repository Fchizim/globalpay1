import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart'; // <-- Add this

class InviteFriends extends StatefulWidget {
  const InviteFriends({super.key});

  @override
  State<InviteFriends> createState() => _InviteFriendsState();
}

class _InviteFriendsState extends State<InviteFriends>
    with SingleTickerProviderStateMixin {
  final int invited = 6;
  final int total = 10;

  final List<String> names = List.generate(
      100,
          (i) =>
      "User${i + 1} ${["Smith","Johnson","Okafor","Adeyemi","Eze","Bakare","Obi","Shittu","Adebayo","Uche"][i % 10]}");

  final Random _random = Random();
  String currentNotification = "";
  late Timer _timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);

    _showRandomNotification();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _showRandomNotification();
    });
  }

  void _showRandomNotification() {
    final name = names[_random.nextInt(names.length)];
    final amount = _random.nextInt(10000) + 1;
    setState(() {
      final shortName = name.length > 15 ? '${name.substring(0, 12)}...' : name;
      currentNotification = "$shortName received ₦$amount just now";
    });
  }

  void _shareInvite() {
    const String inviteText = "Join this amazing app and earn rewards! Sign up with my referral code: ABC123";
    Share.share(inviteText);
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = invited / total;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;
    final gradientStart = isDark ? const Color(0xFF6A1B9A) : const Color(0xFF8E24AA);
    final gradientEnd = isDark ? const Color(0xFF4A148C) : const Color(0xFF6A1B9A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 100),
                SvgPicture.asset(
                  'assets/images/svg/invite.svg',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  color: isDark ? Colors.white : null,
                ),
                const SizedBox(height: 12),
                Text(
                  'Invite friends, get rewarded',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Get Cash for every user invited to sign up\nusing your referral code.',
                  style: TextStyle(
                    fontSize: 14,
                    color: subtitleColor,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 16,
                          backgroundColor:
                          gradientStart.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            gradientEnd,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('₦3,000', style: TextStyle(color: textColor, fontSize: 12)),
                          Text('₦6,000', style: TextStyle(color: textColor, fontSize: 12)),
                          Text('₦10,000', style: TextStyle(color: textColor, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('3 users', style: TextStyle(color: subtitleColor, fontSize: 11)),
                          Text('6 users', style: TextStyle(color: subtitleColor, fontSize: 11)),
                          Text('10 users', style: TextStyle(color: subtitleColor, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _stepCard('Share link', Icons.share, gradientStart, gradientEnd),
                      _stepCard('Invitee done', Icons.task_alt, gradientStart, gradientEnd),
                      _stepCard('Get cash', Icons.attach_money, gradientStart, gradientEnd),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ScaleTransition(
                  scale: _pulseController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: _shareInvite, // <-- open phone share
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: [gradientStart, gradientEnd],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: gradientEnd.withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Invite Now',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: gradientEnd.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications, color: gradientEnd, size: 18),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 200,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 800),
                        child: Text(
                          currentNotification,
                          key: ValueKey(currentNotification),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepCard(String label, IconData icon, Color start, Color end) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [start, end],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: end.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}
