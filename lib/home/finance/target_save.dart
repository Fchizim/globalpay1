import 'package:flutter/material.dart';
import 'package:globalpay/home/finance/create_target_page.dart';
import 'package:intl/intl.dart';
import 'target_model.dart';

// ─── Design tokens ─────────────────────────────────────────────────────────────

const Color _primary = Color(0xFFFF5722);
const Color _primaryLight = Color(0xFFFF5722);
const Color _darkText = Color(0xFF111827);
const Color _mutedText = Color(0xFF6B7280);

final _nf = NumberFormat('#,##0', 'en_US');
String _fmt(double v) => '₦${_nf.format(v)}';

// ─── Root app wrapper (place this at MaterialApp level) ───────────────────────

class TargetSavingsRoot extends StatefulWidget {
  final Widget child;
  const TargetSavingsRoot({super.key, required this.child});

  @override
  State<TargetSavingsRoot> createState() => _TargetSavingsRootState();
}

class _TargetSavingsRootState extends State<TargetSavingsRoot> {
  final List<SavingsTarget> _targets = [];

  void _add(SavingsTarget t) => setState(() => _targets.add(t));

  @override
  Widget build(BuildContext context) =>
      TargetStore(targets: _targets, addTarget: _add, child: widget.child);
}

// ─── Main page ─────────────────────────────────────────────────────────────────

class TargetSavingsPage extends StatefulWidget {
  const TargetSavingsPage({super.key});

  @override
  State<TargetSavingsPage> createState() => _TargetSavingsPageState();
}

class _TargetSavingsPageState extends State<TargetSavingsPage>
    with TickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── Scaffold ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final store = TargetStore.of(context);
    final targets = store?.targets ?? [];

    final active = targets.where((t) => !t.isCompleted).toList();
    final ended = targets.where((t) => t.isCompleted).toList();

    final totalSaved = targets.fold<double>(0, (s, t) => s + t.savedAmount);
    final bg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FB);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(isDark, bg),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                children: [
                  _balanceCard(isDark, totalSaved, targets.length),
                  const SizedBox(height: 16),
                  _quickStats(isDark, active, ended),
                  const SizedBox(height: 16),
                  _trendingSection(isDark),
                  const SizedBox(height: 20),
                  _tabBar(isDark),
                ],
              ),
            ),
          ),
          _buildTabContent(isDark, active, ended),
        ],
      ),
      floatingActionButton: _fab(),
    );
  }

  // ── Sliver AppBar ─────────────────────────────────────────────────────────────

  Widget _buildSliverAppBar(bool isDark, Color bg) {
    final canPop = Navigator.of(context).canPop();

    return SliverAppBar(
      backgroundColor: bg,
      elevation: 0,
      pinned: true,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          if (canPop)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: isDark ? Colors.white : _darkText,
              ),
            ),
          const SizedBox(width: 10),
          Text(
            'Target Savings',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : _darkText,
            ),
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: () => _openNotifications(context),
          child: Padding(
            padding: const EdgeInsets.only(right: 30),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 18,
              color: isDark ? Colors.white70 : _mutedText,
            ),
          ),
        ),
      ],
    );
  }

  void _openNotifications(BuildContext ctx) {
    // Placeholder
  }

  // ── Balance card ──────────────────────────────────────────────────────────────

  Widget _balanceCard(bool isDark, double totalSaved, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$count target${count != 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.lock_rounded, size: 14, color: Colors.white38),
              const SizedBox(width: 5),
              const Text(
                'Secured',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Total Saved',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            totalSaved == 0 ? '₦0.00' : _fmt(totalSaved),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white12),
          const SizedBox(height: 16),
          Row(
            children: [
              _balanceStat(
                'Active',
                '${TargetStore.of(context)?.targets.where((t) => !t.isCompleted).length ?? 0}',
              ),
              _balanceDivider(),
              _balanceStat(
                'Completed',
                '${TargetStore.of(context)?.targets.where((t) => t.isCompleted).length ?? 0}',
              ),
              _balanceDivider(),
              _balanceStat('This Month', _fmt(0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceStat(String label, String value) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    ),
  );

  Widget _balanceDivider() =>
      Container(width: 1, height: 30, color: Colors.white12);

  // ── Quick stats row ───────────────────────────────────────────────────────────

  Widget _quickStats(
    bool isDark,
    List<SavingsTarget> active,
    List<SavingsTarget> ended,
  ) {
    if (active.isEmpty) return const SizedBox.shrink();

    final closest = active.isEmpty
        ? null
        : active.reduce((a, b) => a.daysLeft < b.daysLeft ? a : b);

    final avgPct = active.isEmpty
        ? 0.0
        : active.fold<double>(0, (s, t) => s + t.progress) / active.length;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            isDark: isDark,
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFF7C3AED),
            label: 'Avg Progress',
            value: '${(avgPct * 100).toStringAsFixed(0)}%',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            isDark: isDark,
            icon: Icons.timer_outlined,
            iconColor: const Color(0xFF0891B2),
            label: 'Next Maturity',
            value: closest != null ? '${closest.daysLeft}d' : '—',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            isDark: isDark,
            icon: Icons.check_circle_outline_rounded,
            iconColor: Colors.green,
            label: 'Completed',
            value: '${ended.length}',
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : _darkText,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: isDark ? Colors.white38 : _mutedText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Trending section ──────────────────────────────────────────────────────────

  static const _trending = [
    {
      'title': 'Accommodation',
      'icon': Icons.home_rounded,
      'color': Color(0xFF7C3AED),
    },
    {
      'title': 'Education',
      'icon': Icons.school_rounded,
      'color': Color(0xFF2563EB),
    },
    {
      'title': 'Business',
      'icon': Icons.work_rounded,
      'color': Color(0xFF059669),
    },
    {
      'title': 'Travel',
      'icon': Icons.flight_takeoff_rounded,
      'color': Color(0xFF0891B2),
    },
    {
      'title': 'Appliances',
      'icon': Icons.kitchen_rounded,
      'color': Color(0xFFD97706),
    },
  ];

  Widget _trendingSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Popular Goals',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: isDark ? Colors.white : _darkText,
              ),
            ),
            const Text(
              'See all',
              style: TextStyle(
                fontSize: 13,
                color: _primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _trending.length,
            itemBuilder: (ctx, i) {
              final item = _trending[i];
              final color = item['color'] as Color;
              final icon = item['icon'] as IconData;
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateTargetPage()),
                ),
                child: Container(
                  width: 85,
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 10),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF0F0F0),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, size: 20, color: color),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['title'] as String,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : _mutedText,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────────────────────

  Widget _tabBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0),
        ),
      ),
      child: TabBar(
        controller: _tab,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white38 : _mutedText,
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: [_primary, _primaryLight]),
          borderRadius: BorderRadius.circular(11),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        labelPadding: EdgeInsets.zero,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'Active'),
          Tab(text: 'Completed'),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    bool isDark,
    List<SavingsTarget> active,
    List<SavingsTarget> ended,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: SizedBox(
          height: active.isEmpty && ended.isEmpty ? 260 : null,
          child: TabBarView(
            controller: _tab,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _targetList(isDark, active, empty: _emptyState(isDark, false)),
              _targetList(isDark, ended, empty: _emptyState(isDark, true)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _targetList(
    bool isDark,
    List<SavingsTarget> items, {
    required Widget empty,
  }) {
    if (items.isEmpty) return empty;
    return Column(
      children: [
        const SizedBox(height: 14),
        ...items.map((t) => _TargetCard(target: t, isDark: isDark)),
      ],
    );
  }

  Widget _emptyState(bool isDark, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              completed
                  ? Icons.check_circle_outline_rounded
                  : Icons.savings_outlined,
              size: 32,
              color: isDark ? Colors.white24 : const Color(0xFFD1D5DB),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            completed ? 'No completed targets yet' : 'No active targets',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : _mutedText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            completed
                ? 'Completed savings will appear here.'
                : 'Tap + to set your first savings goal.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white30 : const Color(0xFFD1D5DB),
            ),
          ),
        ],
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────────

  Widget _fab() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateTargetPage()),
      ),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_primary, _primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'New Target',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Target Card ───────────────────────────────────────────────────────────────

