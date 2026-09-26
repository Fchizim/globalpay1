import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/user_model.dart';
import '../provider/user_provider.dart';
import '../services/profile_service.dart';
import '../services/secure_storage_service.dart';
import 'bet_history_screen.dart';
import 'package:provider/provider.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
class BetProvider {
  final String name;
  final String icon;
  final int planId;

  const BetProvider({
    required this.name,
    required this.icon,
    required this.planId,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class BetScreen extends StatefulWidget {
  const BetScreen({super.key});

  @override
  State<BetScreen> createState() => _BetScreenState();
}

class _BetScreenState extends State<BetScreen> {
  final NumberFormat _numFormat = NumberFormat.decimalPattern('en_US');
  UserModel? get _user => context.read<UserProvider>().user;
  String get userId => _user?.userId ?? '';

  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // ── Providers ─────────────────────────────────────────────────────────────
  List<BetProvider> _allProviders = [];
  List<BetProvider> _filteredProviders = [];
  BetProvider? _selectedProvider;
  bool _isLoadingProviders = false;
  String? _providersError;
  bool _showProviders = false;

  // ── Validation ────────────────────────────────────────────────────────────
  bool _isValidating = false;
  bool _isAccountValid = false;
  String? _accountError;
  String? _accountName;

  // ── Amount presets ─────────────────────────────────────────────────────────
  final List<int> _presets = [100, 200, 500, 1000, 2000, 5000];
  int? _selectedPreset;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchBettingProviders();
  }

  @override
  void dispose() {
    _accountController.dispose();
    _amountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Fetch providers ────────────────────────────────────────────────────────
  Future<void> _fetchBettingProviders() async {
    setState(() {
      _isLoadingProviders = true;
      _providersError = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse('https://glopa.org/glo/get_plans.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'fetch': 'BETTING'}),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.body.isEmpty) {
        setState(() => _providersError = 'Empty response. Please try again.');
        return;
      }

      final decoded = jsonDecode(response.body);
      final status = (decoded['status'] ?? '').toString().toLowerCase();

      if (status == 'successful') {
        final List data = decoded['data'] ?? [];
        final providers = data
            .where((p) => p['availability'] == true)
            .map(
              (p) => BetProvider(
                name: p['name'].toString(),
                icon: p['icon'].toString(),
                planId: int.tryParse(p['planID'].toString()) ?? 0,
              ),
            )
            .toList();

        setState(() {
          _allProviders = providers;
          _filteredProviders = List.from(providers);
          _selectedProvider = providers.isNotEmpty ? providers.first : null;
        });
      } else {
        setState(
          () => _providersError =
              (decoded['message'] ?? 'Could not load providers.').toString(),
        );
      }
    } on TimeoutException {
      if (mounted)
        setState(
          () => _providersError = 'Request timed out. Please try again.',
        );
    } catch (e) {
      if (mounted)
        setState(
          () => _providersError = 'Network error. Check your connection.',
        );
    } finally {
      if (mounted) setState(() => _isLoadingProviders = false);
    }
  }

  // ── Validate betting account ───────────────────────────────────────────────
  Future<void> _validateAccount() async {
    final account = _accountController.text.trim();
    if (account.isEmpty) {
      setState(() => _accountError = 'Please enter your account ID');
      return;
    }
    if (_selectedProvider == null) return;

    setState(() {
      _isValidating = true;
      _accountError = null;
      _isAccountValid = false;
      _accountName = null;
    });

    try {
      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          final response = await http
              .post(
                Uri.parse('https://glopa.org/glo/validate_bet.php'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  "plan_id": _selectedProvider!.planId.toString(),
                  "number": account,
                }),
              )
              .timeout(const Duration(seconds: 30));

          if (!mounted) return;

          print("STATUS CODE: ${response.statusCode}");
          print("RAW BODY: ${response.body}");

          final data = jsonDecode(response.body);
          final status = (data['status'] ?? '').toString().toLowerCase();

          if (status == 'successful' || status == 'success') {
            final rawName = data['data']?['name'] ?? data['name'] ?? '';
            setState(() {
              _isAccountValid = true;
              _accountName =
                  (rawName.isEmpty || rawName.toUpperCase() == 'SUCCESS')
                  ? 'Account Verified ✓' // friendly fallback
                  : rawName;
              _accountError = null;
            });
            return;
          } else {
            setState(() {
              _isAccountValid = false;
              _accountError = data['message'] ?? 'Invalid account ID';
            });
            return;
          }
        } on TimeoutException {
          if (attempt == 2) {
            setState(
              () => _accountError = 'Validation timed out. Please try again.',
            );
          } else {
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _accountError = 'Network error. Check your connection.');
      }
    } finally {
      // ← this ALWAYS runs, even on early return or exception
      if (mounted) setState(() => _isValidating = false);
    }
  }

  // ── Fund betting wallet ────────────────────────────────────────────────────
  Future<void> _fundBet() async {
    if (!_isAccountValid) {
      setState(() => _accountError = 'Please verify your account first');
      return;
    }
    if (_selectedProvider == null) return;

    final rawAmount = _amountController.text.trim().replaceAll(',', '');
    final amount = int.tryParse(rawAmount) ?? 0;
    final account = _accountController.text.trim();

    if (account.isEmpty) {
      _showSnack('Please enter your account ID');
      return;
    }
    if (amount < 100) {
      _showSnack('Minimum funding amount is ₦100');
      return;
    }

    final userId = context.read<UserProvider>().user?.userId ?? '';
    if (userId.isEmpty) {
      _showSnack('Session expired. Please login again.');
      return;
    }

    BuildContext? loaderCtx;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) {
        loaderCtx = c;
        return const Center(child: CircularProgressIndicator());
      },
    );
    await Future.microtask(() {});

    try {
      final response = await http
          .post(
            Uri.parse('https://glopa.org/glo/buy_utility.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "user_id": userId,
              "action": "BETTING",
              "plan_id": _selectedProvider!.planId.toString(),
              "number": account,
              "amount": amount,
              "network": _selectedProvider!.name,
            }),
          )
          .timeout(const Duration(seconds: 30));

      _dismissLoader(loaderCtx);
      if (!mounted) return;

      final data = jsonDecode(response.body);
      final status = (data['status'] ?? '').toString();
      final code = (data['code'] ?? '').toString();
      final message =
          (data['message'] ?? 'Transaction failed. Please try again.')
              .toString();

      if (status == 'success') {
        final userProvider = context.read<UserProvider>();
        final localUser = await SecureStorageService.getUser();
        if (localUser != null) {
          final freshUser = await ProfileService.getProfile(localUser.userId);
          if (freshUser != null) await userProvider.updateUser(freshUser);
        }

        _showResultDialog(
          icon: Icons.check_circle_rounded,
          iconColor: Colors.green,
          title: 'Funding Successful',
          message: message,
        );
        setState(() {
          _accountController.clear();
          _amountController.clear();
          _selectedPreset = null;
          _isAccountValid = false;
          _accountName = null;
        });
      } else if (status == 'pending') {
        final userProvider = context.read<UserProvider>();
        final localUser = await SecureStorageService.getUser();
        if (localUser != null) {
          final freshUser = await ProfileService.getProfile(localUser.userId);
          if (freshUser != null) await userProvider.updateUser(freshUser);
        }
        _showResultDialog(
          icon: Icons.hourglass_bottom_rounded,
          iconColor: Colors.orange,
          title: 'Transaction Processing',
          message:
              'Your funding is being processed. You will be notified once confirmed.',
        );
      } else if (code == 'INSUFFICIENT_BALANCE') {
        final userProvider = context.read<UserProvider>();
        final localUser = await SecureStorageService.getUser();
        if (localUser != null) {
          final freshUser = await ProfileService.getProfile(localUser.userId);
          if (freshUser != null) await userProvider.updateUser(freshUser);
        }
        _showResultDialog(
          icon: Icons.account_balance_wallet_outlined,
          iconColor: Colors.deepOrange,
          title: 'Insufficient Balance',
          message: message,
        );
      } else {
        _showResultDialog(
          icon: Icons.cancel_outlined,
          iconColor: Colors.red,
          title: 'Transaction Failed',
          message: message,
        );
      }
    } on TimeoutException {
      _dismissLoader(loaderCtx);
      _showSnack('Request timed out. Please try again.');
    } catch (e) {
      _dismissLoader(loaderCtx);
      _showSnack('Network error. Check your connection.');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _dismissLoader(BuildContext? ctx) {
    if (mounted && ctx != null) {
      try {
        Navigator.of(ctx).pop();
      } catch (_) {}
    }
  }

  void _showResultDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.deepOrange)),
          ),
        ],
      ),
    );
  }

  void _filterProviders(String query) {
    setState(() {
      _filteredProviders = _allProviders
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _setPreset(int amount) {
    setState(() {
      _selectedPreset = amount;
      _amountController.text = amount.toString();
    });
  }

  bool _canProceed() {
    final raw = _amountController.text.trim().replaceAll(',', '');
    final amount = int.tryParse(raw) ?? 0;
    return _isAccountValid && amount >= 100 && _selectedProvider != null;
  }

  String _buttonLabel() {
    if (!_isAccountValid) return 'Verify Account to Continue';
    final raw = _amountController.text.trim().replaceAll(',', '');
    final amount = int.tryParse(raw) ?? 0;
    if (amount < 100) return 'Enter Amount to Continue';
    return 'Fund ₦${_numFormat.format(amount)} → ${_selectedProvider?.name ?? ''}';
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF121212)
        : Colors.grey.shade100;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final fillColor = isDark ? Colors.grey[850]! : Colors.grey[100]!;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[700]!;

    // Screen-size aware scaling so this page and its cards look right on
    // small and large phones/tablets instead of using fixed pixel values.
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scale = (screenWidth / 390.0).clamp(0.85, 1.15);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Betting Wallet Funding',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BetHistoryScreen()),
            ),
            child: const Text(
              'History',
              style: TextStyle(color: Colors.deepOrange),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16 * scale),
        child: ConstrainedBox(
          // Keeps the whole form centered and capped in width on
          // tablets/large screens instead of stretching edge-to-edge.
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Providers error ────────────────────────────────────────────
              if (_providersError != null)
                Container(
                  margin: EdgeInsets.only(bottom: 12 * scale),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14 * scale,
                    vertical: 12 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        color: Colors.red,
                        size: 18 * scale,
                      ),
                      SizedBox(width: 10 * scale),
                      Expanded(
                        child: Text(
                          _providersError!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12 * scale,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _fetchBettingProviders,
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: 13 * scale,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Provider selector ──────────────────────────────────────────
              if (_isLoadingProviders)
                Container(
                  padding: EdgeInsets.all(20 * scale),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                )
              else if (_selectedProvider != null)
                GestureDetector(
                  onTap: () => setState(() => _showProviders = !_showProviders),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16 * scale,
                      vertical: 16 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    // FIX: the provider name had no Expanded/overflow, so a
                    // long provider name could push the chevron icon off
                    // the edge or overflow the row on narrow screens.
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.network(
                            _selectedProvider!.icon,
                            width: 44 * scale,
                            height: 44 * scale,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => CircleAvatar(
                              radius: 22 * scale,
                              backgroundColor: Colors.deepOrange.withOpacity(
                                0.1,
                              ),
                              child: Text(
                                _selectedProvider!.name[0],
                                style: TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12 * scale),
                        Expanded(
                          child: Text(
                            _selectedProvider!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 16 * scale,
                            ),
                          ),
                        ),
                        SizedBox(width: 8 * scale),
                        Icon(
                          _showProviders
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: secondaryTextColor,
                          size: 28 * scale,
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 12 * scale),

              // ── Provider dropdown ──────────────────────────────────────────
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(12 * scale),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterProviders,
                          style: TextStyle(fontSize: 14 * scale),
                          decoration: InputDecoration(
                            hintText: 'Search Betting Platform',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: fillColor,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                            ),
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredProviders.length,
                          itemBuilder: (context, index) {
                            final provider = _filteredProviders[index];
                            final isSelected =
                                _selectedProvider?.planId == provider.planId;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedProvider = provider;
                                  _showProviders = false;
                                  _searchController.clear();
                                  _filteredProviders = List.from(_allProviders);
                                  // ── reset validation on provider change ──
                                  _isAccountValid = false;
                                  _accountName = null;
                                  _accountError = null;
                                  _accountController.clear();
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 12 * scale,
                                  horizontal: 16 * scale,
                                ),
                                margin: EdgeInsets.symmetric(
                                  vertical: 4 * scale,
                                  horizontal: 8 * scale,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.deepOrange.withOpacity(0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        provider.icon,
                                        width: 40 * scale,
                                        height: 40 * scale,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            CircleAvatar(
                                              radius: 20 * scale,
                                              backgroundColor: Colors.deepOrange
                                                  .withOpacity(0.1),
                                              child: Text(
                                                provider.name[0],
                                                style: TextStyle(
                                                  color: Colors.deepOrange,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 12 * scale),
                                    Expanded(
                                      child: Text(
                                        provider.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15 * scale,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      isSelected
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      color: isSelected
                                          ? Colors.deepOrange
                                          : secondaryTextColor,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                crossFadeState: _showProviders
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
              SizedBox(height: 24 * scale),

              // ── Main form card ─────────────────────────────────────────────
              Container(
                padding: EdgeInsets.all(16 * scale),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Account ID + Verify button ───────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _accountController,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                            keyboardType: TextInputType.text,
                            onChanged: (_) => setState(() {
                              _isAccountValid = false;
                              _accountName = null;
                              _accountError = null;
                            }),
                            decoration: InputDecoration(
                              labelText:
                                  'Enter ${_selectedProvider?.name ?? 'Platform'} User ID',
                              labelStyle: TextStyle(
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                              filled: true,
                              fillColor: fillColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 18 * scale,
                                horizontal: 16 * scale,
                              ),
                              suffixIcon: _isAccountValid
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        SizedBox(width: 8 * scale),
                        SizedBox(
                          height: 56 * scale,
                          child: ElevatedButton(
                            onPressed: _isValidating ? null : _validateAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isValidating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Verify',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14 * scale,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),

                    // ── Account error ────────────────────────────────────────
                    if (_accountError != null)
                      Padding(
                        padding: EdgeInsets.only(
                          top: 6 * scale,
                          left: 4 * scale,
                        ),
                        child: Text(
                          _accountError!,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12 * scale,
                          ),
                        ),
                      ),

                    // ── Account holder name ──────────────────────────────────
                    if (_accountName != null)
                      Container(
                        margin: EdgeInsets.only(top: 10 * scale),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12 * scale,
                          vertical: 10 * scale,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        // FIX: account name had no Expanded/overflow, so a
                        // long verified name could overflow the pill.
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              color: Colors.green,
                              size: 16,
                            ),
                            SizedBox(width: 6 * scale),
                            Expanded(
                              child: Text(
                                _accountName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13 * scale,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: 16 * scale),

                    // ── Warning note ─────────────────────────────────────────
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12 * scale,
                        vertical: 10 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_outlined,
                            color: Colors.orange,
                            size: 16,
                          ),
                          SizedBox(width: 8 * scale),
                          Expanded(
                            child: Text(
                              'Please confirm your ${_selectedProvider?.name ?? ''} account ID is correct. Funding a wrong account cannot be reversed.',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 11 * scale,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24 * scale),

                    // ── Amount ───────────────────────────────────────────────
                    Text(
                      'Enter Amount',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15 * scale,
                      ),
                    ),
                    SizedBox(height: 12 * scale),

                    TextField(
                      controller: _amountController,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() => _selectedPreset = null),
                      decoration: InputDecoration(
                        labelText: 'Amount (₦)',
                        labelStyle: TextStyle(
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: fillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 18 * scale,
                          horizontal: 16 * scale,
                        ),
                        prefixText: '₦ ',
                        prefixStyle: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 12 * scale),

                    // ── Amount presets ───────────────────────────────────────
                    Wrap(
                      spacing: 8 * scale,
                      runSpacing: 8 * scale,
                      children: _presets.map((amount) {
                        final isSelected = _selectedPreset == amount;
                        return GestureDetector(
                          onTap: () => _setPreset(amount),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16 * scale,
                              vertical: 10 * scale,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.deepOrange : fillColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.deepOrange
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              '₦${_numFormat.format(amount)}',
                              style: TextStyle(
                                color: isSelected ? Colors.white : textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13 * scale,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 24 * scale),

                    // ── Summary ──────────────────────────────────────────────
                    if (_isAccountValid &&
                        _amountController.text.trim().isNotEmpty)
                      Builder(
                        builder: (_) {
                          final raw = _amountController.text.trim().replaceAll(
                            ',',
                            '',
                          );
                          final amount = int.tryParse(raw) ?? 0;
                          if (amount <= 0) return const SizedBox.shrink();
                          return Container(
                            margin: EdgeInsets.only(bottom: 16 * scale),
                            padding: EdgeInsets.all(14 * scale),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.deepOrange.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                _summaryRow(
                                  'Platform',
                                  _selectedProvider?.name ?? '',
                                  textColor,
                                  secondaryTextColor,
                                  scale,
                                ),
                                SizedBox(height: 6 * scale),
                                _summaryRow(
                                  'Account ID',
                                  _accountController.text.trim(),
                                  textColor,
                                  secondaryTextColor,
                                  scale,
                                ),
                                if (_accountName != null) ...[
                                  SizedBox(height: 6 * scale),
                                  _summaryRow(
                                    'Account Name',
                                    _accountName!,
                                    Colors.green,
                                    secondaryTextColor,
                                    scale,
                                    valueColor: Colors.green,
                                  ),
                                ],
                                SizedBox(height: 6 * scale),
                                _summaryRow(
                                  'Amount',
                                  '₦${_numFormat.format(amount)}',
                                  Colors.deepOrange,
                                  secondaryTextColor,
                                  scale,
                                  valueColor: Colors.deepOrange,
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    // ── Fund button ──────────────────────────────────────────
                    // FIX: label combines an amount + provider name and had
                    // no maxLines/overflow guard — a long provider name
                    // could wrap awkwardly or, on very narrow screens,
                    // crowd the button. FittedBox lets it scale down if
                    // needed instead of visually breaking.
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _canProceed() ? _fundBet : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canProceed()
                              ? Colors.deepOrange
                              : Colors.grey.shade400,
                          padding: EdgeInsets.symmetric(
                            vertical: 18 * scale,
                            horizontal: 12 * scale,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: _canProceed() ? 6 : 0,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _buttonLabel(),
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16 * scale,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FIX: label/value were bare Text widgets in a spaceBetween Row with no
  // Expanded/Flexible, so a long account ID/name could overflow.
  Widget _summaryRow(
    String label,
    String value,
    Color textColor,
    Color labelColor,
    double scale, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: labelColor, fontSize: 12 * scale),
        ),
        SizedBox(width: 12 * scale),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? textColor,
              fontWeight: FontWeight.w600,
              fontSize: 13 * scale,
            ),
          ),
        ),
      ],
    );
  }
}
