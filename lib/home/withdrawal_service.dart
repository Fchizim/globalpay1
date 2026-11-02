import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BankOption {
  final String name;
  final String code;
  final String? logoUrl;

  const BankOption({required this.name, required this.code, this.logoUrl});

  @override
  String toString() => name;
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

/// Thrown by [WithdrawalService.verifyAccount] when the backend gave a
/// clean, definitive answer that this account is not registered at this
/// bank (as opposed to a timeout, rate limit or network error, where we
/// genuinely don't know the answer). Bank detection uses this distinction
/// to avoid retrying banks that have already given a real "no" — see
/// [WithdrawalService.detectBanksForAccount].
class BankVerificationRejected implements Exception {
  final String message;
  const BankVerificationRejected(this.message);

  @override
  String toString() => message;
}

class WithdrawalService {
  static const _base = 'https://glopa.org/glo';

  // A single, long-lived client so concurrent requests to the same host
  // reuse warm connections instead of paying a fresh TCP+TLS handshake
  // each time (which is what the top-level http.get/http.post do).
  static final http.Client _client = http.Client();

  // ── Logo sources ─────────────────────────────────────────────────────
  // Public source with broad commercial/microfinance bank coverage.
  static const _broadLogoSource =
      'https://supermx1.github.io/nigerian-banks-api/data.json';
  static const _broadLogoBase =
      'https://supermx1.github.io/nigerian-banks-api/';

  // Public source that's smaller but has the major fintechs.
  static const _fintechLogoSource = 'https://nigerianbanks.xyz';
  static const _placeholderLogoSuffix = 'default-image.png';

  // Logo resolution priority (deterministic, no fuzzy name matching):
  //   1. banks.php's own `logo` field (always wins)
  //   2. exact CODE match against the merged public sources
  //   3. the hand-verified overrides below
  //   4. null -> UI falls back to the generic bank icon
  //
  // NOTE: these override keys were matched against your OLD bank list.
  // Paystack's codes differ for some banks, so an entry whose key no
  // longer exists in the Paystack list is simply never used (harmless —
  // that bank falls back to the generic icon). The major fintechs
  // (PalmPay 999991, Kuda 50211, Moniepoint 50515, OPay 999992) are
  // already covered by banks.php's own logo field.
  static const Map<String, String> _verifiedOverrides = {
    '100033': 'https://nigerianbanks.xyz/logo/palmpay.png', // PalmPay (old code)
    '090267': 'https://nigerianbanks.xyz/logo/kuda-bank.png', // Kuda (old code)
    '090405':
    'https://nigerianbanks.xyz/logo/moniepoint-mfb-ng.png', // Moniepoint (old code)
    '100026':
    'https://supermx1.github.io/nigerian-banks-api/logos/carbon.png', // Carbon
    '000027': 'https://nigerianbanks.xyz/logo/globus-bank.png', // Globus Bank
    '000029': 'https://nigerianbanks.xyz/logo/lotus-bank.png', // Lotus Bank
    '000025':
    'https://supermx1.github.io/nigerian-banks-api/logos/titan-trust-bank.png', // Titan Trust Bank
    '000031':
    'https://supermx1.github.io/nigerian-banks-api/logos/premiumtrust-bank-ng.png', // PremiumTrust Bank
    '000026': 'https://nigerianbanks.xyz/logo/taj-bank.png', // Taj Bank
    '000030':
    'https://supermx1.github.io/nigerian-banks-api/logos/parallex-bank.png', // Parallex Bank
    '060001':
    'https://supermx1.github.io/nigerian-banks-api/logos/coronation-merchant-bank-ng.png', // Coronation Merchant Bank
    '090325':
    'https://supermx1.github.io/nigerian-banks-api/logos/sparkle-microfinance-bank.png', // Sparkle
  };

  // ── Bank auto-detection priority list ──────────────────────────────
  // Account numbers don't carry their bank with them — the only way to
  // find the right bank is to try verifying against real banks until one
  // answers.
  //
  // Tier 1: the banks/fintechs that cover the overwhelming majority of
  // real Nigerian accounts.
  static const List<String> _tier1Keywords = [
    'opay',
    'palmpay',
    'moniepoint',
    'kuda',
    'gtbank',
    'guaranty trust',
    'access bank',
    'zenith bank',
    'first bank',
    'uba',
    'united bank for africa',
    'union bank',
    'fidelity bank',
    'sterling bank',
    'wema bank',
    'fcmb',
    'first city monument',
    'providus',
  ];

  // Tier 2: less common but still real banks/fintechs.
  static const List<String> _tier2Keywords = [
    'alat',
    'ecobank',
    'stanbic',
    'polaris bank',
    'keystone bank',
    'unity bank',
    'heritage bank',
    'jaiz bank',
    'suntrust',
    'titan trust',
    'globus bank',
    'lotus bank',
    'premiumtrust',
    'parallex',
    'taj bank',
    'coronation',
    'carbon',
    'sparkle',
    'vfd',
    'rubies',
    'mint',
  ];

  // ── Detection concurrency/retry tuning ────────────────────────────
  // Paystack's account-resolve endpoint is rate-limited much more
  // aggressively than Flutterwave's, so concurrency is kept low. A 429
  // comes back from the backend as "UNAVAILABLE", which is treated as
  // "unknown" (retried), never as a definitive rejection.
  static const int _maxConcurrentVerifications = 5;
  static const int _maxDetectionAttempts = 2;
  static const Duration _detectionRetryDelay = Duration(milliseconds: 600);
  static const Duration _detectionCallTimeout = Duration(seconds: 6);

  /// Strips spaces/hyphens and lowercases, so keyword matching doesn't
  /// silently miss a bank purely because of inconsistent spacing.
  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[\s\-]'), '');

  /// Builds the ordered, deduped candidate list for auto-detection:
  /// each priority keyword matched against the loaded bank list, in
  /// priority order, keeping only the first bank matched per keyword and
  /// skipping duplicates.
  static List<BankOption> _priorityBanksFor(
      List<BankOption> banks,
      List<String> keywords,
      ) {
    final seenCodes = <String>{};
    final result = <BankOption>[];
    for (final keyword in keywords) {
      final normalizedKeyword = _normalize(keyword);
      for (final bank in banks) {
        if (_normalize(bank.name).contains(normalizedKeyword)) {
          if (seenCodes.add(bank.code)) {
            result.add(bank);
          }
          break;
        }
      }
    }
    return result;
  }

  /// Recently used recipients, most recent first (deduped, capped at 10 server-side).
  static Future<List<RecipientInfo>> getRecentRecipients(String userId) async {
    final res = await _client
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
  static Future<List<RecipientInfo>> getFavoriteRecipients(
      String userId,
      ) async {
    final res = await _client
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
    final res = await _client
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

  /// Fetches banks from your backend (now backed by Paystack's bank list)
  /// and resolves a logo for each using the priority described above.
  static Future<List<BankOption>> getBanks() async {
    final bankFuture = _client
        .get(Uri.parse('$_base/banks.php'))
        .timeout(const Duration(seconds: 15));
    final broadLogoFuture = _fetchLogoByCode(
      _broadLogoSource,
      pathPrefix: _broadLogoBase,
    );
    final fintechLogoFuture = _fetchLogoByCode(_fintechLogoSource);

    final bankRes = await bankFuture;
    final decoded = jsonDecode(bankRes.body);
    if (decoded['status'] != 'success') {
      throw Exception(decoded['message'] ?? 'Could not load banks');
    }
    final List data = decoded['data'];

    final broadByCode = await broadLogoFuture;
    final fintechByCode = await fintechLogoFuture;
    // Fintech source layered on top so it wins on overlap.
    final Map<String, String> publicByCode = {...broadByCode, ...fintechByCode};

    return data.map((b) {
      final name = b['name'].toString();
      final code = b['code'].toString();
      final backendLogo = b['logo']?.toString();

      final logoUrl = (backendLogo != null && backendLogo.isNotEmpty)
          ? backendLogo
          : publicByCode[code] ?? _verifiedOverrides[code];

      return BankOption(name: name, code: code, logoUrl: logoUrl);
    }).toList();
  }

  static Future<Map<String, String>> _fetchLogoByCode(
      String source, {
        String pathPrefix = '',
      }) async {
    final Map<String, String> logoByCode = {};
    try {
      final res = await _client
          .get(Uri.parse(source))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return logoByCode;

      final List logos = jsonDecode(res.body);
      for (final entry in logos) {
        if (entry is! Map) continue;
        final code = entry['code']?.toString();
        final logoPath = entry['logo']?.toString();
        if (code == null || logoPath == null || logoPath.isEmpty) continue;
        // Skip placeholder images so the bank falls through to the
        // override map or the generic icon.
        if (logoPath.endsWith(_placeholderLogoSuffix)) continue;

        logoByCode[code] = logoPath.startsWith('http')
            ? logoPath
            : '$pathPrefix$logoPath';
      }
    } catch (_) {
      // Logos are a nice-to-have, never let this take down bank loading.
    }
    return logoByCode;
  }

  /// Resolves an account number + bank code to the account holder's name.
  ///
  /// Failure modes:
  ///  - [BankVerificationRejected]: backend gave a definitive "no".
  ///  - plain [Exception] ("Verification temporarily unavailable"): the
  ///    backend/Paystack was rate-limited or down — we don't know the
  ///    answer, so callers should treat it as retryable.
  ///  - [TimeoutException]: request took too long (thrown as-is so the UI
  ///    can show a "tap to retry" message).
  static Future<String> verifyAccount({
    required String accountNumber,
    required String bankCode,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final res = await _client
        .post(
      Uri.parse('$_base/verify_account.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'account_number': accountNumber,
        'bank_code': bankCode,
      }),
    )
        .timeout(timeout);

    final decoded = jsonDecode(res.body);
    if (decoded['status'] != 'success') {
      // Temporary problem (e.g. Paystack rate limit): NOT a rejection.
      if (decoded['code'] == 'UNAVAILABLE') {
        throw Exception('Verification temporarily unavailable');
      }
      // The backend responded normally and definitively said no.
      throw BankVerificationRejected(
        decoded['message'] ?? 'Could not verify account',
      );
    }
    return decoded['data']['account_name'];
  }

  /// Tries to identify which bank(s) an account number belongs to,
  /// without the user picking one first. The same 10-digit number can be
  /// a valid, distinct account at more than one bank, so this checks
  /// every candidate and returns every match, in priority order (tier 1
  /// before tier 2).
  ///
  /// Candidates are verified through a bounded worker pool. Candidates
  /// that were neither matched nor definitively rejected (timeouts, rate
  /// limits) get up to [_maxDetectionAttempts] total passes.
  ///
  /// Returns an empty list if nothing matches — callers should fall back
  /// to letting the user pick a bank manually.
  ///
  /// This intentionally does NOT search the full 600+ bank list.
  static Future<List<DetectedBank>> detectBanksForAccount({
    required String accountNumber,
    required List<BankOption> banks,
  }) async {
    final candidates = [
      ..._priorityBanksFor(banks, _tier1Keywords),
      ..._priorityBanksFor(banks, _tier2Keywords),
    ];
    if (candidates.isEmpty) return [];

    // Keyed by bank code so repeated attempts never double-count a match.
    final matched = <String, DetectedBank>{};
    // Banks that gave a definitive "not this bank" — never re-asked.
    final rejected = <String>{};
    var remaining = candidates;

    for (
    var attempt = 0;
    attempt < _maxDetectionAttempts && remaining.isNotEmpty;
    attempt++
    ) {
      final result = await _tryAllPooled(accountNumber, remaining);
      for (final r in result.matches) {
        matched[r.bank.code] = r;
      }
      rejected.addAll(result.definitivelyRejectedCodes);
      remaining = remaining
          .where(
            (b) => !matched.containsKey(b.code) && !rejected.contains(b.code),
      )
          .toList();
      if (remaining.isNotEmpty && attempt < _maxDetectionAttempts - 1) {
        await Future.delayed(_detectionRetryDelay);
      }
    }

    // Keep priority ordering rather than arrival order.
    final order = {
      for (var i = 0; i < candidates.length; i++) candidates[i].code: i,
    };
    final results = matched.values.toList()
      ..sort((a, b) => order[a.bank.code]!.compareTo(order[b.bank.code]!));

    return results;
  }

  /// Verifies every candidate using a bounded worker pool (size
  /// [_maxConcurrentVerifications]): the moment any worker finishes a
  /// candidate it starts the next one, so no batch waits on a straggler.
  ///
  /// Failures are split into two buckets:
  ///   - [BankVerificationRejected]: definitive "no", tracked separately
  ///     and never retried.
  ///   - anything else (timeout, rate limit, connection error, bad
  ///     response): unknown, stays a candidate for the next pass.
  static Future<_PooledDetectionResult> _tryAllPooled(
      String accountNumber,
      List<BankOption> candidates,
      ) async {
    final results = <DetectedBank>[];
    final rejectedCodes = <String>{};
    var nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        final i = nextIndex;
        if (i >= candidates.length) return;
        nextIndex++;
        final bank = candidates[i];
        try {
          final name = await verifyAccount(
            accountNumber: accountNumber,
            bankCode: bank.code,
            timeout: _detectionCallTimeout,
          );
          results.add(DetectedBank(bank: bank, accountName: name));
        } on BankVerificationRejected {
          rejectedCodes.add(bank.code);
        } catch (_) {
          // Unknown outcome — eligible for a retry pass.
        }
      }
    }

    final workerCount = _maxConcurrentVerifications < candidates.length
        ? _maxConcurrentVerifications
        : candidates.length;
    await Future.wait(List.generate(workerCount, (_) => worker()));
    return _PooledDetectionResult(results, rejectedCodes);
  }

  /// Submits the withdrawal. Returns the raw parsed response — check
  /// `status` ('success'/'error') and, on success, `payment_status`
  /// ('success'/'pending') to decide what to show the user.
  ///
  /// With the Paystack backend, a transfer whose outcome is still unknown
  /// (timeout / 5xx from Paystack) is returned as status 'success' with
  /// payment_status 'pending' — treat that as "processing", not a failure.
  static Future<Map<String, dynamic>> withdraw({
    required String userId,
    required String accountNumber,
    required String bankCode,
    required String bankName,
    required String accountName,
    required double amount,
    required String pin,
  }) async {
    final res = await _client
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
        'pin': pin,
      }),
    )
        .timeout(const Duration(seconds: 40));

    if (res.body.isEmpty) {
      throw Exception(
        'Empty response from server. Please check your balance before retrying.',
      );
    }
    return jsonDecode(res.body);
  }
}

/// A single successful match from [WithdrawalService.detectBanksForAccount].
class DetectedBank {
  final BankOption bank;
  final String accountName;

  const DetectedBank({required this.bank, required this.accountName});
}

/// Internal result of one [WithdrawalService._tryAllPooled] pass:
/// confirmed matches, plus the set of bank codes that were definitively
/// rejected (as opposed to merely unresolved/timed out) during that pass.
class _PooledDetectionResult {
  final List<DetectedBank> matches;
  final Set<String> definitivelyRejectedCodes;

  const _PooledDetectionResult(this.matches, this.definitivelyRejectedCodes);
}