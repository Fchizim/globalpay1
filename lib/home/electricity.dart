import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart'; // adjust path
import 'ele_history_screen.dart';


class Provider {
  final String name;
  final String logo; // network image URL from Tranzit
  final String planId;
  bool isSelected;

  Provider({
    required this.name,
    required this.logo,
    required this.planId,
    this.isSelected = false,
  });
}

class ElectricityScreen extends StatefulWidget {
  const ElectricityScreen({super.key});

  @override
  State<ElectricityScreen> createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends State<ElectricityScreen> {

  final NumberFormat _numFormat = NumberFormat.decimalPattern('en_US');

  final TextEditingController meterController        = TextEditingController();
  final TextEditingController customAmountController = TextEditingController();
  final TextEditingController searchController       = TextEditingController();

  String billType       = 'Prepaid';
  int    selectedAmount = 1000;
  bool   showProviders  = false;

  // ── Validation state ──────────────────────────────────────────────────────
  bool    _isValidating   = false;
  bool    _isMeterValid   = false;
  String? _meterError;
  String? _customerName;
  String? _customerAddress;

  // ── Providers ─────────────────────────────────────────────────────────────
  List<Provider> providers         = [];
  List<Provider> filteredProviders = [];
  bool           _loadingProviders = true;
  String?        _providerError;

  // ── Amounts ───────────────────────────────────────────────────────────────
  final List<int> amounts = [1000, 2000, 3000, 5000, 10000, 20000];

  // ── Banner ────────────────────────────────────────────────────────────────
  final PageController _bannerController = PageController();
  int        _currentBanner = 0;
  late Timer _bannerTimer;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchProviders();

    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_bannerController.hasClients) {
        _currentBanner = (_currentBanner + 1) % 2;
        _bannerController.animateToPage(
          _currentBanner,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _bannerTimer.cancel();
    meterController.dispose();
    customAmountController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // ── Fetch providers dynamically from Tranzit ──────────────────────────────
  Future<void> _fetchProviders() async {
    setState(() {
      _loadingProviders = true;
      _providerError    = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://glopa.org/glo/get_plans.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fetch': 'ELE'}),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      final decoded = jsonDecode(response.body);
      final status  = (decoded['status'] ?? '').toString().toLowerCase();

      if (status == 'successful') {
        final List data = decoded['data'] ?? [];
        final List<Provider> loaded = data
            .where((item) => item['availability'] == true)
            .map<Provider>((item) => Provider(
          name:   item['name'].toString(),
          logo:   item['icon'].toString(),
          planId: item['planID'].toString(),
        ))
            .toList();

        if (loaded.isNotEmpty) loaded[0].isSelected = true;

        setState(() {
          providers         = loaded;
          filteredProviders = List.from(loaded);
          _loadingProviders = false;
        });
      } else {
        setState(() {
          _providerError    = 'Could not load providers. Tap to retry.';
          _loadingProviders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _providerError    = 'Network error. Tap to retry.';
          _loadingProviders = false;
        });
      }
    }
  }

  Provider? get _selectedProvider =>
      providers.isEmpty
          ? null
          : providers.firstWhere((p) => p.isSelected,
          orElse: () => providers.first);

  void filterProviders(String query) {
    setState(() {
      filteredProviders = providers
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // ── Validate meter ────────────────────────────────────────────────────────
  Future<void> _validateMeter() async {
    final meter = meterController.text.trim();
    if (meter.isEmpty) {
      setState(() => _meterError = 'Please enter a meter number');
      return;
    }
    if (_selectedProvider == null) {
      setState(() => _meterError = 'Please select a provider first');
      return;
    }

    setState(() {
      _isValidating    = true;
      _meterError      = null;
      _isMeterValid    = false;
      _customerName    = null;
      _customerAddress = null;
    });

    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final response = await http.post(
          Uri.parse('https://glopa.org/glo/validate_meter.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "plan_id": _selectedProvider!.planId,
            "number":  meter,
          }),
        ).timeout(const Duration(seconds: 30));

        if (!mounted) return;

        final data   = jsonDecode(response.body);
        final status = (data['status'] ?? '').toString();

        if (status == 'success') {
          setState(() {
            _isValidating    = false;
            _isMeterValid    = true;
            _customerName    = data['name']    ?? 'Customer';
            _customerAddress = data['address'] ?? '';
            _meterError      = null;
            final meterType  = (data['meterType'] ?? '').toString().toUpperCase();
            if (meterType.contains('PREPAID'))  billType = 'Prepaid';
            if (meterType.contains('POSTPAID')) billType = 'Postpaid';
          });
          return;
        } else {
          setState(() {
            _isValidating = false;
            _isMeterValid = false;
            _meterError   = data['message'] ?? 'Invalid meter number';
          });
          return;
        }

      } on TimeoutException {
        if (attempt == 2) {
          setState(() {
            _isValidating = false;
            _meterError   = 'Validation timed out. Please try again.';
          });
        } else {
          await Future.delayed(const Duration(seconds: 2));
        }
      } catch (e) {
        setState(() {
          _isValidating = false;
          _meterError   = 'Network error. Check your connection.';
        });
        return;
      }
    }

    if (mounted) setState(() => _isValidating = false);
  }

  // ── Buy electricity ───────────────────────────────────────────────────────
  Future<void> _buyElectricity() async {
    if (!_isMeterValid) {
      setState(() => _meterError = 'Please verify your meter first');
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
      final response = await http.post(
        Uri.parse('https://glopa.org/glo/buy_utility.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id":          userId,
          "action":           "ELE",
          "ele_type":         billType,
          "plan_id":          _selectedProvider!.planId,
          "amount":           selectedAmount,
          "number":           meterController.text.trim(),
          "network":          _selectedProvider!.name,
          "customer_name":    _customerName ?? '',    // ← add
          "customer_address": _customerAddress ?? '', // ← add
        }),
      ).timeout(const Duration(seconds: 30));

      _dismissLoader(loaderCtx);
      if (!mounted) return;

      final data    = jsonDecode(response.body);
      final status  = (data['status']  ?? '').toString();
      final code    = (data['code']    ?? '').toString();
      final message = (data['message'] ?? 'Transaction failed. Please try again.').toString();

      if (status == 'success') {
        final eleData = data['data'];
        final token   = eleData?['electricity_details']?['token'] ?? '';
        final units   = eleData?['electricity_details']?['units'] ?? '';

        _showResultDialog(
          icon:      Icons.check_circle_rounded,
          iconColor: Colors.green,
          title:     'Purchase Successful',
          message:   token.isNotEmpty
              ? '$message\n\nToken: $token\nUnits: ${units}kWh'
              : message,
        );

        setState(() {
          _isMeterValid    = false;
          _customerName    = null;
          _customerAddress = null;
          meterController.clear();
        });

      } else if (status == 'pending') {
        _showResultDialog(
          icon:      Icons.hourglass_bottom_rounded,
          iconColor: Colors.orange,
          title:     'Transaction Processing',
          message:   'Your transaction is being processed. You will be notified once confirmed.',
        );
      } else if (code == 'INSUFFICIENT_BALANCE') {
        _showResultDialog(
          icon:      Icons.account_balance_wallet_outlined,
          iconColor: Colors.deepOrange,
          title:     'Insufficient Balance',
          message:   message,
        );
      } else {
        _showResultDialog(
          icon:      Icons.cancel_outlined,
          iconColor: Colors.red,
          title:     'Transaction Failed',
          message:   message,
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
      try { Navigator.of(ctx).pop(); } catch (_) {}
    }
  }

  void _showResultDialog({
    required IconData icon,
    required Color    iconColor,
    required String   title,
    required String   message,
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
            child: Text('OK', style: TextStyle(color: Colors.deepOrange)),
          ),
        ],
      ),
    );
  }

  // ── Provider avatar (network image with fallback) ─────────────────────────
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
            Icons.electrical_services,
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
    final isDark             = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor    = isDark ? const Color(0xFF121212) : Colors.grey.shade100;
    final cardColor          = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final fillColor          = isDark ? Colors.grey[850]!       : Colors.grey[100]!;
    final textColor          = isDark ? Colors.white            : Colors.black;
    final secondaryTextColor = isDark ? Colors.grey[400]!       : Colors.grey[700]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text('Electricity',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const EleHistoryScreen()
                )
            ),
            child: Text('History',
                style: TextStyle(color: Colors.deepOrange)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Provider selector ──────────────────────────────────────────
            GestureDetector(
              onTap: _loadingProviders
                  ? null
                  : _providerError != null
                  ? _fetchProviders
                  : () => setState(() => showProviders = !showProviders),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: _loadingProviders
                    ? const Row(children: [
                  SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text('Loading providers...'),
                ])
                    : _providerError != null
                    ? Row(children: [
                  const Icon(Icons.refresh, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(_providerError!,
                      style: const TextStyle(color: Colors.red)),
                ])
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      _providerAvatar(_selectedProvider!.logo, 22),
                      const SizedBox(width: 12),
                      Text(_selectedProvider!.name,
                          style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 16)),
                    ]),
                    Icon(
                        showProviders
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: secondaryTextColor, size: 28),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Provider dropdown ──────────────────────────────────────────
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: searchController,
                      onChanged: filterProviders,
                      decoration: InputDecoration(
                        hintText: 'Search Provider',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        filled: true,
                        fillColor: fillColor,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredProviders.length,
                      itemBuilder: (context, index) {
                        final provider = filteredProviders[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              for (var p in providers) p.isSelected = false;
                              provider.isSelected = true;
                              showProviders    = false;
                              searchController.clear();
                              filteredProviders = List.from(providers);
                              _isMeterValid    = false;
                              _customerName    = null;
                              _customerAddress = null;
                              _meterError      = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
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
                                    style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15)),
                              ),
                              Icon(
                                provider.isSelected
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                color: provider.isSelected
                                    ? Colors.deepOrange
                                    : secondaryTextColor,
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ]),
              ),
              crossFadeState: showProviders
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
            const SizedBox(height: 24),

            // ── Banner ─────────────────────────────────────────────────────
            SizedBox(
              height: 120,
              child: PageView(
                controller: _bannerController,
                children: [
                  _bannerWidget('assets/images/png/slide1.PNG'),
                  _bannerWidget('assets/images/png/slide2.JPG'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Main form ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Meter input + Verify ─────────────────────────────
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: meterController,
                        style: TextStyle(
                            color: textColor, fontWeight: FontWeight.w500),
                        keyboardType: TextInputType.text,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9]')),
                        ],
                        onChanged: (_) => setState(() {
                          _isMeterValid    = false;
                          _customerName    = null;
                          _customerAddress = null;
                          _meterError      = null;
                        }),
                        decoration: InputDecoration(
                          labelText: 'Enter Meter / Account Number',
                          labelStyle: TextStyle(
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w500),
                          filled: true,
                          fillColor: fillColor,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 16),
                          suffixIcon: _isMeterValid
                              ? const Icon(Icons.check_circle,
                              color: Colors.green)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isValidating ? null : _validateMeter,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isValidating
                            ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                            : const Text('Verify',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),

                  // ── Meter error ──────────────────────────────────────
                  if (_meterError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(_meterError!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 12)),
                    ),

                  // ── Customer info ────────────────────────────────────
                  if (_customerName != null)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.person_outline,
                                color: Colors.green, size: 16),
                            const SizedBox(width: 6),
                            Text(_customerName!,
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ]),
                          if (_customerAddress != null &&
                              _customerAddress!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.location_on_outlined,
                                  color: Colors.green, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(_customerAddress!,
                                    style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: 11)),
                              ),
                            ]),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ── Prepaid / Postpaid ───────────────────────────────
                  Row(
                    children: ['Prepaid', 'Postpaid'].map((type) {
                      final isSelected = billType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => billType = type),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 4),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(colors: [
                                    Colors.deepOrange,
                                    Colors.deepOrange.shade900,
                                  ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight)
                                      : null,
                                  color: isSelected
                                      ? null
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: isSelected
                                      ? [BoxShadow(
                                      color: Colors.deepOrange
                                          .withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4))]
                                      : [],
                                  border: Border.all(
                                      color: isSelected
                                          ? Colors.deepOrange
                                          : Colors.grey.shade300,
                                      width: 1.5),
                                ),
                                alignment: Alignment.center,
                                child: Text(type,
                                    style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : secondaryTextColor,
                                        fontWeight: FontWeight.bold)),
                              ),
                              if (isSelected)
                                Positioned(
                                  top: 4, right: 8,
                                  child: const Icon(Icons.check_circle,
                                      color: Colors.white, size: 25),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ── Amount grid ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Column(children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: amounts.map((amount) {
                          final isSelected = selectedAmount == amount;
                          return GestureDetector(
                            onTap: () => setState(() {
                              selectedAmount = amount;
                              customAmountController.clear();
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 100, height: 50,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.deepOrange
                                    : cardColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: isSelected
                                    ? [BoxShadow(
                                    color: Colors.deepOrange
                                        .withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 4))]
                                    : [],
                              ),
                              alignment: Alignment.center,
                              child: Text('₦$amount',
                                  style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : secondaryTextColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: customAmountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          final val = int.tryParse(value);
                          if (val != null) setState(() => selectedAmount = val);
                        },
                        style: TextStyle(
                            color: textColor, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Enter Custom Amount',
                          labelStyle: TextStyle(
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w500),
                          filled: true,
                          fillColor: fillColor,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 16),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 32),

                  // ── Pay button ───────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isMeterValid ? _buyElectricity : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isMeterValid
                            ? Colors.deepOrange
                            : Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        shadowColor: Colors.deepOrange,
                        elevation: _isMeterValid ? 6 : 0,
                      ),
                      child: Text(
                        _isMeterValid
                            ? 'Pay ₦${_numFormat.format(selectedAmount)}'
                            : 'Verify Meter to Continue',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
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

  Widget _bannerWidget(String imagePath) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}