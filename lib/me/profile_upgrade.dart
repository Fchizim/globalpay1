import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class KycLevelsPage extends StatelessWidget {
  const KycLevelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final levels = [
      {
        "level": "Level 1",
        "status": "Verified",
        "limit": "\$500 / day",
        "color": Colors.green,
        "icon": LucideIcons.badgeCheck,
        "benefits": [
          "Send & receive money",
          "Buy airtime and pay bills",
          "Basic account security",
        ],
      },
      {
        "level": "Level 2",
        "status": "Pending Upgrade",
        "limit": "\$5,000 / day",
        "color": Colors.orange,
        "icon": LucideIcons.shieldHalf,
        "benefits": [
          "Access business payments",
          "Create GlobalPay wallet ID",
          "Withdraw to bank accounts",
        ],
      },
      {
        "level": "Level 3",
        "status": "Locked",
        "limit": "Unlimited",
        "color": Colors.purple,
        "icon": LucideIcons.shieldCheck,
        "benefits": [
          "Unlimited transfers",
          "International payments",
          "Priority support & API access",
        ],
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0.5,
        title: const Text("KYC Verification"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: levels.length,
          itemBuilder: (context, index) {
            final item = levels[index];
            final color = item["color"] as Color;
            final icon = item["icon"] as IconData;
            final benefits = item["benefits"] as List<String>;

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: color.withOpacity(0.15),
                        radius: 22,
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item["level"].toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            item["status"].toString(),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item["limit"].toString(),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Progress Indicator
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (index + 1) / levels.length,
                      color: color,
                      backgroundColor: Colors.grey[300],
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Benefits
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: benefits.map((b) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.check,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                b,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Upgrade Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        if (item["level"] == "Level 2") {
                          _showUpgradeSheet(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "${item["level"]} button clicked",
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(
                        item["status"] == "Verified"
                            ? "Current Level"
                            : item["status"] == "Locked"
                            ? "Unlock Level"
                            : "Upgrade Now",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showUpgradeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final steps = [
          {
            "title": "Upload valid ID",
            "desc": "Driver’s license, Passport, or National ID",
            "icon": LucideIcons.idCard,
          },
          {
            "title": "Take a selfie",
            "desc": "Ensure your face is clearly visible",
            "icon": LucideIcons.camera,
          },
          {
            "title": "Proof of address",
            "desc": "Upload utility bill or bank statement",
            "icon": LucideIcons.house,
          },
        ];

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Upgrade to Level 2",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                "Complete these quick steps to unlock higher limits.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ...steps.map((step) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.orange.withOpacity(0.15),
                        child: Icon(
                          step["icon"] as IconData,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step["title"].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              step["desc"].toString(),
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        LucideIcons.chevronRight,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("KYC upgrade started"),
                      ),
                    );
                  },
                  child: const Text(
                    "Start Verification",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
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
}
