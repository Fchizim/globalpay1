import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';
import 'api_config.dart';
import 'cpt.dart';
import 'gtag_transaction_page.dart';

// ----------------- PIN bottom sheet -----------------
Future<bool?> showPinBottomSheet(BuildContext context) async {
  final hiddenCtrl = TextEditingController();
  List<String> pins = ["", "", "", ""];
  bool loading = false;

  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          void handleChange(String value) async {
            for (int i = 0; i < 4; i++) {
              pins[i] = i < value.length ? value[i] : "";
            }
            setState(() {});
            if (value.length == 4) {
              setState(() => loading = true);
              await Future.delayed(const Duration(seconds: 1));
              if (context.mounted) Navigator.pop(context, true);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Enter 4-digit PIN",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                        (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 50,
                      height: 60,
                      decoration: BoxDecoration(
                        color: pins[i].isNotEmpty
                            ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.15)
                            : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: pins[i].isNotEmpty
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        pins[i].isNotEmpty ? "•" : "",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                if (loading)
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                const SizedBox(height: 20),
                Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: hiddenCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    onChanged: handleChange,
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

// ----------------- GTag Payment Page -----------------
class GTagPaymentPage extends StatefulWidget {
  final double balance;
  const GTagPaymentPage({super.key, required this.balance});

  @override
  State<GTagPaymentPage> createState() => _GTagPaymentPageState();
}

class _GTagPaymentPageState extends State<GTagPaymentPage> {

  // ── amount ────────────────────────────────────────────────
  String amount = "";

  // ── username lookup ───────────────────────────────────────
  final TextEditingController _usernameCtrl = TextEditingController();
  bool _lookupLoading = false;
  String? _lookupError;
  Map<String, dynamic>? _resolvedUser; // {user_id, name, username, image}

  @override
  void initState() {
    super.initState();
    _usernameCtrl.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _usernameCtrl.removeListener(_onUsernameChanged);
    _usernameCtrl.dispose();
    super.dispose();
  }

  // ── auto-lookup when username is long enough ──────────────
  void _onUsernameChanged() {
    final username = _usernameCtrl.text.trim();
    if (_resolvedUser != null || _lookupError != null) {
      setState(() {
        _resolvedUser = null;
        _lookupError  = null;
      });
    }
    if (username.length >= 3) {
      _lookupUser(username);
    }
  }

  Future<void> _lookupUser(String username) async {
    final me = context.read<UserProvider>().user;
    if (me == null) return;

    setState(() {
      _lookupLoading = true;
      _lookupError   = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/check_gtag_recipient.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username':  username,
          'sender_id': me.userId,
        }),
      ).timeout(const Duration(seconds: 10));

      final map = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;

      if (map['status'] == 'success') {
        setState(() {
          _resolvedUser = map['user'] as Map<String, dynamic>;
          _lookupError  = null;
        });
      } else {
        setState(() {
          _resolvedUser = null;
          _lookupError  = map['message'] as String? ?? 'User not found.';
        });
      }
    } catch (e) {
      debugPrint('gtag lookup error: $e');
      if (mounted) {
        setState(() {
          _resolvedUser = null;
          _lookupError  = 'Could not reach server.';
        });
      }
    } finally {
      if (mounted) setState(() => _lookupLoading = false);
    }
  }

  // ── keypad ────────────────────────────────────────────────
  void _appendNumber(String number) {
    if (number == ".") return;
    setState(() {
      if (amount.length < 12) amount += number;
    });
  }

  void _deleteNumber() {
    setState(() {
      if (amount.isNotEmpty) amount = amount.substring(0, amount.length - 1);
    });
  }

  String get formattedAmount {
    if (amount.isEmpty) return "₦0";
    final formatter =
    NumberFormat.currency(locale: "en_US", symbol: "₦", decimalDigits: 0);
    final intVal = int.tryParse(amount) ?? 0;
    return formatter.format(intVal);
  }

  // ── send ──────────────────────────────────────────────────
  Future<void> _sendMoney() async {
    final intVal = int.tryParse(amount) ?? 0;
    if (intVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an amount')),
      );
      return;
    }
    if (_resolvedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please find a valid recipient first')),
      );
      return;
    }

    final me = context.read<UserProvider>().user;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmPinTransferPage(
          senderUserId:    me?.userId ?? '',
          balance:         widget.balance,
          recipient:       _resolvedUser!,
          prefilledAmount: intVal.toDouble(),
          onTransaction:   (double amount) {},
        ),
      ),
    );
  }

  // ── keypad button ─────────────────────────────────────────
  Widget _buildKeypadButton(String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => _appendNumber(label),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('G-Tag Transfer',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Stack(
        children: [
          // ── background ──────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              isDark
                  ? "assets/images/png/bckdark1.PNG"
                  : "assets/images/png/background.png",
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),

                // ── username field + resolved card ────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // username input
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextField(
                          controller: _usernameCtrl,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.alternate_email,
                                color: Colors.white70),
                            suffixIcon: _lookupLoading
                                ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              ),
                            )
                                : _resolvedUser != null
                                ? const Icon(Icons.check_circle_rounded,
                                color: Colors.greenAccent)
                                : null,
                            hintText: 'Enter G-Tag username',
                            hintStyle:
                            const TextStyle(color: Colors.white60),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // resolved user card
                      if (_resolvedUser != null)
                        _resolvedCard()
                      else if (_lookupError != null)
                        _errorCard(),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── amount display ────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    formattedAmount,
                    key: ValueKey<String>(formattedAmount),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 20),

                // ── keypad ────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var row in [
                          ["1", "2", "3"],
                          ["4", "5", "6"],
                          ["7", "8", "9"],
                          [".", "0", "<"],
                        ])
                          Expanded(
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                              children: row.map((key) {
                                return Expanded(
                                  child: _buildKeypadButton(
                                    key,
                                    onTap: key == "<"
                                        ? _deleteNumber
                                        : () => _appendNumber(key),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              disabledBackgroundColor:
                              Colors.white.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: (_resolvedUser != null &&
                                (int.tryParse(amount) ?? 0) > 0)
                                ? _sendMoney
                                : null,
                            child: Text(
                              "Send Money",
                              style: TextStyle(
                                color: Colors.deepOrange.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── resolved recipient card ───────────────────────────────
  Widget _resolvedCard() {
    final name     = (_resolvedUser!['name']     as String?) ?? 'User';
    final username = (_resolvedUser!['username'] as String?) ?? '';
    final image    = (_resolvedUser!['image']    as String?) ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white24,
            backgroundImage:
            image.isNotEmpty ? NetworkImage(image) : null,
            child: image.isEmpty
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                if (username.isNotEmpty)
                  Text('@$username',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: Colors.greenAccent, size: 20),
        ],
      ),
    );
  }

  // ── error card ────────────────────────────────────────────
  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _lookupError ?? 'User not found.',
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}