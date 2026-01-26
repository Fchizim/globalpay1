import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'airtime_successful_page.dart';

class AirtimePage extends StatefulWidget {
  const AirtimePage({Key? key}) : super(key: key);

  @override
  State<AirtimePage> createState() => _AirtimePageState();
}

class _AirtimePageState extends State<AirtimePage> with SingleTickerProviderStateMixin {
  // Controllers & state
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController manualAmountController = TextEditingController();
  final List<int> quickAmounts = [50, 100, 200, 500, 1000, 2000, 5000, 10000, 50000];
  int? selectedAmount;
  int selectedIndex = 0;

  List<BulkItem> bulkItems = [BulkItem()];

  final Color primary = Colors.deepOrange;

  final List<Map<String, String>> networks = [
    {'name': 'MTN', 'logo': 'assets/images/png/mtn.jpeg'},
    {'name': 'Airtel', 'logo': 'assets/images/png/airtel.jpeg'},
    {'name': 'Glo', 'logo': 'assets/images/png/glo.jpeg'},
    {'name': '9mobile', 'logo': 'assets/images/png/9mobile.jpeg'},
  ];

  // formatter
  final NumberFormat _numFormat = NumberFormat.decimalPattern('en_US');

  late final TabController _tabController;

  // per-screen validation messages
  String? singlePhoneError;
  String? singleAmountError;

  // allowed Nigerian prefixes
  final List<String> _validPrefixes = ['070', '071', '080', '081', '090', '091'];

  @override
  void initState() {
    super.initState();
    // Tab controller to reliably read active tab
    _tabController = TabController(length: 2, vsync: this);

    // formatting listeners (live formatting while typing)
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

  // ------------------ Formatting helpers ------------------
  void _formatAndClamp(TextEditingController controller) {
    // remove non-digits
    final raw = controller.text;
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      // leave the field empty (so prefixText '₦ ' still shows from decoration)
      if (controller.text.isNotEmpty) {
        controller.value = const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
      }
      return;
    }
    int value = int.tryParse(digits) ?? 0;
    if (value > 100000) value = 100000;
    final formatted = _numFormat.format(value);
    if (formatted != controller.text) {
      controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  int? _controllerToInt(TextEditingController controller) {
    final digits = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  // compute bulk total
  int _bulkTotal() {
    var total = 0;
    for (var b in bulkItems) {
      final v = _controllerToInt(b.amountCtrl) ?? 0;
      total += v;
    }
    return total;
  }

  // validate single phone: length 11 and prefix
  String? _validatePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 'Please enter mobile number';
    if (digits.length != 11) return 'Number must be 11 digits';
    final prefix = digits.substring(0, 3);
    if (!_validPrefixes.contains(prefix)) return 'Number must start with 070, 071, 080, 081, 090 or 091';
    return null;
  }

  // ------------------ Quick tap and Continue handlers ------------------
  Future<void> _onQuickAmountTap(int amount) async {
    setState(() {
      selectedAmount = amount;
      manualAmountController.text = _numFormat.format(amount);
      singleAmountError = null; // clear amount error
    });
    await _showOneSecondLoader();
    _showSingleConfirmModal();
  }

  Future<void> _onContinuePressed() async {
    // clear previous errors
    setState(() {
      singlePhoneError = null;
      singleAmountError = null;
      for (var b in bulkItems) {
        b.phoneError = null;
        b.amountError = null;
      }
    });

    // use our TabController for reliable index
    final tabIndex = _tabController.index;
    if (tabIndex == 0) {
      // send to self
      final phone = phoneController.text.trim();
      final phoneErr = _validatePhone(phone);
      final amt = selectedAmount ?? _controllerToInt(manualAmountController);
      String? amtErr;
      if (amt == null || amt < 50) amtErr = 'Enter an amount between ₦50 and ₦100,000';

      if (phoneErr != null || amtErr != null) {
        // show inline errors
        setState(() {
          singlePhoneError = phoneErr;
          singleAmountError = amtErr;
        });
        return;
      }

      await _showOneSecondLoader();
      _showSingleConfirmModal();
    } else {
      // bulk
      if (bulkItems.isEmpty) {
        // no snack: show a top-level error under bulk area by using a temporary item? simpler: show dialog
        // But user asked no more snackbars for mistakes. We'll display a simple dialog here.
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('No recipients'),
            content: const Text('Add at least one recipient.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))
            ],
          ),
        );
        return;
      }

      var ok = true;
      for (var i = 0; i < bulkItems.length; i++) {
        final it = bulkItems[i];
        final phone = it.phoneCtrl.text.trim();
        final phoneErr = _validatePhone(phone);
        final amt = _controllerToInt(it.amountCtrl);
        String? amtErr;
        if (amt == null || amt < 50) amtErr = 'Enter amount ≥ ₦50';
        if (phoneErr != null || amtErr != null) {
          ok = false;
          setState(() {
            it.phoneError = phoneErr;
            it.amountError = amtErr;
          });
        } else {
          setState(() {
            it.phoneError = null;
            it.amountError = null;
          });
        }
      }

      if (!ok) {
        // don't continue, errors are shown inline
        return;
      }

      await _showOneSecondLoader();
      _showBulkConfirmModal();
    }
  }

