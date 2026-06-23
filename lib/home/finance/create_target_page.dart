import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'target_model.dart';
import 'target_save.dart';

// ─── Formatting helpers ────────────────────────────────────────────────────────

final _nf = NumberFormat('#,##0', 'en_US');
final _nfDec = NumberFormat('#,##0.00', 'en_US');

String formatNaira(double v) => '₦${_nf.format(v)}';
String formatNairaFull(double v) => '₦${_nfDec.format(v)}';

// ─── Category model ────────────────────────────────────────────────────────────

class _CategoryItem {
  final String name;
  final IconData icon;
  final Color color;
  const _CategoryItem(this.name, this.icon, this.color);
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class CreateTargetPage extends StatefulWidget {
  const CreateTargetPage({super.key});

  @override
  State<CreateTargetPage> createState() => _CreateTargetPageState();
}

class _CreateTargetPageState extends State<CreateTargetPage>
    with SingleTickerProviderStateMixin {
  int currentStep = 0;

  final amountController = TextEditingController();
  final nameController = TextEditingController();
  final preferredAmountController = TextEditingController();

  // Track raw numeric input separately so we can format display
  double _rawAmount = 0;
  double _rawPreferred = 0;

  late DateTime startDate;
  late DateTime maturityDate;

  String? selectedFrequency;
  String? selectedCategory;
  bool strictMode = false;
  bool showMaturityPicker = false;
  String? amountError;

  // Animation
  late final AnimationController _stepAnim;

  // ── Design tokens ────────────────────────────────────────────────────────────
  static const Color primary = Colors.deepOrange;
  static const Color primaryLight = Colors.deepOrange;
  static const Color darkText = Color(0xFF111827);
  static const Color mutedText = Color(0xFF6B7280);

  static const List<_CategoryItem> categories = [
    _CategoryItem('Accommodation', Icons.home_rounded, Color(0xFF7C3AED)),
    _CategoryItem('Education', Icons.school_rounded, Color(0xFF2563EB)),
    _CategoryItem('Business', Icons.work_rounded, Color(0xFF059669)),
    _CategoryItem('Events', Icons.celebration_rounded, Color(0xFFDB2777)),
    _CategoryItem('Appliances', Icons.kitchen_rounded, Color(0xFFD97706)),
    _CategoryItem(
      'Emergencies',
      Icons.health_and_safety_rounded,
      Color(0xFFDC2626),
    ),
    _CategoryItem('Travel', Icons.flight_takeoff_rounded, Color(0xFF0891B2)),
    _CategoryItem('Festival', Icons.auto_awesome_rounded, Color(0xFF7C3AED)),
    _CategoryItem('Life', Icons.favorite_rounded, Color(0xFFE11D48)),
    _CategoryItem('Family', Icons.family_restroom_rounded, Color(0xFF16A34A)),
    _CategoryItem('Others', Icons.category_rounded, Color(0xFF6B7280)),
  ];

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    startDate = now;
    maturityDate = _dateOnly(now).add(const Duration(days: 30));
    _stepAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    amountController.dispose();
    nameController.dispose();
    preferredAmountController.dispose();
    _stepAnim.dispose();
    super.dispose();
  }

  // ── Validation ───────────────────────────────────────────────────────────────

  bool get step1Valid =>
      _rawAmount >= 1000 &&
      _rawAmount <= 10000000 &&
      amountError == null &&
      selectedFrequency != null;

  bool get step2Valid => _rawPreferred > 0;

  // ── Input handlers ───────────────────────────────────────────────────────────

  void _onAmountChanged(String value) {
    final plain = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (plain.isEmpty) {
      _rawAmount = 0;
      amountError = null;
      preferredAmountController.clear();
      setState(() {});
      return;
    }
    _rawAmount = double.parse(plain);
    if (_rawAmount < 1000) {
      amountError = 'Minimum is ₦1,000';
    } else if (_rawAmount > 10000000) {
      amountError = 'Maximum is ₦10,000,000';
    } else {
      amountError = null;
    }
    _calculateSplit();
    setState(() {});
  }

