import 'package:awing_ai_learning/models/secret_hash.dart';

/// Human avatars must render black or brown.
///
/// A bare emoji such as U+1F9D2 (child) with no skin-tone modifier renders
/// yellow on most platforms and light-skinned on a few. Profiles created
/// before v1.24.4 stored those bare forms, so every path into a profile
/// upgrades them here rather than in a one-shot startup migration (the same
/// reasoning as the PIN hash upgrade above): local load, cloud restore and an
/// older device's write coming back down all pass through fromJson.
///
/// Non-human avatars (the tiger) and avatars that already carry a modifier are
/// returned unchanged.
String darkenHumanAvatar(String emoji) {
  if (emoji.isEmpty) return emoji;
  const modifiers = {0x1F3FB, 0x1F3FC, 0x1F3FD, 0x1F3FE, 0x1F3FF};
  if (emoji.runes.any(modifiers.contains)) return emoji;
  const toneable = {
    0x1F9D2, 0x1F467, 0x1F466, 0x1F9D1, 0x1F469, 0x1F468, // child/girl/boy/adult/woman/man
    0x1F9B8, 0x1F9B9, 0x1F9D9, 0x1F9DA, 0x1F9DD, // hero/villain/mage/fairy/elf
    0x1F476, 0x1F474, 0x1F475, 0x1F478, 0x1F934, // baby/old man/old woman/princess/prince
    0x1F64B, 0x1F646, 0x1F645, 0x1F481, 0x1F647, // gesture people
    0x1F44B, 0x1F44D, 0x1F44E, 0x1F44F, 0x1F64F, 0x1F590, 0x270B, 0x1F44C, // hands
  };
  final first = emoji.runes.first;
  if (!toneable.contains(first)) return emoji;
  return '$emoji\u{1F3FE}';
}

/// A single user profile within an email account.
/// One email can have multiple profiles (e.g. siblings sharing a tablet).
class UserProfile {
  final String id; // unique ID (timestamp-based)
  String displayName;
  String avatarEmoji; // kid-friendly emoji avatar
  String currentLevel; // 'beginner', 'medium', 'expert'
  bool beginnerUnlocked;
  bool mediumUnlocked;
  bool expertUnlocked;
  Map<String, bool> lessonsCompleted; // lessonId → completed
  Map<String, int> quizBestScores; // quizId → best score (0-100)
  int totalXP;

  /// Salted hash of this profile's PIN, or null when it has none.
  ///
  /// v1.23.6 (Session 65b) — was the PIN itself, in plain text, in a blob
  /// synced to Firestore. See [SecretHash].
  SecretHash? pinHash;

  /// True when this object was built from a legacy plaintext PIN and the
  /// hashed form has not been written back to disk yet. AuthService clears
  /// it by re-saving once at load.
  bool migratedLegacySecret = false;

  DateTime createdAt;
  DateTime lastActiveAt;

  UserProfile({
    required this.id,
    required this.displayName,
    this.avatarEmoji = '🧒🏾',
    this.currentLevel = 'beginner',
    this.beginnerUnlocked = true,
    this.mediumUnlocked = false,
    this.expertUnlocked = false,
    Map<String, bool>? lessonsCompleted,
    Map<String, int>? quizBestScores,
    this.totalXP = 0,
    this.pinHash,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  })  : lessonsCompleted = lessonsCompleted ?? {},
        quizBestScores = quizBestScores ?? {},
        createdAt = createdAt ?? DateTime.now(),
        lastActiveAt = lastActiveAt ?? DateTime.now();

  /// Whether this profile has a PIN set.
  bool get hasPin => pinHash != null;

  /// Set or clear the PIN. Anything shorter than 6 digits clears it, which
  /// matches what the callers already assumed.
  void setPin(String? pin) {
    pinHash = (pin != null && pin.length >= 6) ? SecretHash.create(pin) : null;
  }

  /// Verify a PIN attempt. Returns true if no PIN is set or the PIN matches.
  bool verifyPin(String attempt) {
    final h = pinHash;
    if (h == null) return true;
    return h.verify(attempt);
  }

  /// Beginner lessons the user must complete to unlock Medium
  static const beginnerLessonIds = [
    'beginner_alphabet',
    'beginner_vocabulary',
    'beginner_phrases',
    'beginner_tones',
    'beginner_numbers',
    'beginner_pronunciation',
  ];

