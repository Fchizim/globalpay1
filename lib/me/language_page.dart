// // languages_page.dart
// import 'package:flutter/material.dart';
// import '../models/country_info.dart'; // adjust path as needed
//
// class LanguagesPage extends StatefulWidget {
//   final List<CountryInfo> countries;
//
//   const LanguagesPage({super.key, required this.countries});
//
//   @override
//   State<LanguagesPage> createState() => _LanguagesPageState();
// }
//
// class _LanguagesPageState extends State<LanguagesPage> {
//   List<CountryInfo> filteredCountries = [];
//   TextEditingController searchController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     filteredCountries = widget.countries;
//     searchController.addListener(_filterCountries);
//   }
//
//   void _filterCountries() {
//     final query = searchController.text.toLowerCase();
//     setState(() {
//       filteredCountries = widget.countries
//           .where((c) => c.name.toLowerCase().contains(query))
//           .toList();
//     });
//   }
//
//   String flagFromIso2(String iso2) {
//     return iso2.toUpperCase().codeUnits
//         .map((c) => String.fromCharCode(c + 127397))
//         .join();
//   }
//
//   @override
//   void dispose() {
//     searchController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade50,
//       appBar: AppBar(
//         title: Text('Select Language / Country'),
//         backgroundColor: Colors.deepOrange,
//         elevation: 0,
//       ),
//       body: Column(
//         children: [
//           // Search bar
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: TextField(
//               controller: searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search language or country',
//                 prefixIcon: Icon(Icons.search, color: Colors.deepOrange),
//                 filled: true,
//                 fillColor: Colors.white,
//                 contentPadding:
//                 EdgeInsets.symmetric(vertical: 0, horizontal: 16),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(20),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//           ),
//           // List of languages/countries
//           Expanded(
//             child: ListView.builder(
//               physics: BouncingScrollPhysics(),
//               itemCount: filteredCountries.length,
//               itemBuilder: (context, index) {
//                 final country = filteredCountries[index];
//                 return GestureDetector(
//                   onTap: () {
//                     // Handle language/country selection
//                     Navigator.pop(context, country);
//                   },
//                   child: Container(
//                     margin:
//                     EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
//                     padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(18),
//                       boxShadow: [
//                         BoxShadow(
//                             color: Colors.grey.shade200,
//                             blurRadius: 20,
//                             offset: Offset(0, 5)),
//                       ],
//                     ),
//                     child: Row(
//                       children: [
//                         Text(
//                           flagFromIso2(country.iso2),
//                           style: TextStyle(fontSize: 28),
//                         ),
//                         SizedBox(width: 12),
//                         Expanded(
//                           child: Text(
//                             country.name,
//                             style: TextStyle(
//                                 fontSize: 17, fontWeight: FontWeight.w500),
//                           ),
//                         ),
//                         Text(
//                           country.currencyCode,
//                           style: TextStyle(
//                               fontSize: 15,
//                               color: Colors.grey.shade600,
//                               fontWeight: FontWeight.w400),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
