import 'package:flutter/material.dart';
import 'package:globalpay/home/finance/spend_save_withdraw.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpendAndSavePage extends StatefulWidget {
  const SpendAndSavePage({super.key});

  @override
  State<SpendAndSavePage> createState() => _SpendAndSavePageState();
}

class _SpendAndSavePageState extends State<SpendAndSavePage> {
  double savePercentage = 10;
  double pendingPercentage = 10;
  bool _hideBalance = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPercentage();
  }

  Future<void> _loadSavedPercentage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble('save_percentage') ?? 10.0;
    setState(() {
      savePercentage = saved;
      pendingPercentage = saved;
    });
  }

  Future<void> _savePercentage(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('save_percentage', value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const Color primary = Colors.deepOrange;

    final Color onSurface = theme.colorScheme.onSurface;
    final Color cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final Color divider = theme.dividerColor;
    final Color secondaryText = theme.textTheme.bodyMedium!.color!.withOpacity(
      isDark ? 0.6 : 0.7,
    );
    final Color scaffoldBg = isDark ? const Color(0xFF0F0F0F) : Colors.white;

    final Color sliderBg = isDark
        ? const Color(0xFF1C1C1E)
        : Colors.purple.shade50;
    final Color sliderBorder = isDark
        ? const Color(0xFF2C2C2E)
        : Colors.purple.shade100;
    final Color sliderLabelColor = isDark ? Colors.white70 : secondaryText;

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
          'Spend & Save',
          style: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.drag_indicator_rounded,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Summary card ──────────────────────────────────────────────
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
                  // Top accent bar
                  Container(
                    height: 4,
                    width: 48,
                    margin: const EdgeInsets.only(bottom: 18),
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

                  // "Saved" label + eye icon row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Saved',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: secondaryText,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _hideBalance = !_hideBalance),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            _hideBalance
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            key: ValueKey(_hideBalance),
                            size: 17,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Balance amount
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      _hideBalance ? '₦ •••••' : '₦0.00',
                      key: ValueKey(_hideBalance),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Withdraw button
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SpendAndSaveWithdrawPage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      height: 42,
                      width: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: primary, width: 1.5),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Center(
                        child: Text(
                          'Withdraw',
                          style: TextStyle(
                            color: primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Slider container ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
              decoration: BoxDecoration(
                color: sliderBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: sliderBorder, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Save after spend',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sliderLabelColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.deepOrange.withOpacity(0.15)
                              : Colors.deepOrange.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.deepOrange.withOpacity(0.35)
                                : Colors.deepOrange.shade200,
                          ),
                        ),
                        child: Text(
                          '${savePercentage.round()}% active',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.deepOrange.shade200
                                : Colors.deepOrange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final sliderWidth = constraints.maxWidth;
                      const thumbRadius = 12.0;
                      const trackPadding = 24.0;
                      final usable = sliderWidth - trackPadding * 2;
                      final dx =
                          trackPadding +
                          (pendingPercentage / 100) * usable -
                          thumbRadius;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 12,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 22,
                              ),
                              activeTrackColor: primary,
                              inactiveTrackColor: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : Colors.purple.shade100,
                              thumbColor: primary,
                              overlayColor: Colors.deepOrange.withOpacity(0.15),
                              trackHeight: 5,
                            ),
                            child: Slider(
                              value: pendingPercentage,
                              min: 0,
                              max: 100,
                              divisions: 20,
                              onChanged: (v) =>
                                  setState(() => pendingPercentage = v),
                              onChangeEnd: _showConfirmDialog,
                            ),
                          ),
                          Positioned(
                            left: dx.clamp(
                              0,
                              sliderWidth - thumbRadius * 2 - 12,
                            ),
                            top: -32,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepOrange.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${pendingPercentage.round()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Currently saving ${savePercentage.round()}% after each spend',
                    style: TextStyle(
                      color: sliderLabelColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Recent transactions ───────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : Colors.grey.shade100,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: onSurface,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'View All',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepOrange,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_right_rounded,
                              size: 18,
                              color: Colors.deepOrange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(color: divider, endIndent: 16, indent: 16, height: 1),
                  const SizedBox(height: 8),
                  _transactionTile(
                    'Grocery Shopping',
                    '-₦15,000',
                    Icons.shopping_cart_outlined,
                    onSurface,
                    cardBg,
                    isDark,
                  ),
                  _transactionTile(
                    'Transfer to Savings',
                    '-₦10,000',
                    Icons.send_outlined,
                    onSurface,
                    cardBg,
                    isDark,
                  ),
                  _transactionTile(
                    'Salary Credited',
                    '+₦120,000',
                    Icons.account_balance_outlined,
                    onSurface,
                    cardBg,
                    isDark,
                  ),
                  _transactionTile(
                    'Spend & Save Withdraw',
                    '+₦300.00',
                    Icons.savings_outlined,
                    onSurface,
                    cardBg,
                    isDark,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Confirm dialog ────────────────────────────────────────────────────────

  void _showConfirmDialog(double newPercentage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirm New Percentage',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'Change your save-after-spend rate to ${newPercentage.round()}%?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => pendingPercentage = savePercentage);
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() => savePercentage = newPercentage);
              await _savePercentage(newPercentage);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Confirm',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Transaction tile ──────────────────────────────────────────────────────

  Widget _transactionTile(
    String title,
    String amount,
    IconData icon,
    Color textColor,
    Color cardBg,
    bool isDark,
  ) {
    final isCredit = amount.startsWith('+');
    final amountColor = isCredit ? Colors.green : Colors.red;
    final iconBg = isCredit
        ? Colors.green.withOpacity(0.1)
        : Colors.red.withOpacity(0.1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: amountColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
            ),
            Text(
              _hideBalance ? '•••••' : amount,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