  /// Beginner quiz IDs (20 quizzes, all must score >= 90%)
  static const beginnerQuizIds = [
    'beginner_quiz_1',
    'beginner_quiz_2',
    'beginner_quiz_3',
    'beginner_quiz_4',
    'beginner_quiz_5',
    'beginner_quiz_6',
    'beginner_quiz_7',
    'beginner_quiz_8',
    'beginner_quiz_9',
    'beginner_quiz_10',
    'beginner_quiz_11',
    'beginner_quiz_12',
    'beginner_quiz_13',
    'beginner_quiz_14',
    'beginner_quiz_15',
    'beginner_quiz_16',
    'beginner_quiz_17',
    'beginner_quiz_18',
    'beginner_quiz_19',
    'beginner_quiz_20',
  ];

  /// Medium lessons the user must complete to unlock Expert
  static const mediumLessonIds = [
    'medium_clusters',
    'medium_vowels',
    'medium_noun_classes',
    'medium_sentences',
    'medium_numbers',
  ];

  /// Medium quiz IDs (writing quiz must score >= 90%)
  static const mediumQuizIds = [
    'medium_writing_quiz',
  ];

  /// Expert lessons (for tracking completion)
  static const expertLessonIds = [
    'expert_tone_mastery',
    'expert_allophones',
    'expert_elision',
    'expert_conversation',
    'expert_numbers',
  ];

  /// Expert quiz IDs (20 quizzes, all must score >= 90%)
  static const expertQuizIds = [
    'expert_quiz_1',
    'expert_quiz_2',
    'expert_quiz_3',
    'expert_quiz_4',
    'expert_quiz_5',
    'expert_quiz_6',
    'expert_quiz_7',
    'expert_quiz_8',
    'expert_quiz_9',
    'expert_quiz_10',
    'expert_quiz_11',
    'expert_quiz_12',
    'expert_quiz_13',
    'expert_quiz_14',
    'expert_quiz_15',
    'expert_quiz_16',
    'expert_quiz_17',
    'expert_quiz_18',
    'expert_quiz_19',
    'expert_quiz_20',
  ];

  /// Check if all beginner lessons are done AND all 10 quizzes >= 90%
  bool get canUnlockMedium {
    final allLessons = beginnerLessonIds.every(
      (id) => lessonsCompleted[id] == true,
    );
    final allQuizzesPassed = beginnerQuizIds.every(
      (id) => (quizBestScores[id] ?? 0) >= 90,
    );
    return allLessons && allQuizzesPassed;
  }

  /// Check if all medium lessons are done AND writing quiz >= 90%
  bool get canUnlockExpert {
    final allLessons = mediumLessonIds.every(
      (id) => lessonsCompleted[id] == true,
    );
    final allQuizzesPassed = mediumQuizIds.every(
      (id) => (quizBestScores[id] ?? 0) >= 90,
    );
    return allLessons && allQuizzesPassed;
  }

  /// Count of beginner lessons completed
  int beginnerLessonsCompleted() =>
      beginnerLessonIds.where((id) => lessonsCompleted[id] == true).length;

  /// Count of beginner quizzes passed (>= 90%)
  int beginnerQuizzesPassed() =>
      beginnerQuizIds.where((id) => (quizBestScores[id] ?? 0) >= 90).length;

  /// Count of medium lessons completed
  int mediumLessonsCompleted() =>
      mediumLessonIds.where((id) => lessonsCompleted[id] == true).length;

  /// Count of medium quizzes passed (>= 90%)
  int mediumQuizzesPassed() =>
      mediumQuizIds.where((id) => (quizBestScores[id] ?? 0) >= 90).length;

  /// Count of expert lessons completed
  int expertLessonsCompleted() =>
      expertLessonIds.where((id) => lessonsCompleted[id] == true).length;

