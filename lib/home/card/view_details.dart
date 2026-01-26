import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CardDetailsPage extends StatelessWidget {
  final String cardNumber;
  final String holderName;
  final String expiry;
  final String network;

  const CardDetailsPage({
    super.key,
    required this.cardNumber,
    required this.holderName,
    required this.expiry,
    required this.network,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        title: const Text("Card Details"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ----- Card Preview -----
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A148C), Color(0xFF880E4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chip + Logo Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 48,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: const Text("•••",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                      Row(
                        children: [
                          Icon(Icons.credit_card,
                              color: Colors.white.withOpacity(0.9)),
                          const SizedBox(width: 6),
                          const Text(
                            "GlobalPay",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Card Number
                  Text(
                    cardNumber,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Holder + Expiry
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(holderName,
                          style:
                          const TextStyle(color: Colors.white, fontSize: 14)),
                      Text(expiry,
                          style:
                          const TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Network Logo
                  Align(
                    alignment: Alignment.bottomRight,
                    child: network.toLowerCase() == "visa"
                        ? Image.asset("assets/images/png/visa.jpeg", height: 40)
                        : Image.asset("assets/images/png/Mastercard.jpeg",
                        height: 40),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ----- Quick Stats -----
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statCard("Balance", "\$7,450", Colors.green),
                _statCard("Spent", "\$2,550", Colors.orange),
                _statCard("Limit", "\$10,000", Colors.blueAccent),
              ],
            ),
            const SizedBox(height: 32),

            // ----- Spending Pie Chart -----
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: 45,
                      color: Colors.orange,
                      title: "Shopping",
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      value: 30,
                      color: Colors.green,
                      title: "Bills",
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      value: 25,
                      color: Colors.purple,
                      title: "Others",
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ----- Transaction History -----
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recent Transactions",
                style: theme.textTheme.titleMedium!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: List.generate(5, (index) {
                return _transactionTile(
                  title: "Payment to Store $index",
                  date: "Aug ${10 + index}, 2025",
                  amount: "-\$${(index + 1) * 55}",
                  color: Colors.orangeAccent,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _transactionTile(
      {required String title,
        required String date,
        required String amount,
        required Color color}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 4),
              Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Text(amount,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        ],
      ),
    );
  }
}
