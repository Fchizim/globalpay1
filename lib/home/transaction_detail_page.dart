import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'airtime_receipt.dart';

class TransactionDetailScreen extends StatelessWidget {
  final int amount;
  final String network;
  final String phone;

  const TransactionDetailScreen({
    super.key,
    required this.amount,
    required this.network,
    required this.phone,
  });

  String _getNetworkLogo(String network) {
    switch (network.toLowerCase()) {
      case 'mtn':
        return 'assets/images/png/mtn.jpeg';
      case 'airtel':
        return 'assets/images/png/airtel.jpeg';
      case 'glo':
        return 'assets/images/png/glo.jpeg';
      case '9mobile':
      case 'etisalat':
        return 'assets/images/png/9mobile.jpeg';
      default:
        return 'assets/images/png/mtn.jpeg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String transactionId = "TXN-${DateTime.now().millisecondsSinceEpoch}";
    final String time =
    DateFormat('HH:mm, MMM dd, yyyy').format(DateTime.now());

    final formattedAmount = NumberFormat.decimalPattern().format(amount);
    final orderAmount = "₦$formattedAmount";
    final paymentAmount = "₦$formattedAmount";

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    final Color primary = Colors.deepOrange;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final Color textSecondary =
    isDark ? Colors.white70 : const Color(0xFF6B7280);
    final Color cardColor =
    isDark ? const Color(0xFF1C1C1E) : Colors.white.withOpacity(0.98);
    final Color background =
    isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF9FAFB);
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.grey.shade300.withOpacity(0.7);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          "Transaction Detail",
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white70 : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // Bottom bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(top: BorderSide(color: borderColor)),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionReceiptScreen(
                    amount: amount,
                    network: network,
                    recipientPhone: phone,
                    payerPhone: "08167907085", // replace with real user number
                    transactionId:
                    "TXN${DateTime.now().millisecondsSinceEpoch}",
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.receipt_long_rounded, size: 20),
            label: const Text(
              "View Receipt",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),

      // Body
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Transaction Summary
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: AssetImage(_getNetworkLogo(network)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      network.toUpperCase(),
                      style: TextStyle(fontSize: 15, color: textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "₦$formattedAmount",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 26,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle,
                            color: Color(0xFF22C55E), size: 18),
                        SizedBox(width: 5),
                        Text(
                          "Successful",
                          style: TextStyle(
                            color: Color(0xFF22C55E),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Divider(color: borderColor),
                    const SizedBox(height: 5),
                    _buildRow("Order Amount", orderAmount, isDark),
                    _buildRow("Payment Amount", paymentAmount, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Transaction Info
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _buildRow("Recipient Mobile", phone, isDark),
                    _buildRow("Transaction Type", "Airtime Top-up", isDark),
                    _buildTransactionIdRow(context, transactionId, isDark),
                    _buildRow("Create Time", time, isDark),
                    _buildRow("Completion Time", time, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Support Section
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Text(
                      "Any questions about this transaction?",
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _supportButton(Icons.headset_mic, "Customer Service"),
                        const SizedBox(width: 20),
                        _supportButton(Icons.report_problem, "Report a Dispute"),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable Info Row
  static Widget _buildRow(String title, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF111827),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Transaction ID row with Copy Icon
  static Widget _buildTransactionIdRow(
      BuildContext context, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            "Transaction ID",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Transaction ID copied to clipboard"),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Icon(Icons.copy,
                    size: 16, color: isDark ? Colors.grey[400] : Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Support buttons
  static Widget _supportButton(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.deepOrange),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.deepOrange,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
