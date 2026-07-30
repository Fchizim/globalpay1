import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';
import '../provider/balance_provider.dart';
import '../home/currency_con.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Map<String, dynamic>? _virtualAccount;
  bool _loading = true;
  bool _generating = false;
  bool _pending = false;

  Timer? _pollTimer;
  static const int _maxPollTicks = 15; // ~60s at 4s intervals
  static const Duration _pollInterval = Duration(seconds: 4);
  bool _pollTimedOut = false;



  double s(double v) {
    final sw = MediaQuery.of(context).size.width;
    return (sw / 375 * v).clamp(v * 0.85, v * 1.25);
  }

  @override
  void initState() {
    super.initState();
    _fetchVirtualAccount();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }


  Future<void> _showBvnDialog() async {
    final firstNameController = TextEditingController();
    final lastNameController  = TextEditingController();
    final bvnController       = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(s(20), s(20), s(20), s(24)),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(s(24))),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: EdgeInsets.only(bottom: s(16)),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text('Verify Your Identity',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: s(17), color: textColor)),
                    SizedBox(height: s(6)),
                    Text(
                      'Paystack requires these details to issue a dedicated account number, as required by CBN regulation. This is used only for verification and is never shared.',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: s(12), height: 1.4),
                    ),
                    SizedBox(height: s(16)),

                    TextFormField(
                      controller: firstNameController,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.deepOrange),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(s(12))),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'First name is required';
                        return null;
                      },
                    ),
                    SizedBox(height: s(12)),

                    TextFormField(
                      controller: lastNameController,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Last Name',
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.deepOrange),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(s(12))),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Last name is required';
                        return null;
                      },
                    ),
                    SizedBox(height: s(12)),

                    TextFormField(
                      controller: bvnController,
                      keyboardType: TextInputType.number,
                      maxLength: 11,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'BVN (11 digits)',
                        counterText: '',
                        prefixIcon: const Icon(Icons.badge_outlined, color: Colors.deepOrange),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(s(12))),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'BVN is required';
                        if (!RegExp(r'^\d{11}$').hasMatch(v.trim())) return 'BVN must be exactly 11 digits';
                        return null;
                      },
                    ),
                    SizedBox(height: s(20)),

                    SizedBox(
                      width: double.infinity,
                      height: s(48),
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(sheetContext, true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(s(14))),
                        ),
                        child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      _generateVirtualAccount(
        firstName: firstNameController.text.trim(),
        lastName:  lastNameController.text.trim(),
        bvn:       bvnController.text.trim(),
      );
    }
  }

  // ── Fetch current account status ────────────────────────────────────────
  // silent: true suppresses the full-screen loader (used while polling)
  Future<void> _fetchVirtualAccount({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final user = context.read<UserProvider>().user;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('https://glopa.org/glo/get_virtual_account.php?user_id=${user.userId}'),
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;

      setState(() {
        _loading = false;
        switch (data['status']) {
          case 'success':
            _virtualAccount = _normalizeAccount(data['data']);
            _pending = false;
            _pollTimer?.cancel();
            break;
          case 'pending':
            _virtualAccount = null;
            _pending = true;
            _startPollingIfNeeded();
            break;
          default: // 'not_found', 'failed', 'error'
            _virtualAccount = null;
            _pending = false;
            _pollTimer?.cancel();
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Guards against null fields so _detailRow never gets a null String.
  Map<String, dynamic> _normalizeAccount(Map<String, dynamic> raw) => {
    'bank_name':      raw['bank_name']?.toString()      ?? '',
    'account_name':   raw['account_name']?.toString()   ?? '',
    'account_number': raw['account_number']?.toString() ?? '',
  };

  void _startPollingIfNeeded() {
    if (_pollTimer != null && _pollTimer!.isActive) return;
    int ticks = 0;
    _pollTimedOut = false;
    _pollTimer = Timer.periodic(_pollInterval, (timer) async {
      ticks++;
      await _fetchVirtualAccount(silent: true);
      if (!mounted || !_pending || ticks >= _maxPollTicks) {
        timer.cancel();
        if (mounted && _pending) {
          setState(() => _pollTimedOut = true);
        }
      }
    });
  }

  // ── Kick off generation ─────────────────────────────────────────────────
  Future<void> _generateVirtualAccount({
    required String firstName,
    required String lastName,
    required String bvn,
  }) async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    setState(() => _generating = true);
    try {
      final res = await http.post(
        Uri.parse('https://glopa.org/glo/generate_virtual_account.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id':    user.userId,
          'first_name': firstName,
          'last_name':  lastName,
          'bvn':        bvn,
        }),
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;

      switch (data['status']) {
        case 'success':
          setState(() {
            _virtualAccount = _normalizeAccount(data['data']);
            _pending = false;
          });
          break;
        case 'pending':
          setState(() => _pending = true);
          _snack(data['message'] ?? 'Setting up your account…');
          _startPollingIfNeeded();
          break;
        default:
          _snack(data['message'] ?? 'Could not generate account.', isError: true);
      }
    } catch (_) {
      _snack('Network error. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _copyAccountNumber() {
    final number = _virtualAccount?['account_number'] as String?;
    if (number == null || number.isEmpty) return;
    Clipboard.setData(ClipboardData(text: number));
    _snack('Account number copied.');
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF7F7F7);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final balance = context.watch<UserBalance>().balance;
    final formatter = NumberFormat("#,##0.00", "en_US");

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Wallet',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: s(18))),
      ),
      body: RefreshIndicator(
        color: Colors.deepOrange,
        onRefresh: () => _fetchVirtualAccount(),
        child: ListView(
          padding: EdgeInsets.all(s(20)),
          children: [
            // ── Balance card ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(s(20)),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.deepOrange, Color(0xFFFF8A50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(s(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available Balance',
                      style: TextStyle(color: Colors.white70, fontSize: s(13))),
                  SizedBox(height: s(6)),
                  Text('${CurrencyConfig().symbol}${formatter.format(balance)}',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: s(28),
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),

            SizedBox(height: s(24)),

            Text('Fund via Bank Transfer',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: s(15), color: textColor)),
            SizedBox(height: s(6)),
            Text(
              'Get a dedicated account number to fund your wallet anytime — no need to generate a new one each time.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: s(12)),
            ),
            SizedBox(height: s(14)),

            if (_loading)
              const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
            else if (_virtualAccount != null)
              _buildVirtualAccountCard(cardColor, textColor)
            else if (_pending)
                _buildPendingCard(cardColor, textColor)
              else
                _buildGenerateCard(cardColor, textColor),

            SizedBox(height: s(24)),

            Text('More Ways to Fund',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: s(15), color: textColor)),
            SizedBox(height: s(10)),
            _fundOptionTile(
              icon: Icons.credit_card,
              title: 'Debit Card / USSD',
              subtitle: 'Instant top-up via Paystack',
              cardColor: cardColor,
              textColor: textColor,
              onTap: () {
                // Hook up to your existing wallet-topup flow (Paystack)
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVirtualAccountCard(Color cardColor, Color textColor) {
    return Container(
      padding: EdgeInsets.all(s(16)),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(s(16)),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('Bank', _virtualAccount!['bank_name'] as String, textColor),
          SizedBox(height: s(10)),
          _detailRow('Account Name', _virtualAccount!['account_name'] as String, textColor),
          SizedBox(height: s(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _detailRow('Account Number', _virtualAccount!['account_number'] as String, textColor)),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.deepOrange, size: 20),
                onPressed: _copyAccountNumber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: s(12))),
        SizedBox(height: s(2)),
        Text(value.isEmpty ? '—' : value,
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.bold, fontSize: s(15))),
      ],
    );
  }

  Widget _buildPendingCard(Color cardColor, Color textColor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s(20)),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(s(16)),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          if (!_pollTimedOut) ...[
            const SizedBox(
              width: 32, height: 32,
              child: CircularProgressIndicator(color: Colors.deepOrange, strokeWidth: 2.5),
            ),
            SizedBox(height: s(12)),
            Text('Setting up your account…',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: s(15), color: textColor)),
            SizedBox(height: s(6)),
            Text(
              'This usually takes a few seconds. We\'ll show your details here automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: s(12)),
            ),
          ] else ...[
            Icon(Icons.hourglass_disabled, size: s(36), color: Colors.grey),
            SizedBox(height: s(12)),
            Text('This is taking longer than usual',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: s(15), color: textColor)),
            SizedBox(height: s(6)),
            Text(
              'Tap below to check again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: s(12)),
            ),
            SizedBox(height: s(14)),
            TextButton(
              onPressed: () => _fetchVirtualAccount(),
              child: const Text('Check Again', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenerateCard(Color cardColor, Color textColor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s(20)),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(s(16)),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.account_balance, size: s(40), color: Colors.deepOrange),
          SizedBox(height: s(12)),
          Text('No virtual account yet',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: s(15), color: textColor)),
          SizedBox(height: s(6)),
          Text(
            'Generate one to start funding your wallet by bank transfer.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: s(12)),
          ),
          SizedBox(height: s(16)),
          SizedBox(
            width: double.infinity,
            height: s(48),
            child: ElevatedButton(
              onPressed: _generating ? null : _showBvnDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(s(14))),
              ),
              child: _generating
                  ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Generate Virtual Account', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fundOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color cardColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: s(10)),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(s(14)),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepOrange, size: s(24)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: s(14))),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: s(12))),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: s(14), color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}