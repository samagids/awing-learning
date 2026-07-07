import 'package:flutter/material.dart';
import 'package:awing_ai_learning/services/word_gloss.dart';
import 'package:awing_ai_learning/services/dictionary_lookup.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/widgets/ai_mode_toggle.dart';
import 'package:awing_ai_learning/widgets/wrong_translation_reporter.dart';

/// Expert-tier translation: "Grade My Translation".
///
/// - User types the English sentence they wanted to translate
/// - User types their Awing attempt
/// - App validates each word in the attempt:
///     GREEN  - word is in the dictionary AND its English gloss overlaps
///              a word in the expected English sentence
///     BLUE   - word is in the dictionary but doesn't match the expected
///              English (may still be correct — Awing has synonyms)
///     ORANGE - word is NOT in the dictionary
/// - Overall score based on green + blue coverage vs total words
/// - Below, shows the app's OWN word-by-word suggestion so the user
///   can compare their attempt against a dictionary-grounded version.
///
/// Educationally: kids learn better by TRYING then checking against a
/// reference than by copying an LLM's output. This screen enforces the
/// try-first pattern.
class GradeAttemptScreen extends StatefulWidget {
  const GradeAttemptScreen({Key? key}) : super(key: key);

  @override
  State<GradeAttemptScreen> createState() => _GradeAttemptScreenState();
}

class _GradeAttemptScreenState extends State<GradeAttemptScreen> {
  final _englishController = TextEditingController();
  final _awingAttemptController = TextEditingController();
  _GradeResult? _result;

  @override
  void dispose() {
    _englishController.dispose();
    _awingAttemptController.dispose();
    super.dispose();
  }

