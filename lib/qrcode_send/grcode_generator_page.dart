import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class QrCodeGenerator extends StatelessWidget {
  final String qrData;
  final double amount;

  const QrCodeGenerator({
    super.key,
    required this.qrData,
    required this.amount,
  });

  void _shareQR(BuildContext context) {
    Share.share('MoneyDrop QR: $qrData');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepOrange.shade700,
      appBar: AppBar(
        backgroundColor: Colors.deepOrange.shade900,
        title: const Text("MoneyDrop QR"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 20),
                Text(
                  "Scan to claim ₦${amount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _shareQR(context),
                    icon: Icon(
                      Icons.share,
                      color: Colors.deepOrange.shade700,
                    ),
                    label: Text(
                      "Share QR Code",
                      style: TextStyle(
                        color: Colors.deepOrange.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
