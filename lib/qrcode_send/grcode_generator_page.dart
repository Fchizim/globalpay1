import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

// Path to your logo asset. Make sure it's declared under `flutter: assets:`
// in pubspec.yaml. If the file is missing at runtime, the widget silently
// falls back to a plain QR — it never crashes the screen.
const String _kLogoAsset = 'assets/images/png/logooooooooo.jpg';

const _heroGradient = LinearGradient(
  colors: [Color(0xFFFF6A3D), Color(0xFF7B2FF7)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Clamps the system font scale so a phone set to "Largest" text can't push
// fixed-size layouts into overflow.
class _TextScaleClamp extends StatelessWidget {
  final Widget child;
  const _TextScaleClamp({required this.child});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(
        textScaler: mq.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.2,
        ),
      ),
      child: child,
    );
  }
}

class QrCodeGenerator extends StatefulWidget {
  final String qrData;
  final double amount;

  /// Optional extras — all have sensible fallbacks so existing call sites
  /// that only pass qrData/amount keep working unchanged.
  final String? voucherId;
  final String status;

  const QrCodeGenerator({
    super.key,
    required this.qrData,
    required this.amount,
    this.voucherId,
    this.status = 'Active',
  });

  @override
  State<QrCodeGenerator> createState() => _QrCodeGeneratorState();
}

class _QrCodeGeneratorState extends State<QrCodeGenerator> {
  final GlobalKey _captureKey = GlobalKey();

  bool _logoAvailable = true; // flips to false if the asset fails to load

  @override
  void initState() {
    super.initState();
    _checkLogo();
  }

  // Confirms the asset actually resolves before we try to draw it in the
  // center of the QR — if it's missing/corrupt we just render a clean QR
  // with no logo instead of throwing.
  Future<void> _checkLogo() async {
    try {
      await rootBundle.load(_kLogoAsset);
    } catch (_) {
      if (mounted) setState(() => _logoAvailable = false);
    }
  }

  String get _voucherId =>
      widget.voucherId ??
      (widget.qrData.length > 14
          ? widget.qrData.substring(0, 14).toUpperCase()
          : widget.qrData.toUpperCase());

  Color get _statusColor {
    switch (widget.status.toLowerCase()) {
      case 'redeemed':
        return Colors.blueAccent;
      case 'expired':
        return Colors.redAccent;
      default:
        return Colors.greenAccent;
    }
  }

