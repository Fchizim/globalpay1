import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpendAndSavePage extends StatefulWidget {
  const SpendAndSavePage({super.key});

  @override
  State<SpendAndSavePage> createState() => _SpendAndSavePageState();
}

class _SpendAndSavePageState extends State<SpendAndSavePage> {
  double savePercentage = 10;
  double pendingPercentage = 10;

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
    final Color cardBg = theme.cardColor;
    final Color divider = theme.dividerColor;
    final Color secondaryText =
    theme.textTheme.bodyMedium!.color!.withOpacity(isDark ? 0.6 : 0.7);

    // ✅ black in dark mode, white in light mode
    final Color scaffoldBg = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Spend & Save",
          style: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 19.0),
            child: Icon(Icons.drag_indicator),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card (purple gradient always)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.4),
                    spreadRadius: 4,
                    blurRadius: 4,
                    offset: const Offset(0, 3),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.purple.shade50,
                    Colors.purple.shade100,
                    scaffoldBg,
                  ],
                  stops: const [0.0, 0.1, 0.6],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "Saved",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₦0.00",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text('Total Interest',
                              style: TextStyle(color: secondaryText)),
                          Text('₦0.00',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: onSurface)),
                        ],
                      ),
                      Column(
                        children: [
                          Text('Save Count',
                              style: TextStyle(color: secondaryText)),
                          Text('0',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: onSurface)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: InkWell(
                      onTap: () {},
                      child: Container(
                        height: 35,
                        width: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: primary),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Center(
                          child: Text(
                            "Withdraw",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Slider
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.purple.shade50, // keep purple always
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  LayoutBuilder(builder: (context, constraints) {
                    final sliderWidth = constraints.maxWidth;
                    const thumbRadius = 12.0;
                    final dx = (pendingPercentage / 100) *
                        (sliderWidth - thumbRadius * 2);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 12),
                          ),
                          child: Slider(
                            value: pendingPercentage,
                            min: 0,
                            max: 100,
                            divisions: 20,
                            activeColor: primary,
                            onChanged: (value) {
                              setState(() {
                                pendingPercentage = value;
                              });
                            },
                            onChangeEnd: (value) {
                              _showConfirmDialog(value);
                            },
                          ),
                        ),
                        Positioned(
                          left: dx,
                          top: -28,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${pendingPercentage.round()}%",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  // 🔹 only change here:
                  Text(
                    "Currently saving ${savePercentage.round()}% after each spend",
                    style: TextStyle(
                      color: isDark ? Colors.black : secondaryText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Transactions
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text("Recent Transactions",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: onSurface)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 15),
                        child: Row(
                          children: [
                            Text("View All",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.deepOrange)),
                            const Icon(Icons.keyboard_arrow_right_outlined,
                                size: 20, color: Colors.deepOrange),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Divider(color: divider, endIndent: 10, indent: 10),
                  const SizedBox(height: 10),
                  _transactionTile(
                      "Grocery Shopping", "-₦15,000", onSurface, cardBg),
                  _transactionTile(
                      "Transfer to Savings", "-₦10,000", onSurface, cardBg),
                  _transactionTile(
                      "Salary Credited", "+₦120,000", onSurface, cardBg),
                  _transactionTile("Spend & Save Withdraw", "+₦300.00",
                      onSurface, cardBg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(double newPercentage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm New Percentage"),
        content: Text(
          "Do you want to change the save-after-spend percentage to ${newPercentage.round()}%?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                pendingPercentage = savePercentage;
              });
              Navigator.of(ctx).pop();
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                savePercentage = newPercentage;
              });
              await _savePercentage(newPercentage);
              Navigator.of(ctx).pop();
            },
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Widget _transactionTile(
      String title, String amount, Color textColor, Color cardBg) {
    final isCredit = amount.startsWith('+');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: textColor)),
          Text(amount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isCredit ? Colors.green : Colors.red,
              )),
        ],
      ),
    );
  }
}
