// cards_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'delivery details.dart';
import 'online_pyment.dart';

class CardsPage extends StatefulWidget {
  const CardsPage({super.key});

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> with TickerProviderStateMixin {
  bool showPhysical = true;
  late final AnimationController _beatController;

  @override
  void initState() {
    super.initState();
    _beatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      lowerBound: 0.98,
      upperBound: 1.03,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _beatController.dispose();
    super.dispose();
  }

  void _toggle(bool physical) {
    setState(() => showPhysical = physical);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor:
      isDark ? const Color(0xFF080809) : const Color(0xFFFFFBF8),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.white.withOpacity(0.6),
              child: Text(
                "My Cards",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _toggleButton("Physical", showPhysical, () => _toggle(true)),
                    const SizedBox(width: 12),
                    _toggleButton("Virtual", !showPhysical, () => _toggle(false)),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: showPhysical
                        ? _buildPhysicalCardView(isDark)
                        : _buildVirtualCardView(isDark),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),

          // -------- Floating Button --------
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: AnimatedBuilder(
              animation: _beatController,
              builder: (context, child) {
                final scale = _beatController.value;
                return Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 10,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        backgroundColor: Colors.deepOrange,
                        shadowColor:
                        Colors.deepOrangeAccent.withOpacity(0.5),
                      ),
                      onPressed: () {
                        if (showPhysical) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => DeliveryDetailsPage()),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => OnlinePaymentPage()),
                          );
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            showPhysical
                                ? "Get Card Now ₦999"
                                : "Pay Online",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------- PHYSICAL card view ----------
  Widget _buildPhysicalCardView(bool isDark) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        _cardVisual(
          useImage: true,
          cardNumber: "**** **** **** 8321",
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        _featureTile(Icons.attach_money, "Low maintenance",
            "Only ₦10/month — transparent small fee, big value.",
            Colors.orange.shade700),
        const SizedBox(height: 12),
        _featureTile(Icons.shopping_bag_outlined, "Accepted everywhere",
            "100k+ merchants across Nigeria (online & offline).",
            Colors.purple),
        const SizedBox(height: 12),
        _featureTile(Icons.local_shipping, "Fast delivery",
            "Physical cards shipped quickly; virtual cards ready instantly.",
            Colors.blueAccent),
        const SizedBox(height: 12),
        _featureTile(Icons.security, "Bank-level security",
            "PCI-level safety, tokenization & instant fraud alerts.",
            Colors.teal),
        const SizedBox(height: 12),
        _featureTile(Icons.support_agent, "24/7 Support",
            "Live chat & responsive support when you need help.",
            Colors.green),
      ],
    );
  }

  // ---------- VIRTUAL card view ----------
  Widget _buildVirtualCardView(bool isDark) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        _cardVisual(
          useImage: false,
          gradient: const LinearGradient(
            colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          cardNumber: "**** **** **** 4455",
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        _featureTile(Icons.flash_on, "Instant Access",
            "Use your card immediately after creation.", Colors.indigo),
        const SizedBox(height: 12),
        _featureTile(Icons.refresh, "Instant Refunds",
            "Failed transactions refunded instantly.", Colors.redAccent),
        const SizedBox(height: 12),
        _featureTile(Icons.shield_rounded, "Safety",
            "Tokenized payments & rigorous fraud checks.",
            Colors.tealAccent.shade700),
        const SizedBox(height: 12),
        _featureTile(Icons.settings_backup_restore, "Chargebacks & Controls",
            "Freeze, limit & control cards in-app.", Colors.deepPurple),
        const SizedBox(height: 20),
        const Text("Popular Services",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 12),
        Row(
          children: [
            _brandChip("Netflix", Colors.redAccent),
            const SizedBox(width: 10),
            _brandChip("SportyBet", Colors.green),
            const SizedBox(width: 10),
            _brandChip("Spotify", Colors.teal),
          ],
        ),
      ],
    );
  }

  // ---------- helpers ----------
  Widget _cardVisual({
    LinearGradient? gradient,
    required String cardNumber,
    required bool isDark,
    bool useImage = false,
  }) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        image: useImage
            ? const DecorationImage(
          image: AssetImage("assets/images/png/cardbg.png"),
          fit: BoxFit.cover,
        )
            : null,
        gradient: useImage ? null : gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset("assets/images/png/chip.jpeg", height: 28),
              const Text(
                "GlobalPay",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
          const Spacer(),
          Text(cardNumber,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("GOLD EMMANUEL",
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text("12/27",
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _featureTile(
      IconData icon, String title, String subtitle, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF101010)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    accent.withOpacity(0.25),
                    accent.withOpacity(0.08)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: accent.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _brandChip(String name, Color color) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(name,
          style:
          TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _toggleButton(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.deepOrange : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? [
            BoxShadow(
                color: Colors.deepOrange.withOpacity(0.16),
                blurRadius: 10,
                offset: const Offset(0, 6))
          ]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
