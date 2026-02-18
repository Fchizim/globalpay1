import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:globalpay/profile_details/tier%202.dart';
import 'package:globalpay/profile_details/tier2_completion.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:globalpay/services/profile_service.dart';
import 'package:http/http.dart' as http;

import '../home/electricity.dart';
import '../models/user_model.dart';
import '../provider/kyc_provider.dart';
import '../provider/user_provider.dart';
import 'package:provider/provider.dart' as prov;

class KycLevelsPage extends StatefulWidget {
  const KycLevelsPage({super.key});
  @override
  State<KycLevelsPage> createState() => _KycLevelsPageState();
}

class _KycLevelsPageState extends State<KycLevelsPage> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  String nin = "";
  bool showDetails = false;
  String submittedTime = "";
  bool isLoading = true;
  UserModel? providerUser;

  String userId = "";

  @override
  void initState() {
    super.initState();
    _loadFromStorage();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider =
      prov.Provider.of<UserProvider>(context, listen: false);
      final kycProvider =
      prov.Provider.of<KycProvider>(context, listen: false);

      if (userProvider.user != null) {
        await ProfileService.loadKyc(
          userId: userProvider.user!.userId,
          provider: kycProvider,
        );
      }
    });
  }

  Future<void> _loadFromStorage() async {
    final uid = await secureStorage.read(key: "userId") ?? "";
    final ninStr = await secureStorage.read(key: "userNIN") ?? "";
    final submitted = await secureStorage.read(key: "tier2SubmittedTime") ?? "";

    setState(() {
      userId = uid;
      nin = ninStr;
      submittedTime = submitted;
      isLoading = false;
    });
  }

  String get maskedNin {
    if (nin.length != 11) return "";
    return "**** *** ${nin.substring(7)}";
  }

  Widget detailRow(String t, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(t, style: const TextStyle(color: Colors.white70)),
        Text(v,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600))
      ],
    ),
  );

  void _goToReviewPage() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                Tier2Completion(nin: nin, submittedTime: submittedTime)));
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = prov.Provider.of<UserProvider>(context);
    final kycProvider = prov.Provider.of<KycProvider>(context);

    providerUser = userProvider.user;

    // Dynamic values from provider
    final currentTier = kycProvider.kyc?.tier ?? "1";
    final kycStatus = kycProvider.kyc?.status ?? "none";
    final isPending = kycStatus == "pending";
    final isApproved = kycStatus == "approved";
    final isRejected = kycStatus == "rejected";

    final isUnderReview = isPending;
    final showTier3BlockedMsg = isUnderReview && currentTier != "3";

    final isTier1 = currentTier == "1";
    final isTier2 = currentTier == "2";
    final isTier3 = currentTier == "3";

    final isTier2Pending = isTier2 && kycStatus == "pending";
    final isTier2Approved = isTier2 && kycStatus == "approved";
    final isTier3Verified = isTier3 && kycStatus == "approved";

    final bg = Colors.grey.shade100;
    final card = Colors.deepOrange;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          centerTitle: true,
          title: const Text("KYC Levels")),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 35),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (showTier3BlockedMsg)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Icon(Icons.info, color: Colors.red),
                SizedBox(width: 8),
                Expanded(
                    child: Text(
                        "Tier 3 can’t be updated until Tier 2 is approved",
                        style: TextStyle(color: Colors.red)))
              ]),
            ),
          SizedBox(
            height: 55,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isTier2Pending || isTier3Verified
                    ? Colors.grey // disabled style
                    : Colors.deepOrange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: (isTier2Pending || isTier3Verified)
                  ? null // disables button
                  : () {
                if (isTier1 || isTier2Approved) {
                  // Navigate to Tier 2 or Tier 3 page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          Tiertwo(), // replace with Tier3 page if Tier3
                    ),
                  );
                }
              },
              child: Text(
                isTier1
                    ? "Verify Tier 2"
                    : isTier2Pending
                    ? "Tier 2 in Review"
                    : isTier2Approved
                    ? "Verify Tier 3"
                    : isTier3Verified
                    ? "Tier 3 Verified"
                    : "Verify",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          if (isUnderReview)
            GestureDetector(
              onTap: _goToReviewPage,
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12)),
                child: const Row(children: [
                  Icon(Icons.access_time, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(child: Text("Tier 2 verification is under review"))
                ]),
              ),
            ),
          Stack(clipBehavior: Clip.none, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: card,
                borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(80),
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(70),
                    bottomRight: Radius.circular(15)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(currentTier == "1" ? "Beginner" : "Elite",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.deepPurple.shade200,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(currentTier == "1" ? "Current" : "Verified",
                        style: TextStyle(color: Colors.deepOrange.shade900)),
                  )
                ]),
                const SizedBox(height: 25),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("Daily Limit", style: TextStyle(color: Colors.white70)),
                    Text(currentTier == "1" ? "₦50,000" : "₦200,000",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600))
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("Balance Limit", style: TextStyle(color: Colors.white70)),
                    Text(currentTier == "1" ? "₦300,000" : "₦500,000",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600))
                  ])
                ]),
                const SizedBox(height: 20),
                Divider(color: Colors.white24),
                Row(children: [
                  const Text("KYC Details", style: TextStyle(color: Colors.white)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(showDetails ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white),
                    onPressed: () => setState(() => showDetails = !showDetails),
                  )
                ]),
                if (showDetails && providerUser != null)
                  Column(children: [
                    detailRow("Full Name", providerUser!.name),
                    detailRow("Gender", providerUser!.gender),
                    detailRow("Date of Birth", providerUser!.dob),
                    detailRow("Mobile Number", providerUser!.phone),
                    // if (currentTier != "1") detailRow("NIN", maskedNin),
                  ])
              ]),
            ),
            Positioned(
              top: -18,
              right: -10,
              child: SizedBox(
                height: 90,
                width: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset('assets/images/png/medal.png',
                        height: 90, fit: BoxFit.contain),
                    Padding(
                      padding: const EdgeInsets.only(top: 21),
                      child: Text(
                        currentTier,
                        style: const TextStyle(
                          fontSize: 45,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ]),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.deepOrange.shade50,
                borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Level Benefits",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                    color: Colors.deepOrange.shade200,
                    borderRadius: BorderRadius.circular(14)),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [Text("Tier"), Text("Daily Limit"), Text("Balance")]),
              ),
              const SizedBox(height: 15),
              _tierRow("Tier 1", "₦50,000", "₦300,000", currentTier == "1"),
              _tierRow("Tier 2", "₦200,000", "₦500,000", currentTier == "2"),
              _tierRow("Tier 3", "₦5,000,000", "Unlimited", currentTier == "3")
            ]),
          ),
          ElevatedButton(
            onPressed: () async {
              await secureStorage.write(key: "userTier", value: "1");
              await secureStorage.delete(key: "userNIN");
              await secureStorage.delete(key: "tier2UnderReview");
              await secureStorage.delete(key: "tier2SubmittedTime");

              // Optionally reset provider KYC if needed
              final kycProvider = prov.Provider.of<KycProvider>(context, listen: false);
              kycProvider.setKyc(null);

              setState(() {
                nin = "";
              });
            },
            child: const Text("Reset to Tier 1"),
          ),
        ]),
      ),
    );
  }

  Widget _tierRow(String t, String d, String b, bool current) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Text(t),
          if (current) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(6)),
              child: const Text("Current", style: TextStyle(fontSize: 10)),
            )
          ]
        ]),
        Text(d),
        Text(b)
      ]),
    );
  }
}