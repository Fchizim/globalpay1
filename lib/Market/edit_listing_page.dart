import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../provider/user_provider.dart';

class EditListingPage extends StatefulWidget {
  final Map<String, dynamic> product;
  const EditListingPage({super.key, required this.product});

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController titleController;
  late final TextEditingController priceController;
  late final TextEditingController descController;
  late final TextEditingController colorController;
  late final TextEditingController bonusController;

  // ── Categories ────────────────────────────────────────────
  List<Map<String, dynamic>> _categories  = [];
  Map<String, dynamic>?      _selectedCategory;
  bool                       _loadingCats = true;

  // ── Images ────────────────────────────────────────────────
  // Each slot is either a File (newly picked) or a String (existing URL) or null (cleared)
  static const int _maxImages = 7;
  final List<dynamic> _imageSlots = []; // File | String | null

  final ImagePicker _picker = ImagePicker();

  String _selectedStatus = 'available';
  String _selectedState  = 'new';
  bool   _isSaving       = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    titleController = TextEditingController(text: p['name']        ?? '');
    priceController = TextEditingController(text: p['price']?.toString() ?? '');
    descController  = TextEditingController(text: p['description'] ?? '');
    colorController = TextEditingController(text: p['prod_color']  ?? '');
    bonusController = TextEditingController(text: p['bonus']       ?? '');

    _selectedStatus = p['prod_status'] ?? 'available';
    _selectedState  = p['prod_state']  ?? 'new';

    // Seed image slots from existing URLs
    final existing = List<String>.from(p['images'] ?? p['product_images'] ?? []);
    for (final url in existing) {
      _imageSlots.add(url);
    }

