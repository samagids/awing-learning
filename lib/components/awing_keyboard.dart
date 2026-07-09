import 'package:flutter/material.dart';
import 'package:awing_ai_learning/services/awing_keyboard_controller.dart';

/// The Awing on-screen keyboard.
///
/// Renders 5 rows:
///
///   [1] Tone row      — 5 diacritics + curly apostrophe (glottal stop)
///   [2] Top letters   — q w e ɛ r t y u i ɨ
///   [3] Middle letters— o ɔ p a s d f g h j
///   [4] Bottom letters— k l ə z x c v b n ŋ
///   [5] Function row  — Shift, m, Space (wide), Backspace, Enter
///
/// The layout intentionally mixes Awing extras (ɛ ɔ ə ɨ ŋ) into
/// phonetically-natural positions next to their closest QWERTY letter,
/// so users learn key placement by sound, not by memorization.
///
/// Tone row (row 1) uses a *dead-key* pattern: user taps a tone
/// diacritic to arm it (visible highlight), then the next vowel
/// typed comes out with that tone attached. Tapping the tone again
/// disarms it. Tapping any consonant while a tone is armed inserts
/// the consonant and clears the tone (forgiving default).
///
/// All state (armed tone, shift toggle, active target controller)
/// lives in [AwingKeyboardController]. This widget is stateless
/// wiring around that controller — it rebuilds automatically when
/// the controller notifies.
class AwingKeyboard extends StatelessWidget {
  const AwingKeyboard({super.key});

  // Each tone key is (display label, combining mark to insert).
  // We display pre-composed 'á à â ǎ' on the keys because standalone
  // combining marks (U+0301 etc.) attached to a dotted circle U+25CC
  // don't render cleanly on Android's default font — they came out as
  // empty boxes on Dr. Sama's screenshot 3. Pre-composed vowels
  // render everywhere and communicate the tone at a glance. The
  // insert operation still adds the pure combining mark to whatever
  // vowel the user types next.
  static const List<(String, String)> _toneKeys = [
    ('a', ''), // plain / clear-armed-tone
    ('á', '́'), // combining acute (high)
    ('à', '̀'), // combining grave (low)
    ('â', '̂'), // combining circumflex (falling)
    ('ǎ', '̌'), // combining caron (rising)
  ];
  static const String _glottal = '’'; // curly apostrophe

  static const List<String> _row1 = [
    'q', 'w', 'e', 'ɛ', 'r', 't', 'y', 'u', 'i', 'ɨ',
  ];
  static const List<String> _row2 = [
    'o', 'ɔ', 'p', 'a', 's', 'd', 'f', 'g', 'h', 'j',
  ];
  static const List<String> _row3 = [
    'k', 'l', 'ə', 'z', 'x', 'c', 'v', 'b', 'n', 'ŋ',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: AwingKeyboardController.instance,
      builder: (context, _) {
        final ctrl = AwingKeyboardController.instance;
        return Material(
          elevation: 8,
          color: theme.colorScheme.surface,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToneRow(context, ctrl),
                  const SizedBox(height: 4),
                  _buildLetterRow(context, _row1, ctrl),
                  const SizedBox(height: 4),
                  _buildLetterRow(context, _row2, ctrl),
                  const SizedBox(height: 4),
                  _buildLetterRow(context, _row3, ctrl),
                  const SizedBox(height: 4),
                  _buildFunctionRow(context, ctrl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToneRow(BuildContext context, AwingKeyboardController ctrl) {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          // 5 tone keys
          for (final (label, mark) in _toneKeys)
            Expanded(
              child: _ToneKey(
                display: label,
                armed: ctrl.armedTone == mark && mark.isNotEmpty,
                onTap: () {
                  if (mark.isEmpty) {
                    // "plain a" clears any armed tone
                    if (ctrl.armedTone != null) ctrl.armTone(ctrl.armedTone!);
                  } else {
                    ctrl.armTone(mark);
                  }
                },
              ),
            ),
          // Glottal stop
          Expanded(
            child: _ToneKey(
              display: _glottal,
              armed: false,
              onTap: () => ctrl.typeKey(_glottal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterRow(
    BuildContext context,
    List<String> keys,
    AwingKeyboardController ctrl,
  ) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          for (final k in keys)
            Expanded(
              child: _LetterKey(
                character: k,
                shifted: ctrl.shifted,
                highlighted: _isAwingSpecial(k),
                onTap: () => ctrl.typeKey(k),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFunctionRow(
    BuildContext context,
    AwingKeyboardController ctrl,
  ) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _FunctionKey(
              icon: Icons.arrow_upward,
              active: ctrl.shifted,
              onTap: ctrl.toggleShift,
              tooltip: 'Shift',
            ),
          ),
          Expanded(
            flex: 2,
            child: _LetterKey(
              character: 'm',
              shifted: ctrl.shifted,
              highlighted: false,
              onTap: () => ctrl.typeKey('m'),
            ),
          ),
          Expanded(
            flex: 8,
            child: _FunctionKey(
              label: 'space',
              onTap: ctrl.typeSpace,
              tooltip: 'Space',
            ),
          ),
          Expanded(
            flex: 3,
            child: _FunctionKey(
              icon: Icons.backspace_outlined,
              onTap: ctrl.backspace,
              tooltip: 'Backspace',
            ),
          ),
          Expanded(
            flex: 3,
            child: _FunctionKey(
              icon: Icons.keyboard_return,
              onTap: ctrl.typeEnter,
              tooltip: 'Enter',
            ),
          ),
        ],
      ),
    );
  }

  static bool _isAwingSpecial(String c) =>
      c == 'ɛ' || c == 'ɔ' || c == 'ə' || c == 'ɨ' || c == 'ŋ';
}

class _ToneKey extends StatelessWidget {
  final String display;
  final bool armed;
  final VoidCallback onTap;

  const _ToneKey({
    required this.display,
    required this.armed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = armed
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final fg = armed
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Center(
            child: Text(
              display,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: fg,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LetterKey extends StatelessWidget {
  final String character;
  final bool shifted;
  final bool highlighted;
  final VoidCallback onTap;

  const _LetterKey({
    required this.character,
    required this.shifted,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = highlighted
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final fg = highlighted
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Center(
            child: Text(
              shifted ? character.toUpperCase() : character,
              style: TextStyle(
                fontSize: 20,
                fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500,
                color: fg,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FunctionKey extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final bool active;
  final VoidCallback onTap;
  final String? tooltip;

  const _FunctionKey({
    this.icon,
    this.label,
    this.active = false,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = active
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHigh;
    final fg = active
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;
    Widget child = icon != null
        ? Icon(icon, size: 20, color: fg)
        : Text(
            label ?? '',
            style: TextStyle(
              fontSize: 13,
              color: fg,
              fontWeight: FontWeight.w500,
            ),
          );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip ?? '',
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
