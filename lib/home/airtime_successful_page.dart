import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:globalpay/home/transaction_detail_page.dart';

class AirtimeSuccessScreen extends StatefulWidget {
  final int amount;
  final String network;
  final String phone;

  const AirtimeSuccessScreen({
    super.key,
    required this.amount,
    required this.network,
    required this.phone,
  });

  @override
  State<AirtimeSuccessScreen> createState() => _AirtimeSuccessScreenState();
}

class _AirtimeSuccessScreenState extends State<AirtimeSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    // 🎬 Animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // 🎉 Confetti animation
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    Future.delayed(const Duration(milliseconds: 400), () {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // 🏷 Returns network logo path
  String _getNetworkLogo(String network) {
    switch (network.toLowerCase()) {
      case 'mtn':
        return 'assets/images/png/mtn.jpeg';
      case 'airtel':
        return 'assets/images/png/airtel.jpeg';
      case 'glo':
        return 'assets/images/png/glo.jpeg';
      case '9mobile':
      case 'etisalat':
        return 'assets/images/png/9mobile.jpeg';
      default:
        return 'assets/images/png/mtn.jpeg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // 💳 Fintech Color Palette
    final Color greenSuccess = const Color(0xFF22C55E);
    final Color deepOrange = Colors.deepOrange;
    final Color bgColor = isDark ? const Color(0xFF0D0D0D) : Colors.white;
    final Color cardColor = isDark
        ? Colors.grey[900]!.withOpacity(0.6)
        : Colors.white.withOpacity(0.95);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 🎊 Confetti Effect
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 25,
              maxBlastForce: 25,
              minBlastForce: 5,
              gravity: 0.2,
              colors: const [
                Colors.deepOrange,
                Colors.green,
                Colors.amber,
                Colors.orangeAccent,
                Colors.white,
              ],
            ),

            // 🧩 Main Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ Animated Success Icon
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            greenSuccess,
                            greenSuccess.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: greenSuccess.withOpacity(0.4),
                            blurRadius: 25,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),
                  Text(
                    'Payment Successful',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // 💰 Amount
                  Text(
                    '₦${NumberFormat.decimalPattern().format(widget.amount)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color:
                      isDark ? Colors.white : Colors.black.withOpacity(0.8),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 💳 Info Card
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [

                          const SizedBox(height: 20),

                          // 👤 Recipient Row
                          Row(
                            children: [
                              const Text("Recipient"),
                              const Spacer(),
                              Text(
                                widget.phone,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: deepOrange,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),

                          // 🏷 Network Logo, Name, & View Details
                          Column(
                            children: [
                              Row(
                                children: [
                                  Text("Network"),
                                  Spacer(),
                                  Container(
                                    height: 30,
                                    width: 30,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    clipBehavior: Clip.hardEdge,
                                    child: Image.asset(
                                      _getNetworkLogo(widget.network),
                                      fit: BoxFit.cover,
                                    ),
                                  ),

                                  SizedBox(width: 5),
                                  Text(
                                    widget.network.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),

                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TransactionDetailScreen(
                                        amount: widget.amount,
                                        network: widget.network,
                                        phone: widget.phone,
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "View Details",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: deepOrange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Icon(Icons.keyboard_arrow_right_outlined,color: Colors.deepOrange,size: 20,)
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // ✅ Done Button
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: ElevatedButton(
                      onPressed: () {
                        _confettiController.stop();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: deepOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
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
