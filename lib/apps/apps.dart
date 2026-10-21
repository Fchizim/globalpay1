import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marquee/marquee.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import 'package:globalpay/help_page/help_screen.dart';
import 'package:globalpay/profile_details/profile_details.dart';

import '../Market/market_page.dart';
import '../Market/orders_page.dart';
import '../convert/convert_page.dart';
import '../home/coming_soon.dart';
import '../home/home_page.dart';
import '../me/me_page.dart';
import '../home/card/card_page.dart';

import '../models/user_model.dart';
import '../provider/user_provider.dart';

const _gdropBase = 'https://glopa.org/glo';

const _accentGradient = LinearGradient(
  colors: [Color(0xFFFF7A45), Color(0xFFFF4D8D)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

String _commas(num n) => n.round().toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

class MyAppsPage extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const MyAppsPage({super.key, required this.onToggleTheme});

  @override
  State<MyAppsPage> createState() => _MyAppsPageState();
}

class _MyAppsPageState extends State<MyAppsPage> {
  int _selectedIndex = 0;
  bool _redeeming = false; // blocks double-redeem while a request is in flight

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  final Color darkBackground = const Color(0xFF121212);
  final Color darkCard = const Color(0xFF1E1E1E);
  final Color textPrimary = Colors.white;
  final Color accentColor = Colors.deepOrange;

  // ───────────────────────── SCAN HANDLING ─────────────────────────

  Future<void> _openScanner() async {
    final raw = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _QRScannerPage()),
    );
    if (raw == null || !mounted) return;
    await _autoRedeem(raw);
  }

  /// Our GDrop QR is JSON: {"voucher_id": "GDRP-...", "amount": 1000}.
  /// A plain "GDRP-..." string is also accepted.
  String? _parseVoucherId(String raw) {
    try {
      final j = jsonDecode(raw);
      if (j is Map) {
        final id = (j['voucher_id'] ?? j['id'] ?? '').toString();
        if (id.startsWith('GDRP-')) return id;
      }
    } catch (_) {}
    final t = raw.trim();
    if (t.startsWith('GDRP-')) return t;
    return null;
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

  /// Scan -> redeem immediately -> celebration screen.
  Future<void> _autoRedeem(String raw) async {
    if (_redeeming) return;

    final voucherId = _parseVoucherId(raw);
    if (voucherId == null) {
      _snack('Not a GDrop QR code', error: true);
      return;
    }

    final user = context.read<UserProvider>().user;
    if (user == null) return;

    _redeeming = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.deepOrange),
      ),
    );

    Map<String, dynamic>? data;
    String? error;
    try {
      final res = await http
          .post(
            Uri.parse('$_gdropBase/gdrop_redeem.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': user.userId,
              'voucher_id': voucherId.toUpperCase(),
            }),
          )
          .timeout(const Duration(seconds: 20));
      final decoded = jsonDecode(res.body);
      if (decoded['status'] == 'success') {
        data = Map<String, dynamic>.from(decoded);
      } else {
        error = decoded['message']?.toString() ?? 'Redemption failed';
      }
    } catch (_) {
      error = 'Network error. Please try again.';
    }

    _redeeming = false;
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close loader

    if (data == null) {
      _snack(error ?? 'Redemption failed', error: true);
      return;
    }

    HapticFeedback.heavyImpact();
    final amount = double.tryParse(data['amount'].toString()) ?? 0;
    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _RedeemSuccessPage(
          amount: amount,
          sender: data!['sender_username']?.toString() ?? '',
          note: data['note']?.toString() ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final List<Widget> pages = [
      const HomePage(),
      // const FinancePage(),
      const ComingSoonScreen(),
      const CardPage(),
      const ComingSoonScreen(),
      // const CardsPage(),
      // const ComingSoonScreen(),
      MePage(onToggleTheme: widget.onToggleTheme),
    ];

    return Scaffold(
      // Lets page content draw behind the nav bar so it shows through.
      // Add ~100 bottom padding to scrollable pages so the last items
      // aren't hidden behind the bar.
      extendBody: true,
      backgroundColor: isDark ? darkBackground : Colors.grey.shade100,
      appBar: _selectedIndex == 0
          ? buildAppBar(isDark: isDark, user: user)
          : null,
      body: pages[_selectedIndex],
      bottomNavigationBar: _buildNavBar(isDark),
    );
  }

  // ───────────────────────── NAV BAR ─────────────────────────

  Widget _buildNavBar(bool isDark) {
    final Color barColor = isDark ? darkCard : Colors.white;
    final bool shopSelected = _selectedIndex == 2;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: SizedBox(
          height: 84,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 🔹 Floating pill bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 64,
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.45 : 0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _navItem(
                          index: 0,
                          icon: IconsaxPlusLinear.home,
                          activeIcon: IconsaxPlusBold.home,
                          label: 'Home',
                          isDark: isDark,
                        ),
                      ),
                      Expanded(
                        child: _navItem(
                          index: 1,
                          icon: IconsaxPlusLinear.chart_3,
                          activeIcon: IconsaxPlusBold.chart_3,
                          label: 'Finance',
                          isDark: isDark,
                        ),
                      ),
                      // Space for the raised center button
                      const Expanded(child: SizedBox()),
                      Expanded(
                        child: _navItem(
                          index: 3,
                          icon: IconsaxPlusLinear.card,
                          activeIcon: IconsaxPlusBold.card,
                          label: 'Cards',
                          isDark: isDark,
                        ),
                      ),
                      Expanded(
                        child: _navItem(
                          index: 4,
                          icon: IconsaxPlusLinear.grammerly,
                          activeIcon: IconsaxPlusBold.grammerly,
                          label: 'Me',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 🔹 Raised center button (Shop)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _onItemTapped(2),
                    child: AnimatedScale(
                      scale: shopSelected ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      child: Container(
                        height: 58,
                        width: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepOrange,
                              Colors.deepOrange.shade600,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          // Translucent ring (the old solid "cut-out" ring
                          // would look like an opaque disc over content).
                          border: Border.all(
                            color: (isDark ? Colors.white : Colors.black)
                                .withOpacity(0.08),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(
                                shopSelected ? 0.55 : 0.35,
                              ),
                              blurRadius: shopSelected ? 20 : 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          IconsaxPlusBold.shop,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
  }) {
    final bool selected = _selectedIndex == index;
    final Color color = selected
        ? accentColor
        : (isDark ? Colors.white54 : Colors.grey.shade500);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Icon(selected ? activeIcon : icon, color: color, size: 22),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── APP BAR ─────────────────────────

  PreferredSizeWidget buildAppBar({
    required bool isDark,
    required UserModel? user,
  }) {
    final textColor = isDark ? textPrimary : Colors.black87;
    final String? imageUrl = user?.image;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: isDark ? darkBackground : Colors.grey.shade100,
      title: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileDetails(onToggleTheme: () {}),
            ),
          );
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: accentColor.withOpacity(0.1),
              backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                  ? NetworkImage(imageUrl)
                  : const AssetImage('assets/images/png/gold.jpg'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Hi, ${user?.name ?? 'Guest'}",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: textColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.verified,
                        color: Colors.deepOrange,
                        size: 16,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 18,
                    child: Marquee(
                      text: user != null
                          ? "🔥 Welcome back, ${user.name}! Check out new updates! 🔥"
                          : "🔥 Welcome! Check out new updates! 🔥",
                      style: TextStyle(color: textColor, fontSize: 14),
                      blankSpace: 30.0,
                      velocity: 30.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpScreen()),
                  );
                },
                child: Container(
                  height: 23,
                  width: 43,
                  decoration: const BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Help",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _openScanner,
                child: Icon(IconsaxPlusLinear.scan, color: textColor, size: 20),
              ),

              const SizedBox(width: 10),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdersPage()),
                  );
                },
                child: Icon(
                  IconsaxPlusLinear.bag_2,
                  color: textColor,
                  size: 20,
                ), // or whichever order icon you prefer
              ),
              const SizedBox(width: 10),

              Icon(
                IconsaxPlusLinear.notification_bing,
                color: textColor,
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// REDEEM SUCCESS PAGE (full screen, flying confetti)
// ══════════════════════════════════════════════════════════════════════════════
class _RedeemSuccessPage extends StatefulWidget {
  final double amount;
  final String sender;
  final String note;
  const _RedeemSuccessPage({
    required this.amount,
    required this.sender,
    required this.note,
  });

  @override
  State<_RedeemSuccessPage> createState() => _RedeemSuccessPageState();
}

class _RedeemSuccessPageState extends State<_RedeemSuccessPage>
    with TickerProviderStateMixin {
  late final AnimationController _confetti;
  late final AnimationController _pop;
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    const colors = [
      Color(0xFFFF7A45),
      Color(0xFFFF4D8D),
      Color(0xFF7B2FF7),
      Color(0xFFFFC107),
      Color(0xFF4CAF50),
      Color(0xFF29B6F6),
    ];
    _pieces = List.generate(90, (_) => _Piece.random(rnd, colors));

    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA);
    final tc = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _pop,
                        curve: Curves.elasticOut,
                      ),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: _accentGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepOrange.withOpacity(0.35),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.celebration_rounded,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      '🎉 Congratulations!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: tc,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You received',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ShaderMask(
                      shaderCallback: (r) => _accentGradient.createShader(r),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '₦${_commas(widget.amount)}',
                          style: const TextStyle(
                            fontSize: 54,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (widget.sender.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'from @${widget.sender}',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                    if (widget.note.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A1A1A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '"${widget.note}"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: tc.withOpacity(0.75),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: _accentGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
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
                            onTap: () => Navigator.pop(context),
                            child: const Center(
                              child: Text(
                                'Done',
                                style: TextStyle(
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
                  ],
                ),
              ),
            ),
          ),

          // Confetti on top, never blocks taps
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _confetti,
              builder: (_, __) => CustomPaint(
                painter: _ConfettiPainter(_pieces, _confetti.value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Piece {
  final double x; // 0..1 start position across the width
  final double delay; // 0..1 offset in the loop
  final double speed; // fall speed multiplier
  final double sway; // horizontal drift amplitude
  final double swayFreq;
  final double size;
  final double spin;
  final Color color;
  final bool round;

  _Piece({
    required this.x,
    required this.delay,
    required this.speed,
    required this.sway,
    required this.swayFreq,
    required this.size,
    required this.spin,
    required this.color,
    required this.round,
  });

  factory _Piece.random(math.Random r, List<Color> colors) => _Piece(
    x: r.nextDouble(),
    delay: r.nextDouble(),
    speed: 0.7 + r.nextDouble() * 0.8,
    sway: 10 + r.nextDouble() * 40,
    swayFreq: 1 + r.nextDouble() * 3,
    size: 6 + r.nextDouble() * 8,
    spin: (r.nextDouble() - 0.5) * 12,
    color: colors[r.nextInt(colors.length)],
    round: r.nextBool(),
  );
}

class _ConfettiPainter extends CustomPainter {
  final List<_Piece> pieces;
  final double t; // 0..1 loop
  _ConfettiPainter(this.pieces, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      // progress 0..1 down the screen, looping per piece
      final prog = ((t * p.speed) + p.delay) % 1.0;
      final y = -20 + prog * (size.height + 40);
      final x =
          p.x * size.width + math.sin(prog * math.pi * 2 * p.swayFreq) * p.sway;
      final paint = Paint()..color = p.color;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(prog * p.spin);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.55,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}

// ══════════════════════════════════════════════════════════════════════════════
// QR SCANNER PAGE
// ══════════════════════════════════════════════════════════════════════════════
/// Full-screen QR scanner. Returns the scanned string via
/// Navigator.pop(context, raw), or null if the user backs out.
class _QRScannerPage extends StatefulWidget {
  const _QRScannerPage();

  @override
  State<_QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<_QRScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  final ImagePicker _picker = ImagePicker();

  bool _handled = false; // stops multiple pops from repeated detections
  bool _busy = false; // true while analysing a gallery image

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish(String raw) {
    if (_handled) return;
    _handled = true;
    HapticFeedback.mediumImpact();
    Navigator.pop(context, raw);
  }

  void _onDetect(BarcodeCapture capture) {
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw != null && raw.isNotEmpty) {
        _finish(raw);
        return;
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_busy) return;
    HapticFeedback.selectionClick();

    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _busy = true);
    try {
      final BarcodeCapture? result = await _controller.analyzeImage(file.path);
      String? raw;
      for (final b in result?.barcodes ?? const <Barcode>[]) {
        if (b.rawValue != null && b.rawValue!.isNotEmpty) {
          raw = b.rawValue;
          break;
        }
      }

      if (raw != null) {
        _finish(raw);
      } else if (mounted) {
        _toast('No QR code found in that image');
      }
    } catch (_) {
      if (mounted) _toast('Could not read that image');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double frame = size.width * 0.68;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🔹 Camera
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // 🔹 Dark gradients so white text stays readable on any feed
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x99000000),
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0xCC000000),
                    ],
                    stops: [0.0, 0.22, 0.65, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 🔹 Scan frame
          Center(
            child: IgnorePointer(
              child: SizedBox(
                width: frame,
                height: frame,
                child: CustomPaint(painter: _CornerPainter()),
              ),
            ),
          ),

          // 🔹 Back button
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),

          // 🔹 Label under the frame
          Positioned(
            left: 0,
            right: 0,
            top: (size.height / 2) + (frame / 2) + 24,
            child: const IgnorePointer(
              child: Text(
                'Scan QR Code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // 🔹 Bottom actions: Album (left) + Flashlight (right)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 36),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ScannerActionButton(
                      icon: IconsaxPlusLinear.gallery,
                      label: 'Album',
                      loading: _busy,
                      onTap: _pickFromGallery,
                    ),
                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _controller,
                      builder: (_, state, __) {
                        final bool on = state.torchState == TorchState.on;
                        return _ScannerActionButton(
                          icon: on
                              ? IconsaxPlusBold.flash_1
                              : IconsaxPlusLinear.flash_1,
                          label: 'Flashlight',
                          active: on,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _controller.toggleTorch();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── ACTION BUTTON ─────────────────────────

/// Circle icon with a label underneath. The circle fills while pressed
/// (and stays filled when [active], e.g. flashlight on).
class _ScannerActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool loading;

  const _ScannerActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.loading = false,
  });

  @override
  State<_ScannerActionButton> createState() => _ScannerActionButtonState();
}

class _ScannerActionButtonState extends State<_ScannerActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool filled = _pressed || widget.active;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled
                  ? Colors.white.withOpacity(0.32)
                  : Colors.transparent,
            ),
            child: Center(
              child: widget.loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      widget.icon,
                      size: 28,
                      color: widget.active
                          ? Colors.deepOrange.shade300
                          : Colors.white,
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── SCAN FRAME ─────────────────────────

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const double len = 28;
    const double r = 16;
    final w = size.width;
    final h = size.height;

    // top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(len, 0),
      paint,
    );
    // top-right
    canvas.drawPath(
      Path()
        ..moveTo(w - len, 0)
        ..lineTo(w - r, 0)
        ..quadraticBezierTo(w, 0, w, r)
        ..lineTo(w, len),
      paint,
    );
    // bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, h - len)
        ..lineTo(0, h - r)
        ..quadraticBezierTo(0, h, r, h)
        ..lineTo(len, h),
      paint,
    );
    // bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(w - len, h)
        ..lineTo(w - r, h)
        ..quadraticBezierTo(w, h, w, h - r)
        ..lineTo(w, h - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
