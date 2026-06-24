import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:globalpay/home/tv_history.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../provider/user_provider.dart';
import '../services/profile_service.dart';
import '../services/secure_storage_service.dart';
// import 'tv_history_screen.dart';

// ─── Models ───────────────────────────────────────────────────────────────────
class CableProvider {
  final String name;
  final String logo;
  final String planId;
  bool isSelected;

  CableProvider({
    required this.name,
    required this.logo,
    required this.planId,
    this.isSelected = false,
  });
}

class CablePlan {
  final String planId;
  final String name;
  final String amount;
  final String validity;

  const CablePlan({
    required this.planId,
    required this.name,
    required this.amount,
    required this.validity,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class TvScreen extends StatefulWidget {
  const TvScreen({super.key});

  @override
  State<TvScreen> createState() => _TvScreenState();
}

class _TvScreenState extends State<TvScreen> {
  final NumberFormat _numFormat = NumberFormat.decimalPattern('en_US');

  UserModel? get _user => context.read<UserProvider>().user;
  String get _userId => _user?.userId ?? '';

  final TextEditingController _smartCardController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // ── Providers (built dynamically) ─────────────────────────────────────────
  List<CableProvider> providers = [];
  List<CableProvider> filteredProviders = [];
  bool showProviders = false;
  bool _loadingProviders = true;
  String? _providerError;

  // ── Plans ──────────────────────────────────────────────────────────────────
  Map<String, List<CablePlan>> _plansByProvider = {};
  List<CablePlan> _allPlans = [];
  CablePlan? _selectedPlan;
  bool _isLoadingPlans = true;
  String? _plansError;

  // ── Validation ────────────────────────────────────────────────────────────
  bool _isValidating = false;
  bool _isCardValid = false;
  String? _cardError;
  String? _customerName;

  CableProvider? get _selectedProvider => providers.isEmpty
      ? null
      : providers.firstWhere((p) => p.isSelected, orElse: () => providers.first);

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchAllPlans();
  }

  @override
  void dispose() {
    _smartCardController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Fetch all cable plans + build providers dynamically ───────────────────
  Future<void> _fetchAllPlans() async {
    setState(() {
      _loadingProviders = true;
      _isLoadingPlans = true;
      _providerError = null;
      _plansError = null;
    });

    try {
      final response = await http
          .post(
        Uri.parse('https://glopa.org/glo/get_plans.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fetch': 'CABLE'}),
      )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;
      if (response.body.isEmpty) {
        setState(() {
          _providerError = 'Empty response. Tap to retry.';
          _plansError = 'Empty response. Please try again.';
          _loadingProviders = false;
          _isLoadingPlans = false;
        });
        return;
      }

      final decoded = jsonDecode(response.body);
      final status = (decoded['status'] ?? '').toString().toLowerCase();

      if (status == 'successful') {
        final List data = decoded['data'] ?? [];

        final List<CableProvider> loadedProviders = [];
        final Map<String, List<CablePlan>> plansMap = {};

        for (final group in data) {
          if (group['availability'] != true) continue;

          final providerPlanId = group['planID'].toString();
          final name = group['name'].toString();
          final logo = group['icon'].toString();

          loadedProviders.add(CableProvider(
            name: name,
            logo: logo,
            planId: providerPlanId,
          ));

          final List options = group['options'] ?? [];
          plansMap[providerPlanId] = options
              .map<CablePlan>((opt) => CablePlan(
            planId: opt['planID'].toString(),
            name: opt['package'].toString(),
            amount: opt['price'].toString(),
            validity: opt['validation']?.toString() ?? '30 days',
          ))
              .toList();
        }

        if (loadedProviders.isNotEmpty) loadedProviders[0].isSelected = true;

        setState(() {
          providers = loadedProviders;
          filteredProviders = List.from(loadedProviders);
          _plansByProvider = plansMap;
          _allPlans = plansMap[loadedProviders[0].planId] ?? [];
          _loadingProviders = false;
          _isLoadingPlans = false;
        });
      } else {
        final msg = (decoded['message'] ?? 'Could not load plans.').toString();
        setState(() {
          _providerError = msg;
          _plansError = msg;
          _loadingProviders = false;
          _isLoadingPlans = false;
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _providerError = 'Request timed out. Tap to retry.';
          _plansError = 'Request timed out. Please try again.';
          _loadingProviders = false;
          _isLoadingPlans = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _providerError = 'Network error. Tap to retry.';
          _plansError = 'Network error. Check your connection.';
          _loadingProviders = false;
          _isLoadingPlans = false;
        });
      }
    }
  }

  // ── Switch provider plans from cached map ─────────────────────────────────
  void _switchProvider(CableProvider provider) {
    setState(() {
      for (var p in providers) p.isSelected = false;
      provider.isSelected = true;
      showProviders = false;
      _searchController.clear();
      filteredProviders = List.from(providers);
      _isCardValid = false;
      _customerName = null;
      _cardError = null;
      _selectedPlan = null;
      _allPlans = _plansByProvider[provider.planId] ?? [];
    });
  }

  // ── Validate smart card ───────────────────────────────────────────────────
  Future<void> _validateSmartCard() async {
    final card = _smartCardController.text.trim();
    if (card.isEmpty) {
      setState(() => _cardError = 'Please enter your smart card number');
      return;
    }
    if (_selectedProvider == null) return;

    setState(() {
      _isValidating = true;
      _cardError = null;
      _isCardValid = false;
      _customerName = null;
    });

    try {
      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          final response = await http
              .post(
            Uri.parse('https://glopa.org/glo/validate_cable.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "plan_id": _selectedProvider!.planId,
              "number": card,
            }),
          )
              .timeout(const Duration(seconds: 30));

          if (!mounted) return;
          if (response.body.isEmpty) {
            setState(() => _cardError = 'Empty response. Please try again.');
            return;
          }

          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final status = (data['status'] ?? '').toString().toLowerCase();

          if (status == 'success') {
            setState(() {
              _isCardValid = true;
              _customerName = (data['name'] ?? 'Customer').toString();
              _cardError = null;
            });
            return;
          } else {
            setState(() {
              _isCardValid = false;
              _cardError = (data['message'] ?? 'Invalid smart card number').toString();
            });
            return;
          }
        } on TimeoutException {
          if (attempt == 2) {
            if (mounted) setState(() => _cardError = 'Validation timed out. Please try again.');
          } else {
            await Future.delayed(const Duration(seconds: 2));
          }
        } on FormatException {
          if (mounted) setState(() => _cardError = 'Unexpected server response. Please try again.');
          return;
        } catch (e) {
          if (mounted) setState(() => _cardError = 'Network error. Check your connection.');
          return;
        }
      }
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  // ── Refresh the cached user (wallet balance etc.) from the server ─────────
  // Extracted from the 3x-repeated block in BetScreen's _fundBet().
  Future<void> _refreshUser() async {
    final userProvider = context.read<UserProvider>();
    final localUser = await SecureStorageService.getUser();
    if (localUser != null) {
      final freshUser = await ProfileService.getProfile(localUser.userId);
      if (freshUser != null) await userProvider.updateUser(freshUser);
    }
  }

  // ── Buy cable ─────────────────────────────────────────────────────────────
  Future<void> _buyCable() async {
    if (!_isCardValid) {
      setState(() => _cardError = 'Please verify your smart card first');
      return;
    }
    if (_selectedPlan == null) {
      _showSnack('Please select a plan');
      return;
    }

    final userId = _userId;
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
          "action": "CABLE",
          "plan_id": _selectedPlan!.planId,
          "number": _smartCardController.text.trim(),
          "amount": double.tryParse(_selectedPlan!.amount)?.toInt() ?? 0,
          "network": _selectedProvider!.name,
        }),
      )
          .timeout(const Duration(seconds: 30));

      _dismissLoader(loaderCtx);
      if (!mounted) return;

      final data = jsonDecode(response.body);
      final status = (data['status'] ?? '').toString();
      final code = (data['code'] ?? '').toString();
      final message = (data['message'] ?? 'Transaction failed. Please try again.').toString();

      if (status == 'success') {
        await _refreshUser();
        _showResultDialog(
          icon: Icons.check_circle_rounded,
          iconColor: Colors.green,
          title: 'Subscription Successful',
          message: message,
        );
        setState(() {
          _isCardValid = false;
          _customerName = null;
          _smartCardController.clear();
          _selectedPlan = null;
        });
      } else if (status == 'pending') {
        await _refreshUser();
        _showResultDialog(
          icon: Icons.hourglass_bottom_rounded,
          iconColor: Colors.orange,
          title: 'Transaction Processing',
          message: 'Your subscription is being processed. You will be notified once confirmed.',
        );
      } else if (code == 'INSUFFICIENT_BALANCE') {
        await _refreshUser();
        _showResultDialog(
          icon: Icons.account_balance_wallet_outlined,
          iconColor: Colors.deepOrange,
          title: 'Insufficient Balance',
          message: message,
        );
      } else {
        await _refreshUser();
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

  // ── Helpers ───────────────────────────────────────────────────────────────
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
        title: Row(children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ]),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.deepOrange)),
          ),
        ],
      ),
    );
  }

  void _filterProviders(String query) {
    setState(() {
      filteredProviders =
          providers.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  Widget _providerAvatar(String logoUrl, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      child: ClipOval(
        child: Image.network(
          logoUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.tv_outlined,
            size: radius,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey.shade100;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final fillColor = isDark ? Colors.grey[850]! : Colors.grey[100]!;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[700]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text('TV Subscription', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BillHistoryScreen(
                  action: 'CABLE',
                  title:  'Cable History',
                )
                )
                ),
            child: const Text('History', style: TextStyle(color: Colors.deepOrange)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Provider selector ────────────────────────────────────────
            GestureDetector(
              onTap: _loadingProviders
                  ? null
                  : _providerError != null
                  ? _fetchAllPlans
                  : () => setState(() => showProviders = !showProviders),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: _loadingProviders
                    ? const Row(children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text('Loading providers...'),
                ])
                    : _providerError != null
                    ? Row(children: [
                  const Icon(Icons.refresh, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(_providerError!, style: const TextStyle(color: Colors.red)),
                ])
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      _providerAvatar(_selectedProvider!.logo, 22),
                      const SizedBox(width: 12),
                      Text(_selectedProvider!.name,
                          style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 16)),
                    ]),
                    Icon(showProviders ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: secondaryTextColor, size: 28),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Provider dropdown ────────────────────────────────────────
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterProviders,
                      decoration: InputDecoration(
                        hintText: 'Search Provider',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: fillColor,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredProviders.length,
                      itemBuilder: (context, index) {
                        final provider = filteredProviders[index];
                        return GestureDetector(
                          onTap: () => _switchProvider(provider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: provider.isSelected
                                  ? Colors.deepOrange.withOpacity(0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(children: [
                              _providerAvatar(provider.logo, 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(provider.name,
                                    style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 15)),
                              ),
                              Icon(
                                provider.isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                color: provider.isSelected ? Colors.deepOrange : secondaryTextColor,
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ]),
              ),
              crossFadeState: showProviders ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
            const SizedBox(height: 24),

            // ── Main form card ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Smart card input + Verify ────────────────────────
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _smartCardController,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                        keyboardType: TextInputType.text,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))],
                        onChanged: (_) => setState(() {
                          _isCardValid = false;
                          _customerName = null;
                          _cardError = null;
                        }),
                        decoration: InputDecoration(
                          labelText: 'Enter Smart Card / IUC Number',
                          labelStyle: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w500),
                          filled: true,
                          fillColor: fillColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                          suffixIcon: _isCardValid ? const Icon(Icons.check_circle, color: Colors.green) : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isValidating ? null : _validateSmartCard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isValidating
                            ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Verify', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),

                  if (_cardError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(_cardError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),

                  if (_customerName != null)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.person_outline, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        Text(_customerName!,
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13)),
                      ]),
                    ),

                  const SizedBox(height: 24),

                  Text('Select Plan', style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 12),

                  if (_isLoadingPlans)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  else if (_plansError != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(_plansError!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _fetchAllPlans,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ]),
                      ),
                    )
                  else if (_allPlans.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('No plans available.', style: TextStyle(color: Colors.grey.shade500)),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _allPlans.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (_, i) {
                          final plan = _allPlans[i];
                          final isSelected = _selectedPlan?.planId == plan.planId;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedPlan = plan),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.deepOrange.withOpacity(0.08) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? Colors.deepOrange : Colors.grey.shade200,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  color: isSelected ? Colors.deepOrange : Colors.grey.shade400,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(plan.name,
                                          style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Text(plan.validity, style: TextStyle(color: secondaryTextColor, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₦${_numFormat.format(double.tryParse(plan.amount)?.toInt() ?? 0)}',
                                  style:
                                  const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ]),
                            ),
                          );
                        },
                      ),

                  const SizedBox(height: 24),

                  if (_selectedPlan != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.deepOrange.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Selected Plan', style: TextStyle(color: secondaryTextColor, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(_selectedPlan!.name,
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                          Text(
                            '₦${_numFormat.format(double.tryParse(_selectedPlan!.amount)?.toInt() ?? 0)}',
                            style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isCardValid && _selectedPlan != null) ? _buyCable : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        (_isCardValid && _selectedPlan != null) ? Colors.deepOrange : Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: (_isCardValid && _selectedPlan != null) ? 6 : 0,
                      ),
                      child: Text(
                        _selectedPlan != null && _isCardValid
                            ? 'Subscribe — ₦${_numFormat.format(double.tryParse(_selectedPlan!.amount)?.toInt() ?? 0)}'
                            : !_isCardValid
                            ? 'Verify Smart Card to Continue'
                            : 'Select a Plan to Continue',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}