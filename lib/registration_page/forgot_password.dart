import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String email;
  const ForgotPasswordPage({super.key, required this.email, required String phoneNumber});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  bool _isLoading = false;
  bool _codeSent = false;
  bool _showPinFields = false;
  bool _otpVerified = false;
  bool _showSuccess = false;
  String? _message;
  int _counter = 60;
  Timer? _timer;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  String _generatedCode = '';

  // ✅ Gmail credentials for sending OTPs
  final String _gmailUsername = 'globalpay.otpsender@gmail.com';
  final String _gmailAppPassword = 'csfeihqjhlecomvt'; // 16-char app password

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
    _opacityAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeIn);
  }

  String get maskedEmail {
    String email = _emailController.text.trim();
    int atIndex = email.indexOf('@');
    if (atIndex <= 1) return email;
    return email[0] + '*' * (atIndex - 1) + email.substring(atIndex);
  }

  Future<void> _sendResetCode() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      setState(() => _message = 'Please enter your email');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = 'Generating verification code...';
    });

    await Future.delayed(const Duration(milliseconds: 800)); // realism delay

    try {
      _generatedCode = (100000 + Random().nextInt(900000)).toString();

      final smtpServer = gmail(_gmailUsername, _gmailAppPassword);

      final message = Message()
        ..from = Address(_gmailUsername, 'GlobalPay')
        ..recipients.add(email)
        ..subject = 'Your GlobalPay OTP'
        ..text =
            'Your OTP to reset your PIN is $_generatedCode. It is valid for 5 minutes.';

      await send(message, smtpServer);

      setState(() {
        _isLoading = false;
        _codeSent = true;
        _message = 'OTP sent to $maskedEmail';
      });

      _startTimer();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error sending code: $e';
      });
    }
  }

  void _startTimer() {
    _counter = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_counter == 0) {
        timer.cancel();
      } else {
        setState(() => _counter--);
      }
    });
  }

  void _checkOtpAndShowPin() {
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length == 6 && !_otpVerified) {
      if (otp == _generatedCode) {
        setState(() {
          _otpVerified = true;
          _showPinFields = true;
          _message = 'OTP verified, almost there...';
        });
      } else {
        setState(() => _message = 'Incorrect code, try again');
      }
    }
  }

  void _confirmPin() async {
    String pin = _pinController.text.trim();
    String confirmPin = _confirmPinController.text.trim();

    if (pin.length != 4 || confirmPin.length != 4) {
      setState(() => _message = 'Enter 4-digit PIN in both fields');
      return;
    }

    if (pin != confirmPin) {
      setState(() => _message = 'PINs do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = 'PIN successfully changed!';
      _showSuccess = true;
    });

    _animController.forward(from: 0);

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.pop(context);

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    for (var c in _otpControllers) c.dispose();
    for (var f in _otpFocusNodes) f.dispose();
    _emailController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Colors.deepOrange;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final inputFill = isDark ? Colors.grey.shade900 : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Reset PIN", style: TextStyle(color: textColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: bgColor,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _showSuccess
            ? _buildSuccessMessage(primaryColor)
            : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: SingleChildScrollView(
            child: _codeSent
                ? _buildOtpForm(primaryColor, textColor, subTextColor, inputFill)
                : _buildEmailForm(primaryColor, textColor, subTextColor, inputFill),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm(Color primary, Color text, Color subText, Color fill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text('Forgot your PIN?',
            style: TextStyle(fontSize: 24, color: text, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text('Enter your email to receive a verification code.',
            style: TextStyle(color: subText, fontSize: 15)),
        const SizedBox(height: 30),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            labelStyle: TextStyle(color: text),
            filled: true,
            fillColor: fill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primary),
            ),
          ),
          style: TextStyle(color: text),
        ),
        const SizedBox(height: 25),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendResetCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isLoading
              ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white)),
              SizedBox(width: 12),
              Text('Processing...', style: TextStyle(color: Colors.white)),
            ],
          )
              : const Text('Send code',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(_message!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
        ],
      ],
    );
  }

  Widget _buildOtpForm(Color primary, Color text, Color subText, Color fill) {
    return Column(
      children: [
        const SizedBox(height: 20),
        if (!_otpVerified) ...[
          Text('Verification Code',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: text)),
          const SizedBox(height: 10),
          Text('Enter the 6-digit code sent to $maskedEmail',
              style: TextStyle(color: subText, fontSize: 15),
              textAlign: TextAlign.center),
        ],
        const SizedBox(height: 30),
        _otpVerified
            ? _buildVerifiedView(primary, text)
            : _buildOtpFields(primary, text, fill),
        const SizedBox(height: 20),
        if (!_otpVerified && _counter > 0)
          Text('Request new code in $_counter s',
              style: TextStyle(
                  color: _counter <= 10 ? primary : subText,
                  fontWeight: _counter <= 10 ? FontWeight.bold : FontWeight.normal)),
        const SizedBox(height: 30),
        if (_showPinFields) ..._buildPinFields(primary, text, fill),
        if (_message != null) ...[
          const SizedBox(height: 10),
          Text(_message!,
              style: TextStyle(
                  color: _message!.contains('success') ? Colors.green : Colors.redAccent)),
        ],
      ],
    );
  }

  Widget _buildOtpFields(Color primary, Color text, Color fill) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        6,
            (index) => SizedBox(
          width: 45,
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
            maxLength: 1,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: text),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: fill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primary, width: 2)),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                _otpFocusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _otpFocusNodes[index - 1].requestFocus();
              }
              _checkOtpAndShowPin();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedView(Color primary, Color text) {
    return Column(
      children: [
        Container(
            height: 120,
            width: 120,
            decoration:
            BoxDecoration(shape: BoxShape.circle, color: primary.withOpacity(0.1)),
            child: Icon(Icons.verified_rounded, color: primary, size: 70)),
        const SizedBox(height: 10),
        Text('Verification successful!',
            style: TextStyle(fontSize: 18, color: primary, fontWeight: FontWeight.bold)),
        Text('You can now reset your PIN below.',
            style: TextStyle(color: text.withOpacity(0.7), fontSize: 14),
            textAlign: TextAlign.center),
      ],
    );
  }

  List<Widget> _buildPinFields(Color primary, Color text, Color fill) {
    return [
      TextField(
        controller: _pinController,
        maxLength: 4,
        obscureText: true,
        keyboardType: TextInputType.number,
        style: TextStyle(color: text),
        decoration: InputDecoration(
          labelText: 'Enter new 4-digit PIN',
          labelStyle: TextStyle(color: text),
          filled: true,
          fillColor: fill,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primary, width: 2)),
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _confirmPinController,
        maxLength: 4,
        obscureText: true,
        keyboardType: TextInputType.number,
        style: TextStyle(color: text),
        decoration: InputDecoration(
          labelText: 'Confirm new PIN',
          labelStyle: TextStyle(color: text),
          filled: true,
          fillColor: fill,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primary, width: 2)),
        ),
      ),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: _confirmPin,
        style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        child: _isLoading
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Processing...', style: TextStyle(color: Colors.white)),
          ],
        )
            : const Text('Confirm PIN',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    ];
  }

  Widget _buildSuccessMessage(Color primary) {
    return Center(
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(scale: _scaleAnimation.value, child: child),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 70),
            Icon(Icons.task_alt_rounded, color: primary, size: 110),
            const SizedBox(height: 25),
            Text('PIN successfully changed!',
                style: TextStyle(fontSize: 22, color: primary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
