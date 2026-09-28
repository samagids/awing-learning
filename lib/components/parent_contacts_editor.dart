import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awing_ai_learning/models/user_model.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/contribution_service.dart';

const Color _kGreen = Color(0xFF006432);

/// Add / edit / remove the parents and guardians who receive activity
/// reports, shared between first-run setup and Parent Settings.
///
/// v1.23.6 (Session 65a). Two things it is careful about:
///
///  * **An address is not a recipient until its owner says so.** Adding an
///    email only mails that address a confirmation link. Until it is opened,
///    the row shows "waiting" and no report goes there. Without this, anyone
///    with an app login could mail anyone under the app's name.
///  * **It never claims a number works.** A WhatsApp number is stored for
///    later (Cloud API delivery) and used for manual sharing, and the UI says
///    exactly that rather than implying messages are being sent to it.
class ParentContactsEditor extends StatefulWidget {
  /// Shown above the list; setup uses a friendlier line than settings.
  final String? introText;

  const ParentContactsEditor({Key? key, this.introText}) : super(key: key);

  @override
  State<ParentContactsEditor> createState() => _ParentContactsEditorState();
}

class _ParentContactsEditorState extends State<ParentContactsEditor> {
  final Set<String> _busyEmails = <String>{};
  Set<String> _pendingEmails = <String>{};
  bool _statusChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshStatus());
  }

  /// Ask the server which addresses are confirmed.
  ///
  /// The server is the authority: a second parent may have clicked their link
  /// on a completely different device, so the local flag can only ever be a
  /// cache. A failed check leaves the cache alone rather than downgrading
  /// rows to "waiting" on a flaky connection.
  Future<void> _refreshStatus() async {
    if (!mounted) return;
    final auth = context.read<AuthService>();
    final contrib = context.read<ContributionService>();
    if (auth.parentContacts.isEmpty) {
      setState(() => _statusChecked = true);
      return;
    }
    final reply = await contrib.fetchConfirmedContacts();
    if (!mounted) return;
    if (reply == null || reply['status'] != 'success') {
      setState(() => _statusChecked = true);
      return;
    }
    final confirmed = (reply['confirmed'] as List?)?.whereType<String>().toSet() ??
        <String>{};
    final account = (reply['account'] as String?)?.toLowerCase();
    if (account != null) confirmed.add(account);
    final pending =
        (reply['pending'] as List?)?.whereType<String>().toSet() ?? <String>{};

    for (final c in auth.parentContacts) {
      final mail = c.email?.toLowerCase();
      if (mail == null) continue;
      auth.markContactEmailConfirmed(mail, confirmed: confirmed.contains(mail));
    }
    setState(() {
      _pendingEmails = pending;
      _statusChecked = true;
    });
  }

  Future<void> _sendConfirmation(ParentContact contact) async {
    final email = contact.email;
    if (email == null) return;
    final contrib = context.read<ContributionService>();
    final auth = context.read<AuthService>();

    setState(() => _busyEmails.add(email));
    final reply = await contrib.requestContactVerification(email);
    if (!mounted) return;
    setState(() => _busyEmails.remove(email));

    if (reply == null) {
      // Unknown, not failed. Saying "failed" here would push the parent to
      // send again and mail the other parent twice.
      _toast('We could not confirm whether the email went out. '
          'Check with $email before sending again.');
      return;
    }
    if (reply['status'] != 'success') {
      _toast(_readableError(reply['message']));
      return;
    }
    if (reply['confirmed'] == true) {
      auth.markContactEmailConfirmed(email);
      _toast('$email is confirmed.');
    } else {
      setState(() => _pendingEmails = {..._pendingEmails, email.toLowerCase()});
      _toast('Confirmation sent to $email. They need to open the link.');
    }
  }

  String _readableError(Object? raw) {
    final m = (raw ?? '').toString();
    if (m.contains('too many requests')) {
      return 'Too many confirmation emails today. Try again tomorrow.';
    }
    if (m.contains('not-signed-in') || m.contains('unauthorized')) {
      return 'Sign in with Google or Apple first so we can verify your account.';
    }
    if (m.contains('too many contacts')) return 'You have added too many contacts.';
    if (m.contains('invalid email')) return 'That email address was not accepted.';
    return 'Could not send the confirmation: $m';
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  Future<void> _edit({int? index}) async {
    final auth = context.read<AuthService>();
    final existing = index == null ? null : auth.parentContacts[index];

    final result = await showDialog<_ContactDraft>(
      context: context,
      builder: (ctx) => _ContactDialog(existing: existing),
    );
    if (result == null || !mounted) return;

    final error = index == null
        ? auth.addParentContact(
            label: result.label,
            whatsappNumber: result.phone,
            email: result.email,
          )
        : auth.updateParentContact(
            index,
            label: result.label,
            whatsappNumber: result.phone,
            email: result.email,
          );

    if (error != null) {
      _toast(error);
      return;
    }
    setState(() {});

    // A newly added or changed address needs the other parent's consent.
    final saved = auth.parentContacts.firstWhere(
      (c) => c.email != null && c.email == result.email?.trim().toLowerCase(),
      orElse: () => ParentContact(),
    );
    if (saved.hasEmail && !saved.emailConfirmed) {
      await _sendConfirmation(saved);
    }
  }

  Future<void> _remove(int index) async {
    final auth = context.read<AuthService>();
    final contact = auth.parentContacts[index];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove contact?'),
        content: Text(
          '${contact.label} will stop receiving activity reports.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    auth.removeParentContact(index);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final contacts = auth.parentContacts;
        final canAdd = contacts.length < UserAccount.maxParentContacts;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.introText != null) ...[
              Text(
                widget.introText!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
            ],
            if (contacts.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'No contacts yet. Add a parent or guardian to receive '
                  'activity reports.',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              )
            else
              for (int i = 0; i < contacts.length; i++)
                _ContactTile(
                  contact: contacts[i],
                  busy: _busyEmails.contains(contacts[i].email),
                  statusChecked: _statusChecked,
                  pending: contacts[i].email != null &&
                      _pendingEmails.contains(contacts[i].email!.toLowerCase()),
                  onEdit: () => _edit(index: i),
                  onRemove: () => _remove(i),
                  onResend: () => _sendConfirmation(contacts[i]),
                ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: canAdd ? () => _edit() : null,
              icon: const Icon(Icons.person_add_alt),
              label: Text(canAdd
                  ? 'Add parent or guardian'
                  : 'Up to ${UserAccount.maxParentContacts} contacts'),
              style: OutlinedButton.styleFrom(foregroundColor: _kGreen),
            ),
          ],
        );
      },
    );
  }
}

