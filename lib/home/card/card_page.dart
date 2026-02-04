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

  // Responsive scale helper
  double s(double value) {
    final sw = MediaQuery.of(context).size.width;
    return (sw / 375 * value).clamp(value * 0.85, value * 1.25);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? const Color(0xFF080809) : const Color(0xFFFFFBF8),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: ClipRRect(
          borderRadius: BorderRadius.circular(s(12)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: s(12), vertical: s(6)),
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.white.withOpacity(0.6),
              child: Text(
                "My Cards",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: s(16),
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
                SizedBox(height: s(12)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _toggleButton("Physical", showPhysical, () => _toggle(true)),
                    SizedBox(width: s(12)),
                    _toggleButton("Virtual", !showPhysical, () => _toggle(false)),
                  ],
                ),
                SizedBox(height: s(20)),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: s(16)),
                    child: showPhysical
                        ? _buildPhysicalCardView(isDark)
                        : _buildVirtualCardView(isDark),
                  ),
                ),
                SizedBox(height: s(80)),
              ],
            ),
          ),

          // -------- Floating Button --------
          Positioned(
            left: s(16),
            right: s(16),
            bottom: s(24),
            child: AnimatedBuilder(
              animation: _beatController,
              builder: (context, child) {
                final scale = _beatController.value;
                return Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    height: s(56),
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 10,
                        padding: EdgeInsets.symmetric(
                            vertical: s(14), horizontal: s(20)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(s(14))),
                        backgroundColor: Colors.deepOrange,
                        shadowColor: Colors.deepOrangeAccent.withOpacity(0.5),
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
                      child: Text(
                        showPhysical ? "Get Card Now ₦999" : "Pay Online",
                        style: TextStyle(
                          fontSize: s(16),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
      padding: EdgeInsets.only(bottom: s(28)),
      children: [
        _cardVisual(
          useImage: true,
          cardNumber: "**** **** **** 8321",
          isDark: isDark,
        ),
        SizedBox(height: s(20)),
        _featureTile(Icons.attach_money, "Low maintenance",
            "Only ₦10/month — transparent small fee, big value.",
            Colors.orange.shade700),
        SizedBox(height: s(12)),
        _featureTile(Icons.shopping_bag_outlined, "Accepted everywhere",
            "100k+ merchants across Nigeria (online & offline).",
            Colors.purple),
        SizedBox(height: s(12)),
        _featureTile(Icons.local_shipping, "Fast delivery",
            "Physical cards shipped quickly; virtual cards ready instantly.",
            Colors.blueAccent),
        SizedBox(height: s(12)),
        _featureTile(Icons.security, "Bank-level security",
            "PCI-level safety, tokenization & instant fraud alerts.",
            Colors.teal),
        SizedBox(height: s(12)),
        _featureTile(Icons.support_agent, "24/7 Support",
            "Live chat & responsive support when you need help.",
            Colors.green),
      ],
    );
  }

  // ---------- VIRTUAL card view ----------
  Widget _buildVirtualCardView(bool isDark) {
    return ListView(
      padding: EdgeInsets.only(bottom: s(28)),
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
        SizedBox(height: s(20)),
        _featureTile(Icons.flash_on, "Instant Access",
            "Use your card immediately after creation.", Colors.indigo),
        SizedBox(height: s(12)),
        _featureTile(Icons.refresh, "Instant Refunds",
            "Failed transactions refunded instantly.", Colors.redAccent),
        SizedBox(height: s(12)),
        _featureTile(Icons.shield_rounded, "Safety",
            "Tokenized payments & rigorous fraud checks.",
            Colors.tealAccent.shade700),
        SizedBox(height: s(12)),
        _featureTile(Icons.settings_backup_restore, "Chargebacks & Controls",
            "Freeze, limit & control cards in-app.", Colors.deepPurple),
        SizedBox(height: s(20)),
        Text("Popular Services",
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: s(15))),
        SizedBox(height: s(12)),
        Row(
          children: [
            _brandChip("Netflix", Colors.redAccent),
            SizedBox(width: s(10)),
            _brandChip("SportyBet", Colors.green),
            SizedBox(width: s(10)),
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
      height: s(200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(s(18)),
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
      padding: EdgeInsets.all(s(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset("assets/images/png/chip.jpeg", height: s(28)),
              Text(
                "GlobalPay",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: s(16)),
              ),
            ],
          ),
          const Spacer(),
          Text(cardNumber,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: s(20),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
          SizedBox(height: s(8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("GOLD EMMANUEL",
                  style: TextStyle(color: Colors.white70, fontSize: s(12))),
              Text("12/27",
                  style: TextStyle(color: Colors.white70, fontSize: s(12))),
            ],
          )
        ],
      ),
    );
  }

  Widget _featureTile(
      IconData icon, String title, String subtitle, Color accent) {
    return Container(
      padding: EdgeInsets.all(s(12)),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF101010)
            : Colors.white,
        borderRadius: BorderRadius.circular(s(12)),
        border: Border.all(color: Colors.grey.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: s(46),
            height: s(46),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    accent.withOpacity(0.25),
                    accent.withOpacity(0.08)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(s(10)),
              boxShadow: [
                BoxShadow(
                    color: accent.withOpacity(0.06),
                    blurRadius: 10,
                    offset: Offset(0, 4))
              ],
            ),
            child: Icon(icon, color: accent, size: s(22)),
          ),
          SizedBox(width: s(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: s(14))),
                SizedBox(height: s(4)),
                Text(subtitle,
                    style: TextStyle(fontSize: s(12), color: Colors.grey.shade700)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _brandChip(String name, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s(12), vertical: s(8)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(s(10)),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(name,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: s(12))),
    );
  }

  Widget _toggleButton(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: s(20), vertical: s(8)),
        decoration: BoxDecoration(
          color: selected ? Colors.deepOrange : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(s(20)),
          boxShadow: selected
              ? [
            BoxShadow(
                color: Colors.deepOrange.withOpacity(0.16),
                blurRadius: 10,
                offset: Offset(0, 6))
          ]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: s(14)),
        ),
      ),
    );
  }
}
