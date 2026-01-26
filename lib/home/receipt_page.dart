<<<<<<< HEAD
=======
import 'dart:io';
>>>>>>> c30d5f6 (initial commit)
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide TextDirection;
import 'package:flutter/rendering.dart';
<<<<<<< HEAD
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../home/currency_con.dart'; // ✅ CurrencyConfig
=======
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../home/currency_con.dart'; // ✅ CurrencyConfig
// import 'package:media_store_plus/media_store_plus.dart';
>>>>>>> c30d5f6 (initial commit)

class ReceiptPage extends StatefulWidget {
  final String bankName;
  final double amount;
  final String paymentMethod;
  final String recipientName;
  final String accountNumber;
  final DateTime date;

  const ReceiptPage({
    super.key,
    required this.bankName,
    required this.amount,
    required this.paymentMethod,
    required this.recipientName,
    required this.accountNumber,
    required this.date,
  });

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  final GlobalKey _receiptKey = GlobalKey();

  Future<void> _saveReceiptAsImage() async {
    try {
<<<<<<< HEAD
      RenderRepaintBoundary boundary =
      _receiptKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      await ImageGallerySaver.saveImage(
        Uint8List.fromList(pngBytes),
        quality: 100,
        name: "receipt_${DateTime.now().millisecondsSinceEpoch}",
      );

=======
      final boundary =
          _receiptKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) throw Exception("Failed to convert image to bytes");

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Get Android storage directory
      final Directory? baseDir = await getExternalStorageDirectory();
      if (baseDir == null) throw Exception("Storage not available");

      // Convert: /Android/data/<package>/files -> /Pictures/GlobalPay
      final String picturesPath = baseDir.path.replaceFirst(
        RegExp(r'Android/data/.+/files'),
        'Pictures/GlobalPay',
      );

      final Directory picturesDir = Directory(picturesPath);
      if (!picturesDir.existsSync()) picturesDir.createSync(recursive: true);

      final String filePath =
          '$picturesPath/receipt_${DateTime.now().millisecondsSinceEpoch}.png';

      final File file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // Trigger media scan
      const MethodChannel(
        'media_scanner',
      ).invokeMethod('scanFile', {'path': filePath});

>>>>>>> c30d5f6 (initial commit)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Receipt saved to gallery!")),
        );
      }
    } catch (e) {
      if (mounted) {
<<<<<<< HEAD
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error saving receipt: $e")),
        );
=======
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Error saving receipt: $e")));
>>>>>>> c30d5f6 (initial commit)
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final formattedDate =
        "${widget.date.day}-${widget.date.month}-${widget.date.year}";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Transaction Receipt"),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: Center(
        child: Scrollbar(
          thumbVisibility: true,
          thickness: 4,
          radius: const Radius.circular(8),
          child: SingleChildScrollView(
            child: RepaintBoundary(
              key: _receiptKey,
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    if (!isDark)
                      const BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                  ],
                ),
                child: Column(
                  children: [
                    CustomPaint(
                      painter: TearPainter(isDark: isDark),
                      child: Container(height: 24),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: WatermarkPainter(isDark: isDark),
                            ),
                          ),
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                "GlobalPay",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${CurrencyConfig().symbol}${widget.amount.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Successful Transaction",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 28,
                              ),
                              const Divider(),
                              const SizedBox(height: 16),
                              _buildInfoRow("Recipient", widget.recipientName),
                              _buildInfoRow("Account", widget.accountNumber),
                              _buildInfoRow("Bank", widget.bankName),
<<<<<<< HEAD
                              _buildInfoRow("Payment Method", widget.paymentMethod),
                              _buildInfoRow("Date", formattedDate),
                              _buildInfoRow("Reference",
                                  "#TXN${DateTime.now().millisecondsSinceEpoch}"),
=======
                              _buildInfoRow(
                                "Payment Method",
                                widget.paymentMethod,
                              ),
                              _buildInfoRow("Date", formattedDate),
                              _buildInfoRow(
                                "Reference",
                                "#TXN${DateTime.now().millisecondsSinceEpoch}",
                              ),
>>>>>>> c30d5f6 (initial commit)
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.orange.withOpacity(0.2)
                                      : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.deepOrange,
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  "Enjoy Seamless and Unlimited Free Transfers to All Banks.\n"
<<<<<<< HEAD
                                      "Get cashbacks in Airtime & data top-up!\n"
                                      "Up to 150k Naira credit lines & 16 days interest free!\n"
                                      "Enjoy all at PalmPay!",
=======
                                  "Get cashbacks in Airtime & data top-up!\n"
                                  "Up to 150k Naira credit lines & 16 days interest free!\n"
                                  "Enjoy all at PalmPay!",
>>>>>>> c30d5f6 (initial commit)
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          border: Border(
<<<<<<< HEAD
              top: BorderSide(color: colorScheme.outlineVariant, width: 1)),
=======
            top: BorderSide(color: colorScheme.outlineVariant, width: 1),
          ),
>>>>>>> c30d5f6 (initial commit)
          color: colorScheme.surface,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
<<<<<<< HEAD
            _bottomAction(Icons.image_outlined, "Save as Image", _saveReceiptAsImage),
=======
            _bottomAction(
              Icons.image_outlined,
              "Save as Image",
              _saveReceiptAsImage,
            ),
>>>>>>> c30d5f6 (initial commit)
            _bottomAction(Icons.picture_as_pdf_outlined, "Share as PDF", () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("📄 Share as PDF coming soon")),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
<<<<<<< HEAD
          Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
=======
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w500, color: color),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
>>>>>>> c30d5f6 (initial commit)
        ],
      ),
    );
  }

  Widget _bottomAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.deepOrange, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.deepOrange,
            ),
          ),
        ],
      ),
    );
  }
}

class TearPainter extends CustomPainter {
  final bool isDark;
  TearPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.grey.shade800 : Colors.grey.shade200
      ..style = PaintingStyle.fill;

    final path = Path()..moveTo(0, 0);
    const waveWidth = 16.0;
    const waveHeight = 8.0;

    for (double x = 0; x <= size.width; x += waveWidth) {
<<<<<<< HEAD
      path.quadraticBezierTo(x + waveWidth / 4, waveHeight, x + waveWidth / 2, 0);
      path.quadraticBezierTo(x + 3 * waveWidth / 4, -waveHeight, x + waveWidth, 0);
=======
      path.quadraticBezierTo(
        x + waveWidth / 4,
        waveHeight,
        x + waveWidth / 2,
        0,
      );
      path.quadraticBezierTo(
        x + 3 * waveWidth / 4,
        -waveHeight,
        x + waveWidth,
        0,
      );
>>>>>>> c30d5f6 (initial commit)
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class WatermarkPainter extends CustomPainter {
  final bool isDark;
  WatermarkPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    const watermarkText = "GlobalPay";
    final textStyle = TextStyle(
<<<<<<< HEAD
      color: isDark ? Colors.grey.shade900.withOpacity(0.1) : Colors.grey.shade100,
=======
      color: isDark
          ? Colors.grey.shade900.withOpacity(0.1)
          : Colors.grey.shade100,
>>>>>>> c30d5f6 (initial commit)
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );

    for (double y = 0; y < size.height; y += 40) {
      for (double x = 0; x < size.width; x += 120) {
        textPainter.text = TextSpan(text: watermarkText, style: textStyle);
        textPainter.layout();
        textPainter.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
