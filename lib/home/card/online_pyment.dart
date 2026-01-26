import 'dart:async';
import 'package:flutter/material.dart';

class OnlinePaymentPage extends StatefulWidget {
  const OnlinePaymentPage({super.key});

  @override
  State<OnlinePaymentPage> createState() => _OnlinePaymentPageState();
}

class _OnlinePaymentPageState extends State<OnlinePaymentPage> {
  late Timer _timer;
  Duration _remaining = const Duration(days: 3);
  bool _agreed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds > 0) {
        setState(() {
          _remaining -= const Duration(seconds: 1);
        });
      } else {
        _timer.cancel();
      }
    });
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) return "Coupon expired";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final days = duration.inDays;
    final hours = twoDigits(duration.inHours.remainder(24));
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$days d : $hours h : $minutes m : $seconds s";
  }

  bool get _isCouponValid => _remaining.inSeconds > 0;
  double get _amountToPay => _isCouponValid ? 1000.0 : 1500.0;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _showPinModal() {
    final theme = Theme.of(context);
    List<String> pin = ["", "", "", ""];
    int currentIndex = 0;
    final FocusNode focusNode = FocusNode();
    final TextEditingController hiddenController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Enter 4-Digit PIN",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 25),
                    GestureDetector(
                      onTap: () => FocusScope.of(context).requestFocus(focusNode),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(4, (index) {
                          return Container(
                            width: 55,
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.grey[900]
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: pin[index].isNotEmpty
                                    ? Colors.deepOrange
                                    : Colors.grey.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              pin[index].isNotEmpty ? "•" : "",
                              style: const TextStyle(
                                fontSize: 28,
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    TextField(
                      controller: hiddenController,
                      focusNode: focusNode,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      autofocus: true,
                      obscureText: true,
                      style: const TextStyle(color: Colors.transparent),
                      cursorColor: Colors.transparent,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: "",
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          for (int i = 0; i < 4; i++) {
                            pin[i] = i < val.length ? val[i] : "";
                          }
                        });

                        if (val.length == 4) {
                          Navigator.pop(context);
                          _startPayment();
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _startPayment() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PaymentSuccessPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Confirm Details"),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Personal Information",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 8),
                        _InfoRow(title: "First Name", value: "Gold"),
                        _InfoRow(title: "Middle Name", value: "Chile"),
                        _InfoRow(title: "Last Name", value: "Gboms"),
                        _InfoRow(title: "Date of Birth", value: "01/04/2003"),
                        _InfoRow(title: "Gender", value: "Male"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Coupon",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w500)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isCouponValid
                                    ? Colors.deepOrange.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _formatDuration(_remaining),
                                style: TextStyle(
                                  color: _isCouponValid
                                      ? Colors.deepOrange
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_isCouponValid)
                          const _InfoRow(title: "Discount", value: "-₦500.00"),
                        _InfoRow(
                            title: "Card Fee",
                            value: "₦${_isCouponValid ? 1000 : 1500}.00"),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Checkbox(
                      value: _agreed,
                      onChanged: (val) =>
                          setState(() => _agreed = val ?? false),
                      activeColor: Colors.deepOrange,
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: "I have read and agreed ",
                          style: theme.textTheme.bodyMedium,
                          children: const [
                            TextSpan(
                              text:
                              "GlobalPay Debit Card Terms & Conditions",
                              style: TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      _agreed ? Colors.deepOrange : Colors.grey,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _agreed ? _showPinModal : null,
                    child: Text(
                      "Pay ₦${_amountToPay.toStringAsFixed(0)}.00",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _agreed
                            ? Colors.white
                            : Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.deepOrange),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;
  const _InfoRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.bodySmall),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// --------------------------- Payment Success Page ---------------------------

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded,
                color: Colors.greenAccent.shade400, size: 100),
            const SizedBox(height: 20),
            Text(
              "Payment Successful!",
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Your card payment was completed successfully.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding:
                const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Done",style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),),
            )
          ],
        ),
      ),
    );
  }
}
