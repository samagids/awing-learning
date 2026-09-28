import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:awing_ai_learning/models/secret_hash.dart';
import 'package:awing_ai_learning/models/user_model.dart';

/// v1.23.6 (Session 65b) — parent and child PINs stopped being stored in
/// plain text. These tests pin down the two things that would be quietly
/// catastrophic to get wrong: a KDF that does not match the standard (so
/// hashes are not what we think they are), and a migration that drops or
/// mangles the PINs families already have.
void main() {
  group('PBKDF2-HMAC-SHA256 matches the standard', () {
    // Vectors produced with Python's hashlib.pbkdf2_hmac('sha256', ...).
    // If these fail, the Dart transcription drifted from RFC 8018 — check
    // the counter's big-endian encoding and the XOR accumulation first.
    test('known vector: "password" / "salt" / 4096 rounds', () {
      final stored = SecretHash.fromJson({
        'alg': 'pbkdf2-sha256',
        'iter': 4096,
        'salt': base64Encode(utf8.encode('salt')),
        'hash': 'xeR41ZKIyEGqUw22hFxMjZYok6ABzk4RpJY4c6qYE0o=',
      });
      expect(stored, isNotNull);
      expect(stored!.verify('password'), isTrue);
      expect(stored.verify('Password'), isFalse);
    });

    test('known vector: a real 6-digit PIN / 1000 rounds', () {
      final stored = SecretHash.fromJson({
        'alg': 'pbkdf2-sha256',
        'iter': 1000,
        'salt': 'QXdpbmdGaXhlZFNhbHQxNg==', // "AwingFixedSalt16"
        'hash': '50DUmjxq7wIsDKAcu5bi129EhP3nzekJbGJgyKmRlok=',
      });
      expect(stored, isNotNull);
      expect(stored!.verify('482913'), isTrue);
      expect(stored.verify('482914'), isFalse);
    });
  });

  group('SecretHash', () {
    test('verifies the right secret and rejects near misses', () {
      final h = SecretHash.create('123456')!;
      expect(h.verify('123456'), isTrue);
      expect(h.verify('123455'), isFalse);
      expect(h.verify('1234567'), isFalse);
      expect(h.verify(''), isFalse);
      expect(h.verify(null), isFalse);
    });

    test('salts every hash, so the same PIN stores differently', () {
      final a = SecretHash.create('123456')!;
      final b = SecretHash.create('123456')!;
      expect(base64Encode(a.salt), isNot(equals(base64Encode(b.salt))));
      expect(base64Encode(a.hash), isNot(equals(base64Encode(b.hash))));
      // ...and both still verify.
      expect(a.verify('123456'), isTrue);
      expect(b.verify('123456'), isTrue);
    });

    test('an empty secret is "no PIN", not a PIN of ""', () {
      expect(SecretHash.create(null), isNull);
      expect(SecretHash.create(''), isNull);
    });

    test('survives a JSON round trip', () {
      final h = SecretHash.create('654321')!;
      final back = SecretHash.fromJson(jsonDecode(jsonEncode(h.toJson())));
      expect(back, isNotNull);
      expect(back!.verify('654321'), isTrue);
      expect(back.iterations, equals(h.iterations));
    });

    test('malformed records become null rather than an unverifiable PIN', () {
      expect(SecretHash.fromJson(null), isNull);
      expect(SecretHash.fromJson('nonsense'), isNull);
      expect(SecretHash.fromJson({'alg': 'pbkdf2-sha256'}), isNull);
      expect(
        SecretHash.fromJson(
            {'alg': 'pbkdf2-sha256', 'iter': 0, 'salt': 'AA==', 'hash': 'AA=='}),
        isNull,
      );
      expect(
        SecretHash.fromJson({
          'alg': 'pbkdf2-sha256',
          'iter': 1000,
          'salt': '!!not base64!!',
          'hash': 'AA=='
        }),
        isNull,
      );
    });

    test('an unknown algorithm never verifies', () {
      final h = SecretHash.fromJson({
        'alg': 'rot13',
        'iter': 1000,
        'salt': 'AAAAAAAAAAAAAAAAAAAAAA==',
        'hash': 'AAAAAAAAAAAAAAAAAAAAAA==',
      });
      expect(h, isNotNull);
      expect(h!.verify('anything'), isFalse);
    });
  });

  group('no plaintext reaches storage', () {
    test('UserAccount.toJson emits neither accountPin nor passwordHash', () {
      final a = UserAccount(email: 'p@example.com')..setAccountPin('998877');
      final json = a.toJson();
      expect(json.containsKey('accountPin'), isFalse);
      expect(json.containsKey('passwordHash'), isFalse);
      expect(jsonEncode(json).contains('998877'), isFalse,
          reason: 'the PIN itself must not appear anywhere in the record');
    });

    test('UserProfile.toJson emits no plaintext pin', () {
      final p = UserProfile(id: '1', displayName: 'Kid')..setPin('112233');
      final json = p.toJson();
      expect(json.containsKey('pin'), isFalse);
      expect(jsonEncode(json).contains('112233'), isFalse);
    });

    test('a PIN survives a full save/load cycle', () {
      final a = UserAccount(email: 'p@example.com')..setAccountPin('445566');
      a.profiles.add(UserProfile(id: '1', displayName: 'Kid')..setPin('778899'));

      final back = UserAccount.fromJson(
          jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>);

      expect(back.hasAccountPin, isTrue);
      expect(back.verifyAccountPin('445566'), isTrue);
      expect(back.verifyAccountPin('445567'), isFalse);
      expect(back.profiles.single.verifyPin('778899'), isTrue);
      expect(back.migratedLegacySecret, isFalse,
          reason: 'already-hashed records must not be flagged for migration');
    });
  });

  group('migration from pre-1.23.6 plaintext', () {
    Map<String, dynamic> legacyAccount({String? accountPin, String? childPin}) => {
          'email': 'p@example.com',
          'authMethod': 'google',
          'accountPin': accountPin,
          'passwordHash': 'left over from an old build',
          'profiles': [
            {'id': '1', 'displayName': 'Kid', 'pin': childPin},
          ],
        };

    test('an existing parent PIN keeps working', () {
      final a = UserAccount.fromJson(legacyAccount(accountPin: '246813'));
      expect(a.hasAccountPin, isTrue);
      expect(a.verifyAccountPin('246813'), isTrue,
          reason: 'upgrading must not lock a parent out of their own PIN');
      expect(a.verifyAccountPin('000000'), isFalse);
    });

    test('an existing child PIN keeps working', () {
      final a = UserAccount.fromJson(legacyAccount(childPin: '135791'));
      expect(a.profiles.single.verifyPin('135791'), isTrue);
    });

    test('the migration flag is raised, then the plaintext is gone', () {
      final a = UserAccount.fromJson(legacyAccount(accountPin: '246813'));
      expect(a.migratedLegacySecret, isTrue,
          reason: 'AuthService relies on this to trigger the one re-save');

      // What the re-save writes must no longer contain the readable PIN.
      final rewritten = jsonEncode(a.toJson());
      expect(rewritten.contains('246813'), isFalse);
      expect(rewritten.contains('accountPin"'), isFalse);

      // ...and reloading that has nothing left to migrate.
      final reloaded =
          UserAccount.fromJson(jsonDecode(rewritten) as Map<String, dynamic>);
      expect(reloaded.migratedLegacySecret, isFalse);
      expect(reloaded.verifyAccountPin('246813'), isTrue);
    });

    test("a child's plaintext alone flags the account", () {
      final a = UserAccount.fromJson(legacyAccount(childPin: '135791'));
      expect(a.migratedLegacySecret, isTrue);
    });

    test('an account with no PIN at all is not flagged', () {
      final a = UserAccount.fromJson(legacyAccount());
      expect(a.migratedLegacySecret, isFalse);
      expect(a.hasAccountPin, isFalse);
      expect(a.verifyAccountPin('anything'), isTrue,
          reason: 'no PIN set means the gate is open, as before');
    });

    test('a hashed record is never downgraded to a stale plaintext', () {
      final hashed = SecretHash.create('999999')!;
      final a = UserAccount.fromJson({
        'email': 'p@example.com',
        'accountPinHash': hashed.toJson(),
        'accountPin': '111111', // stale leftover from an older device
        'profiles': const [],
      });
      expect(a.verifyAccountPin('999999'), isTrue);
      expect(a.verifyAccountPin('111111'), isFalse);
      expect(a.migratedLegacySecret, isFalse);
    });

    test('a junk plaintext is discarded, not hashed into an unusable PIN', () {
      final a = UserAccount.fromJson(legacyAccount(accountPin: '12'));
      expect(a.hasAccountPin, isFalse,
          reason: 'a 2-digit value was never a valid PIN; keeping it would '
              'leave a gate nothing can open');
      expect(a.migratedLegacySecret, isTrue,
          reason: 'the junk still has to be cleared from disk');
    });
  });
}
