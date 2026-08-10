import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide TextDirection;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../home/currency_con.dart'; // ✅ CurrencyConfig
// import 'package:media_store_plus/media_store_plus.dart';

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
  static const _accent = Colors.deepOrange;
  static const _success = Color(0xFF22C55E);

  final GlobalKey _receiptKey = GlobalKey();

  Future<void> _saveReceiptAsImage() async {
    try {
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Receipt saved to gallery"),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(14),
            backgroundColor: _success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving receipt: $e"),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(14),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final subTextColor = isDark ? Colors.white38 : Colors.grey.shade600;
    final formattedDate =
        "${widget.date.day}-${widget.date.month}-${widget.date.year}";

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0D0D0D)
          : const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          "Transaction Receipt",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
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
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.4)
                          : Colors.black.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
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
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: WatermarkPainter(isDark: isDark),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 8),
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/png/logooooooooo.jpg',
                                      fit: BoxFit.contain,
                                      height: 50,
                                    ),
                                    Text(
                                      "Glonest",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: colorScheme.onSurface,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),
                              // ── Overflow fix: long amounts shrink to fit instead of wrapping/clipping ──
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "${CurrencyConfig().symbol}${widget.amount.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: _accent,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Successful Transaction",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: subTextColor,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Divider(
                                color: subTextColor.withOpacity(0.15),
                                height: 1,
                              ),
                              const SizedBox(height: 18),
                              _buildInfoRow(
                                "Recipient",
                                widget.recipientName,
                                colorScheme,
                                subTextColor,
                              ),
                              _buildInfoRow(
                                "Account",
                                widget.accountNumber,
                                colorScheme,
                                subTextColor,
                              ),
                              _buildInfoRow(
                                "Bank",
                                widget.bankName,
                                colorScheme,
                                subTextColor,
                              ),
                              _buildInfoRow(
                                "Payment Method",
                                widget.paymentMethod,
                                colorScheme,
                                subTextColor,
                              ),
                              _buildInfoRow(
                                "Date",
                                formattedDate,
                                colorScheme,
                                subTextColor,
                              ),
                              _buildInfoRow(
                                "Reference",
                                "#TXN${DateTime.now().millisecondsSinceEpoch}",
                                colorScheme,
                                subTextColor,
                              ),
                              const SizedBox(height: 22),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? _accent.withOpacity(0.12)
                                      : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _accent.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  "Enjoy seamless, unlimited free transfers to all banks. Get cashback on airtime & data top-ups. Enjoy it all with Glonest.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                    height: 1.4,
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
        // decoration: BoxDecoration(
        //   border: Border(
        //     top: BorderSide(
        //       color: colorScheme.outlineVariant.withOpacity(0.5),
        //       width: 1,
        //     ),
        //   ),
        //   color: colorScheme.surface,
        // ),
        // ── Overflow fix: SafeArea + no fixed height, so content isn't clipped
        // by notches/gesture bars on smaller devices ──
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: _bottomAction(
                    Icons.download_rounded,
                    "Save as Image",
                    _saveReceiptAsImage,
                  ),
                ),
                Flexible(
                  child: _bottomAction(
                    Icons.picture_as_pdf_outlined,
                    "Share as PDF",
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Share as PDF coming soon"),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(14),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String title,
    String value,
    ColorScheme colorScheme,
    Color subTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Overflow fix: give the title room to wrap instead of being
          // squeezed by a long value ──
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13.5,
                color: subTextColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _accent, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _accent,
              ),
            ),
          ],
        ),
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
    const watermarkText = "Glonest";
    final textStyle = TextStyle(
      color: isDark
          ? Colors.grey.shade900.withOpacity(0.1)
          : Colors.grey.shade100,
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
