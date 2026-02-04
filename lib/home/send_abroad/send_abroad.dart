// send_abroad_page.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';

// NOTE: keep these imports pointing to YOUR file locations
import '../../models/country_info.dart';
import 'country_loader.dart';

/// ---------------------------------------------------------------------------
/// Mock FX service (replace with your real API call later)
/// - Assumes you're sending from USD to the destination's currency
/// - Simulates "real-time" by returning a value with slight jitter
/// ---------------------------------------------------------------------------
class FxService {
  final Random _rng = Random();

  // Base mock rates per currency code (add as needed)
  static const Map<String, double> _baseRates = {
    'NGN': 1500.0,
    'KES': 130.0,
    'GHS': 15.0,
    'ZAR': 18.5,
    'UGX': 3800.0,
    'INR': 84.0,
    'PHP': 58.0,
    'EUR': 0.92,
    'GBP': 0.78,
    'USD': 1.0,
  };

  Future<double> getUsdTo(String currencyCode) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    final base = _baseRates[currencyCode.toUpperCase()] ?? 100.0;
    // add very light jitter to feel "live"
    final jitter = (1 + (_rng.nextDouble() - 0.5) * 0.002); // ±0.1%
    return base * jitter;
  }
}

/// ---------------------------------------------------------------------------
/// Main Page: 4-step flow (Estimate → Receiver → Payment → Review)
/// - Tabs are NOT swipeable; they are tappable
/// - Next/Back buttons navigate steps
/// ---------------------------------------------------------------------------
class SendAbroadPage extends StatefulWidget {
  const SendAbroadPage({super.key});

  @override
  State<SendAbroadPage> createState() => _SendAbroadPageState();
}

class _SendAbroadPageState extends State<SendAbroadPage> {
  final FxService _fx = FxService();

  // Step control (0=Estimate, 1=Receiver, 2=Payment, 3=Review)
  int _step = 0;

  // Country & amount
  CountryInfo? _selectedCountry;
  final TextEditingController _amountController = TextEditingController();
  List<CountryInfo> _allCountries = [];

  // Receiver info
  bool _existingReceiver = true;
  final TextEditingController _rFirst = TextEditingController();
  final TextEditingController _rMiddle = TextEditingController();
  final TextEditingController _rLast = TextEditingController();
  final TextEditingController _rPhone = TextEditingController();
  final TextEditingController _rEmail = TextEditingController();
  final TextEditingController _rAddress = TextEditingController();
  String _deliveryMethod =
      'Bank Account'; // Cash Pickup | Bank Account | Mobile Wallet

  // Payment
  String _paymentMethod =
      'Wallet Balance'; // Debit Card | Bank Transfer | Mobile Money | Wallet Balance
  final TextEditingController _paymentNotes =
  TextEditingController(); // optional notes

  // FX
  double? _fxRate; // USD -> dest currency
  Timer? _fxTimer;

  // Review
  bool _disclaimerChecked = false;

