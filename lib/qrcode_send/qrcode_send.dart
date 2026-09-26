import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marquee/marquee.dart';
import 'package:mobile_scanner/mobile_scanner.dart' hide BarcodeFormat;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../provider/user_provider.dart';

// ─── constants ────────────────────────────────────────────────────────────────
const _base = 'https://glopa.org/glo';

// A single accent gradient used consistently across the page.
const _accentGradient = LinearGradient(
  colors: [Color(0xFFFF7A45), Color(0xFFFF4D8D)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Hero card gradient (matches the GDrop QR mockup).
const _heroGradient = LinearGradient(
  colors: [Color(0xFFFF6A3D), Color(0xFF7B2FF7)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Path to your logo asset. Make sure it's declared under `flutter: assets:`
// in pubspec.yaml. If the file is missing at runtime, the QR silently falls
// back to a plain code with no embedded logo — it never breaks the screen.
const String _kLogoAsset = 'assets/images/png/logooooooooo.jpg';

// ─── RESPONSIVE HELPERS ────────────────────────────────────────────────────
// Shared scale factor, same baseline used across the app's other screens.
// Clamped so text/padding shrink a bit on small phones and grow a bit on
// tablets without ever looking cartoonish.
double _scale(BuildContext context, double base) {
  final width = MediaQuery.of(context).size.width;
  final factor = (width / 375).clamp(0.85, 1.3);
  return base * factor;
}

// Caps content width on tablets/foldables so cards don't stretch edge to edge.
double _maxContentWidth(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width > 600 ? 480.0 : width;
}

// ─── ENTRY POINT ─────────────────────────────────────────────────────────────
class GDropPage extends StatefulWidget {
  const GDropPage({super.key});
  @override
  State<GDropPage> createState() => _GDropPageState();
}

class _GDropPageState extends State<GDropPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  // Controls whether the Send/Redeem/History pill is shown. Hidden once a
  // GDrop QR is on screen so the QR view reads as its own destination.
  final ValueNotifier<bool> _showTabBar = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _showTabBar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);
    final tc = isDark ? Colors.white : Colors.black;
    final pillBg = isDark ? const Color(0xFF1C1C1C) : Colors.white;

    return ValueListenableBuilder<bool>(
      valueListenable: _showTabBar,
      builder: (context, showTabBar, _) {
        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            centerTitle: false,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: tc, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'GDrop',
              style: TextStyle(
                color: tc,
                fontWeight: FontWeight.w800,
                fontSize: 21,
              ),
            ),
            bottom: !showTabBar
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: _maxContentWidth(context),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: pillBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.06)
                                    : Colors.black.withOpacity(0.04),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    isDark ? 0.2 : 0.04,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TabBar(
                              controller: _tabs,
                              dividerColor: Colors
                                  .transparent, // kills the black underline
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicatorPadding: EdgeInsets.zero,
                              indicator: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: _accentGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepOrange.withOpacity(0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              splashFactory: NoSplash.splashFactory,
                              overlayColor: const WidgetStatePropertyAll(
                                Colors.transparent,
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey.shade500,
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              unselectedLabelStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              tabs: const [
                                Tab(text: 'Send'),
                                Tab(text: 'Redeem'),
                                Tab(text: 'History'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          // Cap width on tablets and center, same as the rest of the app.
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _maxContentWidth(context)),
              child: TabBarView(
                controller: _tabs,
                // Lock the swipe gesture too while a QR result is showing, so
                // the user can't swipe sideways into another tab behind its back.
                physics: showTabBar
                    ? null
                    : const NeverScrollableScrollPhysics(),
                children: [
                  _SendTab(
                    onQrVisibilityChanged: (visible) =>
                        _showTabBar.value = !visible,
                  ),
                  const _RedeemTab(),
                  const _HistoryTab(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SEND TAB
// ══════════════════════════════════════════════════════════════════════════════
class _SendTab extends StatefulWidget {
  // Notifies the parent GDropPage so it can hide its Send/Redeem/History
  // tab bar while the generated QR is on screen.
  final ValueChanged<bool>? onQrVisibilityChanged;
  const _SendTab({this.onQrVisibilityChanged});
  @override
  State<_SendTab> createState() => _SendTabState();
}

class _SendTabState extends State<_SendTab> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  int _design = 0;
  bool _loading = false;
  String _voucherId = '';
  double _voucherAmt = 0;
  String _voucherNote = '';

  final GlobalKey _qrKey = GlobalKey();
  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Generate ───────────────────────────────────────────────────────────────
  Future<void> _generate() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    final amt = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amt < 100) {
      _snack('Minimum amount is ₦100', error: true);
      return;
    }

    // PIN collection — NOT validation. The sheet just returns the 4 digits
    // the user typed; the actual check happens server-side in
    // gdrop_create.php (same as tfmg.php does for p2p transfers).
    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PinSheet(),
    );
    if (pin == null || pin.length != 4) return;

    setState(() => _loading = true);
    try {
      final res = await http
          .post(
            Uri.parse('$_base/gdrop_create.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': user.userId,
              'amount': amt,
              'note': _noteCtrl.text.trim(),
              'design': _design,
              'pin': pin,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(res.body);
      if (!mounted) return;

      if (data['status'] == 'success') {
        setState(() {
          _voucherId = data['voucher_id'];
          _voucherAmt = double.parse(data['amount'].toString());
          _voucherNote = data['note'] ?? '';
        });
        widget.onQrVisibilityChanged?.call(true);
      } else {
        // Covers both "Incorrect PIN." and any other backend rejection
        _snack(data['message'] ?? 'Failed to create GDrop', error: true);
      }
    } catch (e) {
      _snack('Network error. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── capture the hero card as a file ─────────────────────────────────────────
  Future<File?> _captureCard() async {
    try {
      final boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/gdrop_$_voucherId.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      return file;
    } catch (_) {
      return null;
    }
  }

  // ── Save QR to gallery ─────────────────────────────────────────────────────
  Future<void> _saveQR() async {
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

  // ── Share QR ───────────────────────────────────────────────────────────────
  Future<void> _shareQR() async {
    final file = await _captureCard();
    if (file != null) {
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '🎁 I sent you a GDrop gift of ₦${_voucherAmt.toStringAsFixed(0)}!\n'
            'Code: $_voucherId\nRedeem on Glopa app.',
      );
    } else {
      Share.share(
        '🎁 GDrop gift of ₦${_voucherAmt.toStringAsFixed(0)}!\n'
        'Code: $_voucherId\nRedeem on Glopa app.',
      );
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _voucherId));
    _snack('Voucher code copied');
  }

  void _reset() {
    setState(() {
      _voucherId = '';
      _amountCtrl.clear();
      _noteCtrl.clear();
      _design = 0;
    });
    widget.onQrVisibilityChanged?.call(false);
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final tc = isDark ? Colors.white : Colors.black;

    // ── QR result view (matches the GDrop mockup) ──────────────────────────────
    if (_voucherId.isNotEmpty) {
      final qrData = jsonEncode({
        'voucher_id': _voucherId,
        'amount': _voucherAmt,
      });

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          children: [
            RepaintBoundary(
              key: _qrKey,
              child: _GDropHeroCard(
                qrData: qrData,
                voucherId: _voucherId,
                note: _voucherNote,
                status: 'Active',
              ),
            ),

            const SizedBox(height: 18),

            // Action squares: Share / Save Image / Copy Code
            Row(
              children: [
                Expanded(
                  child: _ActionSquare(
                    icon: Icons.near_me_rounded,
                    label: 'Share',
                    onTap: _shareQR,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionSquare(
                    icon: Icons.download_rounded,
                    label: 'Save Image',
                    onTap: _saveQR,
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

            const SizedBox(height: 18),

            // Info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
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
                        Text(
                          'Anyone with this QR can redeem',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: tc,
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

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded, size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text(
                  'Secured by Glonest Encryption',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _GradientButton(label: 'Send Another GDrop', onTap: _reset),
          ],
        ),
      );
    }

    // ── Form view ──────────────────────────────────────────────────────────────
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              gradient: _accentGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepOrange.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 22,
                  child: Marquee(
                    text:
                        '💸 Surprise your loved ones with GDrop cash gifts!    ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    blankSpace: 40,
                    velocity: 40,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'QR-based instant money gift',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Design selector
          Text(
            'Choose a Design',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: tc,
            ),
          ),
          const SizedBox(height: 12),
          // Wrapped in Expanded so three chips always share the row evenly
          // instead of relying on spaceAround, which could overflow if a
          // chip's intrinsic content (QR preview + label) is wider than
          // the leftover space on a narrow phone.
          Row(
            children: [
              Expanded(
                child: _DesignChip(
                  label: 'Plain',
                  selected: _design == 0,
                  color: isDark ? Colors.white : Colors.black,
                  onTap: () => setState(() => _design = 0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DesignChip(
                  label: 'Love ❤️',
                  selected: _design == 1,
                  color: Colors.deepOrange,
                  onTap: () => setState(() => _design = 1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DesignChip(
                  label: 'Gift 🎁',
                  selected: _design == 2,
                  color: Colors.purple,
                  onTap: () => setState(() => _design = 2),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Amount field
          const _FieldLabel('Amount (₦)'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: tc,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
              decoration: InputDecoration(
                prefixText: '₦ ',
                prefixStyle: TextStyle(
                  color: tc,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
                hintText: 'Min ₦100',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Colors.deepOrange,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Note field
          const _FieldLabel('Note (optional)'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _noteCtrl,
              style: TextStyle(color: tc),
              decoration: InputDecoration(
                hintText: 'e.g. Happy Birthday! 🎂',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Colors.deepOrange,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          _GradientButton(
            label: 'Generate GDrop',
            loading: _loading,
            onTap: _generate,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// REDEEM TAB
// ══════════════════════════════════════════════════════════════════════════════
class _RedeemTab extends StatefulWidget {
  const _RedeemTab();
  @override
  State<_RedeemTab> createState() => _RedeemTabState();
}

class _RedeemTabState extends State<_RedeemTab> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _result; // success payload

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  // ── Call backend ──────────────────────────────────────────────────────────
  Future<void> _redeem(String code) async {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty) {
      _snack('Enter a voucher code', error: true);
      return;
    }

    final user = context.read<UserProvider>().user;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      final res = await http
          .post(
            Uri.parse('$_base/gdrop_redeem.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': user.userId, 'voucher_id': clean}),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('GDrop redeem status code: ${res.statusCode}');
      debugPrint('GDrop redeem raw body: ${res.body}');

      final data = jsonDecode(res.body);
      if (!mounted) return;

      if (data['status'] == 'success') {
        setState(() => _result = data);
      } else {
        _snack(data['message'] ?? 'Redemption failed', error: true);
      }
    } catch (e, st) {
      debugPrint('GDrop redeem exception: $e');
      debugPrint('$st');
      _snack('Network error. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Camera scan ───────────────────────────────────────────────────────────
  Future<void> _scanCamera() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _QRScannerPage()),
    );
    if (code != null && mounted) {
      // QR data is JSON: extract voucher_id
      _extractAndRedeem(code);
    }
  }

  // ── Gallery pick ──────────────────────────────────────────────────────────
  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile == null || !mounted) return;

    _snack('Reading QR from image...');
    final scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    try {
      final inputImage = InputImage.fromFilePath(xFile.path);
      final barcodes = await scanner.processImage(inputImage);
      if (barcodes.isEmpty) {
        _snack('No QR code found in image. Enter code manually.', error: true);
        return;
      }
      final raw = barcodes.first.rawValue ?? '';
      _extractAndRedeem(raw);
    } catch (_) {
      _snack('Could not read QR from image. Enter code manually.', error: true);
    } finally {
      await scanner.close();
    }
  }

  void _extractAndRedeem(String raw) {
    // Try to parse JSON (from our own QR)
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final id = json['voucher_id']?.toString() ?? json['id']?.toString() ?? '';
      if (id.startsWith('GDRP-')) {
        _redeem(id);
        return;
      }
    } catch (_) {}
    // Plain string
    if (raw.startsWith('GDRP-')) {
      _redeem(raw);
      return;
    }
    _snack('QR does not contain a valid GDrop code.', error: true);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final tc = isDark ? Colors.white : Colors.black;

    // ── Success view ────────────────────────────────────────────────────────
    if (_result != null) {
      final amt = double.parse(_result!['amount'].toString());
      final sender = _result!['sender_username'] ?? '';
      final note = _result!['note'] ?? '';

      return SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration icon — scaled down on small phones so it
                // doesn't crowd the amount text below it.
                Container(
                  width: _scale(context, 110),
                  height: _scale(context, 110),
                  decoration: BoxDecoration(
                    gradient: _accentGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrange.withOpacity(0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.celebration_rounded,
                    size: _scale(context, 55),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  '🎉 You received',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 6),
                ShaderMask(
                  shaderCallback: (r) => _accentGradient.createShader(r),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '₦${amt.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (sender.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'from @$sender',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                  ),
                ],
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '"$note"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: tc.withOpacity(0.75),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 34),
                _GradientButton(
                  label: 'Redeem Another',
                  onTap: () => setState(() {
                    _result = null;
                    _codeCtrl.clear();
                  }),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Redeem form ─────────────────────────────────────────────────────────
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        children: [
          const SizedBox(height: 4),

          // Scan / Gallery quick actions
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Scan QR',
                  sub: 'Use camera',
                  onTap: _scanCamera,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ActionTile(
                  icon: Icons.image_rounded,
                  label: 'From Gallery',
                  sub: 'Pick QR image',
                  onTap: _pickFromGallery,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Divider with "OR"
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.withOpacity(0.2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR ENTER CODE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.withOpacity(0.2))),
            ],
          ),

          const SizedBox(height: 26),

          // Manual code entry
          const _FieldLabel('Voucher Code'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.8,
              ),
              decoration: InputDecoration(
                hintText: 'GDRP-XXXXXXXX-XXXX-XXXX',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  letterSpacing: 1,
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Colors.deepOrange,
                    width: 1.5,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear_rounded, color: Colors.grey.shade400),
                  onPressed: () => _codeCtrl.clear(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 26),

          _GradientButton(
            label: 'Redeem GDrop',
            loading: _loading,
            onTap: () => _redeem(_codeCtrl.text),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HISTORY TAB
// ══════════════════════════════════════════════════════════════════════════════
class _HistoryTab extends StatefulWidget {
  const _HistoryTab();
  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

// ══════════════════════════════════════════════════════════════════════════════
// HISTORY DETAIL PAGE
// ══════════════════════════════════════════════════════════════════════════════
class _GDropDetailPage extends StatelessWidget {
  final Map<String, dynamic> item;
  const _GDropDetailPage({required this.item});

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, '
          '$hour12:${dt.minute.toString().padLeft(2, '0')} $ampm';
    } catch (_) {
      return raw;
    }
  }

  Widget _divider() => Divider(
    height: 1,
    indent: 16,
    endIndent: 16,
    color: Colors.grey.withOpacity(0.12),
  );

  Widget _row(
    BuildContext context,
    String label,
    String value,
    Color textColor, {
    bool copyable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (copyable) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Copied to clipboard'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              child: Icon(
                Icons.copy_rounded,
                size: 15,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);
    final card = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final tc = isDark ? Colors.white : Colors.black;

    final isSent = item['direction'] == 'sent';
    final status = item['status'] as String;
    final amount = double.parse(item['amount'].toString());
    final note = item['note'] ?? '';
    final voucherId = item['voucher_id'] ?? '';
    final other = isSent
        ? (item['claimed_by'] ?? 'Unclaimed')
        : (item['sender_username'] ?? '');
    final createdAt = item['created_at']?.toString() ?? '';
    final redeemedAt = item['redeemed_at']?.toString();

    final statusColor = status == 'active'
        ? Colors.green
        : status == 'redeemed'
        ? Colors.blue
        : Colors.red;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'GDrop Details',
          style: TextStyle(
            color: tc,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _maxContentWidth(context)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ── Hero amount ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: (isSent ? Colors.deepOrange : Colors.green)
                              .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSent
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: isSent ? Colors.deepOrange : Colors.green,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isSent ? 'You sent' : 'You received',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${isSent ? '-' : '+'}₦${amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: isSent ? Colors.deepOrange : Colors.green,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Detail rows ──
                Container(
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _row(
                        context,
                        'Voucher Code',
                        voucherId,
                        tc,
                        copyable: true,
                      ),
                      _divider(),
                      _row(
                        context,
                        isSent ? 'Sent To' : 'Received From',
                        other.isNotEmpty ? '@$other' : '—',
                        tc,
                      ),
                      _divider(),
                      _row(context, 'Date Created', _formatDate(createdAt), tc),
                      if (redeemedAt != null && redeemedAt.isNotEmpty) ...[
                        _divider(),
                        _row(
                          context,
                          'Date Redeemed',
                          _formatDate(redeemedAt),
                          tc,
                        ),
                      ],
                      if (note.isNotEmpty) ...[
                        _divider(),
                        _row(context, 'Note', '"$note"', tc),
                      ],
                    ],
                  ),
                ),

                // ── Re-share QR for unclaimed sent vouchers ──
                if (isSent && status == 'active') ...[
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Still unclaimed — share again',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: tc,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _GDropHeroCard(
                    qrData: jsonEncode({
                      'voucher_id': voucherId,
                      'amount': amount,
                    }),
                    voucherId: voucherId,
                    note: note,
                    status: 'Active',
                  ),
                  const SizedBox(height: 16),
                  _OutlineBtn(
                    icon: Icons.ios_share_rounded,
                    label: 'Share Code',
                    onTap: () => Share.share(
                      '🎁 GDrop gift of ₦${amount.toStringAsFixed(0)}!\nCode: $voucherId\nRedeem on Glopa app.',
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryTabState extends State<_HistoryTab> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final res = await http
          .get(
            Uri.parse(
              '$_base/gdrop_history.php?user_id=${user.userId}&filter=$_filter',
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        setState(() {
          _items = List<Map<String, dynamic>>.from(data['history']);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Filter chips — wrapped so they scroll horizontally instead of
        // overflowing if labels ever get longer (e.g. localization).
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  value: 'all',
                  current: _filter,
                  onTap: () {
                    _filter = 'all';
                    _load();
                    setState(() {});
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Sent',
                  value: 'sent',
                  current: _filter,
                  onTap: () {
                    _filter = 'sent';
                    _load();
                    setState(() {});
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Received',
                  value: 'received',
                  current: _filter,
                  onTap: () {
                    _filter = 'received';
                    _load();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.deepOrange),
                )
              : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        IconsaxPlusLinear.gift,
                        size: 52,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No GDrop history yet',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: Colors.deepOrange,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _HistoryCard(item: _items[i], isDark: isDark),
                  ),
                ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HERO QR CARD (matches the GDrop mockup: logo, title, tagline, logo-embedded
// QR, tap-to-enlarge, and a Voucher ID / Expires-in / Status stat row)
// ══════════════════════════════════════════════════════════════════════════════
class _GDropHeroCard extends StatefulWidget {
  final String qrData;
  final String voucherId;
  final String note;
  final String status;

  const _GDropHeroCard({
    required this.qrData,
    required this.voucherId,
    required this.note,
    this.status = 'Active',
  });

  @override
  State<_GDropHeroCard> createState() => _GDropHeroCardState();
}

class _GDropHeroCardState extends State<_GDropHeroCard> {
  bool _logoAvailable = true;

  @override
  void initState() {
    super.initState();
    _checkLogo();
  }

  // Confirms the asset actually resolves before we try to draw it in the
  // center of the QR — if it's missing/corrupt we fall back to a clean QR,
  // never a crash.
  Future<void> _checkLogo() async {
    try {
      await rootBundle.load(_kLogoAsset);
    } catch (_) {
      if (mounted) setState(() => _logoAvailable = false);
    }
  }

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

  void _enlarge() {
    final screenWidth = MediaQuery.of(context).size.width;
    // Size off the actual screen instead of a fixed 260, so it never
    // overflows the dialog on small phones.
    final qrSize = (screenWidth - 120).clamp(180.0, 320.0);

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQr(size: qrSize),
              const SizedBox(height: 16),
              Text(
                widget.voucherId,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The QR was fixed at 200px before — the single biggest overflow risk
    // in this card on a narrow phone (this card also gets embedded inside
    // pages with their own side padding, e.g. the 24px in _SendTab). Size
    // it off whatever width the card actually has instead.
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final qrSize = (cardWidth - 24 * 2 - 20 * 2).clamp(140.0, 240.0);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            gradient: _heroGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.25),
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
                        height: 56,
                        width: 56,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 56,
                        width: 56,
                        color: Colors.white.withOpacity(0.15),
                        alignment: Alignment.center,
                        child: const Text(
                          'G',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 14),
              const Text(
                'GDrop',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Share. Redeem. Delight.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 26),

              // white QR card
              GestureDetector(
                onTap: _enlarge,
                child: Container(
                  padding: const EdgeInsets.all(20),
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

              const SizedBox(height: 14),

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

              if (widget.note.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  '"${widget.note}"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              ],

              const SizedBox(height: 22),
              Divider(color: Colors.white.withOpacity(0.2), height: 1),
              const SizedBox(height: 20),

              // stat row
              Row(
                children: [
                  Expanded(
                    child: _HeroStat(
                      icon: Icons.tag_rounded,
                      label: 'Voucher ID',
                      value: widget.voucherId,
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
      Text(
        label,
        style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11),
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.deepOrange, size: 22),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBullet extends StatelessWidget {
  final String text;
  const _InfoBullet(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 15,
          color: Colors.deepOrange,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
        ),
      ],
    ),
  );
}

/// Primary call-to-action button with the shared accent gradient.
class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool loading;
  const _GradientButton({
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 54,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: loading ? null : _accentGradient,
        color: loading ? Colors.deepOrange.withOpacity(0.4) : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: loading
            ? []
            : [
                BoxShadow(
                  color: Colors.deepOrange.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: loading ? null : onTap,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    ),
  );
}

class _DesignChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _DesignChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.12)
              : (isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: QrImageView(
                data: 'preview',
                version: QrVersions.auto,
                size: 48,
                foregroundColor: color,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? color : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.deepOrange, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            Text(
              sub,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.deepOrange, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.deepOrange,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.deepOrange, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

class _FilterChip extends StatelessWidget {
  final String label, value, current;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final active = value == current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          gradient: active ? _accentGradient : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: active ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isDark;
  const _HistoryCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isSent = item['direction'] == 'sent';
    final status = item['status'] as String;
    final amount = double.parse(item['amount'].toString());
    final note = item['note'] ?? '';
    final other = isSent
        ? (item['claimed_by'] ?? 'Unclaimed')
        : (item['sender_username'] ?? '');
    final date = item['created_at']?.toString().substring(0, 16) ?? '';

    Color statusColor = status == 'active'
        ? Colors.green
        : status == 'redeemed'
        ? Colors.blue
        : Colors.red;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _GDropDetailPage(item: item)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Direction icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isSent ? Colors.deepOrange : Colors.green).withOpacity(
                  0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSent
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: isSent ? Colors.deepOrange : Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isSent ? 'Sent' : 'Received',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '${isSent ? '-' : '+'}₦${amount.toStringAsFixed(0)}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: isSent ? Colors.deepOrange : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSent
                        ? (status == 'active' ? 'Unclaimed' : 'To @$other')
                        : 'From @$other',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  if (note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        '"$note"',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        date,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    '  $text',
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade500,
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// PIN SHEET
// Collects the 4-digit PIN and returns it as a String. It does NOT validate
// the PIN itself — there's nothing to validate against on the client. The
// actual check happens server-side in gdrop_create.php, exactly the way
// tfmg.php validates PINs for p2p transfers.
// ══════════════════════════════════════════════════════════════════════════════
class _PinSheet extends StatefulWidget {
  const _PinSheet();
  @override
  State<_PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends State<_PinSheet> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final _pins = List.generate(4, (_) => '');

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onChange);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => FocusScope.of(context).requestFocus(_focus),
    );
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChange);
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChange() {
    final v = _ctrl.text.replaceAll(RegExp(r'\D'), '');
    final t = v.length > 4 ? v.substring(0, 4) : v;
    for (int i = 0; i < 4; i++) _pins[i] = i < t.length ? t[i] : '';
    setState(() {});
    if (t.length == 4) {
      // Hand the raw PIN back to the caller — no client-side approval.
      Navigator.pop(context, t);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final tc = isDark ? Colors.white : Colors.black87;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            // Caps the sheet width on tablets so the PIN boxes don't spread
            // out across the full screen.
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      Text(
                        'Enter Payment PIN',
                        style: TextStyle(
                          color: tc,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: tc),
                        onPressed: () => Navigator.pop(context, null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => FocusScope.of(context).requestFocus(_focus),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Boxes were a fixed 58px, which on a very small
                        // phone (< ~300px usable width after the sheet's
                        // margin+padding) could overflow the row. Derive
                        // the size from what's actually available instead.
                        final boxSize = ((constraints.maxWidth - 3 * 16) / 4)
                            .clamp(46.0, 58.0);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(4, (i) {
                            final filled = _pins[i].isNotEmpty;
                            final isCursor = _ctrl.text.length == i;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: boxSize,
                              height: boxSize,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: filled
                                    ? Colors.deepOrange.withOpacity(0.06)
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: filled || isCursor
                                      ? Colors.deepOrange
                                      : Colors.grey.shade400,
                                  width: filled ? 1.6 : 1.0,
                                ),
                              ),
                              child: filled
                                  ? const Icon(
                                      Icons.circle,
                                      size: 14,
                                      color: Colors.deepOrange,
                                    )
                                  : isCursor
                                  ? Container(
                                      width: 2,
                                      height: 18,
                                      color: Colors.deepOrange,
                                    )
                                  : null,
                            );
                          }),
                        );
                      },
                    ),
                  ),
                  // hidden input
                  TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    style: const TextStyle(
                      fontSize: 0.01,
                      color: Colors.transparent,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// QR SCANNER PAGE
// ══════════════════════════════════════════════════════════════════════════════
class _QRScannerPage extends StatelessWidget {
  const _QRScannerPage();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Scan GDrop QR'),
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    body: MobileScanner(
      onDetect: (capture) {
        final raw = capture.barcodes.first.rawValue;
        if (raw != null) Navigator.pop(context, raw);
      },
    ),
  );
}
