import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:globalpay/home/plan_cache.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../services/profile_service.dart';
import '../services/secure_storage_service.dart';
import 'data_history_screen.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../provider/user_provider.dart';

// ─── Data Plan model ──────────────────────────────────────────────────────────
class DataPlan {
  final String planId;
  final String size;
  final String amount;
  final String validity;
  final String category;

  const DataPlan({
    required this.planId,
    required this.size,
    required this.amount,
    required this.validity,
    required this.category,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _phoneController = TextEditingController();
  final NumberFormat _numFormat = NumberFormat.decimalPattern('en_US');

  // ── Networks ──────────────────────────────────────────────────────────────
  final List<Map<String, String>> networks = [
    {'name': 'MTN',     'logo': 'assets/images/png/mtn.jpeg',     'api': 'MTN'},
    {'name': 'Airtel',  'logo': 'assets/images/png/airtel.jpeg',  'api': 'AIRTEL'},
    {'name': 'Glo',     'logo': 'assets/images/png/glo.jpeg',     'api': 'GLO'},
    {'name': '9Mobile', 'logo': 'assets/images/png/9mobile.jpeg', 'api': '9MOBILE'},
  ];
  int _selectedNetworkIndex = 0;

  // ── Tabs ──────────────────────────────────────────────────────────────────
  final List<String> _tabs      = ['HOT', 'SME', 'Gifting', 'Broadband', 'CG'];
  final List<String> _tabFilter = ['all', 'sme', 'gifting', 'broadband', 'cg'];

  // ── State ─────────────────────────────────────────────────────────────────
  List<DataPlan> _allPlans  = [];
  bool   _isLoading         = false;
  String? _loadError;
  String? _phoneError;

  final List<String> _validPrefixes = ['070','071','080','081','090','091'];

  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final phone = context.read<UserProvider>().user?.phone ?? '';
      if (phone.isNotEmpty) _phoneController.text = phone;
    });

