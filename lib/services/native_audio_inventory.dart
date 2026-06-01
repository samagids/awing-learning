import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Singleton that loads `assets/native_audio_manifest.json` (built by
/// scripts/build_native_audio_manifest.py at Step 1d of build_and_run)
/// and answers per-(audioKey, recorder) "does a clip exist on disk"
/// questions.
///
/// The Dev Mode Record tab uses this to:
///   1. Show per-item badges for which recorders have a clip.
///   2. Power the "Missing from [active recorder]" filter so the dev
///      can quickly find words the current picker target hasn't
///      recorded yet (e.g. Joel's 12 untaped words after the recorder
///      picker shipped).
///
/// Architecture note: this is the BUILD-TIME snapshot of what shipped in
/// the AAB. It does NOT reflect Firestore /recordings submissions
/// uploaded since the last build — those need a rebuild to surface.
/// That's fine: the Record tab uses Firestore for cross-device sync
/// metadata (RecordingsService) and this inventory for "what's
/// actually shippable right now".
class NativeAudioInventory {
  NativeAudioInventory._();
  static final NativeAudioInventory instance = NativeAudioInventory._();

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// category -> audioKey -> {canonical: bool, kids: Set<String>}
  final Map<String, Map<String, _Entry>> _byCategory = {};

  /// Returns the set of recorder slugs that have a clip for [audioKey].
  /// May include the special string 'canonical' if Dr. Sama's recording
  /// is in audio/native/ for this key. Categories are searched in order
  /// (alphabet, vocabulary, sentences, stories) and the first match
  /// wins — typical audioKeys are category-unambiguous so this is fine.
  Set<String> recordersFor(String audioKey) {
    if (!_loaded) return const {};
    for (final cat in _byCategory.values) {
      final entry = cat[audioKey];
      if (entry == null) continue;
      final out = <String>{...entry.kids};
      if (entry.canonical) out.add('canonical');
      return out;
    }
    return const {};
  }

  /// True if the specified kid slug (joel/janelle/joyce/jadyne) has a
  /// clip for [audioKey] across any category. Used by the per-item
  /// status badge in the Record tab.
  bool hasKidRecording(String audioKey, String kidSlug) {
    if (!_loaded || kidSlug.isEmpty) return false;
    for (final cat in _byCategory.values) {
      final entry = cat[audioKey];
      if (entry == null) continue;
      return entry.kids.contains(kidSlug);
    }
    return false;
  }

  /// True if the canonical native/ tier has a clip for [audioKey] —
  /// i.e. Dr. Sama or Berlin recorded it. Used by the "Missing from
  /// [active recorder]" filter as the second-priority status (so the
  /// dev sees that the canonical reference is already covered even if
  /// the active kid isn't).
  bool hasCanonical(String audioKey) {
    if (!_loaded) return false;
    for (final cat in _byCategory.values) {
      final entry = cat[audioKey];
      if (entry == null) continue;
      return entry.canonical;
    }
    return false;
  }

  /// Which adult slug owns the canonical recording for [audioKey], or
  /// null if there's no canonical recording / no manifest entry records
  /// the owner. Used by the Record tab to show distinct S (Dr. Sama)
  /// and B (Berlin) dots instead of a single ambiguous "canonical
  /// exists" indicator. Possible return values:
  ///   - 'samagids' — Dr. Guidion Sama recorded it
  ///   - 'berlin'   — Berlin Sama recorded it
  ///   - null       — no canonical exists OR ownership not tracked
  ///                  (older recordings predating manifest v2)
  String? canonicalRecorderFor(String audioKey) {
    if (!_loaded) return null;
    for (final cat in _byCategory.values) {
      final entry = cat[audioKey];
      if (entry == null) continue;
      return entry.canonicalRecorder;
    }
    return null;
  }

  /// Load the manifest from rootBundle. Safe to call multiple times —
  /// subsequent calls are no-ops once loaded. On asset-missing /
  /// parse-error this stays in the un-loaded state and all queries
  /// return empty/false (i.e. the Record tab just doesn't render
  /// status badges — graceful degradation).
  Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle
          .loadString('assets/native_audio_manifest.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final cats = json['categories'] as Map<String, dynamic>? ?? const {};
      for (final entry in cats.entries) {
        final category = entry.key;
        final keys = entry.value as Map<String, dynamic>;
        final catMap = <String, _Entry>{};
        for (final k in keys.entries) {
          final info = k.value as Map<String, dynamic>;
          catMap[k.key] = _Entry(
            canonical: (info['canonical'] as bool?) ?? false,
            kids: (info['kids'] as List<dynamic>? ?? const [])
                .map((s) => s.toString())
                .toSet(),
            // Manifest v2+ only. Older manifests omit this field
            // entirely → null → "canonical owner unknown" treatment in
            // the badge UI (S dot greys-out, no B dot fills).
            canonicalRecorder: info['canonical_recorder'] as String?,
          );
        }
        _byCategory[category] = catMap;
      }
      _loaded = true;
    } catch (_) {
      // Asset missing or JSON malformed — leave _loaded=false.
      // Queries return empty so the Record tab UI just doesn't render
      // badges. No crash, no app-level impact beyond loss of the
      // status feature until the next build.
    }
  }
}

class _Entry {
  final bool canonical;
  final Set<String> kids;
  final String? canonicalRecorder; // 'samagids' | 'berlin' | null
  _Entry({
    required this.canonical,
    required this.kids,
    this.canonicalRecorder,
  });
}
