import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'confirmDeliveryPage.dart';

class DeliveryDetailsPage extends StatefulWidget {
  final Map<String, String>? previousData;

  const DeliveryDetailsPage({super.key, this.previousData});

  @override
  State<DeliveryDetailsPage> createState() => _DeliveryDetailsPageState();
}

class _DeliveryDetailsPageState extends State<DeliveryDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedState;
  String? _selectedLga;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _additionalController = TextEditingController();

  bool _agreeTerms = false;

  final Map<String, List<String>> _stateLgas = {
    "Abia": ["Aba North", "Aba South", "Umuahia North", "Umuahia South"],
    "Adamawa": ["Yola North", "Yola South", "Mubi North", "Mubi South"],
    "Akwa Ibom": ["Uyo", "Ikot Ekpene", "Eket", "Oron"],
    "Anambra": ["Awka North", "Awka South", "Nnewi North", "Onitsha North"],
    "Lagos": ["Ikeja", "Lekki", "Surulere", "Yaba", "Epe", "Ikorodu"],
    "Rivers": ["Port Harcourt", "Obio-Akpor", "Eleme", "Okrika", "Bonny"],
    "Kano": ["Kano Municipal", "Fagge", "Gwale", "Tarauni", "Dala"],
    "Oyo": ["Ibadan North", "Ibadan South-West", "Ogbomoso", "Oyo East"],
  };

  @override
  void initState() {
    super.initState();
    if (widget.previousData != null) {
      _selectedState = widget.previousData!['state'];
      _selectedLga = widget.previousData!['lga'];
      _addressController.text = widget.previousData!['address'] ?? '';
      _landmarkController.text = widget.previousData!['landmark'] ?? '';
      _phoneController.text = widget.previousData!['phone'] ?? '';
      _additionalController.text =
          widget.previousData!['additionalPhone'] ?? '';
    }
  }

  bool _isValidNigerianNumber(String value) {
    final regExp = RegExp(r'^0[0-9]{10}$');
    return regExp.hasMatch(value);
  }

  void _showPicker({
    required String title,
    required List<String> options,
    required Function(String) onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (BuildContext ctx) {
        String selected = options.first;
        return SizedBox(
          height: 280,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                height: 5,
                width: 60,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: 0),
                  backgroundColor:
                  isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    selected = options[index];
                  },
                  children: options
                      .map((e) => Center(
                    child: Text(
                      e,
                      style: TextStyle(
                        color:
                        isDark ? Colors.white : Colors.grey[900],
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ))
                      .toList(),
                ),
              ),
              const Divider(height: 1, thickness: 0.6),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onSelected(selected);
                },
                child: const Text(
                  "Select",
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 5),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D0D) : Colors.grey[100];
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "Delivery Details",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: cardColor,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Please provide accurate delivery details. P.O. boxes are not accepted.",
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 20),

                // State picker
                _buildPickerField(
                  title: "State",
                  value: _selectedState,
                  icon: LucideIcons.mapPin,
                  onTap: () {
                    _showPicker(
                      title: "Select State",
                      options: _stateLgas.keys.toList(),
                      onSelected: (val) {
                        setState(() {
                          _selectedState = val;
                          _selectedLga = null;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // LGA picker
                _buildPickerField(
                  title: "LGA",
                  value: _selectedLga,
                  icon: LucideIcons.building2,
                  onTap: _selectedState == null
                      ? null
                      : () {
                    _showPicker(
                      title: "Select LGA",
                      options: _stateLgas[_selectedState] ?? [],
                      onSelected: (val) {
                        setState(() => _selectedLga = val);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _addressController,
                  label: 'Full Address',
                  hint: 'Street name, house number, area',
                  icon: LucideIcons.map,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _landmarkController,
                  label: 'Nearest Landmark',
                  hint: 'E.g. Opposite Shoprite, near GTBank',
                  icon: LucideIcons.landmark,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'E.g. 08123456789',
                  icon: LucideIcons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Enter phone number';
                    } else if (!_isValidNigerianNumber(val)) {
                      return 'Invalid Nigerian number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _additionalController,
                  label: 'Additional Phone (Optional)',
                  hint: 'Another reachable number',
                  icon: LucideIcons.phoneCall,
                  keyboardType: TextInputType.phone,
                  optional: true,
                ),
                const SizedBox(height: 24),

                CheckboxListTile(
                  value: _agreeTerms,
                  onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                  activeColor: Colors.deepOrange,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'I confirm all information provided is correct.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 24),

                GestureDetector(
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      if (_agreeTerms) {
                        if (_selectedState != null && _selectedLga != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConfirmDeliveryPage(
                                state: _selectedState!,
                                lga: _selectedLga!,
                                address: _addressController.text,
                                landmark: _landmarkController.text,
                                phone: _phoneController.text,
                                additionalPhone: _additionalController.text,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select state and LGA'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                            Text('Please confirm your details first.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.deepOrange, Colors.orangeAccent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepOrange.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Save Delivery Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickerField({
    required String title,
    required IconData icon,
    required String? value,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextFormField(
          readOnly: true,
          controller: TextEditingController(text: value ?? ''),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.deepOrange),
            labelText: title,
            hintText: value ?? 'Select $title',
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2A2A2A)
                : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (val) {
            if (value == null || value.isEmpty) {
              return 'Please select $title';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool optional = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator ??
              (value) {
            if (!optional && (value == null || value.isEmpty)) {
              return 'Please enter $label';
            }
            return null;
          },
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.deepOrange),
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
