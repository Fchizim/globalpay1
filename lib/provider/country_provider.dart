import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import '../models/country_info.dart';

class CountryProvider with ChangeNotifier {
  List<CountryInfo> _countries = [];
  List<CountryInfo> get countries => _countries;

  Future<void> loadCountries() async {
    final String jsonString = await rootBundle.loadString('assets/countries.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    _countries = jsonList.map((e) => CountryInfo.fromJson(e)).toList();
    notifyListeners(); // 🔔 updates UI everywhere
  }
}
