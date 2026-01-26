import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';

<<<<<<< HEAD

=======
>>>>>>> c30d5f6 (initial commit)
class CountryListPage extends StatelessWidget {
  final List<Map<String, String>> countries = [
    {"name": "United States", "iso2": "US"},
    {"name": "United Kingdom", "iso2": "GB"},
    {"name": "Canada", "iso2": "CA"},
    {"name": "Nigeria", "iso2": "NG"},
    {"name": "India", "iso2": "IN"},
    {"name": "China", "iso2": "CN"},
    // … you can load 200+ from JSON later
  ];

  CountryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Countries")),
      body: ListView.builder(
        itemCount: countries.length,
        itemBuilder: (context, index) {
          final country = countries[index];
          return ListTile(
<<<<<<< HEAD
            leading: CountryFlag.fromCountryCode(
              country["iso2"]!,
              width: 40,
              height: 30,
=======
            leading: SizedBox(
              width: 40,
              height: 30,
              child: CountryFlag.fromCountryCode(country["iso2"]!),
>>>>>>> c30d5f6 (initial commit)
            ),
            title: Text(country["name"]!),
          );
        },
      ),
    );
  }
}
