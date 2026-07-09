import 'package:flutter/material.dart';

/// Singleton that tracks which Awing text field is currently being
/// typed into, so a single [AwingKeyboardOverlay] at the app root can
/// route key presses to the right controller without every screen
/// wiring its own overlay.
///
/// Lifecycle:
///   AwingTextField gains focus  → [bind]   → keyboard slides up
///   AwingTextField loses focus  → [unbind] → keyboard slides down
///
/// Only ONE Awing field can hold focus at a time. If the user taps
/// from one Awing field to another, [bind] is called with the new
/// controller and the keyboard swaps its target without hiding first.
///
/// Non-Awing fields never touch this manager — they use the system
/// keyboard as usual.
class AwingKeyboardController extends ChangeNotifier {
  AwingKeyboardController._();
  static final AwingKeyboardController instance =
      AwingKeyboardController._();

  TextEditingController? _target;
  bool _shifted = false;
  String? _armedTone;

  /// The controller of the currently focused Awing field, or null if
  /// no Awing field has focus. When null, [AwingKeyboardOverlay]
  /// renders nothing.
  TextEditingController? get target => _target;

  /// True if Shift is toggled on for the next key press. Auto-cleared
  /// after any letter/number is typed.
  bool get shifted => _shifted;

  /// The combining tone diacritic (U+0300, U+0301, U+0302, or U+030C)
  /// waiting to be applied to the next vowel typed. null when no tone
  /// is armed. Auto-cleared after any letter/number is typed.
  String? get armedTone => _armedTone;

  bool get isVisible => _target != null;

  /// Route the keyboard to [controller]. If a different controller was
  /// already bound, that state is preserved and the keyboard simply
  /// swaps target — no slide-down animation.
  void bind(TextEditingController controller) {
    if (identical(_target, controller)) return;
    _target = controller;
    _shifted = false;
    _armedTone = null;
    notifyListeners();
  }

  /// Detach from the current target. Called when the Awing field loses
  /// focus (and no other Awing field grabbed focus within a short
  /// window).
  void unbind() {
    if (_target == null) return;
    _target = null;
    _shifted = false;
    _armedTone = null;
    notifyListeners();
  }

  /// User tapped a normal letter/number key. Inserts at the cursor
  /// (respecting the current [TextSelection]). If a tone diacritic
  /// was armed AND the key is a vowel, the vowel is inserted with
  /// the tone attached (Unicode base + combining sequence).
  void typeKey(String key) {
    final c = _target;
    if (c == null) return;
    var toInsert = _shifted ? key.toUpperCase() : key;
    if (_armedTone != null && _isVowelForToning(key)) {
      toInsert = toInsert + _armedTone!;
    }
    _insertAtCursor(c, toInsert);
    _shifted = false;
    _armedTone = null;
    notifyListeners();
  }

  /// User tapped a tone diacritic. Arms the tone so the next vowel
  /// typed gets that mark. Tapping the same tone again disarms.
  void armTone(String tone) {
    _armedTone = (_armedTone == tone) ? null : tone;
    notifyListeners();
  }

  /// User tapped Shift. Single tap = next letter uppercase only.
  void toggleShift() {
    _shifted = !_shifted;
    notifyListeners();
  }

  /// User tapped Backspace. Deletes one Unicode grapheme cluster before
  /// the cursor (so a base + combining mark deletes as one visual char).
  void backspace() {
    final c = _target;
    if (c == null) return;
    final text = c.text;
    final sel = c.selection;
    if (text.isEmpty) return;

    final start = sel.start;
    final end = sel.end;
    if (start < 0) {
      // Cursor never set — treat as end of string
      final safeEnd = text.length;
      if (safeEnd == 0) return;
      final removed = _graphemeBefore(text, safeEnd);
      c.value = TextEditingValue(
        text: text.substring(0, safeEnd - removed),
        selection: TextSelection.collapsed(offset: safeEnd - removed),
      );
      return;
    }
    if (start != end) {
      // Delete the selection
      c.value = TextEditingValue(
        text: text.replaceRange(start, end, ''),
        selection: TextSelection.collapsed(offset: start),
      );
      return;
    }
    if (start == 0) return;
    final removed = _graphemeBefore(text, start);
    c.value = TextEditingValue(
      text: text.replaceRange(start - removed, start, ''),
      selection: TextSelection.collapsed(offset: start - removed),
    );
  }

  /// User tapped Space.
  void typeSpace() {
    final c = _target;
    if (c == null) return;
    _insertAtCursor(c, ' ');
  }

  /// User tapped Enter. For single-line fields this submits; for
  /// multi-line it inserts a newline. Both cases: we insert '\n'
  /// and let the parent decide via onSubmitted etc.
  void typeEnter() {
    final c = _target;
    if (c == null) return;
    _insertAtCursor(c, '\n');
  }

  void _insertAtCursor(TextEditingController c, String s) {
    final text = c.text;
    final sel = c.selection;
    final start = sel.start >= 0 ? sel.start : text.length;
    final end = sel.end >= 0 ? sel.end : text.length;
    c.value = TextEditingValue(
      text: text.replaceRange(start, end, s),
      selection: TextSelection.collapsed(offset: start + s.length),
      composing: TextRange.empty,
    );
  }

  /// How many code units to remove for a single visual backspace.
  /// If the char immediately before [pos] is a combining mark, remove
  /// it AND the preceding base char together (one grapheme). Otherwise
  /// remove one code unit.
  int _graphemeBefore(String text, int pos) {
    if (pos <= 0) return 0;
    final last = text.codeUnitAt(pos - 1);
    // Combining Diacritical Marks range: U+0300..U+036F
    if (last >= 0x0300 && last <= 0x036F && pos >= 2) {
      return 2;
    }
    // Surrogate pair
    if (pos >= 2 && (last & 0xFC00) == 0xDC00) {
      final prev = text.codeUnitAt(pos - 2);
      if ((prev & 0xFC00) == 0xD800) return 2;
    }
    return 1;
  }

  bool _isVowelForToning(String key) {
    // Any Awing vowel — plain or special. Excludes 'i' with combining
    // dot below etc. (we don't type those directly).
    const vowels = {'a', 'e', 'i', 'o', 'u', 'ɛ', 'ɔ', 'ə', 'ɨ'};
    return vowels.contains(key.toLowerCase());
  }
}
