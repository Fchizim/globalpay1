import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert'; // for jsonEncode & jsonDecode
import 'package:http/http.dart' as http; // for http.post
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../apps/apps.dart';
import 'login_page.dart';

class SetPinPage extends StatefulWidget {
  final String email;
  const SetPinPage({super.key, required this.email});

  @override
  State<SetPinPage> createState() => _SetPinPageState();
}

class _SetPinPageState extends State<SetPinPage> with TickerProviderStateMixin {
  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();

  String? firstPin;
  bool isConfirmStage = false;
  bool isLoading = false;
  bool obscurePin = true;

  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  /// Builds the Pinput box theme sized to whatever width is actually
  /// available, instead of a fixed 65x65. 4 boxes + 3 gaps of 8px used
  /// to need ~284px on top of 64px of padding — that overflows on any
  /// phone narrower than ~360px. This solves it for any screen size by
  /// solving backwards from the available width.
  PinTheme _buildPinTheme(BuildContext context, double horizontalPadding) {
    final screenWidth = MediaQuery.of(context).size.width;
    const gapCount = 3;
    const gapWidth = 8.0;
    final available =
        screenWidth - (horizontalPadding * 2) - (gapCount * gapWidth);
    final boxSize = (available / 4).clamp(48.0, 65.0);
    final fontSize = (boxSize * 0.37).clamp(18.0, 24.0);

    return PinTheme(
      width: boxSize,
      height: boxSize,
      textStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.deepOrange.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    );
  }

  Future<void> _savePinLocally(String pin) async {
    setState(() => isLoading = true);

    try {
      final res = await http.post(
        Uri.parse("https://glopa.org/glo/set_pin.php"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": widget.email, "pin": pin}),
      );

      final data = jsonDecode(res.body);

      if (data['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pin', pin);

        if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! Please log in to continue.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => LoginPage(
                onToggleTheme: () {},
                onLoginSuccess: () {},
                prefillEmail: widget.email,
              ),
            ),
          );
        }
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Network error: $e")));
    }
  }

  void _onPinCompleted(String pin) {
    if (!isConfirmStage) {
      setState(() {
        firstPin = pin;
        isConfirmStage = true;
      });
      confirmPinController.clear();
      _fadeController.forward(from: 0);
      _slideController.forward(from: 0);
    } else {
      if (pin == firstPin) {
        _savePinLocally(pin);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("PINs do not match. Try again."),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() {
          isConfirmStage = false;
          firstPin = null;
        });
        pinController.clear();
        confirmPinController.clear();
      }
    }
  }

  @override
  void dispose() {
    pinController.dispose();
    confirmPinController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const horizontalPadding = 32.0;
    final pinTheme = _buildPinTheme(context, horizontalPadding);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFEBD8), Color(0xFFFFF8F2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // LayoutBuilder + a min-height ConstrainedBox means the
          // content stays vertically centered when it fits (the normal
          // case), but becomes scrollable instead of overflowing when
          // it doesn't — e.g. when the keyboard opens on a shorter
          // phone and shrinks the available body height.
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isConfirmStage
                                    ? 'Confirm your 4-digit PIN'
                                    : 'Set your 4-digit PIN',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 30),
                              Pinput(
                                length: 4,
                                controller: isConfirmStage
                                    ? confirmPinController
                                    : pinController,
                                defaultPinTheme: pinTheme,
                                obscureText: obscurePin,
                                obscuringCharacter: "•",
                                onCompleted: _onPinCompleted,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isConfirmStage
                                    ? 'Re-enter the PIN to confirm'
                                    : 'This PIN will be used for login',
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.65),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              TextButton.icon(
                                onPressed: () =>
                                    setState(() => obscurePin = !obscurePin),
                                icon: Icon(
                                  obscurePin
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.deepOrange,
                                ),
                                label: Text(
                                  obscurePin ? 'Show PIN' : 'Hide PIN',
                                  style: const TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isLoading)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: Colors.white.withOpacity(0.2),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.deepOrange,
                    strokeWidth: 4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
