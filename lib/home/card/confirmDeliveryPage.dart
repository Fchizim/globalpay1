import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'card_transfer_successful_page.dart';
import 'delivery details.dart';

class ConfirmDeliveryPage extends StatefulWidget {
  final String state;
  final String lga;
  final String address;
  final String landmark;
  final String phone;
  final String additionalPhone;

  const ConfirmDeliveryPage({
    super.key,
    required this.state,
    required this.lga,
    required this.address,
    required this.landmark,
    required this.phone,
    required this.additionalPhone,
  });

  @override
  State<ConfirmDeliveryPage> createState() => _ConfirmDeliveryPageState();
}

class _ConfirmDeliveryPageState extends State<ConfirmDeliveryPage> {
  bool agreed = false;
  Duration remaining = const Duration(minutes: 9, seconds: 43);
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startCountdown();
  }

  void startCountdown() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remaining.inSeconds > 0) {
        setState(() {
          remaining = Duration(seconds: remaining.inSeconds - 1);
        });
      } else {
        timer.cancel();
      }
    });
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final m = twoDigits(duration.inMinutes.remainder(60));
    final s = twoDigits(duration.inSeconds.remainder(60));
    return "$m:$s";
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _showPaymentSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                "Payment Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 15),
              _detailRow("Payment", "₦1,998.00"),
              const SizedBox(height: 5),
              const Text(
                "If time counts down it will be ₦3,998.00",
                style: TextStyle(fontSize: 13, color: Colors.deepOrange),
              ),
              const SizedBox(height: 10),
              _detailRow("Amount", "₦3,998.00"),
              _detailRow("Coupon", "-₦2,000.00"),
              _detailRow("Payment Method", "Balance"),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showPinModal(context);
                },
                child: const Text(
                  "Confirm to Pay",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showPinModal(BuildContext context) {
    final pinControllers =
    List.generate(4, (_) => TextEditingController());
    final focusNodes = List.generate(4, (_) => FocusNode());
    bool processing = false;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void checkPin() async {
              final pin =
              pinControllers.map((c) => c.text).join();
              if (pin.length == 4) {
                setModalState(() => processing = true);
                await Future.delayed(const Duration(seconds: 1));
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaymentSuccessPage(),
                    ),
                  );
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 25,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Enter 4-digit PIN",
                    style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),

                  if (processing)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(
                        color: Colors.deepOrange,
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        return SizedBox(
                          width: 55,
                          child: TextField(
                            controller: pinControllers[index],
                            focusNode: focusNodes[index],
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            decoration: InputDecoration(
                              counterText: "",
                              filled: true,
                              fillColor: isDark
                                  ? Colors.black
                                  : Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (val) {
                              if (val.isNotEmpty && index < 3) {
                                focusNodes[index + 1].requestFocus();
                              } else if (val.isEmpty && index > 0) {
                                focusNodes[index - 1].requestFocus();
                              }
                              checkPin();
                            },
                          ),
                        );
                      }),
                    ),

                  const SizedBox(height: 10),
                  const Text(
                    "Auto processing after entering 4 digits...",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 15)),
          Text(
            value,
            style:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepOrange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$title: $value',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feeRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
              const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = {
      'state': widget.state,
      'lga': widget.lga,
      'address': widget.address,
      'landmark': widget.landmark,
      'phone': widget.phone,
      'additionalPhone': widget.additionalPhone,
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D0D) : Colors.grey[100];
    final cardColor = isDark ? const Color(0xFF1C1C1C) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardColor,
        title: const Text(
          'Confirm Delivery',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(LucideIcons.mapPin, 'State', widget.state),
                      _infoRow(LucideIcons.building, 'LGA', widget.lga),
                      _infoRow(LucideIcons.map, 'Address', widget.address),
                      _infoRow(LucideIcons.landmark, 'Landmark', widget.landmark),
                      _infoRow(LucideIcons.smartphone, 'Phone', widget.phone),
                      if (widget.additionalPhone.isNotEmpty)
                        _infoRow(LucideIcons.phone, 'Additional', widget.additionalPhone),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DeliveryDetailsPage(previousData: data),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _feeRow('Card fee', '₦999.00'),
                  _feeRow('Delivery fee', '₦2,999.00'),
                  const Divider(height: 20, thickness: 0.6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 18, color: Colors.deepOrange),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'Coupon expires in ${formatDuration(remaining)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        '-₦2,000.00',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                Checkbox(
                  activeColor: Colors.deepOrange,
                  value: agreed,
                  onChanged: (val) {
                    setState(() {
                      agreed = val ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text(
                    'I have read and agreed to GlobalPay Debit Card Terms & Conditions',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  agreed ? Colors.deepOrange : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding:
                  const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: agreed
                    ? () => _showPaymentSheet(context)
                    : null,
                child: const Text(
                  'Pay ₦1,998.00',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
