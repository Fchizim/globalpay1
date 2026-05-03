import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class AddListingPage extends StatefulWidget {
  const AddListingPage({super.key});

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final descController = TextEditingController();
  final locationController = TextEditingController();

  String? selectedCategory;
  String? selectedCondition;
  bool _isPublishing = false;

  final List<XFile> images = [];
  final List<Uint8List> imageBytes = [];
  final ImagePicker _picker = ImagePicker();

  // LIMIT TO 5 IMAGES
  static const int maxImages = 5;

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage(imageQuality: 70);
    if (pickedFiles.isNotEmpty) {
      final newBytes = await Future.wait(
        pickedFiles.map((x) => x.readAsBytes()),
      );
      setState(() {
        images.addAll(pickedFiles);
        imageBytes.addAll(newBytes);

        if (images.length > maxImages) {
          images.removeRange(maxImages, images.length);
          imageBytes.removeRange(maxImages, imageBytes.length);
        }
      });
    }
  }

  void _handlePublish() async {
    if (!_formKey.currentState!.validate()) return;
    if (imageBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Add at least one photo of your item"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);
    await Future.delayed(const Duration(seconds: 2));

    final listing = {
      "title": titleController.text,
      "price": priceController.text,
      "description": descController.text,
      "location": locationController.text,
      "category": selectedCategory,
      "condition": selectedCondition,
      "images": images.map((x) => x.path).toList(),
      "sold": false,
      "date": DateTime.now().toString(),
    };

    if (mounted) {
      setState(() => _isPublishing = false);
      Navigator.pop(context, listing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Colors.deepOrange;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF121212)
              : const Color(0xFFFBFBFB),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                IconsaxPlusLinear.close_circle,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            centerTitle: true,
            title: Text(
              "New Listing",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          body: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // --- PHOTO SECTION ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Product Photos",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${imageBytes.length}/$maxImages",
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                imageBytes.length +
                                (imageBytes.length < maxImages ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == imageBytes.length)
                                return _buildAddPhotoButton();
                              return _buildImagePreview(index);
                            },
                          ),
                        ),

                        const SizedBox(height: 30),
                        const Text(
                          "Information",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),

                        _buildTextField(
                          controller: titleController,
                          label: "Item Name",
                          hint: "What are you selling?",
                          icon: IconsaxPlusLinear.box_1,
                          validator: (v) => v!.isEmpty ? "Enter a title" : null,
                        ),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                controller: priceController,
                                label: "Price",
                                hint: "0.00",
                                icon: IconsaxPlusLinear.card,
                                keyboardType: TextInputType.number,
                                prefixText: "₦ ",
                                validator: (v) => v!.isEmpty ? "Req." : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: _buildDropdown(
                                label: "Condition",
                                value: selectedCondition,
                                items: [
                                  'New',
                                  'Used - Like New',
                                  'Used - Good',
                                  'Used - Fair',
                                ],
                                icon: IconsaxPlusLinear.status,
                                onChanged: (v) =>
                                    setState(() => selectedCondition = v),
                              ),
                            ),
                          ],
                        ),

                        _buildDropdown(
                          label: "Category",
                          value: selectedCategory,
                          items: [
                            'Electronics',
                            'Fashion',
                            'Home',
                            'Real Estate',
                            'Vehicles',
                            'Others',
                          ],
                          icon: IconsaxPlusLinear.grid_1,
                          onChanged: (v) =>
                              setState(() => selectedCategory = v),
                        ),

                        _buildTextField(
                          controller: descController,
                          label: "Description",
                          hint: "Provide details like size, color, or flaws...",
                          icon: IconsaxPlusLinear.note_text,
                          maxLines: 4,
                        ),

                        _buildTextField(
                          controller: locationController,
                          label: "Location",
                          hint: "e.g. Lagos, Nigeria",
                          icon: IconsaxPlusLinear.location,
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // --- FIXED BOTTOM BUTTON ---
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
                        onPressed: _handlePublish,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          "Publish Listing",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_isPublishing)
          Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: Card(
                elevation: 0,
                color: isDark ? Colors.grey.shade900 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: accentColor,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Uploading...",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.deepOrange.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.deepOrange.withOpacity(0.2),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconsaxPlusLinear.add_square, color: Colors.deepOrange),
            SizedBox(height: 4),
            Text(
              "Add Photo",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.deepOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(int index) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        image: DecorationImage(
          image: MemoryImage(imageBytes[index]),
          fit: BoxFit.cover,
        ),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: () => setState(() {
            images.removeAt(index);
            imageBytes.removeAt(index);
          }),
          child: Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: 14, color: Colors.white),
          ),
        ),
      ),
    );
  }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "  $label",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
              prefixText: prefixText,
              prefixIcon: Icon(
                icon,
                size: 20,
                color: Colors.deepOrange.withOpacity(0.8),
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Colors.deepOrange,
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "  $label",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            icon: const Icon(IconsaxPlusLinear.arrow_down_1, size: 16),
            items: items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, style: const TextStyle(fontSize: 14)),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            validator: (v) => v == null ? "Required" : null,
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                size: 20,
                color: Colors.deepOrange.withOpacity(0.8),
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Colors.deepOrange,
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
