import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';   // ← needed for RenderRepaintBoundary
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class QrCodeGenerator extends StatefulWidget {   // ← StatefulWidget
  final String qrData;
  final double amount;

  const QrCodeGenerator({
    super.key,
    required this.qrData,
    required this.amount,
  });

  @override
  State<QrCodeGenerator> createState() => _QrCodeGeneratorState();
}

class _QrCodeGeneratorState extends State<QrCodeGenerator> {
  final GlobalKey _qrKey = GlobalKey();   // ← lives in State, stable across rebuilds

  Future<void> _shareQR() async {
    try {
      final boundary =
      _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final tmp   = await getTemporaryDirectory();
      final file  = File('${tmp.path}/moneydrop_qr.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '💸 Scan to claim ₦${widget.amount.toStringAsFixed(0)} via MoneyDrop!',
      );
    } catch (_) {
      Share.share('MoneyDrop QR: ${widget.qrData}');  // fallback
    }
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
                RepaintBoundary(            // ← wraps QrImageView for screenshot
                  key: _qrKey,
                  child: QrImageView(
                    data:            widget.qrData,
                    version:         QrVersions.auto,
                    size:            200,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Scan to claim ₦${widget.amount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color:      Colors.white,
                    fontSize:   18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _shareQR,    // ← no longer needs context param
                    icon: Icon(Icons.share, color: Colors.deepOrange.shade700),
                    label: Text(
                      "Share QR Code",
                      style: TextStyle(
                        color:      Colors.deepOrange.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize:   18,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
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