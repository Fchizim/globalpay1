import 'package:flutter/material.dart';

class Tier3Confirmation extends StatefulWidget {
  const Tier3Confirmation({super.key});

  @override
  State<Tier3Confirmation> createState() => _Tier3ConfirmationState();
}

class _Tier3ConfirmationState extends State<Tier3Confirmation> {

  late DateTime _submittedTime;
  late String formattedTime;

  @override
  void initState() {
    super.initState();

    // Capture time when user enters page
    _submittedTime = DateTime.now();
    formattedTime = _formatDateTime(_submittedTime);
  }

  // Format: 2-12 01:05 PM
  String _formatDateTime(DateTime dateTime) {
    int day = dateTime.day;
    int month = dateTime.month;

    int hour = dateTime.hour;
    int minute = dateTime.minute;

    String period = hour >= 12 ? "PM" : "AM";

    hour = hour % 12;
    if (hour == 0) hour = 12;

    String formattedMinute =
    minute < 10 ? "0$minute" : minute.toString();
    String formattedHour =
    hour < 10 ? "0$hour" : hour.toString();

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

              // Top Success Icon
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
                "Application for Tier 3 upgrade submitted. Here's\n the progress of your review.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
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
                    // Submitted Successfully
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF27AE60),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Submitted Successfully",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedTime, // ✅ Dynamic time
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        )
                      ],
                    ),

                    const SizedBox(height: 25),

                    // Under Review
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.deepOrange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Under Review",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "A GlobalPay representative will visit your Tier 3 address within 7–14 days. We'll inform you once they're assigned. Your presence isn't mandatory, but if you live in a gated community or have extra security, please ensure someone can grant access to them.",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formattedTime, // ✅ Same dynamic time
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 25),

                    // Upgrade Successfully (Pending)
                     Row(
                      children: [
                        Icon(
                          Icons.circle,
                          color: Colors.grey,
                          size: 14,
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Upgrade Successfully",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
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
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Confirm",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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
