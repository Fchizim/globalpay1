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
/// bank (as opposed to a timeout or network error, where we genuinely
/// don't know the answer). Bank detection uses this distinction to avoid
/// wastefully retrying banks that have already given a real "no" — see
/// [WithdrawalService.detectBanksForAccount].
class BankVerificationRejected implements Exception {
  final String message;
  const BankVerificationRejected(this.message);

  @override
  String toString() => message;
}

class WithdrawalService {
  static const _base = 'https://glopa.org/glo';

  // A single, long-lived client instead of the http.get/http.post
  // top-level convenience functions. Those convenience functions spin
  // up a brand-new client (and therefore a brand-new TCP+TLS connection)
  // for every single call and throw it away afterwards — so a pool of
  // 12 concurrent bank-detection requests to the same host was paying
  // for 12 full handshakes instead of reusing one warm connection.
  // Reusing this client lets the underlying connection to glopa.org
  // stay open and be reused across requests, which removes a real
  // chunk of per-request latency with no change in behavior or
  // accuracy.
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

  // Your own backend already ships pre-verified logos for ~25 major
  // banks (banks.php's own `logo` field) — that always wins, it's the
  // most authoritative source since it's yours.
  //
  // For everything else, resolution is CODE-ONLY against the two public
  // sources — no fuzzy name matching. Fuzzy matching is what caused the
  // "ChamsMobile" entry in your own banks.php to get Lotus Bank's logo
  // by mistake, so it's been removed entirely to avoid wrong logos.
  //
  // The handful of major fintechs/banks below use non-standard codes on
  // the public sources (e.g. PalmPay is "999991" there but "100033" in
  // your backend), so no automatic code match can find them. These were
  // checked by hand, one at a time, against your exact banks.php codes —
  // this is the deterministic, zero-guessing fix for those specific
  // banks. Anything not in this list and not code-matched simply has no
  // publicly available logo anywhere (true for the hundreds of small
  // MFBs in your list) and correctly falls back to the generic icon.
  static const Map<String, String> _verifiedOverrides = {
    '100033': 'https://nigerianbanks.xyz/logo/palmpay.png', // PalmPay
    '090267': 'https://nigerianbanks.xyz/logo/kuda-bank.png', // Kuda
    '090405':
        'https://nigerianbanks.xyz/logo/moniepoint-mfb-ng.png', // Moniepoint MFB
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
  // find the right bank is to try verifying against real banks until
  // ── Tier 1: the banks/fintechs that cover the overwhelming majority
  // of real Nigerian accounts. Raced first, with the fewest concurrent
  // requests, so the common case resolves fast and with the least
  // network contention.
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

  // ── Tier 2: less common but still real banks/fintechs. Only raced if
  // tier 1 comes up empty.
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
  // Firing every candidate bank at once (previously ~39 concurrent
  // requests) overwhelmed verify_account.php and caused legitimate
  // matches to time out inconsistently — the same account number could
  // come back with 1, 2, or 3 matches purely depending on network
  // timing. A bounded worker pool (see _tryAllPooled) keeps this many
  // requests in flight at once, and now that only genuinely-unresolved
  // candidates get retried (definitive rejections are never re-asked —
  // see BankVerificationRejected) and every request reuses one warm
  // connection (see _client) instead of paying a fresh handshake each
  // time, a slow response now genuinely reflects backend/network
  // conditions rather than connection setup overhead — so both a
  // higher concurrency limit and a shorter per-call timeout are safe
  // here. 15 is still comfortably below the 39-at-once that caused the
  // original problem.
  static const int _maxConcurrentVerifications = 15;
  static const int _maxDetectionAttempts = 2;
  static const Duration _detectionRetryDelay = Duration(milliseconds: 100);

  /// Strips spaces/hyphens and lowercases, so keyword matching doesn't
  /// silently miss a bank purely because of inconsistent spacing between
  /// the keyword and how banks.php happens to spell that bank's name
  /// (e.g. "ProvidusBank PLC" vs a keyword written as "providus bank" —
  /// without this normalization that match fails and the bank never
  /// even gets tried in the auto-detect race).
  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[\s\-]'), '');

  /// Builds the ordered, deduped candidate list to race for auto-detection:
  /// each priority keyword matched against the loaded bank list, in
  /// priority order, keeping only the first bank matched per keyword and
  /// skipping duplicates (some banks appear under more than one keyword).
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

  /// Fetches banks from your backend and resolves a logo for each using
  /// a strict, deterministic priority — no fuzzy matching anywhere:
  ///   1. banks.php's own `logo` field, if already set (most authoritative)
  ///   2. exact CODE match against the merged public sources
  ///   3. the hand-verified `_verifiedOverrides` map above
  ///   4. null → UI falls back to the generic bank icon
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
        // Some sources return a placeholder image for banks they don't
        // actually have a logo for — skip those so the bank falls
        // through to the override map or the generic icon instead of
        // showing a blank/placeholder badge.
        if (logoPath.endsWith(_placeholderLogoSuffix)) continue;

        logoByCode[code] = logoPath.startsWith('http')
            ? logoPath
            : '$pathPrefix$logoPath';
      }
    } catch (_) {
      // Network failure, bad JSON, whatever — logos are a nice-to-have,
      // never let this take down bank loading.
    }
    return logoByCode;
  }

  /// Resolves an account number + bank code to the account holder's name.
  /// Throws with a user-facing message on failure (invalid account, network, etc).
  /// Throws [TimeoutException] as-is if the request takes too long, so
  /// callers can show a "still slow? tap to retry" message instead of a
  /// long silent wait.
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
      // The backend responded normally and definitively said no — this
      // is not a network problem, so callers doing bank detection know
      // not to waste a retry on it.
      throw BankVerificationRejected(
        decoded['message'] ?? 'Could not verify account',
      );
    }
    return decoded['data']['account_name'];
  }

  /// Tries to identify which bank(s) an account number belongs to,
  /// without the user picking one first. The same 10-digit account
  /// number can be a valid, distinct account at more than one bank at
  /// once (e.g. a PalmPay wallet and an Opay wallet sharing the same
  /// number) — so this doesn't stop at the first success. It checks
  /// every candidate bank and returns every one that came back valid,
  /// in priority order (tier 1 — the common banks — before tier 2).
  ///
  /// Candidates are verified through a bounded worker pool (see
  /// [_tryAllPooled] and [_maxConcurrentVerifications]) rather than all
  /// at once — firing dozens of requests at verify_account.php
  /// simultaneously overloaded it and caused legitimate matches to time
  /// out inconsistently, which is why the same account number used to
  /// return a different number of matches on different runs. The pool
  /// keeps requests flowing continuously (no batch ever waits on a
  /// straggler), which is both faster and more reliable than fixed
  /// chunking. Unmatched candidates get up to [_maxDetectionAttempts]
  /// total passes, with a short pause between passes, so a transient
  /// slow response gets a fair chance to succeed instead of being
  /// crowded out permanently.
  ///
  /// Returns an empty list if nothing matches — callers should fall
  /// back to letting the user pick a bank manually from the full list
  /// at that point. Callers should let the user choose when more than
  /// one match comes back.
  ///
  /// This intentionally does NOT search the full 600+ bank list: doing
  /// so would mean firing hundreds of requests at verify_account.php
  /// for every account number typed, which is both slow and unfriendly
  /// to your backend.
  static Future<List<DetectedBank>> detectBanksForAccount({
    required String accountNumber,
    required List<BankOption> banks,
  }) async {
    final candidates = [
      ..._priorityBanksFor(banks, _tier1Keywords),
      ..._priorityBanksFor(banks, _tier2Keywords),
    ];
    if (candidates.isEmpty) return [];

    // Keyed by bank code so repeated attempts never double-count the
    // same match.
    final matched = <String, DetectedBank>{};
    // Banks that gave a definitive "not this bank" answer — excluded
    // from every future pass, since asking again can't change a
    // deterministic answer. Most of the ~39 candidates end up here on
    // the first pass (a real account only lives at 1-3 banks), so this
    // is what keeps retry passes small and fast instead of re-running
    // almost the whole candidate list a second time for no benefit.
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

    // Keep the priority ordering (tier 1 before tier 2, and each
    // tier's own keyword order) rather than arrival order, so the most
    // likely/common bank shows first if the caller presents a list.
    final order = {
      for (var i = 0; i < candidates.length; i++) candidates[i].code: i,
    };
    final results = matched.values.toList()
      ..sort((a, b) => order[a.bank.code]!.compareTo(order[b.bank.code]!));

    return results;
  }

  /// Verifies every candidate against [accountNumber] using a bounded
  /// worker pool (size [_maxConcurrentVerifications]) rather than fixed
  /// sequential batches.
  ///
  /// With fixed batches of N, a single slow candidate holds up starting
  /// the *next* N candidates even though the other N-1 slots in its own
  /// batch already finished and sat idle — with ~39 candidates that
  /// meant up to 7 sequential batches, each only as fast as its
  /// slowest member. A worker pool instead keeps a fixed number of
  /// requests continuously in flight: the moment any one candidate
  /// resolves (success, "not found", or timeout), that worker
  /// immediately starts the next candidate in line. No batch ever
  /// waits on a straggler, which is what makes this noticeably faster
  /// than the old chunked approach at the same concurrency limit.
  ///
  /// Also separates failures into two buckets, which matters for how
  /// [detectBanksForAccount] decides what's worth retrying:
  ///   - a [BankVerificationRejected] means the backend definitively
  ///     said "not this bank" — retrying it can never change the
  ///     answer, so it's tracked separately and never retried.
  ///   - any other failure (timeout, connection error, bad response)
  ///     means we genuinely don't know yet, so it stays a candidate
  ///     for the next pass.
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
            timeout: const Duration(seconds: 4),
          );
          results.add(DetectedBank(bank: bank, accountName: name));
        } on BankVerificationRejected {
          // Definitive "no" — never worth asking again.
          rejectedCodes.add(bank.code);
        } catch (_) {
          // Timeout or other network hiccup — genuinely unknown, leave
          // it out of rejectedCodes so it's eligible for a retry pass.
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
