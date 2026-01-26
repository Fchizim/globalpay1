import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("About App"),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 30),

          // App logo
          Center(
            child: CircleAvatar(
              radius: 45,
              backgroundColor: Colors.deepOrange.withOpacity(0.1),
              child: const Icon(IconsaxPlusBold.mobile,
                  size: 40, color: Colors.deepOrange),
            ),
          ),

          const SizedBox(height: 15),

          // App name + version
          const Center(
            child: Text(
              "MyFinance App",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              "Version 1.0.3",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),

          const SizedBox(height: 25),

          // Description
          Text(
            "MyFinance is a secure and reliable digital wallet "
                "that helps you send, receive, and manage money easily. "
                "We prioritize your safety and provide tools to keep your finances in control.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 40),

          // Links
          ListTile(
            leading: const Icon(IconsaxPlusLinear.document, color: Colors.deepOrange),
            title: const Text("Terms of Service"),
            trailing: const Icon(IconsaxPlusLinear.arrow_right_3, size: 20),
            onTap: () {
              // TODO: navigate to Terms page
            },
          ),
          Divider(color: Colors.grey.shade300, height: 0),

          ListTile(
            leading: const Icon(IconsaxPlusLinear.shield, color: Colors.deepOrange),
            title: const Text("Privacy Policy"),
            trailing: const Icon(IconsaxPlusLinear.arrow_right_3, size: 20),
            onTap: () {
              // TODO: navigate to Privacy page
            },
          ),
          Divider(color: Colors.grey.shade300, height: 0),

          ListTile(
            leading: const Icon(IconsaxPlusLinear.sms, color: Colors.deepOrange),
            title: const Text("Contact Support"),
            trailing: const Icon(IconsaxPlusLinear.arrow_right_3, size: 20),
            onTap: () {
              // TODO: navigate to Support/Email
            },
          ),

          const SizedBox(height: 40),

          // Footer
          Center(
            child: Text(
              "© 2025 MyFinance Inc. All rights reserved.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
