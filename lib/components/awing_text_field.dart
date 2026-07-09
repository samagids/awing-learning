import 'package:flutter/material.dart';
import 'package:awing_ai_learning/services/awing_keyboard_controller.dart';

/// A [TextField] that uses the in-app Awing keyboard instead of the
/// phone's system keyboard.
///
/// Behaviorally identical to a normal `TextField`, but with two key
/// differences under the hood:
///
/// 1. `keyboardType: TextInputType.none` — suppresses the OS keyboard.
///    (Flutter 3.7+.)
/// 2. FocusNode listener → binds the field's [controller] to
///    [AwingKeyboardController.instance] on focus, unbinds on
///    blur, so the [AwingKeyboardOverlay] at the app root knows
///    which field to type into.
///
/// A short delay on unbind lets the user tap from one Awing field to
/// another without the keyboard flickering.
class AwingTextField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration? decoration;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final bool autofocus;
  final TextStyle? style;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  const AwingTextField({
    super.key,
    required this.controller,
    this.decoration,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = false,
    this.style,
    this.onSubmitted,
    this.onChanged,
    this.textInputAction,
    this.focusNode,
  });

  @override
  State<AwingTextField> createState() => _AwingTextFieldState();
}

class _AwingTextFieldState extends State<AwingTextField> {
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant AwingTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      if (_ownsFocusNode) _focusNode.dispose();
      _focusNode = widget.focusNode ?? FocusNode();
      _ownsFocusNode = widget.focusNode == null;
      _focusNode.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() {
    final kb = AwingKeyboardController.instance;
    if (_focusNode.hasFocus) {
      kb.bind(widget.controller);
    } else {
      // Delay unbind slightly so a focus switch to another Awing
      // field doesn't cause the keyboard to hide and re-show.
      Future.delayed(const Duration(milliseconds: 80), () {
        if (!mounted) return;
        if (!_focusNode.hasFocus &&
            identical(kb.target, widget.controller)) {
          kb.unbind();
        }
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    // If this field is currently the keyboard's target when it's being
    // destroyed, unbind so the overlay doesn't hold a stale controller.
    final kb = AwingKeyboardController.instance;
    if (identical(kb.target, widget.controller)) {
      kb.unbind();
    }
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.none,
      showCursor: true,
      decoration: widget.decoration,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      autofocus: widget.autofocus,
      style: widget.style,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
    );
  }
}