  // ── capture the hero card as an image ──────────────────────────────────────
  Future<File?> _captureCard() async {
    try {
      final boundary =
          _captureKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/gdrop_${_voucherId}.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<void> _share() async {
    final file = await _captureCard();
    if (file != null) {
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '💸 Scan to claim ₦${widget.amount.toStringAsFixed(0)} via GDrop!',
      );
    } else {
      Share.share('GDrop QR: ${widget.qrData}');
    }
  }

  Future<void> _saveImage() async {
    final file = await _captureCard();
    if (file == null) {
      _snack('Could not save image', error: true);
      return;
    }
    final result = await ImageGallerySaverPlus.saveFile(file.path);
    if (result['isSuccess'] == true) {
      _snack('Saved to gallery!');
    } else {
      _snack('Could not save image', error: true);
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _voucherId));
    _snack('Voucher code copied');
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Clamp sizing so it scales down on small phones and doesn't look
  // tiny/cramped on tablets, same baseline used across the app.
  double _scale(BuildContext context, double base) {
    final width = MediaQuery.of(context).size.width;
    final factor = (width / 375).clamp(0.85, 1.3);
    return base * factor;
  }

  void _enlarge() {
    final screenWidth = MediaQuery.of(context).size.width;
    // Dialog inset (28*2) + dialog padding (24*2) = 104 of horizontal space
    // is used up, so the QR is sized off the real screen width.
    final qrSize = (screenWidth - 120).clamp(150.0, 320.0);

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _TextScaleClamp(
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(28),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            // Scrolls on short screens instead of overflowing vertically.
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildQr(size: qrSize),
                  const SizedBox(height: 16),
                  Text(
                    _voucherId,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Plain QR — no center logo, just a clean, maximally-scannable code.
  Widget _buildQr({double size = 200}) {
    return QrImageView(
      data: widget.qrData,
      version: QrVersions.auto,
      size: size,
      backgroundColor: Colors.white,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Cap the usable content width so the card doesn't stretch edge-to-edge
    // on tablets/foldables.
    final maxContentWidth = screenWidth > 600 ? 480.0 : screenWidth;

    return _TextScaleClamp(
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  _scale(context, 20),
                  8,
                  _scale(context, 20),
                  32,
                ),
                child: Column(
                  children: [
                    // ── top bar ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'GDrop',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: _scale(context, 20),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.help_outline_rounded,
                            size: 22,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── hero gradient card (captured for share/save) ──
                    // LayoutBuilder gives the QR the card's real width, so it
                    // fits exactly on every screen size.
                    RepaintBoundary(
                      key: _captureKey,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final heroPad = _scale(context, 24);
                          final qrPad = _scale(context, 20);
                          final qrSize =
                              (constraints.maxWidth - heroPad * 2 - qrPad * 2)
                                  .clamp(140.0, 260.0);

                          return Container(
                            width: double.infinity,
                            padding: EdgeInsets.fromLTRB(
                              heroPad,
                              _scale(context, 32),
                              heroPad,
                              _scale(context, 24),
                            ),
                            decoration: BoxDecoration(
                              gradient: _heroGradient,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepOrange.withOpacity(0.25),
                                  blurRadius: 26,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // logo badge
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: _logoAvailable
                                      ? Image.asset(
                                          _kLogoAsset,
                                          height: _scale(context, 56),
                                          width: _scale(context, 56),
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          height: _scale(context, 56),
                                          width: _scale(context, 56),
                                          color: Colors.white.withOpacity(0.15),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'G',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: _scale(context, 28),
                                            ),
                                          ),
                                        ),
                                ),
                                SizedBox(height: _scale(context, 14)),
                                Text(
                                  'GDrop',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: _scale(context, 30),
                                  ),
                                ),
                                SizedBox(height: _scale(context, 4)),
                                Text(
                                  'Share. Redeem. Delight.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: _scale(context, 14),
                                  ),
                                ),

                                SizedBox(height: _scale(context, 26)),

                                // white QR card
                                GestureDetector(
                                  onTap: _enlarge,
                                  child: Container(
                                    padding: EdgeInsets.all(qrPad),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.12),
                                          blurRadius: 18,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: _buildQr(size: qrSize),
                                  ),
                                ),

                                SizedBox(height: _scale(context, 14)),

                                GestureDetector(
                                  onTap: _enlarge,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.open_in_full_rounded,
                                        size: 14,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Tap to enlarge',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.85),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: _scale(context, 26)),
                                Divider(
                                  color: Colors.white.withOpacity(0.2),
                                  height: 1,
                                ),
                                SizedBox(height: _scale(context, 20)),

                                // stat row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _HeroStat(
                                        icon: Icons.tag_rounded,
                                        label: 'Voucher ID',
                                        value: _voucherId,
                                      ),
                                    ),
                                    Expanded(
                                      child: _HeroStat(
                                        icon: Icons.all_inclusive_rounded,
                                        label: 'Validity',
                                        value: 'No Expiry',
                                      ),
                                    ),
                                    Expanded(
                                      child: _HeroStat(
                                        icon: Icons.verified_rounded,
                                        label: 'Status',
                                        value: widget.status,
                                        valueColor: _statusColor,
                                        showDot: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: _scale(context, 18)),

                    // ── action row ──
                    Row(
                      children: [
                        Expanded(
                          child: _ActionSquare(
                            icon: Icons.near_me_rounded,
                            label: 'Share',
                            onTap: _share,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionSquare(
                            icon: Icons.download_rounded,
                            label: 'Save Image',
                            onTap: _saveImage,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionSquare(
                            icon: Icons.copy_all_rounded,
                            label: 'Copy Code',
                            onTap: _copyCode,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: _scale(context, 18)),

                    // ── info card ──
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(_scale(context, 18)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: _scale(context, 44),
                            height: _scale(context, 44),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              color: Colors.deepOrange,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Anyone with this QR can redeem',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const _InfoBullet('One-time use only'),
                                const _InfoBullet(
                                  'Never expires — valid until redeemed',
                                ),
                                const _InfoBullet('Secure and encrypted'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: _scale(context, 20)),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 13,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Secured by GlobalPay Encryption',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SMALL WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool showDot;
  const _HeroStat({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
      const SizedBox(height: 8),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11),
        ),
      ),
      const SizedBox(height: 3),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                color: valueColor ?? Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ],
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _ActionSquare extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionSquare({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.deepOrange, size: 22),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _InfoBullet extends StatelessWidget {
  final String text;
  const _InfoBullet(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.check_circle_rounded,
            size: 15,
            color: Colors.deepOrange,
          ),
        ),
        const SizedBox(width: 8),
        // Expanded so long lines wrap instead of overflowing the card.
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
          ),
        ),
      ],
    ),
  );
}
