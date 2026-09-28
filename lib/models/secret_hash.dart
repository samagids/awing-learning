import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// A salted, slow hash of a short secret — used for parent and child PINs.
///
/// v1.23.6 (Session 65b). These were previously stored as plain text, and the
/// whole account blob is synced to `users/{emailKey}/data/accounts`, so every
/// family's PIN sat readable in Firestore. PINs get reused as phone-unlock
/// codes, so that was the most sensitive thing the app held.
///
/// ## What this does and does not buy
///
/// A 6-digit PIN has a million possibilities and must be verifiable on a cheap
/// tablet in well under a second, so **no client-side scheme can make it
/// brute-force-proof** against someone holding the stored hash. Pretending
/// otherwise would be the same mistake as the old "message sent" flag.
///
/// What it does buy, and why it is still worth doing:
///
///  * Nothing readable. A database dump, a console screenshot, a support
///    export or a mis-scoped security rule no longer hands anyone a working
///    PIN, which is the realistic exposure.
///  * No bulk attack. The per-secret salt means a million-row dump cannot be
///    cracked with one pass of precomputed hashes; each account costs its own
///    full search.
///  * A tunable floor. [defaultIterations] is stored *with* each hash, so it
///    can be raised later and old hashes keep verifying.
///
/// ## Why PBKDF2 and not something stronger
///
/// scrypt and Argon2 are better, but neither ships with Flutter, and this runs
/// synchronously inside button handlers on low-end Android tablets. PBKDF2 on
/// the pure-Dart `crypto` SHA-256 keeps verification to roughly a tenth of a
/// second on a slow device while costing an attacker a full derivation per
/// guess.
class SecretHash {
  /// Only value currently written. Stored so a future algorithm change can be
  /// detected rather than silently mis-verified.
  static const String algorithmPbkdf2Sha256 = 'pbkdf2-sha256';

  /// Tuned for a synchronous check on a low-end device. Raising this does not
  /// invalidate existing hashes — each one carries the count it was made with.
  static const int defaultIterations = 12000;

  static const int _saltBytes = 16;
  static const int _keyBytes = 32;

  final String algorithm;
  final int iterations;
  final Uint8List salt;
  final Uint8List hash;

  const SecretHash._({
    required this.algorithm,
    required this.iterations,
    required this.salt,
    required this.hash,
  });

  /// Derive a hash for [secret] with a fresh random salt.
  ///
  /// Returns null for an empty secret so "no PIN" has exactly one
  /// representation and can never be confused with "PIN of empty string".
  static SecretHash? create(String? secret, {int? iterations}) {
    if (secret == null || secret.isEmpty) return null;
    final rounds = iterations ?? defaultIterations;
    final salt = _randomBytes(_saltBytes);
    return SecretHash._(
      algorithm: algorithmPbkdf2Sha256,
      iterations: rounds,
      salt: salt,
      hash: _pbkdf2(
        password: utf8.encode(secret),
        salt: salt,
        iterations: rounds,
        keyLength: _keyBytes,
      ),
    );
  }

  /// Whether [attempt] produces this hash.
  ///
  /// An unrecognised algorithm returns false rather than falling back to a
  /// weaker comparison — a stored hash we cannot evaluate must never be
  /// treated as a match.
  bool verify(String? attempt) {
    if (attempt == null || attempt.isEmpty) return false;
    if (algorithm != algorithmPbkdf2Sha256) return false;
    final candidate = _pbkdf2(
      password: utf8.encode(attempt),
      salt: salt,
      iterations: iterations,
      keyLength: hash.length,
    );
    return _constantTimeEquals(candidate, hash);
  }

  /// True when this hash was made with fewer rounds than we now use, so the
  /// caller can silently re-derive it the next time the secret is known.
  bool get needsRehash =>
      algorithm != algorithmPbkdf2Sha256 || iterations < defaultIterations;

  Map<String, dynamic> toJson() => {
        'alg': algorithm,
        'iter': iterations,
        'salt': base64Encode(salt),
        'hash': base64Encode(hash),
      };

  /// Parse a stored hash. Returns null for anything malformed — a corrupt
  /// record becomes "no PIN", which is recoverable, rather than an
  /// unverifiable PIN, which locks the parent out permanently.
  static SecretHash? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final alg = raw['alg'];
    final iter = raw['iter'];
    final salt = raw['salt'];
    final hash = raw['hash'];
    if (alg is! String || iter is! int || salt is! String || hash is! String) {
      return null;
    }
    if (iter < 1 || iter > 2000000) return null;
    try {
      final saltBytes = base64Decode(salt);
      final hashBytes = base64Decode(hash);
      if (saltBytes.isEmpty || hashBytes.isEmpty) return null;
      return SecretHash._(
        algorithm: alg,
        iterations: iter,
        salt: Uint8List.fromList(saltBytes),
        hash: Uint8List.fromList(hashBytes),
      );
    } catch (_) {
      return null;
    }
  }

  // ==================== Internals ====================

  static Uint8List _randomBytes(int count) {
    // Random.secure() is backed by the platform CSPRNG. It can throw if the
    // platform has none; there is no safe silent fallback, so let it throw
    // rather than mint a predictable salt.
    final rng = Random.secure();
    final out = Uint8List(count);
    for (var i = 0; i < count; i++) {
      out[i] = rng.nextInt(256);
    }
    return out;
  }

  /// PBKDF2 (RFC 2898 / RFC 8018) with HMAC-SHA256 as the PRF.
  ///
  ///     DK = T(1) || T(2) || ... || T(l)
  ///     T(i) = U(1) ^ U(2) ^ ... ^ U(c)
  ///     U(1) = PRF(password, salt || INT_BE32(i))
  ///     U(j) = PRF(password, U(j-1))
  static Uint8List _pbkdf2({
    required List<int> password,
    required Uint8List salt,
    required int iterations,
    required int keyLength,
  }) {
    final prf = Hmac(sha256, password);
    const hLen = 32;
    final blocks = (keyLength + hLen - 1) ~/ hLen;
    final out = Uint8List(blocks * hLen);

    // salt || INT_BE32(blockIndex); the counter is big-endian and 1-based.
    final seed = Uint8List(salt.length + 4);
    seed.setRange(0, salt.length, salt);

    for (var block = 1; block <= blocks; block++) {
      seed[salt.length] = (block >> 24) & 0xff;
      seed[salt.length + 1] = (block >> 16) & 0xff;
      seed[salt.length + 2] = (block >> 8) & 0xff;
      seed[salt.length + 3] = block & 0xff;

      var u = Uint8List.fromList(prf.convert(seed).bytes);
      final accumulator = Uint8List.fromList(u);

      for (var round = 1; round < iterations; round++) {
        u = Uint8List.fromList(prf.convert(u).bytes);
        for (var i = 0; i < hLen; i++) {
          accumulator[i] ^= u[i];
        }
      }
      out.setRange((block - 1) * hLen, block * hLen, accumulator);
    }
    return Uint8List.sublistView(out, 0, keyLength);
  }

  /// Compares without an early return, so timing cannot reveal how much of a
  /// guess was right.
  static bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
