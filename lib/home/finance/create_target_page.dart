import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:globalpay/home/finance/target_save.dart';


class CreateTargetPage extends StatefulWidget {
  const CreateTargetPage({Key? key}) : super(key: key);

  @override
  State<CreateTargetPage> createState() => _CreateTargetPageState();
}

class _CreateTargetPageState extends State<CreateTargetPage> {
  int currentStep = 0;

  // Controllers
  final amountController = TextEditingController();
  final nameController = TextEditingController();
  final preferredAmountController = TextEditingController();

  // Dates
  late DateTime startDate;
  late DateTime maturityDate;

  // State
  String? selectedFrequency;
  bool disableInterest = false;
  bool showMaturityPicker = false;
  String? amountError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    startDate = now;
    maturityDate = now.add(const Duration(days: 1));
  }

  /// Validations for each step
  bool get step1Valid =>
      amountController.text.isNotEmpty &&
          amountError == null &&
          selectedFrequency != null;

  bool get step2Valid => preferredAmountController.text.isNotEmpty;

  /// Called when user changes target amount
  void _onAmountChanged(String value) {
    final plain = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (plain.isEmpty) {
      preferredAmountController.clear();
      amountError = null;
      setState(() {});
      return;
    }

    final numValue = double.tryParse(plain) ?? 0;
    if (numValue < 1000) {
      amountError = "Minimum target amount is ₦1,000";
    } else if (numValue > 10000000) {
      amountError = "Maximum target amount is ₦10,000,000";
    } else {
      amountError = null;
    }

    _calculateDaily();
    setState(() {});
  }

  /// Auto-calculate daily savings
  void _calculateDaily() {
    final plain = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final total = double.tryParse(plain) ?? 0;
    final days = maturityDate.difference(startDate).inDays;
    if (days > 0 && total > 0) {
      final daily = total / days;
      preferredAmountController.text = daily.toStringAsFixed(2);
    } else {
      preferredAmountController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = Colors.deepOrange;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: theme.iconTheme.color,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Target',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(primaryColor),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStepContent(isDark),
              ),
            ),
            _buildBottomButton(primaryColor),
          ],
        ),
      ),
    );
  }

  /// --- Widgets ---
  Widget _buildProgressBar(Color primaryColor) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: List.generate(
              3,
                  (index) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  decoration: BoxDecoration(
                    color: index <= currentStep
                        ? primaryColor
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ),
        Text(
          '${currentStep + 1}/3',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Reach your financial goals with ease',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildBottomButton(Color primaryColor) {
    // validate
    bool disabled =
        (currentStep == 0 && !step1Valid) ||
            (currentStep == 1 && !step2Valid);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          // show back button only if step > 0
          if (currentStep > 0) ...[
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: const Size.fromHeight(55),
                ),
                onPressed: () {
                  if (currentStep > 0) {
                    setState(() => currentStep--);
                  }
                },
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // next / create target button
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: disabled ? Colors.grey : primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                minimumSize: const Size.fromHeight(55),
              ),
              onPressed: disabled
                  ? null
                  : () {
                if (currentStep < 2) {
                  setState(() => currentStep++);
                } else {
                  // Final submit → Navigate to FinancePage
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TargetSavingsPage(),
                    ),
                  );
                }
              },
              child: Text(
                currentStep < 2 ? 'Next' : 'Create target',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Step content builder
  Widget _buildStepContent(bool isDark) {
    final inputFill = isDark ? Colors.grey[850] : Colors.grey[100];
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );

    switch (currentStep) {
    // STEP 1: Basic info
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: inputFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    onChanged: _onAmountChanged,
                    decoration: InputDecoration(
                      prefixText: '₦ ',
                      labelText: 'Min ₦1,000.00- Max ₦10,000,000.00',
                      filled: true,
                      fillColor: inputFill,
                      border: border,
                      errorText: amountError,
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Target Name (Optional)',
                      filled: true,
                      fillColor:inputFill,
                      border: border,
                    ),
                  ),

                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    items: const [
                      DropdownMenuItem(value: 'Others', child: Text('Others')),
                      DropdownMenuItem(
                        value: 'Accommodation',
                        child: Text('Accommodation'),
                      ),
                      DropdownMenuItem(value: 'Business', child: Text('Business')),
                    ],
                    onChanged: (_) {},
                    decoration: InputDecoration(
                      labelText: 'Select a Category (optional)',
                      filled: true,
                      fillColor: inputFill,
                      border: border,
                    ),
                  ),

                ],
              ),
            ),


            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: inputFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    items: const [
                      DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                    ],
                    onChanged: (v) {
                      setState(() => selectedFrequency = v);
                    },
                    decoration: InputDecoration(
                      labelText: 'Select a Savings Frequency',
                      filled: true,
                      fillColor: inputFill,
                      border: border,
                    ),
                  ),

                  const SizedBox(height: 15),
                  TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Start Date & Time',
                      filled: true,
                      fillColor: inputFill,
                      border: border,
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: DateFormat('yyyy-MM-dd HH:mm').format(startDate),
                    ),
                  ),

                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () =>
                        setState(() => showMaturityPicker = !showMaturityPicker),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: inputFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Maturity Date: ${DateFormat('yyyy-MM-dd').format(maturityDate)}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(
                            showMaturityPicker
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.grey[700],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (showMaturityPicker)
                    SizedBox(
                      height: 150,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        minimumDate: startDate,
                        maximumDate: startDate.add(const Duration(days: 365 * 3)),
                        initialDateTime: maturityDate,
                        onDateTimeChanged: (date) {
                          setState(() {
                            maturityDate = date;
                            _calculateDaily();
                          });
                        },
                      ),
                    ),

                ],
              ),
            ),

          ],
        );

    // STEP 2: Preferred saving and interest
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: preferredAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '₦ ',
                labelText: 'Preferred amount to save Daily',
                filled: true,
                fillColor: inputFill,
                border: border,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: inputFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                value: disableInterest,
                onChanged: (v) => setState(() => disableInterest = v),
                activeColor: Colors.deepOrange,
                title: const Text('Enable Strict Saving Mode: Lock my funds until the target maturity date, with no option to cancel or withdraw early.',
                  style: TextStyle(
                      fontSize: 12
                  ),),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Payment Method:',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: inputFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Debit from GlobalPay Wallet'),
            ),
          ],
        );

    // STEP 3: Summary
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: inputFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Target Amount',
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                          ),
                        ),

                        Text(
                          ' ₦${amountController.text}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.deepOrange,
                          ),
                        ),

                        const Divider(color: Colors.grey),

                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Target Name:'),
                                Text(
                                  ' ${nameController.text.isEmpty ? "N/A" : nameController.text}',
                                ),
                              ],
                            ),
                            SizedBox(height: 15),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Category:'),
                                Text(' Business'),
                              ],
                            ),
                            SizedBox(height: 15),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Start Date:'),

                                Text(
                                  ' ${DateFormat('yyyy-MM-dd').format(startDate)}',
                                ),
                              ],
                            ),
                            SizedBox(height: 15),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Maturity Date:'),

                                Text(
                                  ' ${DateFormat('yyyy-MM-dd').format(maturityDate)}',
                                ),
                              ],
                            ),
                            SizedBox(height: 15),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Time:'),

                                Text(
                                  ' ${DateFormat('HH:mm').format(startDate)}',
                                ),
                              ],
                            ),
                            SizedBox(height: 25),

                            Stack(
                              children: [
                                Container(
                                  height: 43,
                                  width: 75,
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Edit ',
                                      style: TextStyle(
                                        color: Colors.deepOrange.shade900,
                                      ),
                                    ),
                                  ),
                                ),

                                Icon(Icons.edit, size: 20, color: Colors.white),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: inputFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Frequency:',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(' ₦${preferredAmountController.text} Daily')

                    ],
                  ),

                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Disable Interests on Savings:',
                      ),
                      Text(' ${disableInterest ? "On" : "Off"}')


                    ],
                  ),
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Payment Method:'),
                      Text(' GlobalPay Wallet')

                    ],
                  ),

                  SizedBox(height: 35),

                  Stack(
                    children: [
                      Container(
                        height: 43,
                        width: 75,
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            'Edit ',
                            style: TextStyle(
                              color: Colors.deepOrange.shade900,
                            ),
                          ),
                        ),
                      ),

                      Icon(Icons.edit, size: 20, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}