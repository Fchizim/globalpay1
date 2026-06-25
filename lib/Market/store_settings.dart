import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../provider/user_provider.dart';

class StoreSettingsPage extends StatefulWidget {
  final Map<String, dynamic> business;
  const StoreSettingsPage({super.key, required this.business,});

  @override
  State<StoreSettingsPage> createState() => _StoreSettingsPageState();
}

class _StoreSettingsPageState extends State<StoreSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _typeCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _rcCtrl;
  late TextEditingController _bioCtrl;

  File? _pickedImage;
  bool _isSaving = false;


  // Accent colour palette choices
  static const List<Color> _accentOptions = [
    Colors.deepOrange,
    Color(0xFF6C63FF), // purple
    Color(0xFF00B386), // teal
    Color(0xFFE91E8C), // pink
    Color(0xFF1565C0), // deep blue
    Color(0xFFF9A825), // amber
  ];
  late Color _selectedAccent;

  @override
  void initState() {
    super.initState();
    final b = widget.business;
    _nameCtrl = TextEditingController(text: b['business_name'] ?? '');
    _typeCtrl = TextEditingController(text: b['business_type'] ?? '');
    _locationCtrl = TextEditingController(text: b['business_location'] ?? '');
    _emailCtrl = TextEditingController(text: b['business_email'] ?? '');
    _phoneCtrl = TextEditingController(text: b['business_phone'] ?? '');
    _rcCtrl = TextEditingController(text: b['rc_number'] ?? '');
    _bioCtrl = TextEditingController(text: b['business_bio'] ?? '');

    // Restore saved accent or default to deepOrange
    final savedHex = b['accent_color'] as String?;
    _selectedAccent = savedHex != null
        ? Color(int.parse(savedHex, radix: 16))
        : Colors.deepOrange;
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _typeCtrl,
      _locationCtrl,
      _emailCtrl,
      _phoneCtrl,
      _rcCtrl,
      _bioCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Image picker ────────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 600,
    );

    if (picked == null) return;

    final user = context.read<UserProvider>().user;

    if (user == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final file = File(picked.path);
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://glopa.org/glo/update_business_image.php'),
      );

      request.headers['Accept'] = '*/*';
      request.headers['User-Agent'] = 'GlobalPayApp/1.0';

      request.fields['user_id'] = user.userId;
      request.fields['business_id'] =
          widget.business['business_id']?.toString() ?? '';

      request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
          ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE: ${response.body}");
      print("USER ID: ${user.userId}");
      print("BUSINESS ID: ${widget.business['business_id']}");
      print("FILE FIELD: ${request.files.first.field}");
      print("FILE PATH: ${file.path}");

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          _pickedImage = file;
          widget.business['Business_img'] =
          data['image'];
        });

        _showSnack(
          'Logo updated successfully',
          isError: false,
        );
      } else {
        _showSnack(data['message']);
      }
    } catch (e) {
      _showSnack('Failed to upload image');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deletePhoto() async {
    final user = context.read<UserProvider>().user;

    if (user == null) return;

    try {
      final res = await http.post(
        Uri.parse(
          'https://glopa.org/glo/delete_business_image.php',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user.userId,
          'business_id': widget.business['business_id'],
        }),
      );

      final data = jsonDecode(res.body);

      if (data['status'] == 'success') {
        setState(() {
          _pickedImage = null;
          widget.business['Business_img'] = null;
        });

        _showSnack(
          'Logo deleted successfully',
          isError: false,
        );
      } else {
        _showSnack(data['message']);
      }
    } catch (e) {
      _showSnack('Failed to delete logo');
    }
  }

  // ── Image options modal ──────────────────────────────────────────────────────
  void _showImageOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Store Logo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _imageOptionTile(
                icon: Icons.delete_outline,
                label: 'Delete Photo',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _deletePhoto();
                },
              ),
              _imageOptionTile(
                icon: Icons.photo_library_outlined,
                label: 'Upload from Gallery',
                color: _selectedAccent,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.gallery);
                },
              ),
              _imageOptionTile(
                icon: Icons.camera_alt_outlined,
                label: 'Take Photo',
                color: _selectedAccent,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color == Colors.red ? Colors.red : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Save ────────────────────────────────────────────────────────────────────
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<UserProvider>().user;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final uri = Uri.parse(
        'https://glopa.org/glo/update_business.php',
      );
      final req = http.MultipartRequest('POST', uri);

      req.fields.addAll({
        'user_id': user.userId,
        'business_id': widget.business['business_id'] ?? '',
        'business_name': _nameCtrl.text.trim(),
        'business_type': _typeCtrl.text.trim(),
        'business_location': _locationCtrl.text.trim(),
        'business_email': _emailCtrl.text.trim(),
        'business_phone': _phoneCtrl.text.trim(),
        'rc_number': _rcCtrl.text.trim(),
        'business_bio': _bioCtrl.text.trim(),
        'accent_color': _selectedAccent.value.toRadixString(16),

      });


      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      final data = jsonDecode(res.body);

      if (!mounted) return;

      if (data['status'] == 'success') {
        _showSnack('Store updated successfully', isError: false);
        Navigator.pop(context, true);
      } else {
        _showSnack(data['message'] ?? 'Update failed');
      }
    } catch (e) {
      _showSnack('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Delete / Deactivate ─────────────────────────────────────────────────────
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Store?'),
        content: const Text(
          'This will permanently delete your store and all its listings. '
              'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = context.read<UserProvider>().user;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final res = await http.post(
        Uri.parse('https://glopa.org/glo/delete_business.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user.userId,
          'business_id': widget.business['business_id'] ?? '',
        }),
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;
      if (data['status'] == 'success') {
        Navigator.popUntil(context, (r) => r.isFirst);
      } else {
        _showSnack(data['message'] ?? 'Could not delete store.');
      }
    } catch (_) {
      _showSnack('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Contact support ─────────────────────────────────────────────────────────
  void _contactSupport() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Support',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Reach out to us through any of the channels below.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _supportTile(
              Icons.email_outlined,
              'Email Us',
              'support@glopa.org',
                  () {},
            ),
            const SizedBox(height: 12),
            _supportTile(
              Icons.chat_bubble_outline,
              'Live Chat',
              'Chat with an agent',
                  () {},
            ),
            const SizedBox(height: 12),
            _supportTile(
              Icons.phone_outlined,
              'Call Us',
              '+234 800 GLOPA 00',
                  () {},
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _supportTile(
      IconData icon,
      String title,
      String sub,
      VoidCallback onTap,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: _selectedAccent, size: 22),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : Colors.white;
    final cardBg = isDark ? Colors.white10 : Colors.grey.shade50;

    final hasExistingImage =
        widget.business['Business_img'] != null &&
            widget.business['Business_img'].toString().isNotEmpty;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Store Settings',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          _isSaving
              ? const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
              : TextButton(
            onPressed: _saveChanges,
            child: Text(
              'Save',
              style: TextStyle(
                color: _selectedAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),

      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Avatar ──────────────────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: _showImageOptions,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!) as ImageProvider
                          : (hasExistingImage
                          ? NetworkImage(widget.business['Business_img'])
                          : null),
                      child: (_pickedImage == null && !hasExistingImage)
                          ? const Icon(
                        Icons.store,
                        size: 34,
                        color: Colors.grey,
                      )
                          : null,
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _selectedAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: bg, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Tap to change logo',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),

            const SizedBox(height: 28),

            // ── Section: Store Info ─────────────────────────────────────────
            _sectionLabel('Store Info', isDark),
            const SizedBox(height: 12),
            _card(
              cardBg,
              Column(
                children: [
                  _field(
                    controller: _nameCtrl,
                    label: 'Business Name',
                    icon: IconsaxPlusLinear.shop,
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  _divider(isDark),
                  _field(
                    controller: _typeCtrl,
                    label: 'Business Type',
                    icon: IconsaxPlusLinear.category,
                  ),
                  _divider(isDark),
                  _field(
                    controller: _locationCtrl,
                    label: 'Location',
                    icon: IconsaxPlusLinear.location,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Section: Contact ────────────────────────────────────────────
            _sectionLabel('Contact Details', isDark),
            const SizedBox(height: 12),
            _card(
              cardBg,
              Column(
                children: [
                  _field(
                    controller: _emailCtrl,
                    label: 'Business Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return null;
                      final valid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v);
                      return valid ? null : 'Enter a valid email';
                    },
                  ),
                  _divider(isDark),
                  _field(
                    controller: _phoneCtrl,
                    label: 'Business Phone',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    readOnly: true,
                  ),
                  _divider(isDark),
                  _field(
                    controller: _rcCtrl,
                    label: 'RC Number',
                    icon: Icons.badge_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Section: Bio ────────────────────────────────────────────────
            _sectionLabel('Store Bio', isDark),
            const SizedBox(height: 12),
            _card(
              cardBg,
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: TextFormField(
                  controller: _bioCtrl,
                  maxLines: 4,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Tell customers about your store…',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    counterStyle: TextStyle(
                      color: Color.fromRGBO(158, 158, 158, 1),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Contact support ─────────────────────────────────────────────
            _actionTile(
              icon: IconsaxPlusLinear.message_question,
              label: 'Contact Support',
              color: Colors.blue,
              cardBg: cardBg,
              onTap: _contactSupport,
            ),

            const SizedBox(height: 12),

            // ── Delete store ────────────────────────────────────────────────
            _actionTile(
              icon: IconsaxPlusLinear.trash,
              label: 'Delete Store',
              color: Colors.red,
              cardBg: isDark
                  ? Colors.red.withOpacity(0.08)
                  : Colors.red.shade50,
              onTap: _confirmDelete,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text, bool isDark) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white60 : Colors.grey.shade600,
      letterSpacing: 0.5,
    ),
  );

  Widget _card(Color bg, Widget child) => Container(
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );

  Widget _divider(bool isDark) => Divider(
    height: 1,
    indent: 48,
    color: isDark ? Colors.white12 : Colors.grey.shade200,
  );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      decoration: InputDecoration(
        border: InputBorder.none,
        prefixIcon: Icon(icon, size: 18, color: Colors.grey),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
    ),
  );

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    required Color cardBg,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Icon(Icons.chevron_right, color: color.withOpacity(0.5)),
        ],
      ),
    ),
  );
}