  /// Count of expert quizzes passed (>= 90%)
  int expertQuizzesPassed() =>
      expertQuizIds.where((id) => (quizBestScores[id] ?? 0) >= 90).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'avatarEmoji': avatarEmoji,
        'currentLevel': currentLevel,
        'beginnerUnlocked': beginnerUnlocked,
        'mediumUnlocked': mediumUnlocked,
        'expertUnlocked': expertUnlocked,
        'lessonsCompleted': lessonsCompleted,
        'quizBestScores': quizBestScores,
        'totalXP': totalXP,
        // The legacy plaintext 'pin' key is deliberately NOT written any
        // more. Emitting it "for compatibility" would put the PIN straight
        // back into Firestore and undo the whole point.
        'pinHash': pinHash?.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'lastActiveAt': lastActiveAt.toIso8601String(),
      };

  /// Builds a profile, upgrading a legacy plaintext `pin` if that is all the
  /// stored record has.
  ///
  /// The upgrade happens here rather than in a one-shot migration pass so
  /// that EVERY path into a profile — local load, cloud restore, an older
  /// device's write coming back down — is covered by the same code. A
  /// migration that only ran at startup would miss the restore path, which
  /// is exactly where the plaintext arrives from.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final legacy = _LegacySecret.read(json['pinHash'], json['pin']);
    final profile = UserProfile(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        displayName: json['displayName'] ?? 'Learner',
        avatarEmoji:
            darkenHumanAvatar(json['avatarEmoji'] ?? '🧒🏾'),
        currentLevel: json['currentLevel'] ?? 'beginner',
        beginnerUnlocked: json['beginnerUnlocked'] ?? true,
        mediumUnlocked: json['mediumUnlocked'] ?? false,
        expertUnlocked: json['expertUnlocked'] ?? false,
        lessonsCompleted: Map<String, bool>.from(json['lessonsCompleted'] ?? {}),
        quizBestScores: Map<String, int>.from(json['quizBestScores'] ?? {}),
        totalXP: json['totalXP'] ?? 0,
        pinHash: legacy.hash,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        lastActiveAt: json['lastActiveAt'] != null
            ? DateTime.parse(json['lastActiveAt'])
            : DateTime.now(),
    );
    profile.migratedLegacySecret = legacy.migrated;
    return profile;
  }
}

/// A parent/guardian who should receive activity reports.
///
/// v1.23.6 (Session 65a) — replaces the single `UserAccount.whatsappNumber`.
/// A family can list more than one (mother, father, guardian) and the same
/// number may legitimately appear on several devices, so nothing here is
/// treated as unique or as an identity.
class ParentContact {
  /// Free text, but seeded from [suggestedLabels] so most rows read
  /// "Mother" / "Father" without the parent typing anything.
  String label;

  /// Full international number, normalized to a leading `+` and digits.
  /// Stored for WhatsApp delivery; see [email] for what is used today.
  String? whatsappNumber;

  /// Where reports are actually delivered right now. WhatsApp delivery from
  /// the device was removed in v1.23.6 (it required WhatsApp to be installed
  /// on the child's device and could not send without a human pressing Send).
  String? email;

  /// Server-confirmed. A report is NEVER sent to an unconfirmed address —
  /// otherwise any signed-in user could use the report endpoint as a relay.
  bool emailConfirmed;

  ParentContact({
    this.label = 'Parent',
    this.whatsappNumber,
    this.email,
    this.emailConfirmed = false,
  });

  static const List<String> suggestedLabels = [
    'Mother',
    'Father',
    'Guardian',
    'Grandparent',
    'Teacher',
  ];

  bool get hasWhatsApp =>
      whatsappNumber != null && whatsappNumber!.trim().isNotEmpty;

  bool get hasEmail => email != null && email!.trim().isNotEmpty;

  /// True when this row can actually receive a report today.
  bool get canReceiveReports => hasEmail && emailConfirmed;

  bool get isBlank => !hasWhatsApp && !hasEmail;

  /// Digits only, for building a `wa.me` link.
  String get whatsappDigits =>
      (whatsappNumber ?? '').replaceAll(RegExp(r'[^\d]'), '');

  /// A number is usable for WhatsApp only if it carries a country code.
  /// Local-format numbers (e.g. 6xxxxxxxx for Cameroon) silently fail on
  /// wa.me, so they are rejected at entry rather than at send time.
  bool get hasPlausibleWhatsApp {
    final d = whatsappDigits;
    return hasWhatsApp && whatsappNumber!.trim().startsWith('+') &&
        d.length >= 8 && d.length <= 15;
  }

