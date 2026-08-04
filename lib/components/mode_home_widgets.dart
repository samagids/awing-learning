import 'package:flutter/material.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';

/// Shared widgets used by all three mode home screens (Beginner, Medium,
/// Expert). Extracted in Session 64 (task H4) so that a style change lands
/// in one file instead of three — the previous private `_LessonTile`,
/// `_VoiceOption`, `_KidVoicePicker`, and `_KidChip` classes had drifted
/// slightly between homes and any future edit was a 3-file chore.

/// Section header used to break up the flat lesson-tile list into
/// scannable groups (Daily / Learn / Practice / Test & Play). Session 64
/// (H1): kids were seeing 12-13 tiles in one flat scroll — Miller's
/// ~7-item working-memory guideline was well exceeded. Sectioning
/// doesn't reduce the tile count but it lets the eye jump to the
/// section a kid wants rather than reading every subtitle.
class SectionHeader extends StatelessWidget {
  final String label;

  const SectionHeader(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6, left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

/// Big rounded card tile with a coloured circle-icon on the left, title,
/// subtitle, and chevron. Used by every "choose a lesson" list.
class LessonTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const LessonTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: color,
          radius: 28,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// Toggle chip used by the "Voice: Man/Woman" (or Boy/Girl) row on each
/// mode home. Selected state uses the mode's accent color as background;
/// unselected is transparent with a grey outline.
class VoiceOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const VoiceOption({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              // Session 64 (H10): bumped 14 → 15 for kid-facing text.
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kid-voice picker card. Lets the user pick whose recorded voice they
/// want to hear (Joel / Joyce / Janelle / Jadyne / etc.) for the current
/// gender-preset character. Session 64 (H3): now surfaces on all three
/// mode homes, not just Beginner.
class KidVoicePicker extends StatelessWidget {
  /// The current male/female character selection — used to look up the
  /// list of available kid voices.
  final bool isFemaleVoice;

  /// Currently-active kid voice slug, or null for "My voice" (the mode's
  /// default TTS character voice).
  final String? activeKid;

  final ValueChanged<String?> onChanged;

  /// Accent color, matches the mode's identity (green / orange / red).
  final Color accentColor;

  const KidVoicePicker({
    super.key,
    required this.isFemaleVoice,
    required this.activeKid,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final character = isFemaleVoice ? 'girl' : 'boy';
    final kids =
        PronunciationService.kidVoicesByCharacter[character] ?? const [];

    return Card(
      // Card background subtly matches the mode's accent tint.
      color: Color.alphaBlend(
        accentColor.withOpacity(0.08),
        Colors.white,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.person_pin_circle_outlined,
              color: accentColor,
            ),
            const SizedBox(width: 12),
            const Text(
              'Whose voice?',
              // Session 64 (H10): bumped 14 → 15 for kid-facing text.
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true, // keep the "My voice" chip visible on RTL
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _KidChip(
                      label: 'My voice',
                      selected: activeKid == null,
                      accent: accentColor,
                      onTap: () => onChanged(null),
                    ),
                    for (final kid in kids) ...[
                      const SizedBox(width: 6),
                      _KidChip(
                        label: PronunciationService.kidDisplayNames[kid] ??
                            kid,
                        selected: activeKid == kid,
                        accent: accentColor,
                        onTap: () => onChanged(kid),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small pill used inside KidVoicePicker. Private to this file.
class _KidChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _KidChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accent : Colors.grey.shade400,
            width: 1.6,
          ),
        ),
        child: Text(
          label,
          // Session 64 (H10): bumped 12 → 14 for kid-facing text.
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