class _ContactTile extends StatelessWidget {
  final ParentContact contact;
  final bool busy;
  final bool pending;
  final bool statusChecked;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onResend;

  const _ContactTile({
    Key? key,
    required this.contact,
    required this.busy,
    required this.pending,
    required this.statusChecked,
    required this.onEdit,
    required this.onRemove,
    required this.onResend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lines = <String>[];
    if (contact.hasWhatsApp) lines.add(contact.whatsappNumber!);
    if (contact.hasEmail) lines.add(contact.email!);

    Widget status;
    if (busy) {
      status = const _StatusChip(
          text: 'Sending…', color: Colors.blueGrey, icon: Icons.hourglass_top);
    } else if (!contact.hasEmail) {
      status = const _StatusChip(
        text: 'No email — reports cannot be sent',
        color: Colors.orange,
        icon: Icons.mark_email_unread_outlined,
      );
    } else if (contact.emailConfirmed) {
      status = const _StatusChip(
          text: 'Receiving reports',
          color: _kGreen,
          icon: Icons.check_circle_outline);
    } else if (pending || statusChecked) {
      status = const _StatusChip(
        text: 'Waiting for them to open the confirmation link',
        color: Colors.orange,
        icon: Icons.schedule,
      );
    } else {
      status = const _StatusChip(
          text: 'Checking…', color: Colors.blueGrey, icon: Icons.sync);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    contact.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Remove',
                  onPressed: onRemove,
                ),
              ],
            ),
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(l,
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              ),
            const SizedBox(height: 8),
            status,
            if (contact.hasEmail && !contact.emailConfirmed && !busy)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onResend,
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero, foregroundColor: _kGreen),
                  child: const Text('Send the confirmation again'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _StatusChip({
    Key? key,
    required this.text,
    required this.color,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 12.5, color: color, height: 1.3)),
        ),
      ],
    );
  }
}