  ParentContact copy() => ParentContact(
        label: label,
        whatsappNumber: whatsappNumber,
        email: email,
        emailConfirmed: emailConfirmed,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'whatsappNumber': whatsappNumber,
        'email': email,
        'emailConfirmed': emailConfirmed,
      };

  factory ParentContact.fromJson(Map<String, dynamic> json) => ParentContact(
        label: (json['label'] as String?)?.trim().isNotEmpty == true
            ? (json['label'] as String).trim()
            : 'Parent',
        whatsappNumber: json['whatsappNumber'] as String?,
        email: json['email'] as String?,
        emailConfirmed: json['emailConfirmed'] == true,
      );
}

/// Represents a logged-in email account that can hold multiple user profiles.
/// Typically a parent registers, then creates child profiles under the account.
class UserAccount {
  final String email;
  final String authMethod; // 'email' or 'google'
  String? parentName; // Parent/guardian display name

  /// Parents/guardians who receive activity reports. v1.23.6 replaced the
  /// single `whatsappNumber` string with this list; `whatsappNumber` survives
  /// below as a read/write shim so older code paths and older installs that
  /// read the same synced document keep working.
  List<ParentContact> parentContacts;

  bool sendQuizNotifications; // Report after each quiz
  bool sendWeeklySummary; // Weekly activity summary
  /// Salted hash of the parent PIN that guards sign-out, profile deletion
  /// and Parent Settings. v1.23.6 — was plain text. See [SecretHash].
  SecretHash? accountPinHash;

  /// Set when this account, or any of its profiles, was loaded from a legacy
  /// plaintext PIN. AuthService re-saves once to replace it on disk, which
  /// also pushes the hashed form up on the next cloud sync.
  bool migratedLegacySecret = false;

  List<UserProfile> profiles;
  DateTime createdAt;

  UserAccount({
    required this.email,
    this.authMethod = 'email',
    this.parentName,
    List<ParentContact>? parentContacts,
    String? whatsappNumber,
    this.sendQuizNotifications = true,
    this.sendWeeklySummary = true,
    this.accountPinHash,
    List<UserProfile>? profiles,
    DateTime? createdAt,
  })  : parentContacts = parentContacts ??
            (whatsappNumber != null && whatsappNumber.trim().isNotEmpty
                ? [ParentContact(label: 'Parent', whatsappNumber: whatsappNumber)]
                : <ParentContact>[]),
        profiles = profiles ?? [],
        createdAt = createdAt ?? DateTime.now();

  /// Whether this account has a parent PIN set.
  bool get hasAccountPin => accountPinHash != null;

  /// Set or clear the parent PIN. Anything shorter than 6 digits clears it.
  void setAccountPin(String? pin) {
    accountPinHash =
        (pin != null && pin.length >= 6) ? SecretHash.create(pin) : null;
  }

  /// Verify the account-level PIN. Returns true if no PIN is set or correct.
  bool verifyAccountPin(String attempt) {
    final h = accountPinHash;
    if (h == null) return true;
    return h.verify(attempt);
  }

  bool get isDeveloper => email.toLowerCase() == 'samagids@gmail.com';

  /// Maximum contacts a family may list. Also the server-side recipient cap.
  static const int maxParentContacts = 3;

  bool get hasWhatsApp => parentContacts.any((c) => c.hasWhatsApp);

  /// Contacts that a report can actually be delivered to today.
  List<ParentContact> get deliverableContacts =>
      parentContacts.where((c) => c.canReceiveReports).toList();

  bool get canDeliverReports => deliverableContacts.isNotEmpty;

  /// Backwards-compatible view of the first WhatsApp number.
  ///
  /// Kept so that (a) older code paths still compile and (b) `toJson` can keep
  /// emitting the legacy key for installs still on <= 1.23.5 that read the same
  /// `users/{emailKey}/data/accounts` document.
  String? get whatsappNumber {
    for (final c in parentContacts) {
      if (c.hasWhatsApp) return c.whatsappNumber;
    }
    return null;
  }

