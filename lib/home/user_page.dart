import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';
import 'api_config.dart';
// import 'confirm_pin_transfer_page.dart';
import 'cpt.dart';

// ─────────────────────────────────────────────────────────────
// Lightweight model for a "recent recipient" — derived from the
// user's own transaction history (service_type == 'p2p_transfer',
// payment_type == 'debit'), NOT a separate hardcoded list.
// ─────────────────────────────────────────────────────────────
class _RecentRecipient {
  final String userId;
  final String name;

  const _RecentRecipient({required this.userId, required this.name});
}

class UserPage extends StatefulWidget {
  final double balance;
  final Function(double) onTransaction;

  const UserPage({
    super.key,
    required this.balance,
    required this.onTransaction,
  });

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  // ── phone lookup state ────────────────────────────────────────────────────
  final TextEditingController _phoneController = TextEditingController();
  bool _lookupLoading = false;
  String? _lookupError;
  Map<String, dynamic>? _resolvedUser; // {user_id, name, phone, image}

  // ── recent recipients (real data, fetched from get_user_transactions.php) ─
  List<_RecentRecipient> _recentRecipients = [];
  bool _recentLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<UserProvider>().user;
    if (user != null && _userId == null) {
      _userId = user.userId;
      _fetchRecentRecipients();
    }
  }

  void _onPhoneChanged() {
    final phone = _phoneController.text.trim();
    if (_resolvedUser != null || _lookupError != null) {
      setState(() {
        _resolvedUser = null;
        _lookupError = null;
      });
    }
    // Auto-trigger lookup once it looks like a complete phone number.
    // Adjust this length check if your phone numbers aren't 10-11 digits.
    if (phone.length >= 10) {
      _lookupRecipient(phone);
    }
  }

  Future<void> _lookupRecipient(String phone) async {
    final user = context.read<UserProvider>().user;
    if (user == null) {
      setState(() => _lookupError = 'You must be logged in.');
      return;
    }

    debugPrint('lookup url: ${ApiConfig.baseUrl}/check_receipient.php');

    setState(() {
      _lookupLoading = true;
      _lookupError = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/check_receipient.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'sender_id': user.userId}),
      );

      final map = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;

      if (map['status'] == 'success') {
        setState(() {
          _resolvedUser = map['user'] as Map<String, dynamic>;
          _lookupError = null;
        });
      } else {
        setState(() {
          _resolvedUser = null;
          _lookupError = map['message'] as String? ?? 'User not found.';
        });
      }
    } catch (e) {
      debugPrint('lookupRecipient error: $e');
      if (mounted) {
        setState(() {
          _resolvedUser = null;
          _lookupError = 'Could not reach the server. Try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _lookupLoading = false);
    }
  }

  // ── Recent recipients — derived from this user's own transaction history,
  Future<void> _fetchRecentRecipients() async {
    if (_userId == null) {
      setState(() => _recentLoading = false);
      return;
    }

    try {
      final res = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/get_user_transactions.php?user_id=$_userId&page=1&limit=20',
            ),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('recent txns response: ${res.body}');

      final data = jsonDecode(res.body);
      if (data['status'] == 'success' && mounted) {
        final list = (data['transactions'] as List);
        final seen = <String>{};
        final recents = <_RecentRecipient>[];

        for (final t in list) {
          final serviceType = (t['service_type'] ?? '')
              .toString()
              .toLowerCase();
          final paymentType = (t['payment_type'] ?? '')
              .toString()
              .toLowerCase();
          if (serviceType != 'p2p_transfer' || paymentType != 'debit') continue;

          final receiverId = (t['service_ref_id'] ?? '').toString();
          if (receiverId.isEmpty || seen.contains(receiverId)) continue;
          seen.add(receiverId);

          final purpose = (t['purpose'] ?? '').toString();
          final name = purpose.startsWith('Sent to ')
              ? purpose.substring(8)
              : 'GlobalPay user';

          recents.add(_RecentRecipient(userId: receiverId, name: name));
          if (recents.length >= 8) break;
        }

        setState(() => _recentRecipients = recents);
      }
    } catch (e) {
      debugPrint('fetchRecentRecipients error: $e');
    } finally {
      if (mounted) setState(() => _recentLoading = false);
    }
  }

  void _openTransferFlow(Map<String, dynamic> recipient) {
    final user = context.read<UserProvider>().user;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmPinTransferPage(
          senderUserId: user?.userId ?? '',
          balance: widget.balance,
          recipient: recipient,
          onTransaction: widget.onTransaction,
        ),
      ),
    );
  }

  // ── masks a phone number like 0801****830 for display ────────────────────
  String _maskPhone(String phone) {
    if (phone.length <= 6) return phone;
    final start = phone.substring(0, 4);
    final end = phone.substring(phone.length - 3);
    return '$start****$end';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF6F6F8);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final fieldColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF2F3F5);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? Colors.white54 : Colors.grey.shade600;
    final hintColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark
        ? Colors.white10
        : Colors.black.withOpacity(0.06);

    // Clamp system font scaling so accessibility "large text" settings
    // can't blow up fixed-height rows.
    final mq = MediaQuery.of(context);
    final clampedTextScaler = mq.textScaler.clamp(
      minScaleFactor: 0.9,
      maxScaleFactor: 1.25,
    );

    return MediaQuery(
      data: mq.copyWith(textScaler: clampedTextScaler),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(
            'Send to GlobalPay',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          backgroundColor: bgColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Recipient card ─────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recipient',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: subTextColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Phone field
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            cursorColor: Colors.deepOrange,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter phone number',
                              hintStyle: TextStyle(
                                color: hintColor,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0,
                              ),
                              filled: true,
                              fillColor: fieldColor,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 16,
                              ),
                              prefixIcon: Icon(
                                IconsaxPlusLinear.call,
                                size: 20,
                                color: hintColor,
                              ),
                              suffixIcon: _lookupLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(14),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                    )
                                  : (_phoneController.text.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(
                                              Icons.close_rounded,
                                              size: 18,
                                              color: hintColor,
                                            ),
                                            onPressed: () {
                                              _phoneController.clear();
                                              setState(() {});
                                            },
                                          )
                                        : null),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Colors.deepOrange,
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Recipient confirmation / error / hint
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _resolvedUser != null
                                ? _recipientFoundCard(
                                    isDark,
                                    textColor,
                                    subTextColor,
                                  )
                                : _lookupError != null
                                ? _recipientErrorCard(isDark)
                                : _hintRow(hintColor),
                          ),

                          const SizedBox(height: 18),

                          // Next button
                          SizedBox(
                            height: 52,
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                disabledBackgroundColor: isDark
                                    ? Colors.white12
                                    : Colors.deepOrange.shade100,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _resolvedUser == null
                                  ? null
                                  : () => _openTransferFlow(_resolvedUser!),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Continue',
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: _resolvedUser == null
                                        ? hintColor
                                        : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Info strip (replaces the loud gradient banner) ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(
                          isDark ? 0.12 : 0.07,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            size: 18,
                            color: Colors.deepOrange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Instant transfers between GlobalPay users',
                              style: TextStyle(
                                color: textColor.withOpacity(0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    // ── Recent ─────────────────────────────────────────
                    _sectionHeader('Recent', textColor),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 92,
                      child: _recentLoading
                          ? const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            )
                          : _recentRecipients.isEmpty
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'No recent transfers yet',
                                style: TextStyle(
                                  color: hintColor,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _recentRecipients.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                final r = _recentRecipients[index];
                                final firstName = r.name.split(' ').first;
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _openTransferFlow({
                                    'user_id': r.userId,
                                    'name': r.name,
                                    'phone': '',
                                    'image': '',
                                  }),
                                  child: SizedBox(
                                    width: 64,
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor: Colors.deepOrange
                                              .withOpacity(isDark ? 0.2 : 0.12),
                                          child: Text(
                                            r.name.isNotEmpty
                                                ? r.name[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: Colors.deepOrange,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          firstName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 26),

                    // ── Favorites — no backing table yet; honest empty state
                    _sectionHeader('Favorites', textColor),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.star_border_rounded,
                            color: hintColor,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Favorites coming soon',
                            style: TextStyle(color: hintColor, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── idle hint ─────────────────────────────────────────────────────────────
  Widget _hintRow(Color hintColor) {
    return Padding(
      key: const ValueKey('hint'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: hintColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Enter a phone number to find a GlobalPay user',
              style: TextStyle(color: hintColor, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── recipient found ────────────────────────────────────────────────────────
  Widget _recipientFoundCard(bool isDark, Color textColor, Color subTextColor) {
    final user = _resolvedUser!;
    final name = (user['name'] as String?) ?? 'GlobalPay user';
    final phone = (user['phone'] as String?) ?? '';
    final image = (user['image'] as String?) ?? '';

    return Container(
      key: const ValueKey('found'),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withOpacity(0.35)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.deepOrange.withOpacity(0.15),
            backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
            child: image.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _maskPhone(phone),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
        ],
      ),
    );
  }

  // ── recipient not found / lookup failed ───────────────────────────────────
  Widget _recipientErrorCard(bool isDark) {
    return Container(
      key: const ValueKey('error'),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _lookupError ?? 'User not found.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
