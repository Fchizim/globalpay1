import 'package:flutter/material.dart';

class TradeChatWidget extends StatelessWidget {
  const TradeChatWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final messages = [
      {"text": "Hi, I want to trade.", "isMe": true},
      {"text": "Sure, please send payment.", "isMe": false},
      {"text": "Payment sent.", "isMe": true},
      {"text": "Confirmed. Trade complete.", "isMe": false},
    ];

    return Container(
      color: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = messages[index];
          final bool isMe = msg["isMe"] as bool; // Correct cast
          final String text = msg["text"] as String;

          return Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? Colors.deepOrange : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
