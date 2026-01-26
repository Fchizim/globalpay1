import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert'; // for jsonEncode & jsonDecode
import 'package:http/http.dart' as http; // for http.post
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../apps/apps.dart';


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

  late final PinTheme pinTheme;
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

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();

    pinTheme = PinTheme(
      width: 65,
      height: 65,
      textStyle: const TextStyle(
        fontSize: 24,
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
        body: jsonEncode({
          "email": widget.email,
          "pin": pin,
        }),
      );

      final data = jsonDecode(res.body);

      if (data['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pin', pin);

        if (mounted) {
          setState(() => isLoading = false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MyAppsPage(onToggleTheme: () {}),
            ),
          );
        }
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error: $e")),
      );
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
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