  set whatsappNumber(String? value) {
    final v = value?.trim();
    if (v == null || v.isEmpty) {
      parentContacts.removeWhere((c) => c.hasWhatsApp && !c.hasEmail);
      for (final c in parentContacts) {
        c.whatsappNumber = null;
      }
      parentContacts.removeWhere((c) => c.isBlank);
      return;
    }
    for (final c in parentContacts) {
      if (c.hasWhatsApp) {
        c.whatsappNumber = v;
        return;
      }
    }
    if (parentContacts.isEmpty) {
      parentContacts.add(ParentContact(label: 'Parent', whatsappNumber: v));
    } else {
      parentContacts.first.whatsappNumber = v;
    }
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'authMethod': authMethod,
        'parentName': parentName,
        'parentContacts': parentContacts.map((c) => c.toJson()).toList(),
        // Legacy mirror: installs on <= 1.23.5 read this key from the same
        // synced document. Dropping it would blank their notification setup.
        'whatsappNumber': whatsappNumber,
        'sendQuizNotifications': sendQuizNotifications,
        'sendWeeklySummary': sendWeeklySummary,
        // As with the profile PIN: the legacy plaintext 'accountPin' key is
        // never written again.
        'accountPinHash': accountPinHash?.toJson(),
        'profiles': profiles.map((p) => p.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    final legacy =
        _LegacySecret.read(json['accountPinHash'], json['accountPin']);
    final account = UserAccount(
        email: json['email'] ?? '',
        authMethod: json['authMethod'] ?? 'email',
        parentName: json['parentName'],
        parentContacts: _parentContactsFromJson(json),
        sendQuizNotifications: json['sendQuizNotifications'] ?? true,
        sendWeeklySummary: json['sendWeeklySummary'] ?? true,
        accountPinHash: legacy.hash,
        profiles: (json['profiles'] as List<dynamic>?)
                ?.map((p) => UserProfile.fromJson(p))
                .toList() ??
            [],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
    );
    // Flag the account when its own PIN, or any child's, arrived as plain
    // text — one re-save then clears every one of them at once.
    account.migratedLegacySecret = legacy.migrated ||
        account.profiles.any((p) => p.migratedLegacySecret);
    return account;
  }

  /// Reads the contact list, migrating installs that only ever stored the
  /// single legacy `whatsappNumber` string.
  ///
  /// The legacy key is only consulted when no list is present, so a device
  /// that has already migrated is never re-seeded from its own mirror.
  static List<ParentContact> _parentContactsFromJson(Map<String, dynamic> json) {
    final raw = json['parentContacts'];
    if (raw is List) {
      final out = <ParentContact>[];
      for (final item in raw) {
        if (item is Map) {
          final c = ParentContact.fromJson(Map<String, dynamic>.from(item));
          if (!c.isBlank) out.add(c);
        }
      }
      if (out.isNotEmpty) return out;
      // An explicitly empty list means the parent removed every contact.
      if (raw.isEmpty) return <ParentContact>[];
    }
    final legacy = json['whatsappNumber'];
    if (legacy is String && legacy.trim().isNotEmpty) {
      return [ParentContact(label: 'Parent', whatsappNumber: legacy.trim())];
    }
    return <ParentContact>[];
  }
}

/// Result of reading a PIN field that may be in either the current hashed
/// form or the pre-1.23.6 plaintext form.
class _LegacySecret {
  final SecretHash? hash;

  /// True when [hash] was just derived from a plaintext value that is still
  /// sitting on disk, so the caller must re-save to remove it.
  final bool migrated;

  const _LegacySecret(this.hash, this.migrated);

  /// [stored] is the `*PinHash` map; [legacyPlaintext] is the old string key.
  ///
  /// A usable hash always wins, so a record that somehow carries both is
  /// never downgraded to the plaintext. A plaintext shorter than 6 digits is
  /// discarded rather than hashed — the setters never accepted one, so it can
  /// only be junk, and hashing it would preserve a PIN nothing can satisfy.
  static _LegacySecret read(Object? stored, Object? legacyPlaintext) {
    final parsed = SecretHash.fromJson(stored);
    if (parsed != null) return _LegacySecret(parsed, false);
    if (legacyPlaintext is String && legacyPlaintext.length >= 6) {
      return _LegacySecret(SecretHash.create(legacyPlaintext), true);
    }
    // Nothing usable. If a plaintext key was present but unusable we still
    // report a migration so the bad value gets cleared from disk.
    return _LegacySecret(
        null, legacyPlaintext is String && legacyPlaintext.isNotEmpty);
  }
}
