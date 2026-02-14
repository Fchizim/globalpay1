import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../provider/user_provider.dart';
import 'profile_upgrade.dart';
import 'email.dart';
import '../services/profile_service.dart';

class ProfileDetails extends StatefulWidget {
  const ProfileDetails({super.key, required Null Function() onToggleTheme});

  @override
  State<ProfileDetails> createState() => _ProfileDetailsState();
}

class _ProfileDetailsState extends State<ProfileDetails> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final firstName = user.name;
    final email = user.email ?? 'Add Email';
    final accountNumber = user.accountNumber ?? '--';
    final gender = user.gender ?? '--';
    final phone = user.phone ?? '--';
    final address = user.address ?? '--';
    final dob = user.dob ?? '--';
    final kycLevel = user.kycLevel ?? 'none';
    final userName = user.name;
    final gTag = user.username ?? '';

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
                    backgroundImage: (user.image != null && user.image.isNotEmpty)
                        ? NetworkImage(user.image)
                        : const AssetImage('assets/images/png/gold.jpg') as ImageProvider,
                  ),
                  const SizedBox(width: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Hi, $firstName",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(IconsaxPlusBold.verify,
                              color: theme.colorScheme.primary),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12)),
                        child: Text(kycLevel,
                            style: const TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            _profileInfoCard(cardColor, [
              _row("Account Number", accountNumber),
              _row("Email", email, onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmailBinding()),
                );
              }),
              _row("Full Name", userName, onTap: () => _editName(user)),
              _row("Phone", phone, onTap: () => _editPhone(user)),
              _row("Global Tag", "@$gTag", onTap: () => _editTag(user)),
              _row("Gender", gender,),
              _row("DOB", dob, onTap: () => _pickDob(user)),
              _row("Address", address, onTap: () => _editAddress(user)),
            ]),

            const SizedBox(height: 15),

            _profileInfoCard(cardColor, [
              _row("KYC Level", kycLevel, onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KycLevelsPage()),
                );
              }),
            ]),
          ],
        ),
      ),
    );
  }

  // EDIT FUNCTIONS
  void _editName(UserModel user) {
    final controller = TextEditingController(text: user.name);
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Edit Full Name",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter full name",
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final value = controller.text.trim();
                        if (value.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Name cannot be empty")),
                          );
                          return;
                        }

                        Navigator.pop(context);

                        final updated = await ProfileService.updateUser(
                          userId: user.userId,
                          body: {"name": value},
                        );

                        if (updated != null) {
                          context.read<UserProvider>().setUser(updated);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Name updated successfully")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Failed to update name")),
                          );
                        }
                      },
                      child: const Text("Save"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editAddress(UserModel user) {
    final controller = TextEditingController(text: user.address ?? '');
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Edit Address",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter your address",
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final value = controller.text.trim();
                        if (value.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Address cannot be empty")),
                          );
                          return;
                        }

                        Navigator.pop(context);

                        final updated = await ProfileService.updateUser(
                          userId: user.userId,
                          body: {"address": value},
                        );

                        if (updated != null) {
                          context.read<UserProvider>().setUser(updated);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Address updated successfully")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Failed to update address")),
                          );
                        }
                      },
                      child: const Text("Save"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editTag(UserModel user) {
    final controller = TextEditingController(text: user.username ?? '');
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Edit Global Tag",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter new tag",
                    prefixText: "@",
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        String value = controller.text.trim();
                        if (value.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Global tag cannot be empty")),
                          );
                          return;
                        }

                        // Clean the tag
                        value = value.toLowerCase().replaceAll(" ", "");

                        Navigator.pop(context);

                        // ✅ Update via ProfileService
                        final updated = await ProfileService.updateUser(
                          userId: user.userId,
                          body: {"username": value},
                        );

                        if (updated != null) {
                          context.read<UserProvider>().setUser(updated);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Global tag updated successfully")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Failed to update global tag")),
                          );
                        }
                      },
                      child: const Text("Save"),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editGender(UserModel user) {
    String tempGender = user.gender ?? '--';

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
                tempGender = val!;
                setState(() {});
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
                userId: user.userId,
                body: {"gender": tempGender},
              );
              if (updated != null) context.read<UserProvider>().setUser(updated);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _pickDob(UserModel user) {
    DateTime temp = DateTime.tryParse(user.dob ?? '') ?? DateTime(2000);

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
                  userId: user.userId,
                  body: {"dob": formatted},
                );
                if (updatedUser != null) context.read<UserProvider>().setUser(updatedUser);
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
    );
  }
  void _editPhone(UserModel user) {
    final controller = TextEditingController(text: user.phone ?? '');
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Edit Phone Number",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter phone number",
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final value = controller.text.trim();

                        // ✅ Validate phone
                        if (value.isEmpty || !RegExp(r'^\d{10,15}$').hasMatch(value)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Enter a valid phone number")),
                          );
                          return;
                        }

                        Navigator.pop(context);

                        // ✅ Update via ProfileService
                        final updated = await ProfileService.updateUser(
                          userId: user.userId,
                          body: {"phone": value},
                        );

                        if (updated != null) {
                          context.read<UserProvider>().setUser(updated);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Phone updated successfully")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Failed to update phone")),
                          );
                        }
                      },
                      child: const Text("Save"),
                    )
                  ],
                )
              ],
            ),
          ),
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
                      Navigator.pop(context);
                      if (value.isNotEmpty) onSave(value);
                    },
                    child: const Text("Save"))
              ])
            ]),
          ),
        ),
      ),
    );
  }

  // UI Helpers
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
        ],
      ),
    ),
  );
}