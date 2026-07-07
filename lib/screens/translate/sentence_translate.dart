import 'package:flutter/material.dart';
import 'package:awing_ai_learning/services/word_gloss.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/widgets/ai_mode_toggle.dart';
import 'package:awing_ai_learning/widgets/wrong_translation_reporter.dart';

/// Medium-tier translation: sentence-level, word-by-word gloss.
///
/// - User types a sentence in one direction, gets a token-by-token
///   translation using the dictionary.
/// - Words found in the dictionary render as green chips with a
///   speaker button (tap to hear the Awing pronunciation).
/// - Words not found render as orange chips with a `?` mark.
/// - Coverage percentage tells the user how much of their sentence
///   the app could translate.
/// - A summary line at the bottom joins the token translations into
///   a naive word-by-word Awing sentence.
///
/// This is HONEST word-by-word — not grammar-preserving translation.
/// The UI is explicit about that. In Phase B (cloud) we can send the
/// same sentence to the LLM for a fluent version; the user chooses
/// via the toggle at the top.
class SentenceTranslateScreen extends StatefulWidget {
  const SentenceTranslateScreen({Key? key}) : super(key: key);

  @override
  State<SentenceTranslateScreen> createState() =>
      _SentenceTranslateScreenState();
}

class _SentenceTranslateScreenState extends State<SentenceTranslateScreen> {
  final _controller = TextEditingController();
  bool _englishToAwing = true;
  GlossResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runGloss() {
    final q = _controller.text.trim();
    if (q.isEmpty) {
      setState(() => _result = null);
      return;
    }
    final r = _englishToAwing
        ? WordGloss.instance.glossEnglish(q)
        : WordGloss.instance.glossAwing(q);
    setState(() => _result = r);
  }

  void _swap() {
    setState(() {
      _englishToAwing = !_englishToAwing;
      _controller.clear();
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sentence Translate')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CloudDataBanner(),
          const Align(
            alignment: Alignment.centerRight,
            child: AIModeToggle(compact: true),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDirectionRow(),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _runGloss(),
                  decoration: InputDecoration(
                    hintText: _englishToAwing
                        ? 'Type an English sentence...'
                        : 'Type an Awing sentence...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _runGloss,
                        icon: const Icon(Icons.translate),
                        label: const Text('Translate'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
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

  Widget _buildDirectionRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _englishToAwing ? 'English' : 'Awing',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: _swap,
          icon: const Icon(Icons.swap_horiz, size: 28),
          tooltip: 'Swap direction',
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _englishToAwing ? 'Awing' : 'English',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
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
              Icon(Icons.chat_bubble_outline,
                  size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Type a sentence above and tap Translate.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                'Word-by-word translation — grammar is simplified.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
    final r = _result!;
    final pct = (r.coverage * 100).round();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Coverage banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: r.coverage >= 0.7
                ? Colors.green.shade50
                : r.coverage >= 0.4
                    ? Colors.orange.shade50
                    : Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                r.coverage >= 0.7 ? Icons.check_circle : Icons.info,
                color: r.coverage >= 0.7
                    ? Colors.green.shade700
                    : Colors.orange.shade800,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Matched ${r.matched} of ${r.totalContent} words ($pct%)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Word-by-word gloss chips
        const Text(
          'Word by word:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: r.tokens.map(_buildTokenChip).toList(),
        ),
        const SizedBox(height: 20),
        // Word-by-word joined sentence
        if (r.matched > 0) ...[
          const Text(
            'Word-by-word translation:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: SelectableText(
              r.wordByWord,
              style: const TextStyle(fontSize: 18, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Note: This is a literal word-for-word translation. '
            'Real Awing grammar may reorder or combine some words.',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 10),
          // Report-wrong-translation flow for the whole sentence.
          // Mirrors the audio-contribution workflow — goes into the
          // Developer Mode Review queue, gets applied to
          // awing_vocabulary.dart on next build.
          Row(
            children: [
              Icon(Icons.flag_outlined,
                  size: 18, color: Colors.orange.shade600),
              const SizedBox(width: 6),
              Text(
                'Wrong translation?',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 4),
              WrongTranslationReportButton(
                english: r.source,
                wrongAwing: r.wordByWord,
                context: 'sentence-translate',
                isSingleWord: false,
                iconSize: 20,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTokenChip(GlossToken token) {
    // Skip pure punctuation AND English stopwords — they don't need
    // per-word Awing translations.
    if (token.isPunctuation) return const SizedBox.shrink();
    // Stopwords + proper nouns render as GREY "kept as-is" chips.
    // The source word is preserved in the sentence flow so the user
    // sees the full structure, not a hole.
    if (token.isStopword) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          token.source,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      );
    }
    final missing = !token.inDictionary;
    final MaterialColor color = missing ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                token.source,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                token.translation ?? '?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color.shade900,
                ),
              ),
            ],
          ),
          if (token.awing != null && _englishToAwing) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: () async {
                try {
                  await PronunciationService().speakAwing(token.awing!);
                } catch (_) {}
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.volume_up,
                    size: 18, color: color.shade700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