  Future<void> _showOneSecondLoader() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.of(context).pop();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ------------------ Single modal ------------------
  void _showSingleConfirmModal() {
    final provider = networks[selectedIndex]['name'] ?? 'Provider';
    final phone = phoneController.text.trim();
    final amount = selectedAmount ?? _controllerToInt(manualAmountController) ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Text('Airtime Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            Text('₦${_numFormat.format(amount)}', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: primary)),
            const SizedBox(height: 30),
            Row(children: [
              Expanded(child: Text('Amount', style: TextStyle())),
              Text('₦${_numFormat.format(amount)}', style: const TextStyle()),
            ]),
            const SizedBox(height: 8),
            _confirmRow('Provider', provider),
            const SizedBox(height: 8),
            _confirmRow('Mobile number', phone.isEmpty ? 'Not entered' : phone),
            const SizedBox(height: 8),
            _confirmRow('Payment method', 'Balance(₦0.00)'),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _showPinBottomSheet(onConfirmed: (pin) {
                  _showSnack('Payment successful (demo). PIN: $pin');
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm to Pay', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }

  // ------------------ Bulk modal ------------------
  void _showBulkConfirmModal() {
    final recipients = bulkItems
        .map((b) => {
      'phone': b.phoneCtrl.text.trim(),
      'provider': networks[b.networkIndex]['name'] ?? 'Provider',
      'amount': _controllerToInt(b.amountCtrl) ?? 0
    })
        .toList();

    final total = _bulkTotal();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        final showCount = recipients.length > 3 ? 3 : recipients.length;
        final senderPhone = phoneController.text.trim();
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Center(child: Text('Bulk Airtime Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              // total amount under title (deep orange)
              Text('₦${_numFormat.format(total)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primary)),
              const SizedBox(height: 12),

              // recipients preview (up to 3)
              Column(
                children: [
                  for (var i = 0; i < showCount; i++)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Recipient ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${recipients[i]['phone']} , ${recipients[i]['provider']}'),
                      trailing: Text('₦${_numFormat.format(recipients[i]['amount'])}'),
                    ),
                  if (recipients.length > 3)
                    GestureDetector(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _showAllRecipientsSheet(recipients);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('See All', style: TextStyle(color: primary)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // mobile number that was imputed (sender phone)
              _confirmRow('Payment method', 'Balance(₦0.00)'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  final total = _bulkTotal(); // get total amount from all bulk entries
                  _showPinBottomSheet(
                    customAmount: total,
                    onConfirmed: (pin) {
                      _showSnack('Bulk payment successful (demo). PIN: $pin');
                    },
                  );
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirm to pay',style: TextStyle(color: Colors.white),),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // header with back button + title
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () {
                    Navigator.of(ctx).pop(); // close “See All”
                    // reopen the previous modal
                    _showBulkConfirmModal();
                  },
                ),
                const Spacer(),
                const Text(
                  'All Recipients',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),

            // scrollable list of all recipients
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: recipients.length,
                itemBuilder: (_, idx) {
                  final r = recipients[idx];
                  return ListTile(
                    title: Text(
                      'Recipient ${idx + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('${r['phone']} , ${r['provider']}'),
                    trailing: Text('₦${_numFormat.format(r['amount'])}'),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ------------------ PIN bottom sheet (auto-advance & auto-submit) ------------------
  // ------------------ PIN bottom sheet (auto-advance & auto-submit) ------------------
  void _showPinBottomSheet({required void Function(String pin) onConfirmed, int? customAmount}) {
    final ctrl1 = TextEditingController();
    final ctrl2 = TextEditingController();
    final ctrl3 = TextEditingController();
    final ctrl4 = TextEditingController();

    final n1 = FocusNode();
    final n2 = FocusNode();
    final n3 = FocusNode();
    final n4 = FocusNode();

    // If customAmount is provided (from bulk), use that; otherwise fall back
    final amount = customAmount ??
        selectedAmount ??
        _controllerToInt(manualAmountController) ??
        0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    'Input PIN',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₦${_numFormat.format(amount)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (int i = 0; i < 4; i++)
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: TextField(
                          controller: [ctrl1, ctrl2, ctrl3, ctrl4][i],
                          focusNode: [n1, n2, n3, n4][i],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          decoration: const InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) async {
                            if (v.isNotEmpty) {
                              if (i < 3) {
                                FocusScope.of(sheetCtx)
                                    .requestFocus([n2, n3, n4, n4][i]);
                              } else {
                                await Future.delayed(
                                    const Duration(milliseconds: 50));
                                final pin =
                                    '${ctrl1.text}${ctrl2.text}${ctrl3.text}${ctrl4.text}';
                                if (pin.length == 4) {
                                  if (Navigator.of(sheetCtx).canPop()) {
                                    Navigator.of(sheetCtx).pop();
                                  }
                                  onConfirmed(pin);
                                  if (mounted) {
                                    final phone = phoneController.text.trim();
                                    final amount = (customAmount ??
                                        selectedAmount ??
                                        _controllerToInt(manualAmountController) ??
                                        0)
                                        .toInt();
                                    final network = networks[selectedIndex]['name'] ?? 'Provider';

                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => AirtimeSuccessScreen(
                                          amount: amount,
                                          network: network,
                                          phone: phone,
                                        ),
                                      ),
                                    );
                                  }


                                }
                              }
                            } else if (i > 0) {
                              FocusScope.of(sheetCtx)
                                  .requestFocus([n1, n1, n2, n3][i]);
                            }
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(sheetCtx).pop();
                    _showSnack('Forgot PIN tapped');
                  },
                  child: const Text('Forgot PIN?'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) FocusScope.of(context).requestFocus(n1);
    });
  }

  // ------------------ small helpers ------------------
  Widget _confirmRow(String label, String value) {
    return Row(children: [
      Expanded(child: Text(label, style: const TextStyle())),
      const SizedBox(width: 12),
      Text(value, textAlign: TextAlign.right),
    ]);
  }

  // ------------------ UI ------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFFFBFA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor: bgColor,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Text('Buy Airtime', style: TextStyle(color: textColor)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primary,
          unselectedLabelColor: textColor.withOpacity(0.6),
          indicatorColor: primary,
          indicatorWeight: 3,
          tabs: const [Tab(text: 'Send to self'), Tab(text: 'Buy in bulk')],
        ),
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

  Widget _singlePurchaseUI(ThemeData theme, Color cardColor, Color textColor, bool isDark) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      // network + phone widget with inline error display
      _networkPhoneWidget(
        selectedIndex: selectedIndex,
        onNetworkChanged: (val) => setState(() => selectedIndex = val),
        phoneController: phoneController,
        cardColor: cardColor,
        isDark: isDark,
        phoneError: singlePhoneError,
      ),
      if (singlePhoneError != null) const SizedBox(height: 6),
      if (singlePhoneError != null)
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 6),
          child: Text(singlePhoneError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ),

      const SizedBox(height: 8),

      _floatingCard(
        cardColor,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Top up Airtime', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.4),
            itemCount: quickAmounts.length,
            itemBuilder: (context, index) {
              final amount = quickAmounts[index];
              final isSelected = selectedAmount == amount;
              return GestureDetector(
                onTap: () => _onQuickAmountTap(amount),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? primary : (isDark ? Colors.grey[800] : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [if (isSelected) BoxShadow(color: primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))],
                  ),
                  alignment: Alignment.center,
                  child: Text('₦${_numFormat.format(amount)}', style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : textColor)),
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
              hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
              prefixText: '₦ ',
              prefixStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w600),
            ),
            style: TextStyle(color: textColor),
            onTap: () => setState(() {
              selectedAmount = null;
              singleAmountError = null;
            }),
          ),
          if (singleAmountError != null) const SizedBox(height: 8),
          if (singleAmountError != null)
            Padding(
              padding: const EdgeInsets.only(left: 4.0, top: 6),
              child: Text(singleAmountError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
        ]),
      ),
      const SizedBox(height: 20),
      _continueButton(),
    ]);
  }

  Widget _bulkPurchaseUI(ThemeData theme, Color cardColor, Color textColor, bool isDark) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      ...bulkItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Column(children: [
          // the network + phone widget (with per-item error)
          _networkPhoneWidget(
            selectedIndex: item.networkIndex,
            onNetworkChanged: (val) => setState(() => item.networkIndex = val),
            phoneController: item.phoneCtrl,
            cardColor: cardColor,
            isDark: isDark,
            phoneError: item.phoneError,
          ),
          if (item.phoneError != null) const SizedBox(height: 6),
          if (item.phoneError != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 6),
              child: Text(item.phoneError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),

          const SizedBox(height: 8),

          // amount input
          TextFormField(
            controller: item.amountCtrl,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(cardColor, isDark).copyWith(
                hintText: '50 - 100,000',
                hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                prefixText: '₦ ',
                prefixStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w600)),
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            onTap: () {
              setState(() {
                item.amountError = null;
              });
            },
          ),

          if (item.amountError != null) const SizedBox(height: 6),
          if (item.amountError != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 6),
              child: Text(item.amountError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),

          // small, unobtrusive remove (X) button aligned to the right
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 36,
              height: 36,
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: 'Remove recipient',
                icon: Icon(Icons.close, size: 20, color: Colors.redAccent),
                onPressed: () {
                  // if user tries to remove, dispose controllers and remove entry
                  setState(() {
                    bulkItems[index].dispose();
                    bulkItems.removeAt(index);
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 12),
        ]);
      }),

      OutlinedButton.icon(
        onPressed: () {
          setState(() {
            final newItem = BulkItem();
            newItem.amountCtrl.addListener(() => _formatAndClamp(newItem.amountCtrl));
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

  Widget _networkPhoneWidget({
    required int selectedIndex,
    required ValueChanged<int> onNetworkChanged,
    required TextEditingController phoneController,
    required Color cardColor,
    required bool isDark,
    String? phoneError,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: selectedIndex,
            items: List.generate(networks.length, (index) {
              final net = networks[index];
              return DropdownMenuItem<int>(
                value: index,
                child: Row(children: [
                  CircleAvatar(radius: 17, backgroundImage: AssetImage(net['logo']!)),
                  const SizedBox(width: 6),
                  Text(net['name']!, style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87)),
                ]),
              );
            }),
            onChanged: (val) {
              if (val != null) onNetworkChanged(val);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Enter mobile number',
              hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
              border: InputBorder.none,
            ),
            onChanged: (_) {
              // clear inline error for this controller when typing
              setState(() {
                if (phoneController == this.phoneController) singlePhoneError = null;
                for (var b in bulkItems) {
                  if (b.phoneCtrl == phoneController) b.phoneError = null;
                }
              });
            },
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Container(height: 30, width: 30, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: primary.withOpacity(0.1)), child: Icon(Icons.person, color: primary)),
        ),
      ]),
    );
  }

  Widget _continueButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), minimumSize: const Size.fromHeight(50), elevation: 2),
      onPressed: _onContinuePressed,
      child: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
    );
  }

  InputDecoration _inputDecoration(Color fillColor, bool isDark) {
    return InputDecoration(
      filled: true,
      fillColor: fillColor == Colors.white ? Colors.grey[100] : const Color(0xFF1E1E1E),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget _floatingCard(Color cardColor, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}

// BulkItem class
class BulkItem {
  TextEditingController phoneCtrl = TextEditingController();
  TextEditingController amountCtrl = TextEditingController();
  int networkIndex = 0;

  // inline errors
  String? phoneError;
  String? amountError;

  void dispose() {
    phoneCtrl.dispose();
    amountCtrl.dispose();
  }
}

