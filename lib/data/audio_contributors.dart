/// Audio contributors to the Awing AI Learning app.
///
/// Shown on the About screen so every native speaker who has lent
/// their voice to the app is credited. Two tiers:
///
///   - [_coreContributors]: founding voices (Dr. Sama + family). They
///     recorded the base audio for the app's 6 character voices via
///     the Record tab. Hard-coded; edit manually if a family member
///     joins.
///
///   - [approvedContributors]: external contributors whose audio
///     submissions were approved and applied via the Contribute tab.
///     Auto-maintained by `scripts/apply_contributions.py` -- when a
///     pronunciationFix or newWord contribution with audio is applied,
///     the submitter's profileName is appended here (deduped).
///     Manual edits OK, but the script will re-add names if they get
///     removed accidentally.

/// Founding native voices, ordered: developer first, then family.
const List<String> _coreContributors = [
  'Dr. Guidion Sama',
  'Joel Sama',
  'Joyce Sama',
  'Jadyne Sama',
  'Janelle Sama',
];

/// Approved external audio contributors.
/// AUTO-MAINTAINED by scripts/apply_contributions.py during build.
/// Sort order: insertion order (first approval first). Don't sort
/// alphabetically -- chronological credit order tells a small story.
const List<String> approvedContributors = [
  'Apongnde Emmanuel',
  'Berlin Sama',
  'Dr. Richard Alombah',
  'Juliette Mandah',
  // 'Sama Guidion' was auto-added here and credited Dr. Sama a second
  // time, family-name-first, as if he were a separate contributor. The
  // skiplist in apply_contributions.py held 'guidion sama' but not the
  // reversed 'sama guidion'. Both that skiplist and the dedup below now
  // compare the SET of name tokens, so word order and titles no longer
  // matter. Do not re-add.
  'Claire Nkehsera',  // auto-added by apply_contributions.py
  'Fosoh Collette Nkenyi',  // auto-added by apply_contributions.py
  // Was auto-added as 'Monto’oh' — the name of her device profile, not a
  // person. She signs in with Apple, which surrenders a display name only
  // on the very first authorization, so googleDisplayName was null on all
  // 13 of her recordings and the client fell back to profileName. Real
  // name confirmed by Dr. Sama; apply_contributions.py now aliases that
  // profile to this entry, so it will not be re-added as a duplicate.
  'Dr. Frida Fozoh',
];

/// Honorifics ignored when deciding whether two spellings name the same
/// person.
const Set<String> _nameTitles = {
  'dr', 'mr', 'mrs', 'ms', 'prof', 'rev', 'sir', 'madam',
};

/// Order- and title-insensitive identity for a person's name.
///
/// This guard previously compared `name.toLowerCase().trim()`, which is
/// why 'Sama Guidion' sat on the About screen next to 'Dr. Guidion Sama'
/// as though they were two people. Comparing the SET of name tokens
/// catches any word order and any honorific. 'Berlin Sama' and 'Joel
/// Sama' stay distinct, because only the shared surname overlaps and
/// never the whole set.
String _nameFingerprint(String name) {
  final tokens = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty && !_nameTitles.contains(t))
      .toList()
    ..sort();
  return tokens.join(' ');
}

/// Full ordered list rendered on the About screen. Core voices first,
/// then approved contributors, deduped so the same person cannot appear
/// twice under a different word order or title.
List<String> get audioContributors {
  final seen = <String>{};
  final out = <String>[];
  for (final name in [..._coreContributors, ...approvedContributors]) {
    final fp = _nameFingerprint(name);
    if (fp.isEmpty) continue;
    if (seen.add(fp)) out.add(name);
  }
  return out;
}
