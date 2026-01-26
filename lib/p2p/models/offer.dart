class P2POffer {
  final String id;
  final String currencyHave; // What the user has
  final String currencyWant; // What the user wants
  final double amountHave; // Amount available to trade
  final double rate; // Exchange rate
  final bool isBuy; // true = Buy offer, false = Sell offer
  final String user; // Offer owner
  final double rating; // User rating
  final String paymentMethod; // Payment method e.g., Bank Transfer, USDT, etc.
  final String terms; // Optional: Any trade terms
  final double minLimit; // Minimum amount allowed
  final double maxLimit; // Maximum amount allowed

  P2POffer({
    required this.id,
    required this.currencyHave,
    required this.currencyWant,
    required this.amountHave,
    required this.rate,
    required this.isBuy,
    this.user = "User",
    this.rating = 4.5,
    this.paymentMethod = "Bank Transfer",
    this.terms = "",
    this.minLimit = 0,
    this.maxLimit = double.infinity,
  });
}
