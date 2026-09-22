import 'package:flutter/material.dart';

import 'package:awing_ai_learning/services/user_registry_service.dart';

/// Green / amber / grey badge showing whether a roster address is a real
/// Awing user.
///
/// Session 64c. Three states, and the third one matters:
///
///   GREEN  check      — this address has signed in to Awing
///   AMBER  warning    — it has not; most often a typo, but also a student
///                       who simply has not installed the app yet
///   GREY   cloud-off  — we could not check (offline / lookup denied)
///
/// Grey is NOT amber. Showing "not a user" to a teacher who is merely
/// offline would be a lie that makes them delete a correct address.
///
/// Amber is deliberately NOT an error and never blocks adding someone:
/// pre-enrolling a student before they install is a normal thing to do.
class EmailKnownIcon extends StatefulWidget {
  const EmailKnownIcon({super.key, required this.email, this.size = 20});

  final String email;
  final double size;

  @override
  State<EmailKnownIcon> createState() => _EmailKnownIconState();
}

class _EmailKnownIconState extends State<EmailKnownIcon> {
  bool? _known;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  @override
  void didUpdateWidget(covariant EmailKnownIcon old) {
    super.didUpdateWidget(old);
    if (old.email != widget.email) _lookup();
  }

  Future<void> _lookup() async {
    setState(() => _loading = true);
    final r = await UserRegistryService.instance.isKnownUser(widget.email);
    if (!mounted) return;
    setState(() {
      _known = r;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Padding(
          padding: EdgeInsets.all(2),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    late final IconData icon;
    late final Color color;
    late final String tip;
    switch (_known) {
      case true:
        icon = Icons.check_circle;
        color = Colors.green.shade600;
        tip = 'This email has used Awing — they will see this set.';
        break;
      case false:
        icon = Icons.warning_amber_rounded;
        color = Colors.amber.shade800;
        tip = 'No Awing account uses this email yet. Check the spelling, '
            'or leave it if they have not installed the app — it will '
            'start working as soon as they sign in with it.';
        break;
      default:
        icon = Icons.cloud_off;
        color = Theme.of(context).disabledColor;
        tip = 'Could not check right now (offline).';
    }
    return Tooltip(
      message: tip,
      child: Icon(icon, size: widget.size, color: color),
    );
  }
}
