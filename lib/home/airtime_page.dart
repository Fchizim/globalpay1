import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../provider/user_provider.dart';
import 'airtime_history_screen.dart';
import 'airtime_successful_page.dart';


// ─── Model ────────────────────────────────────────────────────────────────────
class AirtimeNetwork {
  final String network;
  final String name;
  final String icon;
  final String planId;

  const AirtimeNetwork({
    required this.network,
    required this.name,
    required this.icon,
    required this.planId,
  });

  String get displayName => name == 'VTU' ? network : '$network ($name)';
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class AirtimeScreen extends StatefulWidget {
  const AirtimeScreen({super.key});

  @override
  State<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends State<AirtimeScreen>
    with SingleTickerProviderStateMixin {

  final NumberFormat _numFormat = NumberFormat.decimalPattern('en_US');
  UserModel? get _user => context.read<UserProvider>().user;
  String get userId => _user?.userId ?? '';
  String get userWallet => _user?.wallet.toString() ?? '0';
  String get userPhone => _user?.phone ?? '';

  // ── Networks ──────────────────────────────────────────────────────────────
  List<AirtimeNetwork> _allNetworks       = [];
  AirtimeNetwork?      _selectedNetwork;
  bool                 _isLoadingNetworks  = false;
  String?              _networksError;

  // ── Controllers & state ───────────────────────────────────────────────────
  final TextEditingController phoneController        = TextEditingController();
  final TextEditingController manualAmountController = TextEditingController();

  final List<int> quickAmounts = [
    50, 100, 200, 500, 1000, 2000, 5000, 10000, 50000
  ];
  int? selectedAmount;

  List<BulkItem> bulkItems = [BulkItem()];

  late final TabController _tabController;

  String? singlePhoneError;
  String? singleAmountError;

  final List<String> _validPrefixes = [
    '070', '071', '080', '081', '090', '091'
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAirtimeNetworks();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final phone = _user?.phone ?? '';
      if (phone.isNotEmpty) phoneController.text = phone;
    });

    manualAmountController.addListener(() => _formatAndClamp(manualAmountController));
    for (var b in bulkItems) {
      b.amountCtrl.addListener(() => _formatAndClamp(b.amountCtrl));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    phoneController.dispose();
    manualAmountController.dispose();
    for (var b in bulkItems) b.dispose();
    super.dispose();
  }

  // ── Detect network from phone prefix ──────────────────────────────────────
  AirtimeNetwork? _detectNetworkFromPhone(String phone) {
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
      '0909': '9MOBILE', '0908': '9MOBILE',
    };

    final prefix = digits.substring(0, 4);
    final detectedNetwork = prefixMap[prefix];
    if (detectedNetwork == null) return null;

    return _allNetworks.firstWhere(
          (n) => n.network == detectedNetwork && n.name == 'VTU',
      orElse: () => _allNetworks.firstWhere(
            (n) => n.network == detectedNetwork,
        orElse: () => _allNetworks.first,
      ),
    );
  }

  // ── Fetch networks ─────────────────────────────────────────────────────────
  Future<void> _fetchAirtimeNetworks() async {
    setState(() {
      _isLoadingNetworks = true;
      _networksError     = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://glopa.org/glo/get_plans.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fetch': 'AIRTIME'}),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.body.isEmpty) {
        setState(() => _networksError = 'Empty response. Please try again.');
        return;
      }

      final decoded = jsonDecode(response.body);
      final status  = (decoded['status'] ?? '').toString().toLowerCase();

      if (status == 'successful') {
        final List data = decoded['data'] ?? [];
        final networks = data
            .where((p) => p['availability'] == true)
            .map((p) => AirtimeNetwork(
          network: p['network'].toString(),
          name:    p['name'].toString(),
          icon:    p['icon'].toString(),
          planId:  p['planID'].toString(),
        ))
            .toList();

        setState(() {
          _allNetworks     = networks;
          _selectedNetwork = networks.isNotEmpty ? networks.first : null;
        });
      } else {
        setState(() => _networksError =
            (decoded['message'] ?? 'Could not load networks.').toString());
      }
    } on TimeoutException {
      if (mounted) setState(() => _networksError = 'Request timed out. Please try again.');
    } catch (e) {
      if (mounted) setState(() => _networksError = 'Network error. Check your connection.');
    } finally {
      if (mounted) setState(() => _isLoadingNetworks = false);
    }
  }

