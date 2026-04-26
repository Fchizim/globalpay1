import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart'; // adjust path

class InviteFriends extends StatefulWidget {
  const InviteFriends({super.key});

  @override
  State<InviteFriends> createState() => _InviteFriendsState();
}

class _InviteFriendsState extends State<InviteFriends>
    with SingleTickerProviderStateMixin {

  // ── Referral stats ────────────────────────────────────────────────────────
  int _totalInvited  = 0;
  double _totalEarned = 0;
  List<Map<String, dynamic>> _referralList = [];
  bool _statsLoading = true;

  // Milestones: invite N users → earn ₦X
  final List<Map<String, dynamic>> _milestones = [
    {'users': 3,  'reward': 3000},
    {'users': 6,  'reward': 6000},
    {'users': 10, 'reward': 10000},
  ];

  // ── Fake notification ticker ──────────────────────────────────────────────
  final List<String> names = List.generate(
      100,
          (i) => "User${i + 1} ${[
        "Smith","Johnson","Okafor","Adeyemi","Eze",
        "Bakare","Obi","Shittu","Adebayo","Uche"
      ][i % 10]}");

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchStats();
    });
  }

  // ── Fetch real stats from backend ─────────────────────────────────────────
  Future<void> _fetchStats() async {
    final userId = context.read<UserProvider>().user?.userId ?? '';
    if (userId.isEmpty) return;

    setState(() => _statsLoading = true);

    try {
      final res = await http.post(
        Uri.parse('https://glopa.org/glo/referral_stats.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        if (map['status'] == 'success') {
          setState(() {
            _totalInvited  = (map['total_invited'] as num).toInt();
            _totalEarned   = (map['total_earned']  as num).toDouble();
            _referralList  = List<Map<String, dynamic>>.from(map['referrals'] ?? []);
          });
        }
      }
    } catch (e) {
      debugPrint('Referral stats error: $e');
    } finally {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  // ── Next milestone progress ───────────────────────────────────────────────
  Map<String, dynamic> get _nextMilestone {
    for (final m in _milestones) {
      if (_totalInvited < (m['users'] as int)) return m;
    }
    return _milestones.last; // already past all milestones
  }

  double get _milestoneProgress {
    final next = _nextMilestone['users'] as int;
    return (_totalInvited / next).clamp(0.0, 1.0);
  }

  void _showRandomNotification() {
    final name   = names[_random.nextInt(names.length)];
    final amount = _random.nextInt(10000) + 1;
    setState(() {
      final shortName =
      name.length > 15 ? '${name.substring(0, 12)}...' : name;
      currentNotification = "$shortName received ₦$amount just now";
    });
  }

  void _shareInvite(String referralCode) {
    Share.share(
      '🎉 Join Global Pay and earn ₦200 instantly!\n\n'
          'Sign up with my referral code: $referralCode\n\n'
          'Download here: https://glopa.org/download',
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user         = context.watch<UserProvider>().user;
    final referralCode = user?.referralCode ?? '';
    debugPrint('>>> referralCode in build: $referralCode');
    debugPrint('>>> full user: ${user?.toJson()}');

    final theme    = Theme.of(context);
    final isDark   = theme.brightness == Brightness.dark;
    final bgColor  = isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7);
    final textColor    = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;
    final gradientStart = isDark ? const Color(0xFF6A1B9A) : const Color(0xFF8E24AA);
    final gradientEnd   = isDark ? const Color(0xFF4A148C) : const Color(0xFF6A1B9A);

    final next = _nextMilestone;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Invite Friends',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              child: Column(
                children: [
                  const SizedBox(height: 80),

                  // ── Hero image ────────────────────────────────────────
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
                        fontSize: 14, color: subtitleColor, height: 1.3),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // ── Stats row ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _statCard(
                          label: 'Invited',
                          value: _statsLoading ? '...' : '$_totalInvited',
                          icon: Icons.people_alt_outlined,
                          color: gradientStart,
                          bgColor: gradientStart.withOpacity(0.08),
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          label: 'Earned',
                          value: _statsLoading
                              ? '...'
                              : '₦${_totalEarned.toStringAsFixed(0)}',
                          icon: Icons.account_balance_wallet_outlined,
                          color: Colors.green,
                          bgColor: Colors.green.withOpacity(0.08),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Progress to next milestone ────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Next milestone',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: subtitleColor,
                                  fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '$_totalInvited / ${next['users']} users  →  ₦${next['reward']}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: gradientStart,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: LinearProgressIndicator(
                            value: _milestoneProgress,
                            minHeight: 14,
                            backgroundColor: gradientStart.withOpacity(0.2),
                            valueColor:
                            AlwaysStoppedAnimation<Color>(gradientStart),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // milestone labels
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _milestones.map((m) {
                            final reached =
                                _totalInvited >= (m['users'] as int);
                            return Column(
                              children: [
                                Text(
                                  '₦${m['reward']}',
                                  style: TextStyle(
                                    color: reached
                                        ? Colors.green
                                        : textColor,
                                    fontSize: 12,
                                    fontWeight: reached
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  '${m['users']} users',
                                  style: TextStyle(
                                      color: subtitleColor, fontSize: 10),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Step cards ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _stepCard('Share link', Icons.share,
                            gradientStart, gradientEnd),
                        _stepCard('Invitee signs up', Icons.task_alt,
                            gradientStart, gradientEnd),
                        _stepCard('Get cash', Icons.attach_money,
                            gradientStart, gradientEnd),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Referral code card ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: gradientStart.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: gradientStart.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your referral code',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: subtitleColor,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                referralCode.isEmpty ? '...' : referralCode,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: gradientStart,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                  ClipboardData(text: referralCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                    Text('Referral code copied!')),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: gradientStart.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.copy_rounded,
                                      size: 14, color: gradientStart),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Copy',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: gradientStart,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Invite Now button ─────────────────────────────────
                  ScaleTransition(
                    scale: _pulseController,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () => _shareInvite(referralCode),
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
                          child: const Center(
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

                  const SizedBox(height: 24),

                  // ── Referral history list ─────────────────────────────
                  if (!_statsLoading && _referralList.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Recent referrals',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _referralList.length,
                      itemBuilder: (_, i) {
                        final r = _referralList[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.04)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.black.withOpacity(0.06)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                gradientStart.withOpacity(0.15),
                                child: Text(
                                  (r['name'] as String)
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: TextStyle(
                                      color: gradientStart,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r['name'] ?? '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      '@${r['username'] ?? ''}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: subtitleColor),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '+₦${(r['reward'] as num).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius:
                                      BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      r['status'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.green),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // ── Live notification ticker ──────────────────────────────────
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
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
                    Icon(Icons.notifications,
                        color: gradientEnd, size: 18),
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

  // ── Stat card widget ─────────────────────────────────────────────────────
  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Step card widget ─────────────────────────────────────────────────────
  Widget _stepCard(
      String label, IconData icon, Color start, Color end) {
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
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}