    _fetchCategories();
  }

  @override
  void dispose() {
    titleController.dispose();
    priceController.dispose();
    descController.dispose();
    colorController.dispose();
    bonusController.dispose();
    super.dispose();
  }

  // ── Fetch categories ──────────────────────────────────────
  Future<void> _fetchCategories() async {
    setState(() => _loadingCats = true);
    try {
      final res = await http.get(
        Uri.parse('https://glopa.org/glo/get_category.php'),
        headers: {'Accept': 'application/json'},
      );
      final raw   = res.body.trim();
      final start = raw.indexOf('{');
      if (start == -1) throw Exception('No JSON');
      final data  = jsonDecode(raw.substring(start));
      if (data['status'] == 'success') {
        final cats = List<Map<String, dynamic>>.from(data['categories']);
        setState(() {
          _categories = cats;
          _loadingCats = false;
          // Pre-select the product's category
          final currentCatId = widget.product['cat_id']?.toString();
          if (currentCatId != null) {
            _selectedCategory = cats.firstWhere(
                  (c) => c['cat_id'].toString() == currentCatId,
              orElse: () => cats.first,
            );
          }
        });
      } else {
        setState(() => _loadingCats = false);
      }
    } catch (e) {
      setState(() => _loadingCats = false);
    }
  }

  // ── Image picking ─────────────────────────────────────────
  Future<void> _pickImages() async {
    final remaining = _maxImages - _imageSlots.length;
    if (remaining <= 0) return;
    final picked = await _picker.pickMultiImage(imageQuality: 75);
    if (picked.isEmpty) return;
    setState(() {
      _imageSlots.addAll(picked.take(remaining).map((x) => File(x.path)));
    });
  }

  void _removeSlot(int index) {
    setState(() => _imageSlots.removeAt(index));
  }

  // ── Save ──────────────────────────────────────────────────
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageSlots.isEmpty) {
      _showSnack('Add at least one product photo', isError: true); return;
    }
    if (_selectedCategory == null) {
      _showSnack('Please select a category', isError: true); return;
    }

    final user = context.read<UserProvider>().user;
    if (user == null) {
      _showSnack('Session expired. Please log in.', isError: true); return;
    }

    final businessId = widget.product['business_id']?.toString() ?? '';

    setState(() => _isSaving = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://glopa.org/glo/edit_product.php'),
      );

      request.headers['Accept'] = 'application/json';

      request.fields.addAll({
        'product_id':  widget.product['product_id'].toString(),
        'business_id': businessId,
        'cat_id':      _selectedCategory!['cat_id'].toString(),
        'name':        titleController.text.trim(),
        'description': descController.text.trim(),
        'price':       priceController.text.trim(),
        'prod_status': _selectedStatus,
        'prod_state':  _selectedState,
        'prod_color':  colorController.text.trim(),
        'bonus':       bonusController.text.trim(),
      });

      // Walk all 7 slots
      for (int i = 0; i < _maxImages; i++) {
        final slotKey = 'prod_image${i + 1}';
        if (i < _imageSlots.length) {
          final slot = _imageSlots[i];
          if (slot is File) {
            // New file — attach it
            request.files.add(
              await http.MultipartFile.fromPath(slotKey, slot.path),
            );
          } else if (slot is String) {
            // Existing URL — tell backend to keep it (no file sent = keep)
            request.fields['keep_image${i + 1}'] = '1';
          }
        } else {
          // Slot was removed — tell backend to clear it
          request.fields['clear_image${i + 1}'] = '1';
        }
      }

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final body     = await streamed.stream.bytesToString();

      debugPrint('=== EDIT PRODUCT (${streamed.statusCode}) === $body');

      if (!mounted) return;

      if (streamed.statusCode != 200) {
        _showSnack('Server error (${streamed.statusCode})', isError: true); return;
      }

      final data = jsonDecode(body);
      if (data['status'] == 'success') {
        _showSnack('Product updated!');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pop(context, data['product']);
      } else {
        _showSnack(data['message'] ?? 'Something went wrong', isError: true);
      }
    } catch (e) {
      debugPrint('Edit error: $e');
      _showSnack('Network error. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
      isError ? Colors.red.shade600 : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(children: [
      Scaffold(
        backgroundColor:
        isDark ? const Color(0xFF121212) : const Color(0xFFFBFBFB),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(IconsaxPlusLinear.close_circle,
                color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: Text('Edit Listing',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              )),
        ),
        body: Form(
          key: _formKey,
          child: Column(children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // ── Photos ─────────────────────────────────
                    _sectionTitle('Product Photos',
                        trailing: '${_imageSlots.length}/$_maxImages'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imageSlots.length +
                            (_imageSlots.length < _maxImages ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == _imageSlots.length) {
                            return _buildAddPhotoBtn();
                          }
                          return _buildSlotPreview(i);
                        },
                      ),
                    ),

                    const SizedBox(height: 28),
                    _sectionTitle('Product Info'),
                    const SizedBox(height: 14),

                    _buildTextField(
                      controller: titleController,
                      label: 'Product Name',
                      hint: 'What are you selling?',
                      icon: IconsaxPlusLinear.box_1,
                      validator: (v) =>
                      v!.trim().isEmpty ? 'Enter a product name' : null,
                    ),

                    _buildTextField(
                      controller: priceController,
                      label: 'Price (₦)',
                      hint: '0.00',
                      icon: IconsaxPlusLinear.card,
                      keyboardType: TextInputType.number,
                      prefixText: '₦ ',
                      validator: (v) =>
                      v!.trim().isEmpty ? 'Enter a price' : null,
                    ),

                    _loadingCats
                        ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.deepOrange),
                      ),
                    )
                        : _buildCategoryPicker(isDark),

                    _buildChipSelector(
                      label: 'Status',
                      options: const ['available', 'out_of_stock'],
                      displayLabels: const ['Available', 'Out of Stock'],
                      selected: _selectedStatus,
                      onSelected: (v) =>
                          setState(() => _selectedStatus = v),
                    ),

                    _buildChipSelector(
                      label: 'Condition',
                      options: const ['new', 'used'],
                      displayLabels: const ['New', 'Used'],
                      selected: _selectedState,
                      onSelected: (v) =>
                          setState(() => _selectedState = v),
                    ),

                    _buildTextField(
                      controller: descController,
                      label: 'Description',
                      hint: 'Size, color, features, flaws...',
                      icon: IconsaxPlusLinear.note_text,
                      maxLines: 4,
                    ),

                    _buildTextField(
                      controller: colorController,
                      label: 'Color (optional)',
                      hint: 'e.g. Red, Black',
                      icon: IconsaxPlusLinear.colorfilter,
                    ),

                    _buildTextField(
                      controller: bonusController,
                      label: 'Bonus (optional)',
                      hint: 'e.g. Free delivery',
                      icon: IconsaxPlusLinear.gift,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── Save button ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121212) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('Save Changes',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),

      // ── Saving overlay ──────────────────────────────────
      if (_isSaving)
        Container(
          color: Colors.black.withOpacity(0.6),
          child: Center(
            child: Card(
              elevation: 0,
              color: isDark ? Colors.grey.shade900 : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: const Padding(
                padding: EdgeInsets.all(30),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(
                      color: Colors.deepOrange, strokeWidth: 3),
                  SizedBox(height: 20),
                  Text('Saving...',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ),
        ),
    ]);
  }

  // ── Category sheet ────────────────────────────────────────
  void _showCategorySheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String query = '';
    List<Map<String, dynamic>> filtered = List.from(_categories);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10)),
              ),
              const Text('Select Category',
                  style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) {
                    setSheet(() {
                      query    = v.toLowerCase();
                      filtered = _categories
                          .where((c) => (c['name'] ?? '')
                          .toLowerCase()
                          .contains(query))
                          .toList();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search category...',
                    hintStyle:
                    const TextStyle(fontSize: 14, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.deepOrange, size: 20),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.grey.shade100,
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                    child: Text('No categories found',
                        style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                  controller: scrollCtrl,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final cat        = filtered[i];
                    final isSelected = _selectedCategory?['cat_id'] ==
                        cat['cat_id'];
                    return ListTile(
                      leading: (cat['icon'] as String? ?? '')
                          .isNotEmpty
                          ? Image.network(cat['icon'],
                          width: 28, height: 28,
                          errorBuilder: (_, __, ___) =>
                          const Icon(Icons.category,
                              color: Colors.deepOrange))
                          : const Icon(Icons.category,
                          color: Colors.deepOrange),
                      title: Text(cat['name'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.deepOrange
                                : null,
                          )),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                          color: Colors.deepOrange, size: 20)
                          : null,
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPicker(bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _fieldLabel('Category *'),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _showCategorySheet,
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(children: [
            (_selectedCategory != null &&
                (_selectedCategory!['icon'] as String? ?? '')
                    .isNotEmpty)
                ? Image.network(_selectedCategory!['icon'],
                width: 22, height: 22,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.category,
                    size: 20,
                    color: Colors.deepOrange))
                : const Icon(Icons.category,
                size: 20, color: Colors.deepOrange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedCategory?['name'] ?? 'Select a category',
                style: TextStyle(
                  fontSize: 14,
                  color: _selectedCategory == null
                      ? Colors.grey
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.deepOrange),
          ]),
        ),
      ),
    ]),
  );

  Widget _buildChipSelector({
    required String label,
    required List<String> options,
    required List<String> displayLabels,
    required String selected,
    required void Function(String) onSelected,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _fieldLabel(label),
          const SizedBox(height: 8),
          Row(
            children: List.generate(options.length, (i) {
              final isSelected = selected == options[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelected(options[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: EdgeInsets.only(
                        right: i < options.length - 1 ? 10 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.deepOrange
                          : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white10
                          : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      displayLabels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ]),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _fieldLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
            const TextStyle(fontSize: 14, color: Colors.grey),
            prefixText: prefixText,
            prefixIcon: Icon(icon,
                size: 18,
                color: Colors.deepOrange.withOpacity(0.8)),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide:
              const BorderSide(color: Colors.deepOrange, width: 1),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Image slot preview ────────────────────────────────────
  Widget _buildSlotPreview(int index) {
    final slot = _imageSlots[index];
    final ImageProvider img = slot is File
        ? FileImage(slot)
        : NetworkImage(slot as String) as ImageProvider;

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        image: DecorationImage(image: img, fit: BoxFit.cover),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: () => _removeSlot(index),
          child: Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
                color: Colors.redAccent, shape: BoxShape.circle),
            child: const Icon(Icons.close, size: 14, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildAddPhotoBtn() => GestureDetector(
    onTap: _pickImages,
    child: Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Colors.deepOrange.withOpacity(0.25), width: 1.5),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(IconsaxPlusLinear.add_square, color: Colors.deepOrange),
          SizedBox(height: 4),
          Text('Add Photo',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepOrange)),
        ],
      ),
    ),
  );

  Widget _sectionTitle(String text, {String? trailing}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(text,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold)),
      if (trailing != null)
        Text(trailing,
            style: const TextStyle(
                color: Colors.deepOrange,
                fontWeight: FontWeight.bold)),
    ],
  );

  Widget _fieldLabel(String text) => Text(
    '  $text',
    style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600),
  );
}