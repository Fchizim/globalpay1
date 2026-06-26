import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
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

// ─── ENTRY POINT ─────────────────────────────────────────────────────────────
class GDropPage extends StatefulWidget {
  const GDropPage({super.key});
  @override
  State<GDropPage> createState() => _GDropPageState();
}

class _GDropPageState extends State<GDropPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF121212) : Colors.white;
    final tc     = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor:      bg,
        elevation:            0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: tc, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('GDrop',
            style: TextStyle(
                color: tc, fontWeight: FontWeight.bold, fontSize: 20)),
        bottom: TabBar(
          controller: _tabs,
          labelColor:           Colors.deepOrange,
          unselectedLabelColor: Colors.grey,
          indicatorColor:       Colors.deepOrange,
          tabs: const [
            Tab(text: 'Send'),
            Tab(text: 'Redeem'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _SendTab(),
          _RedeemTab(),
          _HistoryTab(),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SEND TAB
// ══════════════════════════════════════════════════════════════════════════════
class _SendTab extends StatefulWidget {
  const _SendTab();
  @override
  State<_SendTab> createState() => _SendTabState();
}

class _SendTabState extends State<_SendTab> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();

  int    _design      = 0;
  bool   _loading     = false;
  String _voucherId   = '';
  double _voucherAmt  = 0;
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
      _snack('Minimum amount is ₦100', error: true); return;
    }

    // PIN confirmation
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PinSheet(),
    );
    if (ok != true) return;

    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('$_base/gdrop_create.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user.userId,
          'amount':  amt,
          'note':    _noteCtrl.text.trim(),
          'design':  _design,
        }),
      ).timeout(const Duration(seconds: 20));

      final data = jsonDecode(res.body);
      if (!mounted) return;

      if (data['status'] == 'success') {
        setState(() {
          _voucherId   = data['voucher_id'];
          _voucherAmt  = double.parse(data['amount'].toString());
          _voucherNote = data['note'] ?? '';
        });
      } else {
        _snack(data['message'] ?? 'Failed to create GDrop', error: true);
      }
    } catch (e) {
      _snack('Network error. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Save QR to gallery ─────────────────────────────────────────────────────
  Future<void> _saveQR() async {
    try {
      final boundary =
      _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image  = await boundary.toImage(pixelRatio: 3.0);
      final bytes  = await image.toByteData(format: ui.ImageByteFormat.png);
      final result = await ImageGallerySaver.saveImage(
          bytes!.buffer.asUint8List(),
          name: 'GDrop_$_voucherId');
      if (result['isSuccess'] == true) {
        _snack('Saved to gallery!');
      }
    } catch (_) {
      _snack('Could not save image', error: true);
    }
  }

  // ── Share QR ───────────────────────────────────────────────────────────────
  Future<void> _shareQR() async {
    try {
      final boundary =
      _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final tmp   = await getTemporaryDirectory();
      final file  = File('${tmp.path}/gdrop_$_voucherId.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '🎁 I sent you a GDrop gift of ₦${_voucherAmt.toStringAsFixed(0)}!\n'
            'Code: $_voucherId\nRedeem on Glopa app.',
      );
    } catch (_) {
      // fallback: share code as text
      Share.share(
        '🎁 GDrop gift of ₦${_voucherAmt.toStringAsFixed(0)}!\n'
            'Code: $_voucherId\nRedeem on Glopa app.',
      );
    }
  }

  void _reset() => setState(() {
    _voucherId = '';
    _amountCtrl.clear();
    _noteCtrl.clear();
    _design = 0;
  });

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade600 : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final card   = isDark ? const Color(0xFF242424) : Colors.grey.shade50;
    final tc     = isDark ? Colors.white : Colors.black;

    // ── QR result view ────────────────────────────────────────────────────────
    if (_voucherId.isNotEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [

          // QR card (repaint boundary for screenshot)
          RepaintBoundary(
            key: _qrKey,
            child: _GDropQRCard(
              voucherId:  _voucherId,
              amount:     _voucherAmt,
              note:       _voucherNote,
              design:     _design,
            ),
          ),

          const SizedBox(height: 28),

          // Code chip (tap to copy)
          GestureDetector(
            onTap: () {
              // copy to clipboard via share
              Share.share(_voucherId);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color:        Colors.deepOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border:       Border.all(color: Colors.deepOrange.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.copy, color: Colors.deepOrange, size: 16),
                const SizedBox(width: 8),
                Text(_voucherId,
                    style: const TextStyle(
                        color:      Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                        fontSize:   15,
                        letterSpacing: 1.2)),
              ]),
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Row(children: [
            Expanded(
              child: _OutlineBtn(
                icon:  Icons.download_rounded,
                label: 'Save',
                onTap: _saveQR,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _OutlineBtn(
                icon:  Icons.share_rounded,
                label: 'Share',
                onTap: _shareQR,
              ),
            ),
          ]),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _reset,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Send Another GDrop',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      );
    }

    // ── Form view ──────────────────────────────────────────────────────────────
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepOrange.shade600, Colors.purple.shade300],
              begin: Alignment.topLeft,
              end:   Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            SizedBox(
              height: 24,
              child: Marquee(
                text:       '💸 Surprise your loved ones with GDrop cash gifts!    ',
                style:      const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                blankSpace: 40,
                velocity:   40,
              ),
            ),
            const SizedBox(height: 6),
            const Text('QR-based instant money gift',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),

        const SizedBox(height: 24),

        // Design selector
        const Text('Choose a Design',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _DesignChip(index: 0, label: 'Plain', selected: _design == 0,
                color: Colors.black,
                onTap: () => setState(() => _design = 0)),
            _DesignChip(index: 1, label: 'Love ❤️', selected: _design == 1,
                color: Colors.deepOrange,
                onTap: () => setState(() => _design = 1)),
            _DesignChip(index: 2, label: 'Gift 🎁', selected: _design == 2,
                color: Colors.purple,
                onTap: () => setState(() => _design = 2)),
          ],
        ),

        const SizedBox(height: 24),

        // Amount field
        const _FieldLabel('Amount (₦)'),
        const SizedBox(height: 8),
        TextField(
          controller:   _amountCtrl,
          keyboardType: TextInputType.number,
          style: TextStyle(
              color: tc, fontWeight: FontWeight.bold, fontSize: 22),
          decoration: InputDecoration(
            prefixText: '₦ ',
            prefixStyle: TextStyle(
                color: tc, fontWeight: FontWeight.bold, fontSize: 22),
            hintText:  'Min ₦100',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
            filled:    true,
            fillColor: card,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: Colors.deepOrange, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Note field
        const _FieldLabel('Note (optional)'),
        const SizedBox(height: 8),
        TextField(
          controller: _noteCtrl,
          style: TextStyle(color: tc),
          decoration: InputDecoration(
            hintText:  'e.g. Happy Birthday! 🎂',
            hintStyle: const TextStyle(color: Colors.grey),
            filled:    true,
            fillColor: card,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: Colors.deepOrange, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _loading ? null : _generate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              disabledBackgroundColor: Colors.deepOrange.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
                : const Text('Generate GDrop',
                style: TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize:   16)),
          ),
        ),
        const SizedBox(height: 30),
      ]),
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
  bool   _loading = false;
  Map<String, dynamic>? _result; // success payload

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  // ── Call backend ──────────────────────────────────────────────────────────
  Future<void> _redeem(String code) async {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty) { _snack('Enter a voucher code', error: true); return; }

    final user = context.read<UserProvider>().user;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('$_base/gdrop_redeem.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': user.userId, 'voucher_id': clean}),
      ).timeout(const Duration(seconds: 20));

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
    final xFile  = await picker.pickImage(source: ImageSource.gallery);
    if (xFile == null || !mounted) return;

    _snack('Reading QR from image...');
    final scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    try {
      final inputImage = InputImage.fromFilePath(xFile.path);
      final barcodes   = await scanner.processImage(inputImage);
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
      final id   = json['voucher_id']?.toString() ?? json['id']?.toString() ?? '';
      if (id.startsWith('GDRP-')) { _redeem(id); return; }
    } catch (_) {}
    // Plain string
    if (raw.startsWith('GDRP-')) { _redeem(raw); return; }
    _snack('QR does not contain a valid GDrop code.', error: true);
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade600 : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card   = isDark ? const Color(0xFF242424) : Colors.grey.shade50;
    final tc     = isDark ? Colors.white : Colors.black;

    // ── Success view ────────────────────────────────────────────────────────
    if (_result != null) {
      final amt    = double.parse(_result!['amount'].toString());
      final sender = _result!['sender_username'] ?? '';
      final note   = _result!['note'] ?? '';

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Confetti-style icon
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color:  Colors.deepOrange.withOpacity(0.1),
                shape:  BoxShape.circle,
              ),
              child: const Icon(Icons.celebration_rounded,
                  size: 64, color: Colors.deepOrange),
            ),
            const SizedBox(height: 24),
            Text('🎉 You received',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            Text(
              '₦${amt.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize:   46,
                  fontWeight: FontWeight.w900,
                  color:      Colors.deepOrange),
            ),
            if (sender.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('from @$sender',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
            ],
            if (note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color:        card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('"$note"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color:     tc.withOpacity(0.75))),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => setState(() {
                  _result = null;
                  _codeCtrl.clear();
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Redeem Another',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      );
    }

    // ── Redeem form ─────────────────────────────────────────────────────────
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [

        const SizedBox(height: 8),

        // Scan / Gallery quick actions
        Row(children: [
          Expanded(
            child: _ActionTile(
              icon:  Icons.qr_code_scanner_rounded,
              label: 'Scan QR',
              sub:   'Use camera',
              onTap: _scanCamera,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _ActionTile(
              icon:  Icons.image_rounded,
              label: 'From Gallery',
              sub:   'Pick QR image',
              onTap: _pickFromGallery,
            ),
          ),
        ]),

        const SizedBox(height: 28),

        // Divider with "OR"
        Row(children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('OR ENTER CODE',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400)),
          ),
          const Expanded(child: Divider()),
        ]),

        const SizedBox(height: 24),

        // Manual code entry
        const _FieldLabel('Voucher Code'),
        const SizedBox(height: 8),
        TextField(
          controller:     _codeCtrl,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
              fontFamily:    'monospace',
              fontSize:      18,
              fontWeight:    FontWeight.bold,
              letterSpacing: 2),
          decoration: InputDecoration(
            hintText:  'GDRP-XXXXXXXX-XXXX-XXXX',
            hintStyle: TextStyle(
                color:         Colors.grey.shade400,
                fontSize:      14,
                fontWeight:    FontWeight.normal,
                letterSpacing: 1),
            filled:    true,
            fillColor: card,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: Colors.deepOrange, width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () => _codeCtrl.clear(),
            ),
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _loading ? null : () => _redeem(_codeCtrl.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              disabledBackgroundColor: Colors.deepOrange.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
                : const Text('Redeem GDrop',
                style: TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize:   16)),
          ),
        ),
      ]),
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
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ampm   = dt.hour >= 12 ? 'PM' : 'AM';
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, '
          '$hour12:${dt.minute.toString().padLeft(2, '0')} $ampm';
    } catch (_) {
      return raw;
    }
  }

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16);

  Widget _row(BuildContext context, String label, String value, Color textColor,
      {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(
                    color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          if (copyable) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Copied to clipboard'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              },
              child: Icon(Icons.copy, size: 15, color: Colors.grey.shade400),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF121212) : Colors.white;
    final card   = isDark ? const Color(0xFF242424) : Colors.grey.shade50;
    final tc     = isDark ? Colors.white : Colors.black;

    final isSent    = item['direction'] == 'sent';
    final status    = item['status'] as String;
    final amount    = double.parse(item['amount'].toString());
    final note      = item['note'] ?? '';
    final voucherId = item['voucher_id'] ?? '';
    final design    = int.tryParse(item['design']?.toString() ?? '0') ?? 0;
    final other     = isSent
        ? (item['claimed_by'] ?? 'Unclaimed')
        : (item['sender_username'] ?? '');
    final createdAt  = item['created_at']?.toString() ?? '';
    final redeemedAt = item['redeemed_at']?.toString();

    final statusColor = status == 'active'   ? Colors.green
        : status == 'redeemed' ? Colors.blue
        : Colors.red;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('GDrop Details',
            style: TextStyle(color: tc, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          // ── Hero amount ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: (isSent ? Colors.deepOrange : Colors.green).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSent ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  color: isSent ? Colors.deepOrange : Colors.green,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(isSent ? 'You sent' : 'You received',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              Text(
                '${isSent ? '-' : '+'}₦${amount.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: isSent ? Colors.deepOrange : Colors.green),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Detail rows ──
          Container(
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              _row(context, 'Voucher Code', voucherId, tc, copyable: true),
              _divider(),
              _row(context, isSent ? 'Sent To' : 'Received From',
                  other.isNotEmpty ? '@$other' : '—', tc),
              _divider(),
              _row(context, 'Date Created', _formatDate(createdAt), tc),
              if (redeemedAt != null && redeemedAt.isNotEmpty) ...[
                _divider(),
                _row(context, 'Date Redeemed', _formatDate(redeemedAt), tc),
              ],
              if (note.isNotEmpty) ...[
                _divider(),
                _row(context, 'Note', '"$note"', tc),
              ],
            ]),
          ),

          // ── Re-share QR for unclaimed sent vouchers ──
          if (isSent && status == 'active') ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Still unclaimed — share again',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: tc)),
            ),
            const SizedBox(height: 14),
            _GDropQRCard(
              voucherId: voucherId,
              amount: amount,
              note: note,
              design: design,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => Share.share(
                  '🎁 GDrop gift of ₦${amount.toStringAsFixed(0)}!\nCode: $voucherId\nRedeem on Glopa app.',
                ),
                icon: const Icon(Icons.share_rounded, color: Colors.deepOrange),
                label: const Text('Share Code',
                    style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.deepOrange),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _HistoryTabState extends State<_HistoryTab> {
  List<Map<String, dynamic>> _items   = [];
  bool                       _loading = true;
  String                     _filter  = 'all';

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
      final res = await http.get(
        Uri.parse('$_base/gdrop_history.php?user_id=${user.userId}&filter=$_filter'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        setState(() {
          _items   = List<Map<String, dynamic>>.from(data['history']);
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
    final tc     = isDark ? Colors.white : Colors.black;

    return Column(children: [

      // Filter chips
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(children: [
          _FilterChip(label: 'All',      value: 'all',      current: _filter,
              onTap: () { _filter = 'all';      _load(); setState((){}); }),
          const SizedBox(width: 8),
          _FilterChip(label: 'Sent',     value: 'sent',     current: _filter,
              onTap: () { _filter = 'sent';     _load(); setState((){}); }),
          const SizedBox(width: 8),
          _FilterChip(label: 'Received', value: 'received', current: _filter,
              onTap: () { _filter = 'received'; _load(); setState((){}); }),
        ]),
      ),

      const SizedBox(height: 8),

      Expanded(
        child: _loading
            ? const Center(
            child: CircularProgressIndicator(color: Colors.deepOrange))
            : _items.isEmpty
            ? Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(IconsaxPlusLinear.gift,
                size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No GDrop history yet',
                style: TextStyle(color: Colors.grey.shade400)),
          ]),
        )
            : RefreshIndicator(
          onRefresh: _load,
          color: Colors.deepOrange,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) =>
                _HistoryCard(item: _items[i], isDark: isDark),
          ),
        ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// QR CARD WIDGET (used for display + screenshot)
// ══════════════════════════════════════════════════════════════════════════════
class _GDropQRCard extends StatelessWidget {
  final String voucherId;
  final double amount;
  final String note;
  final int    design;

  const _GDropQRCard({
    required this.voucherId,
    required this.amount,
    required this.note,
    required this.design,
  });

  Color get _fgColor {
    switch (design) {
      case 1: return Colors.deepOrange;
      case 2: return Colors.purple;
      default: return Colors.black;
    }
  }

  LinearGradient get _gradient {
    switch (design) {
      case 1: return LinearGradient(
          colors: [Colors.deepOrange.shade400, Colors.pink.shade300],
          begin: Alignment.topLeft, end: Alignment.bottomRight);
      case 2: return LinearGradient(
          colors: [Colors.purple.shade400, Colors.indigo.shade300],
          begin: Alignment.topLeft, end: Alignment.bottomRight);
      default: return const LinearGradient(
          colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrData = jsonEncode({
      'voucher_id': voucherId,
      'amount':     amount,
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient:     _gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.18),
            blurRadius: 20,
            offset:     const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: [
        // Header
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            design == 1 ? '❤️ GDrop' : design == 2 ? '🎁 GDrop' : '💸 GDrop',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            '₦${amount.toStringAsFixed(0)}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
          ),
        ]),
        const SizedBox(height: 20),

        // QR
        Container(
          padding:     const EdgeInsets.all(16),
          decoration:  BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: QrImageView(
            data:            qrData,
            version:         QrVersions.auto,
            size:            200,
            foregroundColor: _fgColor,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Note
        if (note.isNotEmpty)
          Text('"$note"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color:     Colors.white70,
                  fontStyle: FontStyle.italic,
                  fontSize:  14)),

        const SizedBox(height: 8),
        Text('Scan to claim · Glopa GDrop',
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 11)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SMALL WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _DesignChip extends StatelessWidget {
  final int index; final String label; final bool selected;
  final Color color; final VoidCallback onTap;
  const _DesignChip({required this.index, required this.label,
    required this.selected, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:        selected ? color.withOpacity(0.12) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(
            color: selected ? color : Colors.grey.shade300, width: 1.5),
      ),
      child: Column(children: [
        QrImageView(
          data:            'preview',
          version:         QrVersions.auto,
          size:            60,
          foregroundColor: color,
          backgroundColor: Colors.white,
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color:      selected ? color : Colors.grey.shade600)),
      ]),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon; final String label, sub; final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label,
    required this.sub, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color:        isDark ? const Color(0xFF242424) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: Colors.deepOrange.withOpacity(0.25)),
        ),
        child: Column(children: [
          Icon(icon, color: Colors.deepOrange, size: 32),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
          Text(sub,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ]),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _OutlineBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon:  Icon(icon, color: Colors.deepOrange, size: 18),
    label: Text(label,
        style: const TextStyle(
            color: Colors.deepOrange, fontWeight: FontWeight.bold)),
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
      side:    const BorderSide(color: Colors.deepOrange),
      shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class _FilterChip extends StatelessWidget {
  final String label, value, current; final VoidCallback onTap;
  const _FilterChip({required this.label, required this.value,
    required this.current, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final active = value == current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color:        active ? Colors.deepOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border:       Border.all(
              color: active ? Colors.deepOrange : Colors.grey.shade300),
        ),
        child: Text(label,
            style: TextStyle(
                color:      active ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize:   13)),
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
    final isSent   = item['direction'] == 'sent';
    final status   = item['status'] as String;
    final amount   = double.parse(item['amount'].toString());
    final note     = item['note'] ?? '';
    final other    = isSent
        ? (item['claimed_by'] ?? 'Unclaimed')
        : (item['sender_username'] ?? '');
    final date     = item['created_at']?.toString().substring(0, 16) ?? '';

    Color statusColor = status == 'active'   ? Colors.green
        : status == 'redeemed' ? Colors.blue
        : Colors.red;

    return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _GDropDetailPage(item: item)),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:        isDark ? const Color(0xFF242424) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border:       Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Row(children: [
        // Direction icon
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color:  (isSent ? Colors.deepOrange : Colors.green).withOpacity(0.1),
            shape:  BoxShape.circle,
          ),
          child: Icon(
            isSent ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: isSent ? Colors.deepOrange : Colors.green,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),

        // Info
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                isSent ? 'Sent' : 'Received',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                '${isSent ? '-' : '+'}₦${amount.toStringAsFixed(0)}',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize:   16,
                    color:      isSent ? Colors.deepOrange : Colors.green),
              ),
            ]),
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
                child: Text('"$note"',
                    style: TextStyle(
                        color:     Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                        fontSize:  12)),
              ),
            const SizedBox(height: 6),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:        statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                      color:      statusColor,
                      fontSize:   10,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Text(date,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            ]),
          ]),
        ),
          ]),
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
        color: Colors.grey.shade500),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// PIN SHEET (reused from MoneyDrop)