  void _onPreferredChanged(String value) {
    final plain = value.replaceAll(RegExp(r'[^0-9.]'), '');
    _rawPreferred = double.tryParse(plain) ?? 0;
    setState(() {});
  }

  void _calculateSplit() {
    final days = maturityDate.difference(_dateOnly(startDate)).inDays;
    if (days > 0 && _rawAmount > 0) {
      _rawPreferred = _rawAmount / days;
      preferredAmountController.text = _rawPreferred.toStringAsFixed(2);
    } else {
      preferredAmountController.clear();
      _rawPreferred = 0;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Future<void> _openCategoryModal(bool isDark) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryModal(
        isDark: isDark,
        categories: categories,
        selected: selectedCategory,
      ),
    );
    if (selected != null) setState(() => selectedCategory = selected);
  }

  void _submit() {
    final store = TargetStore.of(context);
    final target = SavingsTarget(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameController.text.trim().isEmpty
          ? (selectedCategory ?? 'My Target')
          : nameController.text.trim(),
      targetAmount: _rawAmount,
      dailyAmount: _rawPreferred,
      frequency: selectedFrequency!,
      category: selectedCategory,
      startDate: startDate,
      maturityDate: maturityDate,
      strictMode: strictMode,
    );
    store?.addTarget(target);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TargetSavingsPage()),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffold = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FB);

    return Scaffold(
      backgroundColor: scaffold,
      appBar: _buildAppBar(isDark, scaffold),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildProgressBar(isDark),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: child,
                    ),
                  ),
                  child: _buildStepContent(isDark),
                ),
              ),
            ),
            _buildBottomBar(isDark, scaffold),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, Color bg) {
    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: isDark ? Colors.white : darkText,
        ),
      ),
      title: Text(
        'New Target',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 17,
          letterSpacing: -0.4,
          color: isDark ? Colors.white : darkText,
        ),
      ),
      centerTitle: true,
    );
  }

  // ── Progress bar ─────────────────────────────────────────────────────────────

  Widget _buildProgressBar(bool isDark) {
    final steps = ['Target Info', 'Save Plan', 'Review'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: List.generate(3, (i) {
              final filled = i <= currentStep;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: filled
                              ? const LinearGradient(
                                  colors: [primary, primaryLight],
                                )
                              : null,
                          color: filled
                              ? null
                              : (isDark
                                    ? const Color(0xFF2C2C2E)
                                    : const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    if (i < 2) const SizedBox(width: 5),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) {
              final active = i == currentStep;
              final done = i < currentStep;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (done)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 12,
                      color: primary,
                    ),
                  if (done) const SizedBox(width: 3),
                  Text(
                    steps[i],
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: active
                          ? primary
                          : done
                          ? primary.withOpacity(0.7)
                          : (isDark ? Colors.white38 : mutedText),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Bottom CTA bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar(bool isDark, Color bg) {
    final disabled =
        (currentStep == 0 && !step1Valid) || (currentStep == 1 && !step2Valid);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE9EAEC),
          ),
        ),
      ),
      child: Row(
        children: [
          if (currentStep > 0) ...[
            GestureDetector(
              onTap: () => setState(() => currentStep--),
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Back',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white70 : mutedText,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: AnimatedOpacity(
              opacity: disabled ? 0.4 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: GestureDetector(
                onTap: disabled
                    ? null
                    : () {
                        if (currentStep < 2) {
                          setState(() => currentStep++);
                        } else {
                          _submit();
                        }
                      },
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: disabled
                        ? null
                        : const LinearGradient(
                            colors: [primary, primaryLight],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                    color: disabled ? const Color(0xFFD1D5DB) : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: disabled
                        ? null
                        : [
                            BoxShadow(
                              color: primary.withOpacity(0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 7),
                            ),
                          ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentStep < 2 ? 'Continue' : 'Create Target',
                          style: TextStyle(
                            color: disabled
                                ? const Color(0xFF9CA3AF)
                                : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.1,
                          ),
                        ),
                        if (!disabled) ...[
                          const SizedBox(width: 8),
                          Icon(
                            currentStep < 2
                                ? Icons.arrow_forward_rounded
                                : Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Field decoration ──────────────────────────────────────────────────────────

  InputDecoration _fieldDeco({
    required String label,
    required bool isDark,
    String? prefix,
    String? error,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      errorText: error,
      filled: true,
      fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      suffixIcon: suffix,
      labelStyle: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.white54 : mutedText,
      ),
      prefixStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : darkText,
      ),
      errorStyle: const TextStyle(fontSize: 11.5, color: Color(0xFFEF4444)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: _border(Colors.transparent),
      enabledBorder: _border(
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEEEFF1),
      ),
      focusedBorder: _border(primary, width: 1.5),
      errorBorder: _border(const Color(0xFFEF4444)),
      focusedErrorBorder: _border(const Color(0xFFEF4444), width: 1.5),
    );
  }

  OutlineInputBorder _border(Color c, {double width = 1}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: c, width: width),
  );

  // ── Card section wrapper ──────────────────────────────────────────────────────

  Widget _card({required Widget child, bool isDark = false}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0),
      ),
    ),
    child: child,
  );

  Widget _label(String text, {bool isDark = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: isDark ? Colors.white : Colors.black,
      ),
    ),
  );

  // ─── Step content ─────────────────────────────────────────────────────────────

  Widget _buildStepContent(bool isDark) {
    switch (currentStep) {
      case 0:
        return _buildStep1(isDark);
      case 1:
        return _buildStep2(isDark);
      case 2:
        return _buildStep3(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 1 ────────────────────────────────────────────────────────────────────

  Widget _buildStep1(bool isDark) {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('GOAL AMOUNT', isDark: isDark),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                onChanged: _onAmountChanged,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : darkText,
                  letterSpacing: -0.5,
                ),
                decoration: _fieldDeco(
                  label: '1,000 – 10,000,000',
                  isDark: isDark,
                  prefix: '₦ ',
                  error: amountError,
                ),
              ),
              if (_rawAmount >= 1000 && amountError == null) ...[
                const SizedBox(height: 10),
                _amountChips(),
              ],
              const SizedBox(height: 14),
              _label('TARGET NAME', isDark: isDark),
              TextField(
                controller: nameController,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : darkText,
                ),
                decoration: _fieldDeco(
                  label: 'e.g. My New Laptop  (optional)',
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 14),
              _label('CATEGORY', isDark: isDark),
              _categoryTile(isDark),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _card(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('SAVINGS FREQUENCY', isDark: isDark),
              _frequencySelector(isDark),
              const SizedBox(height: 14),
              _label('STARTS', isDark: isDark),
              _dateTile(
                icon: Icons.calendar_today_rounded,
                text: DateFormat('EEE, MMM d yyyy · HH:mm').format(startDate),
                isDark: isDark,
                tappable: false,
              ),
              const SizedBox(height: 14),
              _label('MATURES ON', isDark: isDark),
              _dateTile(
                icon: Icons.event_rounded,
                text: DateFormat('EEE, MMM d yyyy').format(maturityDate),
                isDark: isDark,
                tappable: true,
                active: showMaturityPicker,
                onTap: () =>
                    setState(() => showMaturityPicker = !showMaturityPicker),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOut,
                child: showMaturityPicker
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          height: 150,
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.date,
                            minimumDate: _dateOnly(
                              startDate,
                            ).add(const Duration(days: 1)),
                            maximumDate: _dateOnly(
                              startDate,
                            ).add(const Duration(days: 365 * 3)),
                            initialDateTime: maturityDate,
                            onDateTimeChanged: (d) {
                              setState(() {
                                maturityDate = _dateOnly(d);
                                _calculateSplit();
                              });
                            },
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              if (!showMaturityPicker && _rawAmount > 0) ...[
                const SizedBox(height: 12),
                _durationInsight(isDark),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _amountChips() {
    final multiples = [0.25, 0.5, 0.75, 1.0];
    return Wrap(
      spacing: 8,
      children: multiples.map((m) {
        final v = (_rawAmount * m).roundToDouble();
        if (v < 1000) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () {
            amountController.text = v.toStringAsFixed(0);
            _rawAmount = v;
            amountError = null;
            _calculateSplit();
            setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primary.withOpacity(0.2)),
            ),
            child: Text(
              '${(m * 100).toInt()}% · ${formatNaira(v)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _categoryTile(bool isDark) {
    final cat = selectedCategory == null
        ? null
        : categories.firstWhere((c) => c.name == selectedCategory);

    return GestureDetector(
      onTap: () => _openCategoryModal(isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cat != null
                ? cat.color.withOpacity(0.4)
                : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEEEFF1)),
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (cat?.color ?? mutedText).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                cat?.icon ?? Icons.grid_view_rounded,
                size: 18,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                cat?.name ?? 'Select category  (optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: cat != null ? FontWeight.w600 : FontWeight.w400,
                  color: cat != null
                      ? (isDark ? Colors.white : darkText)
                      : (isDark ? Colors.white38 : mutedText),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDark ? Colors.white30 : mutedText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _frequencySelector(bool isDark) {
    final options = ['Daily', 'Weekly', 'Monthly'];
    return Row(
      children: options.map((f) {
        final active = selectedFrequency == f;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedFrequency = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: f != options.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(colors: [primary, primaryLight])
                    : null,
                color: active
                    ? null
                    : (isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF4F5F7)),
                borderRadius: BorderRadius.circular(12),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: primary.withOpacity(0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? Colors.white
                        : (isDark ? Colors.white54 : mutedText),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _dateTile({
    required IconData icon,
    required String text,
    required bool isDark,
    required bool tappable,
    bool active = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? primary.withOpacity(0.5)
                : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEEEFF1)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? primary : (isDark ? Colors.white38 : mutedText),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : darkText,
                ),
              ),
            ),
            if (tappable)
              Icon(
                active
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: isDark ? Colors.white30 : mutedText,
              ),
          ],
        ),
      ),
    );
  }

  Widget _durationInsight(bool isDark) {
    final days = maturityDate.difference(_dateOnly(startDate)).inDays;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, size: 16, color: primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Save ${formatNaira(_rawAmount / days)}/day over $days days to reach ${formatNaira(_rawAmount)}',
              style: const TextStyle(
                fontSize: 12.5,
                color: primary,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2 ────────────────────────────────────────────────────────────────────

  Widget _buildStep2(bool isDark) {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(
                'AMOUNT PER ${(selectedFrequency ?? 'PERIOD').toUpperCase()}',
                isDark: isDark,
              ),
              TextField(
                controller: preferredAmountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: _onPreferredChanged,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : darkText,
                ),
                decoration: _fieldDeco(
                  label:
                      'Amount to save per ${selectedFrequency?.toLowerCase() ?? 'period'}',
                  isDark: isDark,
                  prefix: '₦ ',
                ),
              ),
              const SizedBox(height: 10),
              _progressPreview(isDark),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _card(
          isDark: isDark,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Strict Saving Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white : darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Funds are locked until maturity. No early withdrawal.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : mutedText,
                        height: 1.5,
                      ),
                    ),
                    if (strictMode) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              size: 12,
                              color: Color(0xFFDC2626),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Withdrawal locked until maturity',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: strictMode,
                  onChanged: (v) => setState(() => strictMode = v),
                  activeColor: primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _card(
          isDark: isDark,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primary, primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Glonest Wallet',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? Colors.white : darkText,
                    ),
                  ),
                  Text(
                    'Auto-debit enabled',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : mutedText,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 12,
                      color: Colors.green,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Connected',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _progressPreview(bool isDark) {
    final days = maturityDate.difference(_dateOnly(startDate)).inDays;
    final projected = (_rawPreferred * days).clamp(0, _rawAmount);
    final prog = _rawAmount > 0 ? (projected / _rawAmount) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Projected total',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : mutedText,
              ),
            ),
            Text(
              '${formatNaira(projected.toDouble())} / ${formatNaira(_rawAmount)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: prog >= 1.0
                    ? Colors.green
                    : (isDark ? Colors.white : darkText),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: prog.clamp(0.0, 1.0),
            backgroundColor: isDark
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation(
              prog >= 1.0 ? Colors.green : primary,
            ),
            minHeight: 7,
          ),
        ),
        if (prog >= 1.0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: const [
                Icon(Icons.check_circle_rounded, size: 13, color: Colors.green),
                SizedBox(width: 5),
                Text(
                  'You\'ll hit your goal on time!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Step 3 (Review) ───────────────────────────────────────────────────────────

  Widget _buildStep3(bool isDark) {
    final cat = selectedCategory == null
        ? null
        : categories.firstWhere((c) => c.name == selectedCategory);

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5722), Color(0xFFFF5722)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.32),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (cat != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(cat.icon, size: 18, color: Colors.white),
                    ),
                  if (cat != null) const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      nameController.text.trim().isEmpty
                          ? (selectedCategory ?? 'My Target')
                          : nameController.text.trim(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      selectedFrequency ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Target Amount',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                formatNaira(_rawAmount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.white24),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _heroStat('Starts', DateFormat('MMM d').format(startDate)),
                  _heroStat(
                    'Matures',
                    DateFormat('MMM d, yy').format(maturityDate),
                  ),
                  _heroStat(
                    'Save',
                    '${formatNaira(_rawPreferred)}/${_freqShort()}',
                  ),
                  _heroStat(
                    'Days',
                    '${maturityDate.difference(_dateOnly(startDate)).inDays}',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _card(
          isDark: isDark,
          child: Column(
            children: [
              _summaryRow(
                'Target Name',
                nameController.text.trim().isEmpty
                    ? '—'
                    : nameController.text.trim(),
                isDark: isDark,
              ),
              _summaryRow('Category', selectedCategory ?? '—', isDark: isDark),
              _summaryRow(
                'Start',
                DateFormat('MMM d, yyyy HH:mm').format(startDate),
                isDark: isDark,
              ),
              _summaryRow(
                'Maturity',
                DateFormat('MMM d, yyyy').format(maturityDate),
                isDark: isDark,
              ),
              const SizedBox(height: 6),
              _editChip(onTap: () => setState(() => currentStep = 0)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _card(
          isDark: isDark,
          child: Column(
            children: [
              _summaryRow(
                '${selectedFrequency ?? 'Period'} Savings',
                formatNairaFull(_rawPreferred),
                isDark: isDark,
              ),
              _summaryRow(
                'Strict Mode',
                strictMode ? 'Enabled' : 'Disabled',
                isDark: isDark,
                valueColor: strictMode ? const Color(0xFFDC2626) : Colors.green,
              ),
              _summaryRow('Payment', 'Glonest Wallet', isDark: isDark),
              const SizedBox(height: 6),
              _editChip(onTap: () => setState(() => currentStep = 1)),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  String _freqShort() {
    switch (selectedFrequency) {
      case 'Daily':
        return 'day';
      case 'Weekly':
        return 'wk';
      case 'Monthly':
        return 'mo';
      default:
        return '';
    }
  }

  Widget _heroStat(String label, String value) => Column(
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  Widget _summaryRow(
    String label,
    String value, {
    required bool isDark,
    Color? valueColor,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white38 : mutedText,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? (isDark ? Colors.white : darkText),
          ),
        ),
      ],
    ),
  );

  Widget _editChip({required VoidCallback onTap}) => Align(
    alignment: Alignment.centerRight,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_rounded, size: 13, color: primary),
            SizedBox(width: 5),
            Text(
              'Edit',
              style: TextStyle(
                color: primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── Category Modal ────────────────────────────────────────────────────────────

class _CategoryModal extends StatelessWidget {
  final bool isDark;
  final List<_CategoryItem> categories;
  final String? selected;

  const _CategoryModal({
    required this.isDark,
    required this.categories,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF111111) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const Text(
              'What are you saving for?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick the category that matches your goal.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 18),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.88,
              ),
              itemBuilder: (ctx, i) {
                final item = categories[i];
                final sel = item.name == selected;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, item.name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: sel
                          ? item.color.withOpacity(0.12)
                          : (isDark
                                ? const Color(0xFF1C1C1E)
                                : const Color(0xFFF4F5F7)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: sel ? item.color : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item.icon, size: 22, color: item.color),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel
                                ? item.color
                                : (isDark
                                      ? Colors.white60
                                      : const Color(0xFF6B7280)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
