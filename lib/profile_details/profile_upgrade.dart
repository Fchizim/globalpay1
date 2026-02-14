import 'package:flutter/material.dart';
import 'package:globalpay/profile_details/tier%202.dart';
import 'package:globalpay/profile_details/tier2_completion.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KycLevelsPage extends StatefulWidget {
  const KycLevelsPage({super.key});
  @override
  State<KycLevelsPage> createState() => _KycLevelsPageState();
}

class _KycLevelsPageState extends State<KycLevelsPage> {
  int currentTier = 1;
  String nin = "";
  bool showDetails = false;
  bool isUnderReview = false;
  String submittedTime = "";
  bool isLoading = true;
  bool showTier3BlockedMsg = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentTier = prefs.getInt('userTier') ?? 1;
      nin = prefs.getString('userNIN') ?? "";
      isUnderReview = prefs.getBool('tier2UnderReview') ?? false;
      submittedTime = prefs.getString('tier2SubmittedTime') ?? "";
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
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              onPressed: () async {
                if (isUnderReview) {
                  setState(() => showTier3BlockedMsg = true);
                  Future.delayed(const Duration(seconds: 3),
                          () => setState(() => showTier3BlockedMsg = false));
                } else {
                  final r = await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const Tiertwo()));
                  if (r == true) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('tier2UnderReview', true);
                    await prefs.setString('tier2SubmittedTime',
                        DateTime.now().toIso8601String());
                    setState(() {
                      isUnderReview = true;
                      submittedTime = DateTime.now().toIso8601String();
                    });
                  }
                }
              },
              child: Text(isUnderReview ? "Verify Tier 3" : "Verify Tier 2",
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
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
                borderRadius: BorderRadius.only(topRight: Radius.circular(80), topLeft: Radius.circular(15), bottomLeft: Radius.circular(70), bottomRight: Radius.circular(15)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                Row(children: [
                  Text(currentTier == 1 ? "Beginner" : "Elite",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.deepPurple.shade200,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(currentTier == 1 ? "Current" : "Verified",
                        style: TextStyle(color: Colors.deepOrange.shade900)),
                  )
                ]),

                const SizedBox(height: 25),

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("Daily Limit",
                        style: TextStyle(color: Colors.white70)),
                    Text(currentTier == 1 ? "₦50,000" : "₦200,000",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600))
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("Balance Limit",
                        style: TextStyle(color: Colors.white70)),
                    Text(currentTier == 1 ? "₦300,000" : "₦500,000",
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
                    icon: Icon(
                        showDetails
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.white),
                    onPressed: () => setState(() => showDetails = !showDetails),
                  )
                ]),

                if (showDetails)
                  Column(children: [
                    detailRow("Full Name", "Gold"),
                    detailRow("Gender", "Male"),
                    detailRow("Date of Birth", "Apr,1,11"),
                    detailRow("Mobile Number", "08161739306"),
                    if (currentTier >= 2) detailRow("NIN", maskedNin)
                  ])
              ]),
            ),

            // MEDAL WITH NUMBER CENTERED
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
                        currentTier.toString(),
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
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
              const SizedBox(height: 12),

              Container(
                padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                    color: Colors.deepOrange.shade200,
                    borderRadius: BorderRadius.circular(14)),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Tier"),
                      Text("Daily Limit"),
                      Text("Balance")
                    ]),
              ),

              const SizedBox(height: 15),

              _tierRow("Tier 1", "₦50,000", "₦300,000", true),
              _tierRow("Tier 2", "₦200,000", "₦500,000", false),
              _tierRow("Tier 3", "₦5,000,000", "Unlimited", false)
            ]),
          ),

          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('userTier', 1);
              await prefs.remove('userNIN');
              await prefs.remove('tier2UnderReview');
              await prefs.remove('tier2SubmittedTime');
              setState(() {
                currentTier = 1;
                nin = "";
                isUnderReview = false;
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
              padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
