import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/components/awing_text_field.dart';
import 'package:awing_ai_learning/services/contribution_service.dart';
import 'package:awing_ai_learning/services/auth_service.dart';
import 'package:awing_ai_learning/services/analytics_service.dart';
import 'package:awing_ai_learning/components/image_attachment_picker.dart';

/// Compact flag-icon button. Tap → dialog for reporting a wrong
/// translation with optional correction + word-by-word breakdown.
///
/// Reused everywhere translations are shown: Word Translate result
/// cards, cloud-generated examples, Sentence Translate word chips,
/// Grade My Attempt reference — anywhere a user might see wrong
/// Awing and want to correct it.
///
/// Submissions go through the standard [ContributionService.submit()]
/// pipeline → webhook → Developer Mode review queue → approved
/// corrections get applied to `awing_vocabulary.dart` on next build via
/// scripts/apply_contributions.py.
class WrongTranslationReportButton extends StatelessWidget {
  /// The English source (e.g. "boy" or "big stomach boy").
  final String english;

  /// The Awing translation the app displayed (which the user is
  /// flagging as wrong).
  final String wrongAwing;

  /// Optional context — where the report came from (e.g. "word",
  /// "sentence", "cloud-example", "grade-reference").
  final String context;

  /// If true (Word Translate single-entry case), the user is
  /// reporting a single word. If false, the user is reporting a
  /// sentence-level translation and the dialog offers a word-by-word
  /// input field for finer-grained correction.
  final bool isSingleWord;

  /// Icon size — small for chips, larger for cards.
  final double iconSize;

  const WrongTranslationReportButton({
    Key? key,
    required this.english,
    required this.wrongAwing,
    this.context = 'word',
    this.isSingleWord = true,
    this.iconSize = 18,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: iconSize,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: Icon(Icons.flag_outlined, color: Colors.orange.shade600),
      tooltip: 'Report wrong translation',
      onPressed: () => _openDialog(context),
    );
  }

  Future<void> _openDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => _ReportDialog(
        english: english,
        wrongAwing: wrongAwing,
        context: this.context,
        isSingleWord: isSingleWord,
      ),
    );
  }
}

class _ReportDialog extends StatefulWidget {
  final String english;
  final String wrongAwing;
  final String context;
  final bool isSingleWord;

  const _ReportDialog({
    required this.english,
    required this.wrongAwing,
    required this.context,
    required this.isSingleWord,
  });

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _correctionController = TextEditingController();
  final _wordByWordController = TextEditingController();
  final _notesController = TextEditingController();
  bool _submitting = false;
  String? _error;
  /// v1.22.0 (Session 66): optional photo attached to this correction.
  String? _imagePath;

  @override
  void dispose() {
    _correctionController.dispose();
    _wordByWordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final correction = _correctionController.text.trim();
    if (correction.isEmpty) {
      setState(() => _error = 'Please enter the correct Awing translation.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    // Bundle the structured data into the notes field as JSON so the
    // Python apply_contributions.py can parse it. Keeps the shared
    // Contribution model unchanged.
    final wordByWordRaw = _wordByWordController.text.trim();
    final wordByWordMap = _parseWordByWord(wordByWordRaw);
    final freeNotes = _notesController.text.trim();
    final structuredNotes = {
      'wrong': widget.wrongAwing,
      'context': widget.context,
      if (wordByWordMap.isNotEmpty) 'wordByWord': wordByWordMap,
      if (freeNotes.isNotEmpty) 'freeText': freeNotes,
    };

    try {
      final auth = context.read<AuthService>();
      final profileName = auth.currentProfile?.displayName ?? 'Anonymous';
      final deviceId = AnalyticsService.instance.isOptedOut
          ? 'anonymous'
          : 'contributor';
      final id = await context.read<ContributionService>().submit(
        deviceId: deviceId,
        type: ContributionType.translationCorrection,
        profileName: profileName,
        targetWord: widget.wrongAwing,
        correction: correction,
        englishMeaning: widget.english,
        imagePath: _imagePath,
        notes: jsonEncode(structuredNotes),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(id != null
              ? 'Thank you! Correction submitted for review.'
              : 'Saved locally — will send when back online.'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not submit: $e';
      });
    }
  }

  /// Parse a user-typed word-by-word block like:
  ///   big: wíŋɔ́
  ///   stomach: nəpəmə
  ///   boy: mɔ́ mbyâŋnə
  /// (also accepts "=" separator and comma-separated one-liner)
  Map<String, String> _parseWordByWord(String raw) {
    final out = <String, String>{};
    if (raw.isEmpty) return out;
    final parts = raw.split(RegExp(r'[,\n;]+'));
    for (final line in parts) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final m = RegExp(r'^\s*([^:=]+?)\s*[:=]\s*(.+?)\s*$').firstMatch(trimmed);
      if (m != null) {
        out[m.group(1)!] = m.group(2)!;
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.flag, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          const Text('Report wrong translation'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _readonlyRow('English', widget.english),
            const SizedBox(height: 6),
            _readonlyRow('App showed', widget.wrongAwing, isWrong: true),
            const SizedBox(height: 16),
            const Text(
              'Correct Awing translation:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            AwingTextField(
              controller: _correctionController,
              minLines: 1,
              maxLines: 2,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.isSingleWord
                    ? 'e.g. mɔ́ mbyâŋnə'
                    : 'The full correct Awing sentence',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (!widget.isSingleWord) ...[
              const SizedBox(height: 14),
              const Text(
                'Word-by-word (helps train the AI):',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                'One per line, English : Awing',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              AwingTextField(
                controller: _wordByWordController,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'big: wíŋɔ́\nstomach: nəpəmə\nboy: mɔ́ mbyâŋnə',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'Notes (optional):',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _notesController,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. "məbîə is not real Awing — OCR mistake"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // v1.22.0 (Session 66) — optional photo attached to the
            // translation correction. Useful when the wrong translation
            // shows a real-world thing the user can photograph
            // (e.g. "this fruit is called X in my village").
            ImageAttachmentPicker(
              imagePath: _imagePath,
              onChanged: (p) => setState(() => _imagePath = p),
              label: 'Add a photo (optional)',
              hint: 'A picture of the thing helps us confirm the meaning.',
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send, size: 16),
          label: Text(_submitting ? 'Sending...' : 'Submit'),
        ),
      ],
    );
  }

  Widget _readonlyRow(String label, String value, {bool isWrong = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: isWrong ? Colors.red.shade700 : Colors.black87,
              fontWeight: isWrong ? FontWeight.w600 : FontWeight.w400,
              decoration: isWrong ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ],
    );
  }
}
