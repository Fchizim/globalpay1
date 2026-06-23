import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SpendAndSaveWithdrawPage extends StatefulWidget {
  /// Pass the user's actual Spend & Save balance here.
  final double availableBalance;

  const SpendAndSaveWithdrawPage({super.key, this.availableBalance = 0.0});

  @override
  State<SpendAndSaveWithdrawPage> createState() =>
      _SpendAndSaveWithdrawPageState();
}

class _SpendAndSaveWithdrawPageState extends State<SpendAndSaveWithdrawPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  int? _selectedQuickPercent; // 25 | 50 | 75 | 100
  bool _isProcessing = false;

  static const Color _primary = Colors.deepOrange;

  // ── quick-select options ───────────────────────────────────────────────
  final List<_QuickOption> _quickOptions = const [
    _QuickOption(label: '25%', percent: 25),
    _QuickOption(label: '50%', percent: 50),
    _QuickOption(label: '75%', percent: 75),
    _QuickOption(label: 'All', percent: 100),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── helpers ────────────────────────────────────────────────────────────

  double get _enteredAmount {
    final raw = _amountController.text.replaceAll(',', '');
    return double.tryParse(raw) ?? 0.0;
  }

  bool get _isValid =>
      _enteredAmount > 0 && _enteredAmount <= widget.availableBalance;

  void _applyQuickPercent(int percent) {
    setState(() => _selectedQuickPercent = percent);
    final value = widget.availableBalance * percent / 100;
    _amountController.text = _formatAmount(value);
  }

  String _formatAmount(double v) {
    // e.g. 12345.6 → "12,345.60"
    final parts = v.toStringAsFixed(2).split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    );
    return '$whole.${parts[1]}';
  }

  void _onAmountChanged(String raw) {
    // clear quick-select highlight when user types manually
    setState(() => _selectedQuickPercent = null);
  }

  Future<void> _handleWithdraw() async {
    if (!_isValid) return;
    setState(() => _isProcessing = true);

    // Simulate network delay – replace with your actual API call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isProcessing = false);

    _showSuccessSheet();
  }

  // ── success bottom sheet ───────────────────────────────────────────────

  void _showSuccessSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 28),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.green,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Withdrawal Successful!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₦${_amountController.text} has been sent\nto your main wallet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // close sheet
                  Navigator.of(context).pop(); // go back
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color onSurface = theme.colorScheme.onSurface;
    final Color cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final Color scaffoldBg = isDark ? const Color(0xFF0F0F0F) : Colors.white;
    final Color secondaryText = theme.textTheme.bodyMedium!.color!.withOpacity(
      isDark ? 0.6 : 0.65,
    );
    final Color fieldBg = isDark
        ? const Color(0xFF1C1C1E)
        : Colors.grey.shade50;
    final Color fieldBorder = isDark
        ? const Color(0xFF2C2C2E)
        : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        title: Text(
          'Withdraw',
          style: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Balance summary card ─────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: cardBg,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : Colors.purple.shade50,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.25)
                          : Colors.purple.withOpacity(0.08),
                      spreadRadius: 2,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // accent bar
                    Container(
                      height: 4,
                      width: 48,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade400,
                            Colors.deepOrange.shade300,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Text(
                      'Spend & Save Balance',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: secondaryText,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₦${_formatAmount(widget.availableBalance)}',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Available to withdraw',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Amount input ─────────────────────────────────────────
              Text(
                'Enter amount',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: secondaryText,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: fieldBorder),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '₦',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ),
                      ),
                    ),
                    Container(width: 1, height: 28, color: fieldBorder),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        onChanged: _onAmountChanged,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                        ],
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                    // Clear button
                    if (_amountController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _amountController.clear();
                          setState(() => _selectedQuickPercent = null);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Quick-select chips ───────────────────────────────────
              Text(
                'Quick select',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: secondaryText,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: _quickOptions.map((opt) {
                  final selected = _selectedQuickPercent == opt.percent;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: opt.percent == 100 ? 0 : 10,
                      ),
                      child: GestureDetector(
                        onTap: () => _applyQuickPercent(opt.percent),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 48,
                          decoration: BoxDecoration(
                            color: selected
                                ? _primary
                                : (isDark
                                      ? const Color(0xFF1C1C1E)
                                      : Colors.grey.shade50),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? _primary
                                  : (isDark
                                        ? const Color(0xFF2C2C2E)
                                        : Colors.grey.shade200),
                              width: selected ? 0 : 1,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: Colors.deepOrange.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              opt.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white60
                                          : Colors.grey.shade700),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // ── Info note ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.deepOrange.withOpacity(0.08)
                      : Colors.deepOrange.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.deepOrange.withOpacity(0.2)
                        : Colors.deepOrange.shade100,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: isDark
                          ? Colors.deepOrange.shade200
                          : Colors.deepOrange.shade600,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Funds will be transferred instantly to your main wallet. No fees apply.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          color: isDark
                              ? Colors.deepOrange.shade200
                              : Colors.deepOrange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // ── Withdraw button ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isValid ? 1.0 : 0.45,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _handleWithdraw,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: _isValid ? 4 : 0,
                      shadowColor: Colors.deepOrange.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isValid
                                ? 'Withdraw ₦${_amountController.text}'
                                : 'Enter an amount',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data class ─────────────────────────────────────────────────────────────

class _QuickOption {
  final String label;
  final int percent;
  const _QuickOption({required this.label, required this.percent});
}
