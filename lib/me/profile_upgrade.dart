import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:math' as math;

class KycLevelsPage extends StatefulWidget {
  const KycLevelsPage({super.key});

  @override
  State<KycLevelsPage> createState() => _KycLevelsPageState();
}

class _KycLevelsPageState extends State<KycLevelsPage> {
  int currentTier = 1;
  bool verified = false;
  String? verifiedCode;

  final nin = TextEditingController();
  final bvn = TextEditingController();
  final address = TextEditingController();

  final tiers = {
    1: {"title": "Basic", "limit": "₦50k Daily"},
    2: {"title": "Standard", "limit": "₦200k Daily"},
    3: {"title": "Premium", "limit": "Unlimited"},
  };

  void verify() {
    if (currentTier == 1 && nin.text.isEmpty) return;
    if (currentTier == 2 && (nin.text.isEmpty || bvn.text.isEmpty)) return;
    if (currentTier == 3 && address.text.isEmpty) return;

    setState(() {
      verified = true;
      verifiedCode =
          List.generate(4, (_) => math.Random().nextInt(9)).join();
    });
  }

  void upgrade() {
    if (currentTier < 3) {
      setState(() {
        currentTier++;
        verified = false;
        nin.clear();
        bvn.clear();
        address.clear();
      });
    }
  }

  void uploadSheet(String title) {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (_) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title,
                style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
                leading: const Icon(LucideIcons.image),
                title: const Text("Choose from Gallery")),
            ListTile(
                leading: const Icon(LucideIcons.camera),
                title: const Text("Take Photo")),
          ]),
        ));
  }

  Widget field(String label, IconData icon, TextEditingController c, bool dark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          filled: true,
          fillColor: dark ? Colors.white10 : Colors.white,
          border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF121212) : Colors.grey.shade100;
    final card = dark ? const Color(0xFF1C1C1E) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        centerTitle: true,
        title: const Text("Identity Verification",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          /// TIER BAR
          Row(
            children: List.generate(
                3,
                    (i) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    decoration: BoxDecoration(
                        color: i + 1 <= currentTier
                            ? Colors.orange
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(4)),
                  ),
                )),
          ),

          const SizedBox(height: 24),

          /// MAIN CARD
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 20)
                ]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.orange.withOpacity(.15),
                      child: const Icon(LucideIcons.shieldCheck,
                          color: Colors.orange)),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Tier $currentTier — ${tiers[currentTier]!["title"]}",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(tiers[currentTier]!["limit"]!,
                        style: const TextStyle(color: Colors.grey)),
                  ])
                ],
              ),

              const SizedBox(height: 24),

              if (!verified) ...[
                if (currentTier >= 1)
                  field("NIN Number", LucideIcons.idCard, nin, dark),
                if (currentTier >= 2)
                  field("BVN Number", LucideIcons.lock, bvn, dark),
                if (currentTier == 3) ...[
                  field("Residential Address", LucideIcons.bomb, address, dark),
                  GestureDetector(
                    onTap: () => uploadSheet("Upload Proof of Address"),
                    child: uploadTile("Upload Proof of Address"),
                  ),
                  GestureDetector(
                    onTap: () => uploadSheet("Face Verification"),
                    child: uploadTile("Face Capture"),
                  ),
                ],

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: verify,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                      child: const Text("Submit Verification",
                          style: TextStyle(color: Colors.white))),
                )
              ] else
                Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: Colors.green.withOpacity(.1),
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      const Icon(LucideIcons.check, color: Colors.green),
                      const SizedBox(width: 8),
                      Text("Verified • $verifiedCode",
                          style: const TextStyle(fontWeight: FontWeight.bold))
                    ])),
            ]),
          ),

          const SizedBox(height: 24),

          if (verified && currentTier < 3)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: upgrade,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18))),
                child: const Text("Continue to Next Tier",
                    style: TextStyle(color: Colors.white)),
              ),
            )
        ]),
      ),
    );
  }

  Widget uploadTile(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange)),
      child: Row(children: [
        const Icon(LucideIcons.upload, color: Colors.orange),
        const SizedBox(width: 10),
        Text(title)
      ]),
    );
  }
}
