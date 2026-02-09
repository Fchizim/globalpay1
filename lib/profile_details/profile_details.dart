import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:globalpay/me/profile_upgrade.dart';
import 'package:globalpay/profile_details/email_binding.dart';
import 'package:globalpay/profile_details/invite.dart';
import 'package:globalpay/profile_details/kyc_level.dart';

import '../models/user_model.dart';
import '../services/profile_service.dart';
import '../services/secure_storage_service.dart';

class ProfileDetails extends StatefulWidget {
  const ProfileDetails({super.key});

  @override
  State<ProfileDetails> createState() => _ProfileDetailsState();
}

class _ProfileDetailsState extends State<ProfileDetails> {
  UserModel? _user;
  bool _loadingUser = true;

  String get firstName => _user?.name ?? 'User';
  String get email => _user?.email ?? 'Add Email';
  String get accountNumber => _user?.accountNumber ?? '--';
  String get gender => _user?.gender ?? '--';
  String get address => _user?.address ?? '--';
  String get dob => _user?.dob ?? '--';
  String get kycLevel => _user?.kycLevel ?? 'none';
  String get userName => _user?.name ?? '';
  String get gTag => _user?.username ?? '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final localUser = await SecureStorageService.getUser();
    if (!mounted) return;

    setState(() {
      _user = localUser;
      _loadingUser = false;
    });

    // Fetch fresh profile from backend
    if (localUser != null) {
      final freshUser = await ProfileService.getProfile(localUser.userId);
      if (freshUser != null && mounted) {
        setState(() {
          _user = freshUser;
        });
      }
    }
  }

  void _editAddress() => _editPopup("Edit Address", address, (v) async {
    final updated = await ProfileService.updateUser(
      userId: _user!.userId,
      body: {"address": v},
    );

    if (updated != null) {
      setState(() => _user = updated);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Address updated")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update address")));
    }
  });

  void _editName() => _editPopup("Edit Full Name", userName, (v) async {
    final updated = await ProfileService.updateUser(
      userId: _user!.userId,
      body: {"name": v},
    );

    if (updated != null) {
      setState(() => _user = updated);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Name updated")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update name")));
    }
  });

  void _editGender() {
    String tempGender = gender; // current gender

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Select Gender"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ["Male", "Female", "Other"].map((g) {
            return RadioListTile<String>(
              title: Text(g),
              value: g,
              groupValue: tempGender,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    tempGender = val;
                  });
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final updated = await ProfileService.updateUser(
                userId: _user!.userId,
                body: {"gender": tempGender},
              );

              if (updated != null) {
                setState(() => _user = updated);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Gender updated")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to update gender")),
                );
              }

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _editTag() => _editPopup("Edit Global Tag", gTag, (v) async {
    final clean = v.toLowerCase().replaceAll(" ", "");

    final updated = await ProfileService.updateUser(
      userId: _user!.userId,
      body: {"username": clean},
    );

    if (updated != null) {
      setState(() => _user = updated);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Username updated")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Username already exists")));
    }
  }, prefix: "@");

  void _pickDob() {
    DateTime temp = DateTime.tryParse(dob) ?? DateTime(2000);

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

                final updatedUser = await ProfileService.updateUser(
                  userId: _user!.userId,
                  body: {"dob": formatted},
                );

                if (updatedUser != null) {
                  setState(() => _user = updatedUser);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Date of Birth updated")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to update DOB")),
                  );
                }

                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
    );
  }

  void _editPopup(
      String title, String initial, Function(String) onSave,
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
            // Profile Header
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
                        child: Text(kycLevel,
                            style: const TextStyle(color: Colors.white)),
                      )
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            _profileInfoCard(cardColor, [
              _row("Account Number", accountNumber),
              _row("Email", email,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EmailBinding()))),
              _row("Full Name", userName, onTap: _editName),
              _row("Global Tag", "@$gTag", onTap: _editTag),
              _row("Gender", gender, onTap: _editGender),
              _row("DOB", dob, onTap: _pickDob),
              _row("Address", address,onTap: _editAddress),
            ]),

            const SizedBox(height: 15),

            _profileInfoCard(cardColor, [
              _row("KYC Level", kycLevel,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const KycLevelsPage()))),
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
