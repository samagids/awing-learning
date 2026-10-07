import 'package:flutter/material.dart';

/// A text controller that renders its value as bullets and never, at any
/// point, draws a real character.
///
/// WHY THIS EXISTS
/// ---------------
/// `TextField(obscureText: true)` is not safe against a camera or a screen
/// recording. Flutter's EditableText deliberately reveals the character you
/// just typed for a few hundred milliseconds before masking it:
///
///   // editable_text.dart, buildTextSpan()
///   text = widget.obscuringCharacter * text.length;
///   final int? o = _obscureShowCharTicksPending > 0 ? _obscureLatestCharIndex : null;
///   if (o != null) text = text.replaceRange(o, o + 1, _value.text.substring(o, o + 1));
///
/// At 30 frames per second that reveal is roughly ten frames per digit. A
/// screen recording of a parent entering an 8-digit PIN therefore contains
/// all eight digits in the clear, each sitting in its own frame, and anyone
/// who steps through the file can read the whole thing off.
///
/// This was found on 2026-10-07 in the account-deletion recording made for
/// App Review: every digit of the parent PIN was legible frame by frame, in
/// 48pt type. It affects every PIN field in the app, not just that one — the
/// parental gate has behaved this way since it was written.
///
/// HOW THIS FIXES IT
/// -----------------
/// When `obscureText` is true, EditableText builds the span itself and never
/// calls the controller. So the fix is to turn `obscureText` OFF and mask in
/// the controller, which EditableText *does* delegate to. There is no reveal
/// path here: `buildTextSpan` cannot see which character was typed last and
/// has nothing to time, so it emits bullets and only bullets.
///
/// USING IT
/// --------
/// Replace the controller and drop `obscureText`:
///
///   final pin = PinTextController();
///   TextField(
///     controller: pin,
///     keyboardType: TextInputType.number,
///     autocorrect: false,              // obscureText used to imply these
///     enableSuggestions: false,
///     enableIMEPersonalizedLearning: false,
///     ...
///   )
///
/// The three keyboard flags matter. `obscureText: true` implied them, so
/// removing it without setting them by hand would start feeding PINs to the
/// keyboard's predictive-text dictionary — trading a visual leak for a
/// stored one.
///
/// `controller.text` is unchanged and still holds the real digits; only the
/// drawing is masked. Everything that reads the PIN keeps working.
class PinTextController extends TextEditingController {
  PinTextController({String? text}) : super(text: text);

  /// The glyph drawn in place of each character.
  static const String bullet = '•';

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Deliberately ignores `value.composing`: showing composing text would
    // reintroduce exactly the leak this class exists to close.
    return TextSpan(style: style, text: bullet * value.text.length);
  }
}
