import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:globalpay/profile_details/tier3_confirmation.dart';
import '../assets/nigeria_lgas.json.dart';
import 'nigeria_lgs.dart'; // Your nigeriaLgs map

class TierThree extends StatefulWidget {
  const TierThree({super.key});

  @override
  State<TierThree> createState() => _TierThreeState();
}

class _TierThreeState extends State<TierThree> {
  // Tier 3 selections
  String selectedCountry = "Nigeria"; // Pre-selected
  String selectedState = "";
  String selectedLga = "";

  final TextEditingController addressController = TextEditingController();

  late final Map<String, Map<String, List<String>>> countries;

  late List<String> stateList;
  late List<String> lgaList;

  @override
  void initState() {
    super.initState();

    countries = {
      "Nigeria": nigeriaLgs,
    };

    stateList = countries[selectedCountry]?.keys.toList() ?? [];
    stateList.sort();
    lgaList = [];
  }

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

  // ================== CONFIRM MODAL ==================

  void _showConfirmModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Center(
                child: Text(
                  "Confirm Address",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Please ensure that the address information you entered matches your utility bill.",
                style: TextStyle(color: Colors.deepOrange),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _confirmRow("State", selectedState),
                    const SizedBox(height: 10),
                    _confirmRow("LGA", selectedLga),
                    const SizedBox(height: 10),
                    _confirmRow(
                        "Address Details", addressController.text.trim()),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Modify",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Tier3Confirmation()));

                        // 🔥 SEND DATA HERE
                        print("State: $selectedState");
                        print("LGA: $selectedLga");
                        print("Address: ${addressController.text.trim()}");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Confirm",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _confirmRow(String title, String value) {
    return Row(
      children: [
        Icon(Icons.location_on_outlined, color: Colors.deepOrange,),
        Text(
          "$title: ",
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ================== YOUR ORIGINAL PICKER ==================

  void showWheelPicker({
    required List<String> items,
    required String currentValue,
    required Function(String) onSelected,
    required String title,
  }) {
    int selectedIndex = currentValue.isEmpty ? 0 : items.indexOf(currentValue);
    if (selectedIndex < 0) selectedIndex = 0;

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          height: 320,
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: CupertinoPicker(
                  scrollController:
                  FixedExtentScrollController(initialItem: selectedIndex),
                  itemExtent: 45,
                  onSelectedItemChanged: (index) {
                    selectedIndex = index;
                  },
                  children:
                  items.map((e) => Center(child: Text(e))).toList(),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      onSelected(items[selectedIndex]);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Done",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // ================== BUILD ==================

  @override
  Widget build(BuildContext context) {
    bool isValid = selectedCountry.isNotEmpty &&
        selectedState.isNotEmpty &&
        selectedLga.isNotEmpty &&
        addressController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          "KYC Verification",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            onPressed: isValid ? _showConfirmModal : null, // 👈 ADDED HERE
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              disabledBackgroundColor: Colors.deepOrange.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              "Next",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ),

      // 👇 YOUR ORIGINAL BODY REMAINS UNTOUCHED
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Upload a utility bill containing your address.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepOrange.shade200),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle,
                      size: 40, color: Colors.deepOrange),
                  SizedBox(height: 10),
                  Text(
                    "Upload Utility Bill or Bank Statement",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Containing your address, Not older than 3 months",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            buildField(
              "Country",
              selectedCountry,
              null,
              showDropdownIcon: false,
            ),

            buildField(
              "State",
              selectedState.isEmpty ? "Select State" : selectedState,
                  () {
                showWheelPicker(
                  items: stateList,
                  currentValue: selectedState,
                  onSelected: (val) {
                    setState(() {
                      selectedState = val;
                      selectedLga = "";
                      lgaList = countries[selectedCountry]?[val] ?? [];
                      lgaList.sort();
                    });
                  },
                  title: "Select State",
                );
              },
            ),

            buildField(
              "LGA",
              selectedLga.isEmpty ? "Select LGA" : selectedLga,
              selectedState.isEmpty
                  ? null
                  : () {
                showWheelPicker(
                  items: lgaList,
                  currentValue: selectedLga,
                  onSelected: (val) {
                    setState(() => selectedLga = val);
                  },
                  title: "Select LGA",
                );
              },
            ),

            const SizedBox(height: 20),
            const Text("Address Details"),
            const SizedBox(height: 8),

            TextField(
              controller: addressController,
              decoration: InputDecoration(
                hintText: "e.g. 32, Metro Street",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                  const BorderSide(color: Colors.black),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            const Text(
              '* Including Street, house NO. or landmark or nearest\n bus stop',
              style: TextStyle(color: Colors.deepOrange),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildField(String title, String value, VoidCallback? onTap,
      {bool showDropdownIcon = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border:
              Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showDropdownIcon)
                  const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
