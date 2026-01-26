import 'package:flutter/material.dart';

class EmailBinding extends StatefulWidget {
  const EmailBinding({super.key});

  @override
  State<EmailBinding> createState() => _EmailBindingState();
}

class _EmailBindingState extends State<EmailBinding> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        title: Text('Bind Email'),
        centerTitle: true,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 70,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.deepOrange.shade50
            ),
          )


        ],
      ),
    );
  }
}