    _isLoading = true;
    _loadFeesAndPlans();
  }

  Future<void> _loadFeesAndPlans() async {
    await Future.wait([
      _waitForCache(),
    ]);
    if (mounted) _fetchPlans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _waitForCache() async {
    if (PlansCache.instance.isReady) return;

    const maxWait = Duration(seconds: 10);
    final deadline = DateTime.now().add(maxWait);

    while (!PlansCache.instance.isReady && DateTime.now().isBefore(deadline)) {
      if (!PlansCache.instance.isFetching) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  // ── NEW: Detect network index from phone prefix ────────────────────────────
  int? _detectNetworkIndexFromPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 4) return null;

    const prefixMap = {
      // MTN
      '0803': 'MTN', '0806': 'MTN', '0703': 'MTN', '0706': 'MTN',
      '0813': 'MTN', '0816': 'MTN', '0810': 'MTN', '0814': 'MTN',
      '0903': 'MTN', '0906': 'MTN', '0913': 'MTN', '0916': 'MTN',
      // Airtel
      '0802': 'AIRTEL', '0808': 'AIRTEL', '0708': 'AIRTEL',
      '0812': 'AIRTEL', '0701': 'AIRTEL', '0902': 'AIRTEL',
      '0907': 'AIRTEL', '0901': 'AIRTEL', '0911': 'AIRTEL',
      // Glo
      '0805': 'GLO', '0807': 'GLO', '0705': 'GLO',
      '0815': 'GLO', '0811': 'GLO', '0905': 'GLO', '0915': 'GLO',
      // 9Mobile
      '0809': '9MOBILE', '0818': '9MOBILE', '0817': '9MOBILE',
      '0908': '9MOBILE', '0909': '9MOBILE',
    };

    final detected = prefixMap[digits.substring(0, 4)];
    if (detected == null) return null;

    final idx = networks.indexWhere((n) => n['api'] == detected);
    return idx == -1 ? null : idx;
  }


  // ── Fetch live plans ──────────────────────────────────────────────────────
  Future<void> _fetchPlans() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _allPlans  = [];
    });

    try {
      Map<String, dynamic> decoded;

      if (PlansCache.instance.isReady) {
        debugPrint('DataScreen: using cached plans');
        decoded = PlansCache.instance.rawData!;
      } else {
        debugPrint('DataScreen: fetching fresh plans');
        final response = await http.post(
          Uri.parse('https://glopa.org/glo/get_plans.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'fetch': 'DATA'}),
        ).timeout(const Duration(seconds: 15));

        if (!mounted) return;
        if (response.body.isEmpty) {
          setState(() => _loadError = 'Empty response. Please try again.');
          return;
        }

        decoded = jsonDecode(response.body);
        final status = (decoded['status'] ?? '').toString().toLowerCase();
        if (status == 'successful') PlansCache.instance.setData(decoded);
      }

      final status = (decoded['status'] ?? '').toString().toLowerCase();
      if (status == 'successful') {
        final api    = networks[_selectedNetworkIndex]['api']!;
        final parsed = _parsePlans(decoded, api);
        setState(() => _allPlans = parsed);
      } else {
        setState(() => _loadError =
            (decoded['message'] ?? 'Could not load plans.').toString());
      }
    } on TimeoutException {
      if (mounted) setState(() => _loadError = 'Request timed out. Please try again.');
    } catch (e) {
      debugPrint('_fetchPlans error: $e');
      if (mounted) setState(() => _loadError = 'Network error. Please check your connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<DataPlan> _parsePlans(Map<String, dynamic> decoded, String networkApi) {
    try {
      final List data = decoded['data'] ?? [];
      final List<DataPlan> plans = [];

      for (final group in data) {
        final network = (group['network'] ?? '').toString().toUpperCase();
        if (network != networkApi) continue;

        final available = group['availability'] == true;
        if (!available) continue;

        final category = (group['type'] ?? 'gifting').toString().toLowerCase();

        final List options = group['options'] ?? [];
        for (final opt in options) {
          plans.add(DataPlan(
            planId:   opt['planID'].toString(),
            size:     opt['package'].toString(),
            amount:   opt['price'].toString(),
            validity: opt['validation'].toString(),
            category: category,
          ));
        }
      }

      return plans;
    } catch (e) {
      debugPrint('_parsePlans error: $e');
      return [];
    }
  }

  // ── Filter plans by tab ───────────────────────────────────────────────────
  List<DataPlan> _plansForTab(int tabIndex) {
    final filter = _tabFilter[tabIndex];
    if (filter == 'all') return _allPlans;
    return _allPlans.where((p) => p.category == filter).toList();
  }
  String _cleanPhone(String phone) =>
      phone.replaceAll(RegExp(r'[^0-9]'), '');
  // ── Validate phone ────────────────────────────────────────────────────────
  String? _validatePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 'Please enter a mobile number';
    if (digits.length != 11) return 'Number must be 11 digits';
    final prefix = digits.substring(0, 3);
    if (!_validPrefixes.contains(prefix)) {
      return 'Must start with 070, 071, 080, 081, 090 or 091';
    }
    return null;
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ── Confirm sheet ─────────────────────────────────────────────────────────
  void _showConfirmSheet(DataPlan plan) {
    final phoneErr = _validatePhone(_cleanPhone(_phoneController.text));
    if (phoneErr != null) {
      setState(() => _phoneError = phoneErr);
      return;
    }
    setState(() => _phoneError = null);
    FocusManager.instance.primaryFocus?.unfocus();

    final networkName = networks[_selectedNetworkIndex]['name']!;
    final networkLogo = networks[_selectedNetworkIndex]['logo']!;
    final user = context.read<UserProvider>().user;
    final walletStr = user?.wallet.toString() ?? '0';
    final walletFmt   = '₦${_numFormat.format(double.tryParse(walletStr) ?? 0)}';
    final amountFmt = '₦${_numFormat.format(int.tryParse(plan.amount) ?? 0)}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 16),
            const Text('Confirm Purchase',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(amountFmt,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                    color: Colors.deepOrange)),
            const SizedBox(height: 20),
            _confirmRow(
              leading: CircleAvatar(radius: 18,
                  backgroundImage: AssetImage(networkLogo)),
              label: 'Provider',
              value: '$networkName Data',
            ),
            const Divider(height: 1),
            _confirmRow(
              leading: const Icon(Icons.data_usage_rounded,
                  size: 36, color: Colors.teal),
              label: 'Plan',
              value: '${plan.size} — ${plan.validity}',
            ),
            const Divider(height: 1),
            _confirmRow(
              leading: const Icon(Icons.phone_android_rounded,
                  size: 36, color: Colors.blue),
              label: 'Mobile Number',
              value: _cleanPhone(_phoneController.text),  // ← cleaned
            ),
            const Divider(height: 1),
            _confirmRow(
              leading: Icon(Icons.account_balance_wallet_rounded,
                  size: 36, color: Colors.deepOrange),
              label: 'Payment Method',
              value: 'Wallet ($walletFmt)',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _buyData(plan);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirm to Pay',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }

  // ── Buy data ──────────────────────────────────────────────────────────────
  Future<void> _buyData(DataPlan plan) async {
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

    final phone = _cleanPhone(_phoneController.text);  // ← was .trim()
    final networkName = networks[_selectedNetworkIndex]['name']!;

    try {
      final response = await http.post(
        Uri.parse('https://glopa.org/glo/buy_utility.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": userId,
          "action": "DATA",
          "plan_id": plan.planId,
          "number": phone,
          "amount": int.tryParse(plan.amount) ?? 0,
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint('BUY DATA STATUS: ${response.statusCode}');
      debugPrint('BUY DATA BODY:   ${response.body}');

      _dismissLoader(loaderCtx);

      if (response.body.isEmpty) {
        _showSnack('Empty response. Please try again.');
        return;
      }

      if (!mounted) return;

      final data    = jsonDecode(response.body);
      final status  = (data['status']  ?? '').toString();
      final code    = (data['code']    ?? '').toString();
      final message = (data['message'] ?? 'Transaction failed. Please try again.').toString();

      if (status == 'success') {
        // ── Refresh wallet balance ──
        final userProvider = context.read<UserProvider>();
        final localUser = await SecureStorageService.getUser();
        if (localUser != null) {
          final freshUser = await ProfileService.getProfile(localUser.userId);
          if (freshUser != null) await userProvider.updateUser(freshUser);
        }

        _showResultDialog(
          icon: Icons.check_circle_rounded,
          iconColor: Colors.green,
          title: 'Purchase Successful',
          message: message,
        );
      } else if (status == 'pending') {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Transaction Processing'),
            content: const Text(
              'Your transaction is being processed. '
                  'You will receive a notification once confirmed. '
                  'Your wallet has been debited and will be refunded if it fails.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK',
                    style: TextStyle(color: Colors.deepOrange)),
              ),
            ],
          ),
        );
      } else if (code == 'SERVICE_UNAVAILABLE' ||
          code == 'PROVIDER_BALANCE_LOW') {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 22),
              const SizedBox(width: 8),
              const Text('Service Unavailable'),
            ]),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK',
                    style: TextStyle(color: Colors.deepOrange)),
              ),
            ],
          ),
        );
      } else if (code == 'INSUFFICIENT_BALANCE') {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.deepOrange, size: 22),
              const SizedBox(width: 8),
              const Text('Insufficient Balance'),
            ]),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Fund Wallet',
                    style: TextStyle(color: Colors.deepOrange)),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              const Icon(Icons.cancel_outlined, color: Colors.red, size: 22),
              const SizedBox(width: 8),
              const Text('Transaction Failed'),
            ]),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Try Again',
                    style: TextStyle(color: Colors.deepOrange)),
              ),
            ],
          ),
        );
      }
    } on TimeoutException {
      _dismissLoader(loaderCtx);
      _showSnack('Request timed out. Please check your connection and try again.');
    } catch (e) {
      debugPrint('BUY DATA ERROR: $e');
      _dismissLoader(loaderCtx);
      _showSnack('Network error. Please check your connection.');
    }
  }

  void _dismissLoader(BuildContext? ctx) {
    if (mounted && ctx != null) {
      try { Navigator.of(ctx).pop(); } catch (_) {}
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
            child: Text('OK',
                style: TextStyle(color: Colors.deepOrange)),
          ),
        ],
      ),
    );
  }

  // ── Confirm row ───────────────────────────────────────────────────────────
  Widget _confirmRow({
    required Widget leading,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        SizedBox(width: 40, child: leading),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Plan card ─────────────────────────────────────────────────────────────
  Widget _planCard(DataPlan plan, {required bool isDark}) {
    return GestureDetector(
      onTap: () => _showConfirmSheet(plan),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Category badge ──────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                plan.category.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.deepOrange,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // ── Size ────────────────────────────────────────────
            Text(
              plan.size,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),

            // ── Validity ────────────────────────────────────────
            Text(
              plan.validity,
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            const Spacer(),

            // ── Price ───────────────────────────────────────────
            Text(
              '₦${_numFormat.format(int.tryParse(plan.amount) ?? 0)}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.deepOrange),
            ),
          ],
        ),
      ),
    );
  }

  // ── Plans grid ────────────────────────────────────────────────────────────
  Widget _plansGrid(int tabIndex, {required bool isDark}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(_loadError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchPlans,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor:Colors.deepOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
        ),
      );
    }

    final plans = _plansForTab(tabIndex);
    if (plans.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('No plans in this category.',
              style: TextStyle(color: Colors.grey.shade500)),
        ]),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: plans.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, i) => _planCard(plans[i], isDark: isDark),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final isDark  = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF6F6F6);
    final cardBg  = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    // ── Derived for the detected-network badge ─────────────────────────────
    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final showBadge   = phoneDigits.length >= 4;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(children: [

          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              IconButton(
                icon: Icon(Icons.arrow_back,
                    color: isDark ? Colors.white : Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text('Mobile Data',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark ? Colors.white : Colors.black87)),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DataHistoryScreen()
                    )
                ),
                child: Text('History',
                    style: TextStyle(color: Colors.deepOrange)),
              ),
            ]),
          ),

          // ── Network + Phone card ───────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            // ── Wrapped in Column to accommodate the badge row ──────────
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  // ── Network dropdown ──────────────────────────────────
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedNetworkIndex,
                      dropdownColor: cardBg,
                      items: List.generate(networks.length, (i) {
                        final net = networks[i];
                        return DropdownMenuItem<int>(
                          value: i,
                          child: Row(children: [
                            CircleAvatar(
                                radius: 16,
                                backgroundImage: AssetImage(net['logo']!)),
                            const SizedBox(width: 6),
                            Text(net['name']!,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87)),
                          ]),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null && val != _selectedNetworkIndex) {
                          setState(() => _selectedNetworkIndex = val);
                          PlansCache.instance.invalidate();
                          _fetchPlans();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // ── Phone field ───────────────────────────────────────
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Enter mobile number',
                        hintStyle: TextStyle(
                            color: isDark ? Colors.white54 : Colors.grey),
                        border: InputBorder.none,
                      ),
                      // ── UPDATED: auto-detect network on typing ────────
                      onChanged: (val) {
                        final raw = val ?? '';
                        setState(() => _phoneError = null);

                        // ── Auto-strip spaces/non-digits as user types or pastes ──
                        final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
                        if (cleaned != raw) {
                          _phoneController.value = TextEditingValue(
                            text: cleaned,
                            selection: TextSelection.collapsed(offset: cleaned.length),
                          );
                        }

                        if (cleaned.length >= 4) {
                          final idx = _detectNetworkIndexFromPhone(cleaned);
                          if (idx != null && idx != _selectedNetworkIndex) {
                            setState(() => _selectedNetworkIndex = idx);
                            PlansCache.instance.invalidate();
                            _fetchPlans();
                          }
                        }
                      },
                    ),
                  ),

                  // ── Contacts icon ─────────────────────────────────────
                  IconButton(
                    onPressed: () {/* TODO: contacts picker */},
                    icon: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.deepOrange.withOpacity(0.1)),
                      child: Icon(Icons.person,
                          color: Colors.deepOrange, size: 18),
                    ),
                  ),
                ]),

                // ── Detected-network badge ────────────────────────────────
                if (showBadge)
                  Padding(
                    padding:
                    const EdgeInsets.only(left: 12, top: 4, bottom: 2),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundImage: AssetImage(
                            networks[_selectedNetworkIndex]['logo']!),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${networks[_selectedNetworkIndex]['name']!} detected',
                        style: TextStyle(
                            color: Colors.deepOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.check_circle,
                          color: Color(0xFF22C55E), size: 13),
                    ]),
                  ),
              ],
            ),
          ),

          // ── Phone error ────────────────────────────────────────────────
          if (_phoneError != null)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(_phoneError!,
                    style: const TextStyle(
                        color: Colors.red, fontSize: 12)),
              ),
            ),

          const SizedBox(height: 10),

          // ── Tabs + Grid ────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(15)),
                child: Column(children: [
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: Colors.deepOrange,
                    unselectedLabelColor:
                    isDark ? Colors.grey.shade400 : Colors.grey,
                    indicatorColor: Colors.deepOrange,
                    dividerColor: Colors.transparent,
                    tabs: _tabs.map((t) => Tab(text: t)).toList(),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: List.generate(
                        _tabs.length,
                            (i) => _plansGrid(i, isDark: isDark),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),

          const SizedBox(height: 10),
        ]),
      ),
    );
  }
}