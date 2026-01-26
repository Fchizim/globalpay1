import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
<<<<<<< HEAD
import 'package:untitle1/home/all_asset.dart';
import 'package:untitle1/home/finance/spend_save.dart';
=======
import 'package:globalpay/home/all_asset.dart';
import 'package:globalpay/home/finance/spend_save.dart';
>>>>>>> c30d5f6 (initial commit)

import '../home/finance/budgeting_page.dart';
import '../home/finance/create_target_page.dart';
import '../home/finance/target_save.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.deepOrange.shade50.withOpacity(0.2),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        elevation: 0,
        title: Text(
          "Finance",
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 24,
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
                  padding: const EdgeInsets.all(16.0),
                  child: _balanceCard(isDark),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
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
                            isDark: isDark),
                      ),
                      _financeCard(width,
                          icon: Icons.savings,
                          title: "Safebox",
                          subtitle: "Hidden stash",
                          isDark: isDark),
                      _financeCard(width,
                          icon: Icons.request_quote,
                          title: "Loan",
                          subtitle: "Quick cash",
                          isDark: isDark),
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
                            isDark: isDark),
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
                            isDark: isDark),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _balanceCard(bool isDark) {
    return InkWell(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context)=> AllAsset()));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              height: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.deepOrange.shade300],
                ),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
            ),
            Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _PatchPainter())),
                Padding(
                  padding: const EdgeInsets.all(20.0),
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 5),
                              Text(
                                  _hideBalances
                                      ? "*****"
                                      : "₦850,000.00",
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 28,
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
                                  size: 24,
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
                                      size: 28,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.grey[700]
                                  ),
                                  onPressed: () => setState(
                                          () => _showDetails = !_showDetails)
                              )
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context)=> SpendAndSavePage()));
                              },
                              child: _subBalance("Spend & Save", "₦300,000.00",
                                  isDark),
                            ),
                            _subBalance("Safebox Balance", "₦200,000.00", isDark),
                            InkWell(
                              onTap: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context)=> TargetSavingsPage()));
                              },
                              child: _subBalance("Target Save Balance", "₦150,000.00",
                                  isDark),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                        crossFadeState: _showDetails
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 300),
                      ),
                      const SizedBox(height: 15),
                      _actionButton(
                          title: "Set a New Saving Goal",
                          icon: Icons.add_task,
                          onTap: () {}),
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

  Widget _subBalance(String label, String amount, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                  fontSize: 14)),
          Text(_hideBalances ? "*****" : amount,
              style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _actionButton(
      {required String title,
        required IconData icon,
        required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.purple,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
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
        required bool isDark}) {
    return Container(
      width: (width - 48) / 2,
      height: 130,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black12 : Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient avatar container
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.deepOrange.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const Spacer(),
          Text(title,
              style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Text(subtitle,
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                  fontSize: 12,
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