  void _grade() {
    final english = _englishController.text.trim();
    final attempt = _awingAttemptController.text.trim();
    if (english.isEmpty || attempt.isEmpty) {
      setState(() => _result = null);
      return;
    }

    // Build the expected-English word set from the English sentence
    // (lowercased, tokenized).
    final expectedTokens = english
        .toLowerCase()
        .replaceAll(RegExp(r'[^\sa-z0-9]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 2)
        .toSet();

    // Gloss the Awing attempt.
    final gloss = WordGloss.instance.glossAwing(attempt);
    final gradedTokens = <_GradedToken>[];
    for (final tok in gloss.tokens) {
      if (RegExp(r"^[\p{P}]+$", unicode: true).hasMatch(tok.source) ||
          tok.source.trim().isEmpty) {
        continue;
      }
      _GradeLevel level;
      if (!tok.inDictionary) {
        level = _GradeLevel.notFound;
      } else {
        // Check overlap between token's translation and the expected
        // English tokens.
        final translationTokens = (tok.translation ?? '')
            .toLowerCase()
            .replaceAll(RegExp(r'[^\sa-z0-9]'), ' ')
            .split(RegExp(r'\s+'))
            .where((t) => t.length >= 2)
            .toSet();
        final overlap = translationTokens.intersection(expectedTokens);
        level = overlap.isNotEmpty ? _GradeLevel.match : _GradeLevel.wrongMeaning;
      }
      gradedTokens.add(_GradedToken(
        source: tok.source,
        translation: tok.translation,
        level: level,
      ));
    }

    // Build the reference gloss from English so user can compare.
    final referenceGloss = WordGloss.instance.glossEnglish(english);

    setState(() {
      _result = _GradeResult(
        english: english,
        attempt: attempt,
        graded: gradedTokens,
        reference: referenceGloss,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grade My Translation')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CloudDataBanner(),
          const Align(
            alignment: Alignment.centerRight,
            child: AIModeToggle(compact: true),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'English sentence (what you want to say):',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _englishController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'e.g. I am going to the market',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your Awing translation:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _awingAttemptController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Type your Awing attempt...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _grade,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Grade my attempt'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildResult()),
        ],
      ),
    );
  }

  Widget _buildResult() {
    if (_result == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_outlined,
                  size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Enter both an English sentence and your Awing attempt,\n'
                'then tap Grade.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                'The app checks each word against the dictionary — no cheating!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
    final r = _result!;
    final total = r.graded.length;
    final matches = r.graded.where((g) => g.level == _GradeLevel.match).length;
    final synonyms =
        r.graded.where((g) => g.level == _GradeLevel.wrongMeaning).length;
    final missing =
        r.graded.where((g) => g.level == _GradeLevel.notFound).length;
    final pct = total == 0 ? 0 : ((matches / total) * 100).round();

    MaterialColor scoreColor;
    IconData scoreIcon;
    String scoreLabel;
    if (pct >= 70) {
      scoreColor = Colors.green;
      scoreIcon = Icons.emoji_events;
      scoreLabel = 'Great work!';
    } else if (pct >= 40) {
      scoreColor = Colors.orange;
      scoreIcon = Icons.thumb_up_outlined;
      scoreLabel = 'Nice try — keep going.';
    } else {
      scoreColor = Colors.red;
      scoreIcon = Icons.school_outlined;
      scoreLabel = 'Learning takes practice!';
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Score header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scoreColor.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scoreColor.shade300),
          ),
          child: Row(
            children: [
              Icon(scoreIcon, size: 40, color: scoreColor.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$pct% match',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: scoreColor.shade900,
                      ),
                    ),
                    Text(scoreLabel,
                        style: TextStyle(color: scoreColor.shade800)),
                    const SizedBox(height: 4),
                    Text(
                      '$matches match • $synonyms possible synonyms • '
                      '$missing not in dictionary',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Per-word breakdown
        const Text('Your words:',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: r.graded.map(_buildGradedChip).toList(),
        ),
        const SizedBox(height: 20),
        // Reference translation for comparison
        Row(
          children: [
            const Text(
              'App\'s dictionary suggestion:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            WrongTranslationReportButton(
              english: r.english,
              wrongAwing: r.reference.wordByWord,
              context: 'grade-reference',
              isSingleWord: false,
              iconSize: 20,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.teal.shade200),
          ),
          child: SelectableText(
            r.reference.wordByWord,
            style: const TextStyle(fontSize: 17, height: 1.4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Words the app couldn\'t find: '
          '${r.reference.tokens.where((t) => !t.inDictionary && t.source.trim().isNotEmpty && !RegExp(r"^[\p{P}]+$", unicode: true).hasMatch(t.source)).map((t) => t.source).join(", ")}',
          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 16),
        // Suggestions from the dictionary for missing words
        if (missing > 0) ...[
          const Text(
            'Words not in dictionary — check spelling:',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange),
          ),
          const SizedBox(height: 8),
          ...r.graded
              .where((g) => g.level == _GradeLevel.notFound)
              .map(_buildFuzzySuggestions),
        ],
      ],
    );
  }

  Widget _buildGradedChip(_GradedToken g) {
    MaterialColor color;
    IconData icon;
    switch (g.level) {
      case _GradeLevel.match:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case _GradeLevel.wrongMeaning:
        color = Colors.blue;
        icon = Icons.help_outline;
        break;
      case _GradeLevel.notFound:
        color = Colors.orange;
        icon = Icons.error_outline;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color.shade700),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                g.source,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color.shade900,
                ),
              ),
              if (g.translation != null)
                Text(
                  g.translation!,
                  style: TextStyle(fontSize: 12, color: color.shade800),
                ),
            ],
          ),
          if (g.level != _GradeLevel.notFound) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: () async {
                try {
                  await PronunciationService().speakAwing(g.source);
                } catch (_) {}
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.volume_up,
                    size: 16, color: color.shade700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFuzzySuggestions(_GradedToken g) {
    // For each missing word, offer up to 3 fuzzy dictionary matches so
    // the user can see close alternatives.
    final hits = DictionaryLookup.instance.lookupAwing(g.source, maxResults: 3);
    if (hits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          '  • "${g.source}" — no close match found',
          style: const TextStyle(fontSize: 13),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('  • "${g.source}" — did you mean:',
              style: const TextStyle(fontSize: 13)),
          ...hits.map((h) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Text(
                  '${h.awing}  →  ${h.english}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

enum _GradeLevel { match, wrongMeaning, notFound }

class _GradedToken {
  final String source;
  final String? translation;
  final _GradeLevel level;
  const _GradedToken({
    required this.source,
    required this.translation,
    required this.level,
  });
}

class _GradeResult {
  final String english;
  final String attempt;
  final List<_GradedToken> graded;
  final GlossResult reference;
  const _GradeResult({
    required this.english,
    required this.attempt,
    required this.graded,
    required this.reference,
  });
}
