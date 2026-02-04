import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:media_store_plus/media_store_plus.dart';
// import 'package:gallery_saver/gallery_saver.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';

class TransactionReceiptScreen extends StatefulWidget {
  final int amount;
  final String network;
  final String recipientPhone;
  final String payerPhone;
  final String transactionId;

  const TransactionReceiptScreen({
    super.key,
    required this.amount,
    required this.network,
    required this.recipientPhone,
    required this.payerPhone,
    required this.transactionId,
  });

  @override
  State<TransactionReceiptScreen> createState() =>
      _TransactionReceiptScreenState();
}

class _TransactionReceiptScreenState extends State<TransactionReceiptScreen> {
  ui.Image? _logoImage;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _loadLogo();
  }

  Future<void> _loadLogo() async {
    final data = await rootBundle.load(
      'assets/images/png/logo_transparent.png',
    );
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _logoImage = frame.image;
    });
  }

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

  Future<void> _shareReceipt() async {
    final image = await _screenshotController.capture();
    if (image != null) {
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/receipt.png';
      final file = await File(path).writeAsBytes(image);
      await Share.shareXFiles([XFile(file.path)], text: "My GlobalPay Receipt");
    }
  }

  Future<void> _saveReceipt() async {
    try {
      final image = await _screenshotController.capture();
      if (image == null) return;

      final Directory? baseDir = await getExternalStorageDirectory();
      if (baseDir == null) throw Exception("Storage not available");

      // Convert: /Android/data/<pkg>/files → /Pictures/GlobalPay
      final String picturesPath = baseDir.path
          .replaceFirst(RegExp(r'Android/data/.+/files'), 'Pictures/GlobalPay');

      final Directory picturesDir = Directory(picturesPath);
      if (!picturesDir.existsSync()) {
        picturesDir.createSync(recursive: true);
      }

      final String filePath =
          '$picturesPath/receipt_${DateTime.now().millisecondsSinceEpoch}.png';

      final File file = File(filePath);
      await file.writeAsBytes(image);

      // Tell Android Gallery about the new image
      const MethodChannel('media_scanner')
          .invokeMethod('scanFile', {'path': filePath});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Receipt saved to gallery")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error saving receipt: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount = NumberFormat.decimalPattern().format(widget.amount);
    final time = DateFormat('HH:mm, MMM dd, yyyy').format(DateTime.now());
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color background = isDark
        ? const Color(0xFF0D0D0D)
        : const Color(0xFFF9FAFB);
    final Color cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.grey.shade300;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final Color textSecondary = isDark
        ? Colors.white70
        : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: background,
        elevation: 0,
        title: Text(
          'Transaction Receipt',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _shareReceipt,
            icon: Icon(Icons.share, color: textPrimary),
            tooltip: "Share Receipt",
          ),
          IconButton(
            onPressed: _saveReceipt,
            icon: Icon(Icons.download, color: textPrimary),
            tooltip: "Save Receipt",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Screenshot(
          controller: _screenshotController,
          child: ClipPath(
            clipper: ReceiptTearClipper(toothWidth: 14.0, toothDepth: 10.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ✅ Watermark
                  if (_logoImage != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: WatermarkPainter(
                            isDark: isDark,
                            logoImage: _logoImage!,
                          ),
                        ),
                      ),
                    ),

                  // ✅ Receipt content
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/png/logo_transparent.png',
                            height: 40,
                          ),
                          Text(
                            "lobalPay",
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipOval(
                        child: Image.asset(
                          _getNetworkLogo(widget.network),
                          height: 48,
                          width: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "₦$formattedAmount",
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Successful transaction",
                        style: TextStyle(color: textSecondary, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: TextStyle(color: textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      Divider(color: borderColor, height: 1),
                      const SizedBox(height: 10),
                      _infoRow("Transaction Type", "Top up Airtime", isDark),
                      _infoRow(
                        "Bill Provider",
                        widget.network.toUpperCase(),
                        isDark,
                      ),
                      _infoRow(
                        "Recipient Mobile Number",
                        widget.recipientPhone,
                        isDark,
                      ),
                      _infoRow("Order Amount", "₦$formattedAmount", isDark),
                      _transactionIdRow(context, widget.transactionId, isDark),
                      _infoRow("Transaction Date", time, isDark),
                      _infoRow(
                        "Payer Mobile Number",
                        widget.payerPhone,
                        isDark,
                      ),
                      _infoRow("Payment Method", "Wallet", isDark),
                      const SizedBox(height: 12),
                      Divider(color: borderColor),
                      const SizedBox(height: 8),
                      Text(
                        "Get cashbacks in Airtime & Data top-up. Unlimited free transfers every Tuesday. Up to ₦150k credit lines & 16 days interest free. Enjoy all at GlobalPay!",
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _infoRow(String title, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _transactionIdRow(
      BuildContext context,
      String id,
      bool isDark,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              "Transaction ID",
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    id,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF111827),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Transaction ID copied"),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.copy,
                    size: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Watermark Painter ----------------
class WatermarkPainter extends CustomPainter {
  final bool isDark;
  final ui.Image logoImage;
  final List<_WatermarkItem> _items;

  WatermarkPainter({required this.isDark, required this.logoImage})
      : _items = _generateItems(logoImage);

  static List<_WatermarkItem> _generateItems(ui.Image logoImage) {
    const spacingX = 140.0;
    const spacingY = 110.0;
    const baseFontSize = 20.0;
    final random = Random();
    final List<_WatermarkItem> items = [];

    for (double y = -spacingY; y < 920 + spacingY; y += spacingY) {
      for (double x = -spacingX; x < 920 + spacingX; x += spacingX) {
        items.add(
          _WatermarkItem(
            offset: Offset(x, y),
            angle: (random.nextDouble() - 0.5) * pi / 9,
            opacity: 0.05 + random.nextDouble() * 0.09,
            fontSize: baseFontSize,
          ),
        );
      }
    }
    return items;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final item in _items) {
      if (item.offset.dx < -50 ||
          item.offset.dx > size.width + 50 ||
          item.offset.dy < -50 ||
          item.offset.dy > size.height + 50) {
        continue;
      }

      canvas.save();
      canvas.translate(item.offset.dx, item.offset.dy);
      canvas.rotate(item.angle);

      final logoSize = item.fontSize * 1.5;
      final paint = Paint()..color = Colors.white.withOpacity(item.opacity);

      canvas.drawImageRect(
        logoImage,
        Rect.fromLTWH(
          0,
          0,
          logoImage.width.toDouble(),
          logoImage.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, logoSize, logoSize),
        paint,
      );

      final textStyle = TextStyle(
        fontSize: item.fontSize,
        fontWeight: FontWeight.w700,
        color: (isDark ? Colors.white : Colors.black).withOpacity(item.opacity),
      );
      final textPainter = TextPainter(
        text: TextSpan(text: "lobalPay", style: textStyle),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(logoSize, (logoSize - item.fontSize) / 2),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WatermarkItem {
  final Offset offset;
  final double angle;
  final double opacity;
  final double fontSize;
  _WatermarkItem({
    required this.offset,
    required this.angle,
    required this.opacity,
    required this.fontSize,
  });
}

// ---------------- Tear edge ----------------
class ReceiptTearClipper extends CustomClipper<Path> {
  final double toothWidth;
  final double toothDepth;

  ReceiptTearClipper({this.toothWidth = 12.0, this.toothDepth = 8.0});

  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.moveTo(0, 0);

    double x = 0.0;
    while (x < size.width) {
      final mid = ((x + toothWidth / 2).clamp(0.0, size.width)).toDouble();
      final next = ((x + toothWidth).clamp(0.0, size.width)).toDouble();
      path.lineTo(mid, toothDepth);
      path.lineTo(next, 0);
      x += toothWidth;
    }

    path.lineTo(size.width, size.height - toothDepth);

    x = size.width;
    while (x > 0) {
      final mid = ((x - toothWidth / 2).clamp(0.0, size.width)).toDouble();
      final next = ((x - toothWidth).clamp(0.0, size.width)).toDouble();
      path.lineTo(mid, size.height - toothDepth);
      path.lineTo(next, size.height);
      x -= toothWidth;
    }

    path.lineTo(0, toothDepth);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
