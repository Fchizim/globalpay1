import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:globalpay/me/profile_upgrade.dart';
import 'package:globalpay/profile_details/email_binding.dart';
import 'package:globalpay/profile_details/invite.dart';
import 'package:globalpay/profile_details/kyc_level.dart';

import '../models/user_model.dart';
import '../services/secure_storage_service.dart';

/// Helper class for storing user name and other info
class LocalUser {
  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  static Future<void> setName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name);
  }

  static Future<String?> getTag() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('gtag');
  }

  static Future<void> setTag(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gtag', tag);
  }

  static Future<String?> getDob() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('dob');
  }

  static Future<void> setDob(String dob) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dob', dob);
  }
}

class ProfileDetails extends StatefulWidget {
  const ProfileDetails({super.key});

  @override
  State<ProfileDetails> createState() => _ProfileDetailsState();
}

class _ProfileDetailsState extends State<ProfileDetails> {
  UserModel? _user;
  bool _loadingUser = true;

  String userName = "Gold Emmanuel";
  String gTag = "gold";
  String dob = "2005-05-17";

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadLocalInfo();
  }

  Future<void> _loadUser() async {
    final user = await SecureStorageService.getUser();
    if (!mounted) return;

    setState(() {
      _user = user;
      _loadingUser = false;
    });
  }

  Future<void> _loadLocalInfo() async {
    final name = await LocalUser.getName();
    final tag = await LocalUser.getTag();
    final d = await LocalUser.getDob();

    setState(() {
      if (name != null) userName = name;
      if (tag != null) gTag = tag;
      if (d != null) dob = d;
    });
  }

  String get firstName {
    final parts = userName.split(" ");
    final name = parts.first;
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  void _editName() => _editPopup("Edit Full Name", userName, (v) async {
    await LocalUser.setName(v);
    setState(() => userName = v);
  });

  void _editTag() => _editPopup("Edit Global Tag", gTag, (v) async {
    final clean = v.toLowerCase().replaceAll(" ", "");
    await LocalUser.setTag(clean);
    setState(() => gTag = clean);
  }, prefix: "@");

  void _pickDob() {
    DateTime temp = DateTime.parse(dob);

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: Theme.of(context).cardColor,
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: temp,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (v) => temp = v,
              ),
            ),
            CupertinoButton(
              child: const Text("Done"),
              onPressed: () async {
                final formatted = temp.toIso8601String().split("T").first;
                await LocalUser.setDob(formatted);
                setState(() => dob = formatted);
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
    );
  }

  void _editPopup(String title, String initial, Function(String) onSave,
      {String prefix = ""}) {
    final controller = TextEditingController(text: initial);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(title,
                  style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  prefixText: prefix,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isNotEmpty) onSave(value);
                    Navigator.pop(context);
                  },
                  child: const Text("Save"),
                )
              ])
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final scaffoldColor = isDark ? const Color(0xFF121212) : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: scaffoldColor,
        elevation: 0,
        centerTitle: true,
        title: const Text("My Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            // Profile Header - KEEP AVATAR & "Hi, Gold"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    backgroundImage: _user?.image != null && _user!.image.isNotEmpty
                        ? NetworkImage(_user!.image) as ImageProvider
                        : const AssetImage('assets/images/png/gold.jpg'),
                  ),
                  const SizedBox(width: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text("Hi, $firstName",
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 6),
                          Icon(IconsaxPlusBold.verify,
                              color: theme.colorScheme.primary),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Text("President",
                            style: TextStyle(color: Colors.white)),
                      )
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Profile Info - Top
            _profileInfoCard(cardColor, [
              _row("Account Number", "1234567890"),
              _row("Email", "Add Email",
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EmailBinding()))),
              _row("Full Name", userName, onTap: _editName),
              _row("Global Tag", "@$gTag", onTap: _editTag),
              _row("Gender", "Male"),
              _row("DOB", dob, onTap: _pickDob),
              _row("Address", "Enugu, Nigeria"),
            ]),

            const SizedBox(height: 15),

            // Profile Info - Bottom
            _profileInfoCard(cardColor, [
              _row("KYC Level", "President",
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const KycLevelsPage()))),
            ])
          ],
        ),
      ),
    );
  }

  Widget _profileInfoCard(Color color, List<Widget> items) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      decoration:
      BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(children: items),
    ),
  );

  Widget _row(String title, String value, {VoidCallback? onTap}) => InkWell(
    onTap: onTap,
    child: Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Row(
              children: [
                Text(value),
                if (onTap != null) const SizedBox(width: 6),
                if (onTap != null)
                  const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            )
          ]),
    ),
  );
}