  // ── Buy airtime ────────────────────────────────────────────────────────────
  Future<bool> buyAirtime(BuildContext loaderContext) async {
    final phone = _cleanPhone(phoneController.text);
    final amount  = selectedAmount ?? _controllerToInt(manualAmountController) ?? 0;
    final network = _selectedNetwork;

    if (userId.isEmpty) {
      _dismissLoader(loaderContext);
      _showSnack("Session expired. Please login again.");
      return false;
    }
    if (phone.isEmpty || phone.length < 11) {
      _dismissLoader(loaderContext);
      _showSnack("Enter a valid phone number");
      return false;
    }
    if (network == null) {
      _dismissLoader(loaderContext);
      _showSnack("Please select a network");
      return false;
    }
    if (amount < 50) {
      _dismissLoader(loaderContext);
      setState(() => singleAmountError = 'Minimum airtime is ₦50');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse("https://glopa.org/glo/buy_utility.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "action":  "AIRTIME",
          "plan_id": network.planId,
          "number":  phone,
          "amount":  amount.toInt(),
          "network": network.displayName,
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint("STATUS: ${response.statusCode}");
      debugPrint("BODY:   ${response.body}");

      if (response.body.isEmpty) {
        _dismissLoader(loaderContext);
        _showSnack("Empty response. Please try again.");
        return false;
      }

      final data    = jsonDecode(response.body);
      final status  = data['status']  ?? '';
      final code    = data['code']    ?? '';
      final message = data['message'] ?? 'Transaction failed. Please try again.';

      _dismissLoader(loaderContext);

      if (status == 'success') {
        if (!mounted) return false;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AirtimeSuccessScreen(
              amount:        amount,
              network:       network.displayName,
              phone:         phone,
              transactionId: data['transaction_id']?.toString() ?? '',
              ref:           data['ref']?.toString() ?? '',
              newBalance:    (data['new_balance'] as num?)?.toDouble() ?? 0.0,
              action: data['action']?.toString() ?? '',
            ),
          ),
        );
        return true;
      } else if (status == 'pending') {
        if (!mounted) return false;
        _showAlertDialog(
          title:   'Transaction Processing',
          content: 'Your transaction is being processed. You will receive a '
              'notification once confirmed. Your wallet has been debited '
              'and will be refunded if it fails.',
        );
        return false;
      } else if (code == 'PROVIDER_BALANCE_LOW' || code == 'SERVICE_UNAVAILABLE') {
        if (!mounted) return false;
        _showAlertDialog(
          icon:      Icons.warning_amber_rounded,
          iconColor: Colors.orange,
          title:     'Service Unavailable',
          content:   message,
        );
        return false;
      } else if (code == 'BELOW_MINIMUM') {
        if (!mounted) return false;
        _showAlertDialog(
          icon:      Icons.info_outline_rounded,
          iconColor: Colors.deepOrange,
          title:     'Amount Too Low',
          content:   message,
        );
        return false;
      } else {
        if (!mounted) return false;
        _showAlertDialog(
          icon:        Icons.cancel_outlined,
          iconColor:   Colors.red,
          title:       'Transaction Failed',
          content:     message,
          actionLabel: 'Try Again',
        );
        return false;
      }
    } on TimeoutException {
      _dismissLoader(loaderContext);
      _showSnack("Request timed out. Please check your connection and try again.");
      return false;
    } catch (e) {
      debugPrint("AIRTIME ERROR: $e");
      _dismissLoader(loaderContext);
      _showSnack("Network error. Please check your connection.");
      return false;
    }
  }

  void _dismissLoader(BuildContext loaderContext) {
    if (mounted) {
      try { Navigator.of(loaderContext).pop(); } catch (_) {}
    }
  }

  // ── Formatting helpers ─────────────────────────────────────────────────────
  void _formatAndClamp(TextEditingController controller) {
    final raw    = controller.text;
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      if (controller.text.isNotEmpty) {
        controller.value = const TextEditingValue(
            text: '', selection: TextSelection.collapsed(offset: 0));
      }
      return;
    }
    int value = int.tryParse(digits) ?? 0;
    if (value > 100000) value = 100000;
    final formatted = _numFormat.format(value);
    if (formatted != controller.text) {
      controller.value = TextEditingValue(
        text:      formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  int? _controllerToInt(TextEditingController controller) {
    final digits = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  int _bulkTotal() {
    var total = 0;
    for (var b in bulkItems) {
      total += _controllerToInt(b.amountCtrl) ?? 0;
    }
    return total;
  }
  String _cleanPhone(String phone) =>
      phone.replaceAll(RegExp(r'[^0-9]'), '');
  String? _validatePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 'Please enter mobile number';
    if (digits.length != 11) return 'Number must be 11 digits';
    final prefix = digits.substring(0, 3);
    if (!_validPrefixes.contains(prefix))
      return 'Number must start with 070, 071, 080, 081, 090 or 091';
    return null;
  }

  // ── Handlers ───────────────────────────────────────────────────────────────
  void _onQuickAmountTap(int amount) {
    setState(() {
      selectedAmount = amount;
      manualAmountController.text = _numFormat.format(amount);
      singleAmountError = null;
    });

    final phoneErr = _validatePhone(phoneController.text.trim());
    if (phoneErr != null) {
      setState(() => singlePhoneError = phoneErr);
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSingleConfirmModal();
    });
  }

  void _onContinuePressed() {
    setState(() {
      singlePhoneError  = null;
      singleAmountError = null;
      for (var b in bulkItems) {
        b.phoneError  = null;
        b.amountError = null;
      }
    });

    if (_tabController.index == 0) {
      final phoneErr = _validatePhone(phoneController.text.trim());
      final amt      = selectedAmount ?? _controllerToInt(manualAmountController);
      String? amtErr;
      if (amt == null || amt < 50) amtErr = 'Minimum airtime is ₦50';

      if (phoneErr != null || amtErr != null) {
        setState(() {
          singlePhoneError  = phoneErr;
          singleAmountError = amtErr;
        });
        return;
      }

      FocusManager.instance.primaryFocus?.unfocus();
      WidgetsBinding.instance.addPostFrameCallback(
              (_) => _showSingleConfirmModal());
    } else {
      if (bulkItems.isEmpty) {
        _showAlertDialog(
            title: 'No recipients',
            content: 'Add at least one recipient.');
        return;
      }

      var ok = true;
      for (var i = 0; i < bulkItems.length; i++) {
        final it       = bulkItems[i];
        final phoneErr = _validatePhone(it.phoneCtrl.text.trim());
        final amt      = _controllerToInt(it.amountCtrl);
        String? amtErr;
        if (amt == null || amt < 50) amtErr = 'Enter amount ≥ ₦50';
        if (phoneErr != null || amtErr != null) {
          ok = false;
          setState(() {
            it.phoneError  = phoneErr;
            it.amountError = amtErr;
          });
        } else {
          setState(() {
            it.phoneError  = null;
            it.amountError = null;
          });
        }
      }

      if (!ok) return;

      FocusManager.instance.primaryFocus?.unfocus();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showBulkConfirmModal());
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ── Alert dialog ───────────────────────────────────────────────────────────
  void _showAlertDialog({
    IconData? icon,
    Color?    iconColor,
    required String title,
    required String content,
    String actionLabel = 'OK',
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(title)),
        ]),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(actionLabel,
                style: TextStyle(color: Colors.deepOrange)),
          ),
        ],
      ),
    );
  }

  // ── Single confirm modal ───────────────────────────────────────────────────
  void _showSingleConfirmModal() {
    final phone = _cleanPhone(phoneController.text);
    final amount = selectedAmount ?? _controllerToInt(manualAmountController) ?? 0;
    final walletStr = userWallet;
    final walletFormatted = '₦${_numFormat.format(double.tryParse(walletStr) ?? 0)}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding:
        EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(
                child: Text('Airtime Payment',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            Text('₦${_numFormat.format(amount)}',
                style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange)),
            const SizedBox(height: 30),
            _confirmRow('Amount', '₦${_numFormat.format(amount)}'),
            const SizedBox(height: 8),
            _confirmRow('Network', _selectedNetwork?.displayName ?? ''),
            const SizedBox(height: 8),
            _confirmRow('Mobile number',
                _cleanPhone(phoneController.text).isEmpty
                    ? 'Not entered'
                    : _cleanPhone(phoneController.text)),
            const SizedBox(height: 8),
            _confirmRow('Payment method', 'Wallet ($walletFormatted)'),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                BuildContext? loaderCtx;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (c) {
                    loaderCtx = c;
                    return const Center(
                        child: CircularProgressIndicator());
                  },
                );
                await Future.microtask(() {});
                await buyAirtime(loaderCtx ?? context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm to Pay',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }

  // ── Bulk confirm modal ─────────────────────────────────────────────────────
  void _showBulkConfirmModal() {
    final recipients = bulkItems.map((b) => {
      'phone':   b.phoneCtrl.text.trim(),
      'network': _allNetworks.isNotEmpty
          ? _allNetworks[b.networkIndex].displayName
          : 'Network',
      'amount':  _controllerToInt(b.amountCtrl) ?? 0,
    }).toList();

    final total = _bulkTotal();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        final showCount =
        recipients.length > 3 ? 3 : recipients.length;
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 16),
            child:
            Column(mainAxisSize: MainAxisSize.min, children: [
              Center(
                  child: Text('Bulk Airtime Payment',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              Text('₦${_numFormat.format(total)}',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange)),
              const SizedBox(height: 12),
              Column(children: [
                for (var i = 0; i < showCount; i++)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Recipient ${i + 1}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '${recipients[i]['phone']} · ${recipients[i]['network']}'),
                    trailing: Text(
                        '₦${_numFormat.format(recipients[i]['amount'])}'),
                  ),
                if (recipients.length > 3)
                  GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showAllRecipientsSheet(recipients);
                    },
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('See All',
                          style: TextStyle(
                              color: Colors.deepOrange)),
                    ),
                  ),
              ]),
              const SizedBox(height: 8),
              _confirmRow(
                  'Payment method',
                  'Wallet (₦${_numFormat.format(double.tryParse(
                      userWallet ?? '0') ?? 0)})'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  BuildContext? loaderCtx;
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (c) {
                      loaderCtx = c;
                      return const Center(
                          child: CircularProgressIndicator());
                    },
                  );
                  await Future.microtask(() {});
                  await buyAirtime(loaderCtx ?? context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirm to Pay',
                    style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 12),
            ]),
          ),
        );
      },
    );
  }

  void _showAllRecipientsSheet(List<Map<String, dynamic>> recipients) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () {
                Navigator.of(ctx).pop();
                _showBulkConfirmModal();
              },
            ),
            const Spacer(),
            const Text('All Recipients',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
          ]),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: recipients.length,
              itemBuilder: (_, idx) {
                final r = recipients[idx];
                return ListTile(
                  title: Text('Recipient ${idx + 1}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600)),
                  subtitle:
                  Text('${r['phone']} · ${r['network']}'),
                  trailing: Text(
                      '₦${_numFormat.format(r['amount'])}'),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  // ── Small helpers ──────────────────────────────────────────────────────────
  Widget _confirmRow(String label, String value) {
    return Row(children: [
      Expanded(child: Text(label)),
      const SizedBox(width: 12),
      Text(value, textAlign: TextAlign.right),
    ]);
  }

  InputDecoration _inputDecoration(Color fillColor, bool isDark) {
    return InputDecoration(
      filled: true,
      fillColor: fillColor == Colors.white
          ? Colors.grey[100]
          : const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget _floatingCard(Color cardColor, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: child,
    );
  }

  Widget _continueButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size.fromHeight(50),
          elevation: 2),
      onPressed: _onContinuePressed,
      child: const Text('Continue',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16)),
    );
  }

  // ── Network + Phone card (Data screen style) ───────────────────────────────
  Widget _networkPhoneCard(Color cardColor, bool isDark, Color textColor) {
    // Show error if networks failed to load
    if (_networksError != null) {
      return Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(_networksError!,
                  style:
                  const TextStyle(color: Colors.red, fontSize: 12))),
          TextButton(
            onPressed: _fetchAirtimeNetworks,
            child: Text('Retry',
                style: TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            // ── Network dropdown ──────────────────────────────────────
            if (_isLoadingNetworks)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedNetwork?.planId,
                  dropdownColor: cardColor,
                  items: _allNetworks.map((net) {
                    return DropdownMenuItem<String>(
                      value: net.planId,
                      child: Row(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            net.icon,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => CircleAvatar(
                              radius: 16,
                              backgroundColor:
                              Colors.deepOrange.withOpacity(0.1),
                              child: Text(net.displayName[0],
                                  style: TextStyle(
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(net.displayName,
                            style: TextStyle(
                                fontSize: 13, color: textColor)),
                      ]),
                    );
                  }).toList(),
                  onChanged: (val) {
                    final raw = val ?? '';
                    setState(() => singlePhoneError = null);

                    // ── Auto-strip spaces/non-digits as user types or pastes ──
                    final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
                    if (cleaned != raw) {
                      phoneController.value = TextEditingValue(
                        text: cleaned,
                        selection: TextSelection.collapsed(offset: cleaned.length),
                      );
                    }

                    if (cleaned.length >= 4) {
                      final detected = _detectNetworkFromPhone(cleaned);
                      if (detected != null &&
                          detected.planId != _selectedNetwork?.planId) {
                        setState(() => _selectedNetwork = detected);
                      }
                    }
                  },
                ),
              ),

            const SizedBox(width: 8),

            // ── Phone field ───────────────────────────────────────────
            Expanded(
              child: TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Enter mobile number',
                  hintStyle: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() => singlePhoneError = null);
                  final digits =
                  val.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.length >= 4) {
                    final detected = _detectNetworkFromPhone(val);
                    if (detected != null &&
                        detected.planId != _selectedNetwork?.planId) {
                      setState(() => _selectedNetwork = detected);
                    }
                  }
                },
              ),
            ),

            // ── Contacts icon ─────────────────────────────────────────
            IconButton(
              onPressed: () {},
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

          // ── Detected network badge ────────────────────────────────────
          if (_selectedNetwork != null &&
              phoneController.text
                  .replaceAll(RegExp(r'[^0-9]'), '')
                  .length >=
                  4)
            Padding(
              padding:
              const EdgeInsets.only(left: 8, top: 4, bottom: 2),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    _selectedNetwork!.icon,
                    width: 18,
                    height: 18,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_selectedNetwork!.network} detected',
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.check_circle,
                    color: Color(0xFF22C55E), size: 13),
              ]),
            ),

          // ── Phone error ───────────────────────────────────────────────
          if (singlePhoneError != null)
            Padding(
              padding:
              const EdgeInsets.only(left: 8, top: 4, bottom: 2),
              child: Text(singlePhoneError!,
                  style: const TextStyle(
                      color: Colors.red, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme     = Theme.of(context);
    final isDark    = theme.brightness == Brightness.dark;
    final bgColor   = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFFFBFA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor: bgColor,
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context)),
        title: Text('Buy Airtime', style: TextStyle(color: textColor)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepOrange,
          unselectedLabelColor: textColor.withOpacity(0.6),
          indicatorColor: Colors.deepOrange,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Send to self'),
            Tab(text: 'Buy in bulk'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AirtimeHistoryScreen()
                )
            ),
            child: Text('History',
                style: TextStyle(color: Colors.deepOrange)),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _singlePurchaseUI(theme, cardColor, textColor, isDark),
          _bulkPurchaseUI(theme, cardColor, textColor, isDark),
        ],
      ),
    );
  }

  // ── Single purchase UI ─────────────────────────────────────────────────────
  Widget _singlePurchaseUI(ThemeData theme, Color cardColor,
      Color textColor, bool isDark) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      // ── Network + Phone card ─────────────────────────────────────────
      _networkPhoneCard(cardColor, isDark, textColor),
      const SizedBox(height: 12),

      // ── Amount card ──────────────────────────────────────────────────
      _floatingCard(cardColor,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Top up Airtime',
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.deepOrange)),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.4),
                  itemCount: quickAmounts.length,
                  itemBuilder: (context, index) {
                    final amount     = quickAmounts[index];
                    final isSelected = selectedAmount == amount;
                    return GestureDetector(
                      onTap: () => _onQuickAmountTap(amount),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.deepOrange
                              : (isDark
                              ? Colors.grey[800]
                              : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                  color:
                                  Colors.deepOrange.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3))
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text('₦${_numFormat.format(amount)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : textColor)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: manualAmountController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(cardColor, isDark).copyWith(
                    hintText: '50 - 100,000',
                    hintStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey),
                    prefixText: '₦ ',
                    prefixStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.w600),
                  ),
                  style: TextStyle(color: textColor),
                  onTap: () => setState(() {
                    selectedAmount    = null;
                    singleAmountError = null;
                  }),
                ),
                if (singleAmountError != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 6),
                    child: Text(singleAmountError!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 12)),
                  ),
                ],
              ])),
      const SizedBox(height: 20),
      _continueButton(),
    ]);
  }

  // ── Bulk purchase UI ───────────────────────────────────────────────────────
  Widget _bulkPurchaseUI(ThemeData theme, Color cardColor,
      Color textColor, bool isDark) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      ...bulkItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item  = entry.value;
        return Column(children: [
          // Network dropdown per bulk item
          if (_allNetworks.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: item.networkIndex,
                  isExpanded: true,
                  items: List.generate(_allNetworks.length, (i) {
                    final net = _allNetworks[i];
                    return DropdownMenuItem<int>(
                      value: i,
                      child: Row(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(net.icon,
                              width: 28,
                              height: 28,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                Colors.deepOrange.withOpacity(0.1),
                                child: Text(net.displayName[0],
                                    style: TextStyle(
                                        color: Colors.deepOrange,
                                        fontSize: 11)),
                              )),
                        ),
                        const SizedBox(width: 8),
                        Text(net.displayName,
                            style: TextStyle(
                                color: textColor, fontSize: 13)),
                      ]),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null)
                      setState(() => item.networkIndex = val);
                  },
                ),
              ),
            ),

          // Phone field
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3))
              ],
            ),
            child: TextField(
              controller: item.phoneCtrl,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Enter mobile number',
                hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey),
                border: InputBorder.none,
              ),
              onChanged: (_) =>
                  setState(() => item.phoneError = null),
            ),
          ),
          if (item.phoneError != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 6),
              child: Text(item.phoneError!,
                  style: const TextStyle(
                      color: Colors.red, fontSize: 12)),
            ),
          const SizedBox(height: 8),

          // Amount field
          TextFormField(
            controller: item.amountCtrl,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(cardColor, isDark).copyWith(
                hintText: '50 - 100,000',
                hintStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey),
                prefixText: '₦ ',
                prefixStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.w600)),
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black87),
            onTap: () =>
                setState(() => item.amountError = null),
          ),
          if (item.amountError != null)
            Padding(
              padding: const EdgeInsets.only(
                  left: 8, bottom: 6, top: 4),
              child: Text(item.amountError!,
                  style: const TextStyle(
                      color: Colors.red, fontSize: 12)),
            ),

          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Remove recipient',
              icon: Icon(Icons.close,
                  size: 20, color: Colors.deepOrange),
              onPressed: () => setState(() {
                bulkItems[index].dispose();
                bulkItems.removeAt(index);
              }),
            ),
          ),
          const SizedBox(height: 12),
        ]);
      }),

      OutlinedButton.icon(
        onPressed: () {
          setState(() {
            final newItem = BulkItem();
            newItem.amountCtrl
                .addListener(() => _formatAndClamp(newItem.amountCtrl));
            bulkItems.add(newItem);
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Add another recipient'),
      ),
      const SizedBox(height: 20),
      _continueButton(),
    ]);
  }
}

// ─── BulkItem ─────────────────────────────────────────────────────────────────
class BulkItem {
  TextEditingController phoneCtrl  = TextEditingController();
  TextEditingController amountCtrl = TextEditingController();
  int networkIndex = 0;

  String? phoneError;
  String? amountError;

  void dispose() {
    phoneCtrl.dispose();
    amountCtrl.dispose();
  }
}
