import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String email;

  const ForgotPasswordPage({
    super.key,
    required this.email,
    required String phoneNumber,
  });

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // EMAIL
  late final TextEditingController _emailController;
  String? _emailError;

  // OTP
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
  List.generate(6, (_) => FocusNode());
  String? _otpError;

  // PIN
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String? _pinError;
  String? _confirmPinError;

  bool _codeSent = false;
  bool _verifyingOtp = false;
  bool _otpVerified = false;
  bool _showSuccess = false;

  Timer? _timer;
  int _secondsLeft = 60;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _pinController.dispose();
    _confirmPinController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ---------------- BACK BUTTON LOGIC ----------------
  void _handleBack() {
    if (_showSuccess) {
      Navigator.pop(context);
      return;
    }

    if (_otpVerified) {
      setState(() {
        _otpVerified = false;
        _pinController.clear();
        _confirmPinController.clear();
        _pinError = null;
        _confirmPinError = null;
      });
      return;
    }

    if (_codeSent) {
      setState(() {
        _codeSent = false;
        _verifyingOtp = false;
        _otpError = null;
        for (final c in _otpControllers) {
          c.clear();
        }
        _timer?.cancel();
      });
      return;
    }

    Navigator.pop(context);
  }

  // ---------------- EMAIL VALIDATION ----------------
  bool _isValidEmail(String email) {
    return RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    ).hasMatch(email);
  }

  // ---------------- SEND CODE ----------------
  void _sendCode() {
    final email = _emailController.text.trim();

    if (email.isEmpty || !_isValidEmail(email)) {
      setState(() => _emailError = "Enter a valid email address");
      return;
    }

    setState(() {
      _emailError = null;
      _codeSent = true;
      _secondsLeft = 60;
    });

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  // ---------------- OTP ----------------
  void _onOtpTap(int index) {
    if (index > 0 && _otpControllers[index - 1].text.isEmpty) {
      setState(() => _otpError = "Fill previous box first");
      return;
    }
    _otpFocusNodes[index].requestFocus();
  }

  void _onOtpChanged(int index, String value) async {
    if (value.isEmpty) return;

    if (index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }

    final otp = _otpControllers.map((e) => e.text).join();
    if (otp.length == 6) {
      setState(() {
        _verifyingOtp = true;
        _otpError = null;
      });

      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;
      setState(() {
        _verifyingOtp = false;
        _otpVerified = true;
      });
    }
  }

  // ---------------- CONFIRM PIN ----------------
  void _confirmPin() async {
    setState(() {
      _pinError = null;
      _confirmPinError = null;
    });

    if (_pinController.text.length != 4) {
      setState(() => _pinError = "PIN must be 4 digits");
      return;
    }

    if (_pinController.text != _confirmPinController.text) {
      setState(() => _confirmPinError = "PINs do not match");
      return;
    }

    setState(() => _showSuccess = true);
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : Colors.white;
    final fill = isDark ? Colors.grey.shade900 : Colors.grey.shade100;
    final text = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.white70 : Colors.black54;
    final primary = Colors.deepOrange;

    return WillPopScope(
      onWillPop: () async {
        _handleBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
          ),
          title: const Text("Reset PIN"),
          backgroundColor: bg,
          elevation: 0,
          foregroundColor: text,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: bg,
            statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _showSuccess
              ? _successView(primary)
              : Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: !_codeSent
                ? _emailView(primary, text, subText, fill)
                : _otpVerified
                ? _pinView(primary, fill)
                : _otpView(primary, fill, text, subText),
          ),
        ),
      ),
    );
  }

  // ---------------- EMAIL ----------------
  Widget _emailView(
      Color primary, Color text, Color subText, Color fill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Text("Forgot your PIN?",
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: text)),
        const SizedBox(height: 10),
        Text("Enter your email address",
            style: TextStyle(color: subText)),
        const SizedBox(height: 30),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: "Email",
            errorText: _emailError,
            filled: true,
            fillColor: fill,
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (_) => setState(() => _emailError = null),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: _sendCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            minimumSize: const Size(double.infinity, 56),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child:
          const Text("Send Code", style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }

  // ---------------- OTP ----------------
  Widget _otpView(
      Color primary, Color fill, Color text, Color subText) {
    return Column(
      children: [
        Text("Verification Code",
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: text)),
        const SizedBox(height: 8),
        Text("Enter the 6-digit code",
            style: TextStyle(color: subText)),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            6,
                (i) => SizedBox(
              width: 46,
              child: TextField(
                controller: _otpControllers[i],
                focusNode: _otpFocusNodes[i],
                maxLength: 1,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: fill,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onTap: () => _onOtpTap(i),
                onChanged: (v) => _onOtpChanged(i, v),
              ),
            ),
          ),
        ),
        if (_otpError != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child:
            Text(_otpError!, style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 30),
        if (_verifyingOtp) const CircularProgressIndicator(),
        const SizedBox(height: 30),
        _secondsLeft > 0
            ? Text("Resend code in $_secondsLeft s",
            style: TextStyle(color: subText))
            : TextButton(
          onPressed: _sendCode,
          child: const Text("Didn’t receive code? Send again"),
        ),
      ],
    );
  }

  // ---------------- PIN ----------------
  Widget _pinView(Color primary, Color fill) {
    return Column(
      children: [
        TextField(
          controller: _pinController,
          maxLength: 4,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "New PIN",
            errorText: _pinError,
            filled: true,
            fillColor: fill,
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (_) => setState(() => _pinError = null),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _confirmPinController,
          maxLength: 4,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Confirm PIN",
            errorText: _confirmPinError,
            filled: true,
            fillColor: fill,
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (_) =>
              setState(() => _confirmPinError = null),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _confirmPin,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            minimumSize: const Size(double.infinity, 56),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text("Confirm PIN",
              style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }

  // ---------------- SUCCESS ----------------
  Widget _successView(Color primary) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.check_circle, size: 110, color: primary),
          const SizedBox(height: 20),
          const Text(
            "PIN successfully changed!",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
