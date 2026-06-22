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
        body: jsonEncode({
          'phone': phone,
          'sender_id': user.userId,
        }),
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
      final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/get_user_transactions.php?user_id=$_userId&page=1&limit=20'),
    ).timeout(const Duration(seconds: 15));

      debugPrint('recent txns response: ${res.body}');

      final data = jsonDecode(res.body);
      if (data['status'] == 'success' && mounted) {
        final list = (data['transactions'] as List);
        final seen = <String>{};
        final recents = <_RecentRecipient>[];

        for (final t in list) {
          final serviceType = (t['service_type'] ?? '').toString().toLowerCase();
          final paymentType = (t['payment_type'] ?? '').toString().toLowerCase();
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

    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey.shade100;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white38 : Colors.grey.shade600;
    final hintColor = isDark ? Colors.white54 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Transfer to GlobalPay", style: TextStyle(color: textColor)),
        backgroundColor: bgColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// To Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 15, top: 15, bottom: 5),
                      child: Text('To',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w500, color: textColor)),
                    ),
                    const SizedBox(height: 10),

                    /// Phone Number Field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        cursorColor: Colors.deepOrange,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: '   Enter phone number',
                          hintStyle: TextStyle(color: hintColor),
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
                              : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Colors.deepOrange),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    /// Recipient confirmation / error card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: _resolvedUser != null
                          ? _recipientFoundCard(isDark, textColor, subTextColor)
                          : _lookupError != null
                          ? _recipientErrorCard(isDark)
                          : Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            const Icon(IconsaxPlusBold.user,
                                color: Colors.deepOrange, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Enter a phone number to find a GlobalPay user',
                                style: TextStyle(color: hintColor, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            disabledBackgroundColor: Colors.deepOrange.withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed:
                          _resolvedUser == null ? null : () => _openTransferFlow(_resolvedUser!),
                          child: const Text(
                            'Next',
                            style:
                            TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [Colors.deepOrange, Colors.orangeAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Text(
                  '⚡ Instant, Zero-Issue Transactions',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),

            /// Recent Section — real data, derived from transaction history
            _sectionHeader('Recent', _fetchRecentRecipients, textColor, subTextColor),
            SizedBox(
              height: 110,
              child: _recentLoading
                  ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepOrange),
                ),
              )
                  : _recentRecipients.isEmpty
                  ? Center(
                child: Text('No recent transfers yet',
                    style: TextStyle(color: hintColor, fontSize: 13)),
              )
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: _recentRecipients.length,
                itemBuilder: (context, index) {
                  final r = _recentRecipients[index];
                  return GestureDetector(
                    onTap: () => _openTransferFlow({
                      'user_id': r.userId,
                      'name': r.name,
                      'phone': '',
                      'image': '',
                    }),
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.deepOrange.withOpacity(0.15),
                            child: Text(
                              r.name.isNotEmpty ? r.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  color: Colors.deepOrange, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              r.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            /// Favorites Section — no backing table exists yet for this.
            /// Honest empty state instead of fake/mock contacts.
            _sectionHeader('Favorites', () {}, textColor, subTextColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                child: Column(
                  children: [
                    Icon(Icons.star_border_rounded, color: hintColor, size: 30),
                    const SizedBox(height: 8),
                    Text('Favorites coming soon',
                        style: TextStyle(color: hintColor, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
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
      decoration: BoxDecoration(
        color: isDark ? Colors.green.withOpacity(0.12) : Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.deepOrange.withOpacity(0.15),
            backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
            child: image.isEmpty
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style:
                    TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w700)),
                Text(_maskPhone(phone), style: TextStyle(color: subTextColor, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
        ],
      ),
    );
  }

  // ── recipient not found / lookup failed ───────────────────────────────────
  Widget _recipientErrorCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.red.withOpacity(0.12) : Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.35)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_lookupError ?? 'User not found.',
                style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
      String title, VoidCallback onViewAll, Color textColor, Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: textColor, fontSize: 21, fontWeight: FontWeight.w500)),
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              children: [
                Text('View All', style: TextStyle(color: subTextColor)),
                const SizedBox(width: 3),
                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: subTextColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}