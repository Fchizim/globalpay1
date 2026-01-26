// country_info.dart
class CountryInfo {
  final String name;
  final String iso2;
  final String currencyCode;
  final String currencySymbol;

  CountryInfo({
    required this.name,
    required this.iso2,
    required this.currencyCode,
    required this.currencySymbol,
  });

  factory CountryInfo.fromJson(Map<String, dynamic> json) {
    return CountryInfo(
      name: json['name'],
      iso2: json['iso2'],
      currencyCode: json['currency_code'],
      currencySymbol: json['currency_symbol'],
    );
  }
}
