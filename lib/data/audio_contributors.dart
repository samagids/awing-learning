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
];

/// Full ordered list rendered on the About screen. Core voices first,
/// then approved contributors. Deduped by case-insensitive match so a
/// core name accidentally re-added via the contribution flow doesn't
/// appear twice.
List<String> get audioContributors {
  final seen = <String>{};
  final out = <String>[];
  for (final name in _coreContributors) {
    if (seen.add(name.toLowerCase().trim())) out.add(name);
  }
  for (final name in approvedContributors) {
    if (seen.add(name.toLowerCase().trim())) out.add(name);
  }
  return out;
}
