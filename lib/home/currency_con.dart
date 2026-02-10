class CurrencyConfig {
  static final CurrencyConfig _instance = CurrencyConfig._internal();

  factory CurrencyConfig() => _instance;

  CurrencyConfig._internal();

  String symbol = '₦'; // default currency symbol
}
