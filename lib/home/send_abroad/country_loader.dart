// country_loader.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/country_info.dart';


Future<List<CountryInfo>> loadCountries() async {
  final data = await rootBundle.loadString('assets/data/countries.json');
  final List<dynamic> jsonResult = json.decode(data);
  return jsonResult.map((c) => CountryInfo.fromJson(c)).toList();
}