class _ContactDraft {
  final String label;
  final String? phone;
  final String? email;
  const _ContactDraft(this.label, this.phone, this.email);
}

class _ContactDialog extends StatefulWidget {
  final ParentContact? existing;
  const _ContactDialog({Key? key, this.existing}) : super(key: key);

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late String _label;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.existing?.whatsappNumber ?? '');
    _email = TextEditingController(text: widget.existing?.email ?? '');
    final existingLabel = widget.existing?.label;
    _label = (existingLabel != null &&
            ParentContact.suggestedLabels.contains(existingLabel))
        ? existingLabel
        : ParentContact.suggestedLabels.first;
  }

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final accountEmail = auth.currentAccount?.email;

    return AlertDialog(
      title: Text(widget.existing == null ? 'Add contact' : 'Edit contact'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _label,
              decoration: const InputDecoration(
                  labelText: 'Who is this?', border: OutlineInputBorder()),
              items: ParentContact.suggestedLabels
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (v) => setState(() => _label = v ?? _label),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Email for reports',
                border: const OutlineInputBorder(),
                helperMaxLines: 3,
                helperText: accountEmail == null
                    ? 'Reports are delivered here.'
                    : 'Reports are delivered here. Your own address '
                        '($accountEmail) needs no confirmation; anyone else '
                        'must open a confirmation link first.',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-()]')),
                LengthLimitingTextInputFormatter(20),
              ],
              decoration: const InputDecoration(
                labelText: 'WhatsApp number (optional)',
                hintText: '+237 6XX XXX XXX',
                border: OutlineInputBorder(),
                helperMaxLines: 3,
                helperText:
                    'Saved for WhatsApp delivery and for sharing a report by '
                    'hand. The same number can be used on every child\'s '
                    'device.',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              _ContactDraft(
                _label,
                _phone.text.trim().isEmpty ? null : _phone.text.trim(),
                _email.text.trim().isEmpty ? null : _email.text.trim(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen, foregroundColor: Colors.white),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ==================== First-run prompt ====================

const String _kSetupPromptShownKey = 'parent_contacts_setup_shown';

/// Offer the contacts step once, just after a family creates their first
/// profile. Always skippable — the app must stay fully usable for a parent
/// who does not want to give a number or an address.
Future<void> maybeShowParentContactsSetup(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_kSetupPromptShownKey) == true) return;
  if (!context.mounted) return;

  final auth = context.read<AuthService>();
  if (auth.currentAccount == null) return;
  if (auth.parentContacts.isNotEmpty) {
    await prefs.setBool(_kSetupPromptShownKey, true);
    return;
  }

  // Mark it shown before awaiting the sheet: if the parent backs out with the
  // system gesture we still do not re-prompt on every launch.
  await prefs.setBool(_kSetupPromptShownKey, true);
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _ParentContactsSetupSheet(),
  );
}

class _ParentContactsSetupSheet extends StatelessWidget {
  const _ParentContactsSetupSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Keep parents in the loop',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add the parents or guardians who should get a daily quiz '
                  'report and a weekly summary. You can add a mother and a '
                  'father, and the same details can be used on every child\'s '
                  'device.',
                  style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 18),
                const ParentContactsEditor(),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Not now'),
                ),
                Center(
                  child: Text(
                    'You can change this any time in Parent Settings.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
