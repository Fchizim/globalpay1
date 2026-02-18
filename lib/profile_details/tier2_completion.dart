import 'package:flutter/material.dart';
import 'package:globalpay/profile_details/profile_upgrade.dart';

class Tier2Completion extends StatefulWidget {
  final String nin;
  const Tier2Completion({super.key, required this.nin, required String submittedTime});

  @override
  State<Tier2Completion> createState() => _Tier2CompletionState();
}

class _Tier2CompletionState extends State<Tier2Completion> {
  late DateTime _submittedTime;
  late String formattedTime;

  @override
  void initState() {
    super.initState();
    _submittedTime = DateTime.now();
    formattedTime = _formatDateTime(_submittedTime);
  }

  String _formatDateTime(DateTime dateTime) {
    int day = dateTime.day;
    int month = dateTime.month;
    int hour = dateTime.hour;
    int minute = dateTime.minute;
    String period = hour >= 12 ? "PM" : "AM";
    hour = hour % 12;
    if (hour == 0) hour = 12;
    String formattedMinute = minute < 10 ? "0$minute" : minute.toString();
    String formattedHour = hour < 10 ? "0$hour" : hour.toString();
    return "$day-$month $formattedHour:$formattedMinute $period";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Success Icon
              Container(
                height: 110,
                width: 110,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFF27AE60),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              const Text(
                "Application for Tier 2 upgrade submitted. Here's\n the progress of your review.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 30),

              // Timeline Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEEF3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle,
                            color: Color(0xFF27AE60), size: 24),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Submitted Successfully",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(formattedTime,
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.access_time,
                            color: Colors.deepOrange, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Under Review",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text(
                                "Access would be gained to tier 2 after Review",
                                style: TextStyle(
                                    color: Colors.grey[600], height: 1.4),
                              ),
                              const SizedBox(height: 6),
                              Text(formattedTime,
                                  style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Icon(Icons.circle, color: Colors.grey, size: 14),
                        const SizedBox(width: 12),
                        Text("Upgrade Successfully",
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Confirm Button
              Container(
                height: 55,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context,
                      MaterialPageRoute(
                        builder: (_) => KycLevelsPage(),
                      ),
                    ) ; // send 'true' back
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "OK",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
