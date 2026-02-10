import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:globalpay/me/profile_upgrade.dart';
import 'package:globalpay/profile_details/email.dart';
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

    if (localUser != null) {
      final freshUser = await ProfileService.getProfile(localUser.userId);
      if (freshUser != null && mounted) {
        setState(() => _user = freshUser);
      }
    }
  }

  /// ================= AVATAR SHEET ===================

  void _showAvatarSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),

            ListTile(
              leading: const Icon(IconsaxPlusBold.camera),
              title: const Text("Take Photo"),
              onTap: () => Navigator.pop(context),
            ),

            ListTile(
              leading: const Icon(IconsaxPlusBold.gallery),
              title: const Text("Upload from Gallery"),
              onTap: () => Navigator.pop(context),
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.close, color: Colors.red),
              title: const Text("Cancel",
                  style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// ===============================================

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _showAvatarSheet,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor:
                          theme.colorScheme.primary.withOpacity(.1),
                          backgroundImage:
                          _user?.image != null && _user!.image.isNotEmpty
                              ? NetworkImage(_user!.image)
                              : const AssetImage(
                              'assets/images/png/gold.jpg')
                          as ImageProvider,
                        ),

                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle),
                            child: const Icon(IconsaxPlusBold.camera,
                                size: 16, color: Colors.white),
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(width: 18),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text("Hi, $firstName",
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600)),
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
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const EmailBinding()))),
              _row("Full Name", userName),
              _row("Global Tag", "@$gTag"),
              _row("Gender", gender),
              _row("DOB", dob),
              _row("Address", address),
            ]),

            const SizedBox(height: 15),

            _profileInfoCard(cardColor, [
              _row("KYC Level", kycLevel,
                  onTap: () => Navigator.push(context,
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