  @override
  void initState() {
    super.initState();
    loadCountries().then((countries) {
      setState(() => _allCountries = countries);
    });

    // react to amount changes
    _amountController.addListener(_recompute);

    // Poll FX every 10s when a country is selected
    _fxTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshFx();
    });
  }

  @override
  void dispose() {
    _fxTimer?.cancel();
    _amountController.dispose();
    _rFirst.dispose();
    _rMiddle.dispose();
    _rLast.dispose();
    _rPhone.dispose();
    _rEmail.dispose();
    _rAddress.dispose();
    _paymentNotes.dispose();
    super.dispose();
  }

  // ----- FX helpers -----
  Future<void> _refreshFx() async {
    if (_selectedCountry == null) return;
    final rate = await _fx.getUsdTo(_selectedCountry!.currencyCode);
    if (mounted) setState(() => _fxRate = rate);
  }

  void _recompute() {
    // currently nothing else to compute; fx refresh is timer-based + country change
    setState(() {});
  }

  double get _sendAmountUsd {
    final txt = _amountController.text.trim();
    if (txt.isEmpty) return 0;
    return double.tryParse(txt.replaceAll(',', '')) ?? 0;
    // You can apply NumberFormat if you wish
  }

  double get _receiverGets {
    if (_fxRate == null) return 0;
    return _sendAmountUsd * _fxRate!;
  }

  // ----- Navigation -----
  void _goTo(int index) => setState(() => _step = index);

  void _next() {
    if (_step < 3) setState(() => _step += 1);
  }

  void _back() {
    if (_step > 0) setState(() => _step -= 1);
  }

  // ----- Validation per step -----
  bool get _canContinueFromEstimate =>
      _selectedCountry != null && _sendAmountUsd > 0;

  bool get _canContinueFromReceiver {
    if (_existingReceiver) {
      // In real app you'd force selecting one existing contact
      return true;
    }
    return _rFirst.text.isNotEmpty &&
        _rLast.text.isNotEmpty &&
        _rPhone.text.isNotEmpty;
  }

  bool get _canContinueFromPayment => _paymentMethod.isNotEmpty;

  bool get _canConfirmOnReview => _disclaimerChecked;

  // ----- Country picker -----
  void _openCountryPicker() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      backgroundColor:
      theme.bottomSheetTheme.backgroundColor ?? theme.colorScheme.surface,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return CountryModal(
              countries: _allCountries,
              controller: controller,
              onSelected: (country) {
                setState(() {
                  _selectedCountry = country;
                });
                Navigator.pop(context);
                _refreshFx(); // fetch fresh rate for new country
              },
            );
          },
        );
      },
    );
  }

  // ----- PIN & Receipt -----
  Future<void> _enterPinAndSend() async {
    final pinController = TextEditingController();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final result = await showModalBottomSheet<String>(
      isScrollControlled: true,
      backgroundColor: theme.bottomSheetTheme.backgroundColor ?? cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Enter Payment PIN",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(),
                    hintText: '••••',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context, pinController.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Confirm PIN"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null && result.length >= 4) {
      _showReceipt();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PIN entry cancelled or invalid.")),
      );
    }
  }

  void _showReceipt() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final rcName = _existingReceiver
        ? "Existing Receiver"
        : "${_rFirst.text.trim()} ${_rLast.text.trim()}";

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Receipt",
      barrierColor: Colors.black54.withOpacity(0.5), // dim behind dialog
      pageBuilder: (context, animation1, animation2) {
        return Stack(
          children: [
            // Background photo (barrier replacement)
            Positioned.fill(
              child: Image.asset(
                "assets/images/png/background.png", // your photo
                fit: BoxFit.cover,
              ),
            ),

            // Centered dialog
            Center(
              child: Dialog(
                backgroundColor: theme.dialogBackgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Payment Receipt",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: cs.tertiary,
                            size: 30,
                          ),
                          _receiptRow("Transaction", "Successful", theme),
                          _receiptRow(
                            "You paid",
                            "\$${_sendAmountUsd.toStringAsFixed(2)}",
                            theme,
                          ),
                          _receiptRow(
                            "Receiver gets",
                            "${_selectedCountry?.currencyCode ?? ''} ${_receiverGets.toStringAsFixed(2)}",
                            theme,
                          ),
                          _receiptRow("To", rcName, theme),
                          _receiptRow(
                            "Country",
                            _selectedCountry?.name ?? '',
                            theme,
                          ),
                          _receiptRow("Delivery", _deliveryMethod, theme),
                          _receiptRow("Payment", _paymentMethod, theme),
                          _receiptRow(
                            "Rate",
                            "1 USD = ${_fxRate?.toStringAsFixed(4) ?? '--'} ${_selectedCountry?.currencyCode ?? ''}",
                            theme,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Money will be delivered within minutes.",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              height: 40,
                              width: 70,
                              decoration: BoxDecoration(
                                color: cs.tertiaryContainer,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Icon(
                                  Icons.exit_to_app,
                                  color: cs.onTertiaryContainer,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _receiptRow(String a, String b, ThemeData theme) {
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            a,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            b,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.tertiary,
            ),
          ),
        ],
      ),
    );
  }

  // ----- UI -----
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tabs = ["Estimate", "Receiver", "Payment", "Review"];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Send money"),
        backgroundColor: theme.appBarTheme.backgroundColor ?? cs.surface,
        foregroundColor: theme.appBarTheme.foregroundColor ?? cs.onSurface,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Step Header (not swipeable; tappable)
          Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: List.generate(tabs.length, (i) {
                final active = _step == i;
                return Expanded(
                  child: InkWell(
                    onTap: () => _goTo(i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tabs[i],
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: active
                                ? cs.primary
                                : theme.textTheme.labelLarge?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: active ? cs.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildStepContent(),
              ),
            ),
          ),

          // Footer controls
          Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _back,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Back"),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _primaryCtaEnabled() ? _onPrimaryCta : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_step == 3 ? "Confirm & Send" : "Next"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Decide when primary CTA is enabled & what it does
  bool _primaryCtaEnabled() {
    switch (_step) {
      case 0:
        return _canContinueFromEstimate;
      case 1:
        return _canContinueFromReceiver;
      case 2:
        return _canContinueFromPayment;
      case 3:
        return _canConfirmOnReview;
      default:
        return false;
    }
  }

  void _onPrimaryCta() {
    if (_step < 3) {
      _next();
    } else {
      _enterPinAndSend();
    }
  }

  // Build content per step
  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildEstimate();
      case 1:
        return _buildReceiver();
      case 2:
        return _buildPayment();
      case 3:
        return _buildReview();
      default:
        return const SizedBox.shrink();
    }
  }

  // -------------------- STEP 1: ESTIMATE --------------------
  Widget _buildEstimate() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final divider = DividerTheme.of(context).color ?? cs.outlineVariant;

    return Column(
      key: const ValueKey('estimate'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top container (Welcome, Send to: tabs)
        Card(
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, Gold Emmanuel",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                // Existing / New receiver toggle
                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _toggleChip(
                        label: "Existing receiver",
                        selected: _existingReceiver,
                      ),
                      _toggleChip(
                        label: "New receiver",
                        selected: !_existingReceiver,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Select destination country
                Text(
                  "Select your receiver’s country",
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _openCountryPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: divider),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        if (_selectedCountry != null)
                          SizedBox(
                            width: 32,
                            height: 24,
                            child: CountryFlag.fromCountryCode(
                              _selectedCountry!.iso2,
                              // borderRadius: 6, // uncomment if your package supports it
                            ),
                          )
                        else
                          Icon(
                            Icons.flag_outlined,
                            color: theme.iconTheme.color?.withOpacity(0.6),
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedCountry?.name ?? "Tap to choose country",
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _selectedCountry == null
                                  ? theme.textTheme.bodyLarge?.color
                                  ?.withOpacity(0.7)
                                  : theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_selectedCountry != null)
                  Text(
                    "We send to ${_selectedCountry!.name} every day.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Conversion box
        Card(
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _amountTile(
                        label: "You send",
                        controller: _amountController,
                        prefix: "\$",
                        suffix: "USD",
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.compare_arrows_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _staticTile(
                        label: "Receiver gets",
                        value: _selectedCountry == null
                            ? "--"
                            : "${_selectedCountry!.currencyCode} ${_receiverGets.toStringAsFixed(2)}",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _selectedCountry == null
                        ? "Select a country to see the rate."
                        : "Exchange rate • 1 USD = ${_fxRate?.toStringAsFixed(4) ?? '--'} ${_selectedCountry!.currencyCode}",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Delivery method row
        Card(
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "How will your receiver get money?",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                _deliveryPill("Cash Pickup", icon: Icons.store_mall_directory),

                const SizedBox(height: 8),

                Stack(
                  children: [
                    _deliveryPill("Bank Account", icon: Icons.account_balance),
                    Positioned(
                      right: 6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: cs.primary),
                        ),
                        child: Text(
                          "Popular",
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSecondaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _deliveryPill("Mobile Wallet", icon: Icons.phone_android),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _toggleChip({required String label, required bool selected}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Expanded(
      child: InkWell(
        onTap: () =>
            setState(() => _existingReceiver = label == "Existing receiver"),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? theme.cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? cs.primary : theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _amountTile({
    required String label,
    required TextEditingController controller,
    String? prefix,
    String? suffix,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final divider = DividerTheme.of(context).color ?? cs.outlineVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
          Row(
            children: [
              if (prefix != null)
                Text(
                  prefix,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: "0.00",
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
              ),
              if (suffix != null)
                Text(
                  suffix,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _staticTile({required String label, required String value}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final divider = DividerTheme.of(context).color ?? cs.outlineVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _deliveryPill(String label, {required IconData icon}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final selected = _deliveryMethod == label;

    return GestureDetector(
      onTap: () => setState(() => _deliveryMethod = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.secondaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? cs.onPrimary : cs.onSecondaryContainer,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected ? cs.onPrimary : cs.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- STEP 2: RECEIVER --------------------
  Widget _buildReceiver() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      key: const ValueKey('receiver'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Receiver details",
          style: theme.textTheme.titleSmall?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),

        // If existing receiver, show mini info card
        if (_existingReceiver)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.secondaryContainer,
                child: Icon(Icons.person, color: cs.onSecondaryContainer),
              ),
              title: const Text("Select existing receiver"),
              subtitle: const Text("Tap to choose from your saved receivers"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Navigate to your saved contacts page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Pick from saved receivers (TODO)"),
                  ),
                );
              },
            ),
          ),

        if (!_existingReceiver) ...[
          _input("First name", _rFirst),
          _input("Middle name (optional)", _rMiddle),
          _input("Last name", _rLast),
          _input("Mobile number", _rPhone, keyboard: TextInputType.phone),
          _input(
            "Email (optional)",
            _rEmail,
            keyboard: TextInputType.emailAddress,
          ),
          _input("Address (optional)", _rAddress, maxLines: 2),
        ],

        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Make sure your receiver details match their ID for smoother pickup.",
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _input(
      String label,
      TextEditingController c, {
        TextInputType keyboard = TextInputType.text,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // -------------------- STEP 3: PAYMENT --------------------
  Widget _buildPayment() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final methods = [
      'Wallet Balance',
      'Debit Card',
      'Bank Transfer',
      'Mobile Money',
    ];
    return Column(
      key: const ValueKey('payment'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select payment method",
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: methods.map((m) => _paymentChip(m)).toList(),
        ),
        const SizedBox(height: 16),
        _input("Payment notes (optional)", _paymentNotes, maxLines: 2),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 1,
          child: const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text("You’ll confirm with your payment PIN"),
            subtitle: Text("Secure 6-digit code to authorize transfers"),
          ),
        ),
      ],
    );
  }

  Widget _paymentChip(String label) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sel = _paymentMethod == label;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? cs.primary : cs.secondaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconForPayment(label),
              size: 18,
              color: sel ? cs.onPrimary : cs.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: sel ? cs.onPrimary : cs.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForPayment(String m) {
    switch (m) {
      case 'Wallet Balance':
        return Icons.account_balance_wallet_outlined;
      case 'Debit Card':
        return Icons.credit_card;
      case 'Bank Transfer':
        return Icons.account_balance_outlined;
      case 'Mobile Money':
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  // -------------------- STEP 4: REVIEW --------------------
  Widget _buildReview() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final destCcy = _selectedCountry?.currencyCode ?? '--';
    final rcName = _existingReceiver
        ? "Existing Receiver"
        : "${_rFirst.text.trim()} ${_rLast.text.trim()}".trim();

    // For demo, simple fee calc: 1.5% + 1.00
    final fee = (_sendAmountUsd * 0.015) + 1.00;
    final total = _sendAmountUsd + fee;

    return Column(
      key: const ValueKey('review'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Review transfer",
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),

        Card(
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _row(
                  "You pay",
                  "\$${_sendAmountUsd.toStringAsFixed(2)}",
                  theme,
                ),
                _row(
                  "Receiver gets",
                  "$destCcy ${_receiverGets.toStringAsFixed(2)}",
                  theme,
                ),
                const Divider(),
                _row("Delivery method", _deliveryMethod, theme),
                _row("Payment method", _paymentMethod, theme),
                _row("Money will be sent", "Within minutes", theme),
                const Divider(),
                _row(
                  "Transfer amount",
                  "\$${_sendAmountUsd.toStringAsFixed(2)}",
                  theme,
                ),
                _row("Transfer fee", "\$${fee.toStringAsFixed(2)}", theme),
                _row("Transfer total", "\$${total.toStringAsFixed(2)}", theme),
                _row(
                  "Exchange rate",
                  "1 USD = ${_fxRate?.toStringAsFixed(4) ?? '--'} $destCcy",
                  theme,
                ),
                _row("Receiver name", rcName, theme),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _disclaimerChecked,
              onChanged: (v) => setState(() => _disclaimerChecked = v ?? false),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  "I understand Global Pay won’t be held responsible for transfers sent to wrong details.",
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(String a, String b, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(a, style: theme.textTheme.bodyMedium),
          Text(
            b,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Country Modal (searchable list)
/// ---------------------------------------------------------------------------
class CountryModal extends StatefulWidget {
  final List<CountryInfo> countries;
  final ScrollController controller;
  final Function(CountryInfo) onSelected;

  const CountryModal({
    super.key,
    required this.countries,
    required this.controller,
    required this.onSelected,
  });

  @override
  State<CountryModal> createState() => _CountryModalState();
}

class _CountryModalState extends State<CountryModal> {
  List<CountryInfo> filteredCountries = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredCountries = widget.countries;
  }

  void _filter(String query) {
    setState(() {
      filteredCountries = widget.countries
          .where(
            (c) =>
        c.name.toLowerCase().contains(query.toLowerCase()) ||
            c.currencyCode.toLowerCase().contains(query.toLowerCase()),
      )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final divider = DividerTheme.of(context).color ?? cs.outlineVariant;

    return Material(
      color: theme.bottomSheetTheme.backgroundColor ?? cs.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 5,
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            decoration: BoxDecoration(
              color: divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search country or currency",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filter,
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: widget.controller,
              itemCount: filteredCountries.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: divider),
              itemBuilder: (context, index) {
                final country = filteredCountries[index];
                return ListTile(
                  leading: SizedBox(
                    width: 32,
                    height: 24,
                    child: CountryFlag.fromCountryCode(
                      country.iso2,
                      // borderRadius: 4, // uncomment if your package supports it
                    ),
                  ),
                  title: Text(country.name),
                  subtitle: Text(
                    "${country.currencyCode} (${country.currencySymbol})",
                  ),
                  onTap: () => widget.onSelected(country),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
