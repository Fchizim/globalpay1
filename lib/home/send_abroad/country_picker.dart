// country_picker_page.dart
import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import '../../models/country_info.dart';
import 'country_loader.dart';

class CountryPickerPage extends StatefulWidget {
  final CountryInfo? selectedCountry;

  const CountryPickerPage({
    super.key,
    this.selectedCountry,
    required Null Function(dynamic CountryInfo) onSelected,
  });

  @override
  State<CountryPickerPage> createState() => _CountryPickerPageState();
}

class _CountryPickerPageState extends State<CountryPickerPage> {
  List<CountryInfo> allCountries = [];
  List<CountryInfo> filteredCountries = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCountries().then((countries) {
      setState(() {
        allCountries = countries;
        filteredCountries = countries;
      });
    });
  }

  void _filterCountries(String query) {
    final results = allCountries
        .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    setState(() {
      filteredCountries = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Country"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: allCountries.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search country",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterCountries,
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: filteredCountries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final country = filteredCountries[index];
                return ListTile(
                  leading: SizedBox(
                    width: 32,
                    height: 24,
                    child: CountryFlag.fromCountryCode(
                      country.iso2,
                      // optionally: borderRadius: 4, if the package supports it
                    ),
                  ),

                  title: Text(country.name),
                  subtitle: Text(
                    "${country.currencyCode} (${country.currencySymbol})",
                  ),
                  onTap: () {
                    Navigator.pop(context, country);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