// ══════════════════════════════════════════════════════════════════════════════
class _PinSheet extends StatefulWidget {
  const _PinSheet();
  @override
  State<_PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends State<_PinSheet> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();
  final _pins  = List.generate(4, (_) => '');
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onChange);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => FocusScope.of(context).requestFocus(_focus));
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
    if (t.length == 4 && !_loading) {
      setState(() => _loading = true);
      // Validate PIN against your backend here if needed;
      // for now accept any 4-digit entry after 1.5s
      Future.delayed(const Duration(milliseconds: 1500),
              () { if (mounted) Navigator.pop(context, true); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card   = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final tc     = isDark ? Colors.white : Colors.black87;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          margin:  const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
              color: card, borderRadius: BorderRadius.circular(18)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const SizedBox(width: 40),
              Text('Enter Payment PIN',
                  style: TextStyle(
                      color: tc, fontSize: 16, fontWeight: FontWeight.w700)),
              IconButton(
                  icon: Icon(Icons.close, color: tc),
                  onPressed: () => Navigator.pop(context, false)),
            ]),
            const SizedBox(height: 16),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).requestFocus(_focus),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (i) {
                  final filled   = _pins[i].isNotEmpty;
                  final isCursor = _ctrl.text.length == i && !_loading;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 58, height: 58,
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
                          width: filled ? 1.6 : 1.0),
                    ),
                    child: filled
                        ? const Icon(Icons.circle,
                        size: 14, color: Colors.deepOrange)
                        : isCursor
                        ? Container(
                        width: 2, height: 18,
                        color: Colors.deepOrange)
                        : null,
                  );
                }),
              ),
            ),
            // hidden input
            TextField(
              controller: _ctrl,
              focusNode:  _focus,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                  border: InputBorder.none, counterText: ''),
              style: const TextStyle(
                  fontSize: 0.01, color: Colors.transparent),
            ),
            if (_loading) ...[
              const SizedBox(height: 8),
              const CircularProgressIndicator(
                  color: Colors.deepOrange, strokeWidth: 2.5),
            ],
            const SizedBox(height: 8),
          ]),
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