import 'package:flutter/material.dart';
import '../apps/apps.dart';

class MyHomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const MyHomePage({super.key, required this.onToggleTheme});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // ⬇️ just return a Scaffold or your main dashboard
    return MyAppsPage(onToggleTheme: () {  },);
  }
}