class _TargetCard extends StatelessWidget {
  final SavingsTarget target;
  final bool isDark;

  const _TargetCard({required this.target, required this.isDark});

  static const _catColors = {
    'Accommodation': Color(0xFF7C3AED),
    'Education': Color(0xFF2563EB),
    'Business': Color(0xFF059669),
    'Events': Color(0xFFDB2777),
    'Appliances': Color(0xFFD97706),
    'Emergencies': Color(0xFFDC2626),
    'Travel': Color(0xFF0891B2),
    'Festival': Color(0xFF7C3AED),
    'Life': Color(0xFFE11D48),
    'Family': Color(0xFF16A34A),
    'Others': Color(0xFF6B7280),
  };

  static const _catIcons = {
    'Accommodation': Icons.home_rounded,
    'Education': Icons.school_rounded,
    'Business': Icons.work_rounded,
    'Events': Icons.celebration_rounded,
    'Appliances': Icons.kitchen_rounded,
    'Emergencies': Icons.health_and_safety_rounded,
    'Travel': Icons.flight_takeoff_rounded,
    'Festival': Icons.auto_awesome_rounded,
    'Life': Icons.favorite_rounded,
    'Family': Icons.family_restroom_rounded,
    'Others': Icons.category_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final catColor = _catColors[target.category] ?? _primary;
    final catIcon = _catIcons[target.category] ?? Icons.savings_rounded;
    final pct = target.percentComplete;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(catIcon, size: 20, color: catColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.2,
                        color: isDark ? Colors.white : _darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      target.isCompleted
                          ? 'Completed · ${DateFormat('MMM d, yyyy').format(target.maturityDate)}'
                          : '${target.daysLeft} days left · matures ${DateFormat('MMM d').format(target.maturityDate)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: target.isCompleted
                            ? Colors.green
                            : (isDark ? Colors.white38 : _mutedText),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: target.isCompleted
                      ? Colors.green.withOpacity(0.1)
                      : catColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: target.isCompleted ? Colors.green : catColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              FractionallySizedBox(
                widthFactor: target.progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: target.isCompleted
                          ? [Colors.green, Colors.greenAccent]
                          : [catColor, catColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Amount row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _amountCell(
                label: 'Saved',
                value: _fmt(target.savedAmount),
                isDark: isDark,
                highlight: false,
              ),
              _amountCell(
                label: 'Target',
                value: _fmt(target.targetAmount),
                isDark: isDark,
                highlight: false,
              ),
              _amountCell(
                label: 'Per ${target.frequency.toLowerCase()}',
                value: _fmt(target.dailyAmount),
                isDark: isDark,
                highlight: true,
                color: catColor,
              ),
            ],
          ),

          if (target.strictMode) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 12, color: Color(0xFFDC2626)),
                  SizedBox(width: 5),
                  Text(
                    'Strict mode — locked until maturity',
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
    );
  }

  Widget _amountCell({
    required String label,
    required String value,
    required bool isDark,
    required bool highlight,
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: isDark ? Colors.white38 : _mutedText,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: highlight && color != null
                ? color
                : (isDark ? Colors.white : _darkText),
          ),
        ),
      ],
    );
  }
}
