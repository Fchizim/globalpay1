import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BankOption {
  final String name;
  final String code;
  const BankOption({required this.name, required this.code});

  @override
  String toString() => name; // lets DropdownSearch filter/display by name directly
}

class RecipientInfo {
  final String accountNumber;
  final String bankCode;
  final String bankName;
  final String accountName;

  const RecipientInfo({
    required this.accountNumber,
    required this.bankCode,
    required this.bankName,
    required this.accountName,
  });

  String get key => '$accountNumber|$bankCode';

  factory RecipientInfo.fromJson(Map<String, dynamic> j) => RecipientInfo(
    accountNumber: j['account_number'].toString(),
    bankCode: j['bank_code'].toString(),
    bankName: j['bank_name'].toString(),
    accountName: j['account_name'].toString(),
  );
}

class WithdrawalService {
  static const _base = 'https://glopa.org/glo';

  /// Recently used recipients, most recent first (deduped, capped at 10 server-side).
  static Future<List<RecipientInfo>> getRecentRecipients(String userId) async {
    final res = await http
        .get(Uri.parse('$_base/get_recent_recipients.php?user_id=$userId'))
        .timeout(const Duration(seconds: 15));

    final decoded = jsonDecode(res.body);
    if (decoded['status'] != 'success') {
      throw Exception(decoded['message'] ?? 'Could not load recent recipients');
    }
    final List data = decoded['data'];
    return data.map((r) => RecipientInfo.fromJson(r)).toList();
  }

  /// The user's saved favorite recipients.
  static Future<List<RecipientInfo>> getFavoriteRecipients(String userId) async {
    final res = await http
        .get(Uri.parse('$_base/get_favorite_recipients.php?user_id=$userId'))
        .timeout(const Duration(seconds: 15));

    final decoded = jsonDecode(res.body);
    if (decoded['status'] != 'success') {
      throw Exception(decoded['message'] ?? 'Could not load favorites');
    }
    final List data = decoded['data'];
    return data.map((r) => RecipientInfo.fromJson(r)).toList();
  }

  /// Adds the recipient to favorites if it isn't one yet, removes it otherwise.
  /// Returns the new favorite state.
  static Future<bool> toggleFavorite({
    required String userId,
    required RecipientInfo recipient,
  }) async {
    final res = await http
        .post(
      Uri.parse('$_base/toggle_favorite_recipient.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'account_number': recipient.accountNumber,
        'bank_code': recipient.bankCode,
        'bank_name': recipient.bankName,
        'account_name': recipient.accountName,
      }),
    )
        .timeout(const Duration(seconds: 15));

    final decoded = jsonDecode(res.body);
    if (decoded['status'] != 'success') {
      throw Exception(decoded['message'] ?? 'Could not update favorite');
    }
    return decoded['is_favorite'] == true;
  }

  static Future<List<BankOption>> getBanks() async {
    final res = await http
        .get(Uri.parse('$_base/banks.php'))
        .timeout(const Duration(seconds: 15));

    final decoded = jsonDecode(res.body);
    if (decoded['status'] != 'success') {
      throw Exception(decoded['message'] ?? 'Could not load banks');
    }

    final List data = decoded['data'];
    return data
        .map((b) => BankOption(name: b['name'], code: b['code']))
        .toList();
  }

  /// Resolves an account number + bank code to the account holder's name.
  /// Throws with a user-facing message on failure (invalid account, network, etc).
  static Future<String> verifyAccount({
    required String accountNumber,
    required String bankCode,
  }) async {
    final res = await http
        .post(
      Uri.parse('$_base/verify_account.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'account_number': accountNumber,
        'bank_code': bankCode,
      }),
    )
        .timeout(const Duration(seconds: 20));

    final decoded = jsonDecode(res.body);
    if (decoded['status'] != 'success') {
      throw Exception(decoded['message'] ?? 'Could not verify account');
    }
    return decoded['data']['account_name'];
  }

  /// Submits the withdrawal. Returns the raw parsed response — check
  /// `status` ('success'/'error') and, on success, `payment_status`
  /// ('success'/'pending') to decide what to show the user.
  static Future<Map<String, dynamic>> withdraw({
    required String userId,
    required String accountNumber,
    required String bankCode,
    required String bankName,
    required String accountName,
    required double amount,
  }) async {
    final res = await http
        .post(
      Uri.parse('$_base/withdraw.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'account_number': accountNumber,
        'bank_code': bankCode,
        'bank_name': bankName,
        'account_name': accountName,
        'amount': amount,
      }),
    )
        .timeout(const Duration(seconds: 40));

    if (res.body.isEmpty) {
      throw Exception('Empty response from server. Please check your balance before retrying.');
    }
    return jsonDecode(res.body);
  }
}