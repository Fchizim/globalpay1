import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:globalpay/home/all_asset.dart';
import 'package:globalpay/home/finance/spend_save.dart';

import '../home/finance/budgeting_page.dart';
import '../home/finance/create_target_page.dart';
import '../home/finance/target_save.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _showDetails = false;
  bool _hideBalances = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide =
        Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double s(double value, BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return (sw / 375 * value).clamp(value * 0.85, value * 1.25);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : Colors.deepOrange.shade50.withOpacity(0.2),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        elevation: 0,
        title: Text(
          "Finance",
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: s(24, context),
              fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(s(16, context)),
                  child: _balanceCard(isDark, context),
                ),
                Padding(
                  padding:
                  EdgeInsets.symmetric(horizontal: s(16, context)),
                  child: Wrap(
                    spacing: s(16, context),
                    runSpacing: s(16, context),
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CreateTargetPage()));
                        },
                        child: _financeCard(width,
                            icon: Icons.flag,
                            title: "Target Save",
                            subtitle: "Set savings goals",
                            isDark: isDark,
                            context: context),
                      ),
                      _financeCard(width,
                          icon: Icons.savings,
                          title: "Safebox",
                          subtitle: "Hidden stash",
                          isDark: isDark,
                          context: context),
                      _financeCard(width,
                          icon: Icons.request_quote,
                          title: "Loan",
                          subtitle: "Quick cash",
                          isDark: isDark,
                          context: context),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SpendAndSavePage()));
                        },
                        child: _financeCard(width,
                            icon: IconsaxPlusBold.money_3,
                            title: "Spend & Save",
                            subtitle: "Save a percentage everytime you spend",
                            isDark: isDark,
                            context: context),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => BudgetingPage()));
                        },
                        child: _financeCard(width,
                            icon: Icons.pie_chart_outline,
                            title: "Budgeting",
                            subtitle: "Track expenses",
                            isDark: isDark,
                            context: context),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: s(30, context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _balanceCard(bool isDark, BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => AllAsset()));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(s(16, context)),
          boxShadow: [
            BoxShadow(
                color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: s(5, context),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.deepOrange.shade300],
                ),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(s(16, context)),
                    topRight: Radius.circular(s(16, context))),
              ),
            ),
            Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _PatchPainter())),
                Padding(
                  padding: EdgeInsets.all(s(20, context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Total Assets",
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.grey[700],
                                      fontSize: s(14, context),
                                      fontWeight: FontWeight.w500)),
                              SizedBox(height: s(5, context)),
                              Text(
                                  _hideBalances
                                      ? "*****"
                                      : "₦0.00",
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: s(28, context),
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _hideBalances
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: s(24, context),
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey[700],
                                ),
                                onPressed: () => setState(() {
                                  _hideBalances = !_hideBalances;
                                }),
                              ),
                              IconButton(
                                  icon: Icon(
                                      _showDetails
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      size: s(28, context),
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.grey[700]),
                                  onPressed: () =>
                                      setState(() => _showDetails = !_showDetails))
                            ],
                          )
                        ],
                      ),
                      SizedBox(height: s(10, context)),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context)=> SpendAndSavePage()));
                              },
                              child: _subBalance("Spend & Save", "₦0.00",
                                  isDark, context),
                            ),
                            _subBalance("Safebox Balance", "₦0.00", isDark, context),
                            InkWell(
                              onTap: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context)=> TargetSavingsPage()));
                              },
                              child: _subBalance("Target Save Balance", "₦0.00",
                                  isDark, context),
                            ),
                            SizedBox(height: s(10, context)),
                          ],
                        ),
                        crossFadeState: _showDetails
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 300),
                      ),
                      SizedBox(height: s(15, context)),
                      _actionButton(
                          title: "Set a New Saving Goal",
                          icon: Icons.add_task,
                          onTap: () {},
                          context: context),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _subBalance(String label, String amount, bool isDark, BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: s(8, context)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                  fontSize: s(14, context))),
          Text(_hideBalances ? "*****" : amount,
              style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: s(15, context),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _actionButton(
      {required String title,
        required IconData icon,
        required VoidCallback onTap,
        required BuildContext context}) {
    return InkWell(
      borderRadius: BorderRadius.circular(s(12, context)),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
            vertical: s(14, context), horizontal: s(12, context)),
        decoration: BoxDecoration(
          color: Colors.purple,
          borderRadius: BorderRadius.circular(s(12, context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: s(18, context)),
            SizedBox(width: s(8, context)),
            Flexible(
              child: Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: s(13, context),
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _financeCard(double width,
      {required IconData icon,
        required String title,
        required String subtitle,
        required bool isDark,
        required BuildContext context}) {
    final cardWidth = (width - s(48, context)) / 2;
    return Container(
      width: cardWidth,
      height: s(130, context),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(s(18, context)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black12 : Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: EdgeInsets.all(s(16, context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: s(36, context),
            height: s(36, context),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.deepOrange.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            child: Icon(icon, color: Colors.white, size: s(20, context)),
          ),
          const Spacer(),
          Text(title,
              style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: s(16, context),
                  fontWeight: FontWeight.bold)),
          Text(subtitle,
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                  fontSize: s(12, context),
                  fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }
}

class _PatchPainter extends CustomPainter {
  final Random _rand = Random();

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 16; i++) {
      double x = _rand.nextDouble() * size.width;
      double y = _rand.nextDouble() * size.height;
      double radius = 2 + _rand.nextDouble() * 4;
      Color color = (_rand.nextBool()
          ? Colors.pinkAccent.withOpacity(0.15)
          : Colors.blueAccent.withOpacity(0.15));
      final paint = Paint()..color = color;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
