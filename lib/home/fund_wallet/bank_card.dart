import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class TopUpCardPage extends StatefulWidget {
  const TopUpCardPage({super.key});

  @override
  State<TopUpCardPage> createState() => _TopUpCardPageState();
}

class _TopUpCardPageState extends State<TopUpCardPage> {
  final _formKey = GlobalKey<FormState>();

  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _pinController = TextEditingController();
  final _amountController = TextEditingController();

  bool _saveCard = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _pinController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(
      BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fieldColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: theme.colorScheme.primary),
      filled: true,
      fillColor: fieldColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  Future<void> _showExpiryPicker() async {
    final now = DateTime.now();
    int selectedMonth = now.month;
    int selectedYear = now.year;

    // 👇 build the rolling 11-year list dynamically
    final List<int> years = List.generate(11, (index) => now.year + index);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    await showModalBottomSheet(
      context: context,
      backgroundColor: sheetColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SizedBox(
              height: 300,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Select Expiry Date",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Months wheel
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            itemExtent: 40,
                            perspective: 0.001,
                            physics: const FixedExtentScrollPhysics(),
                            useMagnifier: true,
                            magnification: 1.2,
                            overAndUnderCenterOpacity: 0.4,
                            onSelectedItemChanged: (index) {
                              setSheetState(() => selectedMonth = index + 1);
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, index) {
                                return Center(
                                  child: Text(
                                    "${index + 1}".padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                );
                              },
                              childCount: 12,
                            ),
                          ),
                        ),
                        // Years wheel
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            itemExtent: 40,
                            perspective: 0.001,
                            physics: const FixedExtentScrollPhysics(),
                            useMagnifier: true,
                            magnification: 1.2,
                            overAndUnderCenterOpacity: 0.4,
                            onSelectedItemChanged: (index) {
                              setSheetState(() => selectedYear = years[index]);
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, index) {
                                return Center(
                                  child: Text(
                                    "${years[index]}",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                );
                              },
                              childCount: years.length,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        final mm = selectedMonth.toString().padLeft(2, '0');
                        _expiryController.text =
                        "$mm/${selectedYear % 100}";
                        Navigator.pop(context);
                      },
                      child: const Text("Select"),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldColor =
    isDark ? const Color(0xFF121212) : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: scaffoldColor,
        title: Text(
          'Top-Up with Bank Card',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scaffoldColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _cardNumberController,
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecoration(
                        context, 'Card Number', IconsaxPlusLinear.card),
                    validator: (val) =>
                    val == null || val.length < 16
                        ? 'Enter valid card number'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _showExpiryPicker,
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: _expiryController,
                              decoration: _fieldDecoration(
                                  context, 'MM/YY', IconsaxPlusLinear.calendar),
                              validator: (val) =>
                              val == null || val.isEmpty
                                  ? 'Enter expiry'
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _cvvController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          decoration: _fieldDecoration(
                              context, 'CVV', IconsaxPlusLinear.lock),
                          validator: (val) =>
                          val == null || val.length < 3
                              ? 'Enter CVV'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: _fieldDecoration(
                        context, 'Enter Card PIN', IconsaxPlusLinear.key),
                    validator: (val) =>
                    val == null || val.length < 4 ? 'Enter PIN' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecoration(
                        context, 'Amount (₦)', IconsaxPlusLinear.money),
                    validator: (val) =>
                    val == null || val.isEmpty ? 'Enter amount' : null,
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _saveCard,
                    onChanged: (v) =>
                        setState(() => _saveCard = v ?? false),
                    title: Text(
                      'Save this card for future top-ups',
                      style: theme.textTheme.bodyMedium,
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isProcessing
                    ? null
                    : () {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isProcessing = true);
                    Future.delayed(const Duration(seconds: 2), () {
                      setState(() => _isProcessing = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Top-Up Successful!'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    });
                  }
                },
                icon: _isProcessing
                    ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Icon(IconsaxPlusLinear.card_add,
                    color: Colors.white),
                label: Text(
                  _isProcessing ? 'Processing...' : 'Top-Up Now',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
