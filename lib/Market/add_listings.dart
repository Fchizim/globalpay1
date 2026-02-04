import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddListingPage extends StatefulWidget {
  const AddListingPage({super.key});

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final descController = TextEditingController();
  final locationController = TextEditingController();
  String selectedCategory = '';
  String selectedCondition = '';

  final List<XFile> images = [];
  final List<Uint8List> imageBytes = [];

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage(imageQuality: 80);
    if (pickedFiles.isNotEmpty) {
      final newBytes = await Future.wait(
        pickedFiles.map((x) => x.readAsBytes()),
      );
      setState(() {
        images.addAll(pickedFiles);
        imageBytes.addAll(newBytes);
        // keep max 10
        if (images.length > 10) {
          images.removeRange(10, images.length);
          imageBytes.removeRange(10, imageBytes.length);
        }
      });
    }
  }

  void _publish() {
    final listing = {
      "title": titleController.text,
      "price": priceController.text,
      "description": descController.text,
      "location": locationController.text,
      "category": selectedCategory,
      "condition": selectedCondition,
      "images": images.map((x) => x.path).toList(),
    };
    Navigator.pop(context, listing); // send back to previous screen
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Colors.deepOrange;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF121212) : Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, Colors.purple.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text("Add Listing"),
        actions: [
          TextButton(
            onPressed: _publish,
            child:
            const Text("Publish", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Photos: ${imageBytes.length}/10",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: imageBytes.length + 1,
                itemBuilder: (context, index) {
                  if (index == imageBytes.length) {
                    return GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 90,
                        margin:
                        const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.grey.shade300,
                        ),
                        child: const Icon(Icons.add_a_photo,
                            size: 30, color: Colors.black54),
                      ),
                    );
                  } else {
                    return Stack(
                      children: [
                        Container(
                          width: 90,
                          margin:
                          const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: MemoryImage(imageBytes[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                images.removeAt(index);
                                imageBytes.removeAt(index);
                              });
                            },
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        )
                      ],
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 18),
            _buildCard(
              child: TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: "Title",
                ),
              ),
            ),
            _buildCard(
              child: TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: "Price",
                ),
              ),
            ),
            _buildCard(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    border: InputBorder.none, labelText: 'Category'),
                initialValue: selectedCategory.isEmpty ? null : selectedCategory,
                items: [
                  'Electronics',
                  'Fashion',
                  'Home',
                  'Other'
                ]
                    .map((c) =>
                    DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => selectedCategory = v ?? ''),
              ),
            ),
            _buildCard(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    border: InputBorder.none, labelText: 'Condition'),
                initialValue: selectedCondition.isEmpty ? null : selectedCondition,
                items: [
                  'New',
                  'Used - Like New',
                  'Used - Good',
                  'Used - Fair'
                ]
                    .map((c) =>
                    DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => selectedCondition = v ?? ''),
              ),
            ),
            _buildCard(
              child: TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: "Description",
                ),
              ),
            ),
            _buildCard(
              child: TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: "Location",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }
}
