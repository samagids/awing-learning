import 'package:flutter/material.dart';
import 'package:awing_ai_learning/components/awing_audio_button.dart';
import 'package:awing_ai_learning/services/dictionary_lookup.dart';
import 'package:awing_ai_learning/services/example_sentences.dart';
import 'package:awing_ai_learning/widgets/ai_mode_toggle.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/ai_toggle_service.dart';
import 'package:awing_ai_learning/services/cloud_ai_service.dart';
import 'package:awing_ai_learning/services/on_device_model_service.dart';
import 'package:awing_ai_learning/components/awing_text_field.dart';
import 'package:awing_ai_learning/services/word_gloss.dart';
import 'package:awing_ai_learning/widgets/wrong_translation_reporter.dart';

/// Beginner-tier translation: word lookup with English meaning + example
/// sentence.
///
/// Flow: user types a word → taps Generate → for each match, shows:
///   • Awing word (with speaker)
///   • English meaning
///   • Category + difficulty chips
///   • One example sentence in Awing + English gloss (if we have one
///     bundled for that word — coverage limited to ~50 verified
///     phrases; Cloud AI will fill the gap when Phase B ships)
///
/// Same UX pattern as Sentence Translate (Medium) — type, then tap.
class WordTranslateScreen extends StatefulWidget {
  const WordTranslateScreen({Key? key}) : super(key: key);

  @override
  State<WordTranslateScreen> createState() => _WordTranslateScreenState();
}

class _WordTranslateScreenState extends State<WordTranslateScreen> {
  final _controller = TextEditingController();
  bool _englishToAwing = true;
  List<LookupResult> _results = const [];
  bool _generated = false;

  @override
  void initState() {
    super.initState();
    DictionaryLookup.instance.build();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generate() {
    final q = _controller.text.trim();
    if (q.isEmpty) {
      setState(() {
        _results = const [];
        _generated = false;
      });
      return;
    }
    final results = _englishToAwing
        ? DictionaryLookup.instance.lookupEnglish(q)
        : DictionaryLookup.instance.lookupAwing(q);
    setState(() {
      _results = results;
      _generated = true;
    });
  }

  void _swapDirection() {
    setState(() {
      _englishToAwing = !_englishToAwing;
      _controller.clear();
      _results = const [];
      _generated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Word Translate')),
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
                // Use Awing on-screen keyboard when typing Awing;
                // system keyboard when typing English.
                _englishToAwing
                    ? TextField(
                        controller: _controller,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _generate(),
                        decoration: InputDecoration(
                          hintText: 'Type an English word...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _controller.text.isEmpty
                              ? null
                              : IconButton(
                                tooltip: 'Clear',
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _controller.clear();
                                      _results = const [];
                                      _generated = false;
                                    });
                                  },
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    : AwingTextField(
                        controller: _controller,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _generate(),
                        decoration: InputDecoration(
                          hintText: 'Type an Awing word...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _controller.text.isEmpty
                              ? null
                              : IconButton(
                                tooltip: 'Clear',
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _controller.clear();
                                      _results = const [];
                                      _generated = false;
                                    });
                                  },
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _generate,
                  icon: const Icon(Icons.translate),
                  label: const Text('Generate'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildResults()),
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
          onPressed: _swapDirection,
          icon: const Icon(Icons.swap_horiz, size: 28),
          tooltip: 'Swap direction',
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
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

  Widget _buildResults() {
    if (!_generated) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.translate, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _englishToAwing
                    ? 'Type an English word, then tap Generate.'
                    : 'Type an Awing word, then tap Generate.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                'Tip: don\'t worry about tone marks — the app finds words with or without them.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sentiment_dissatisfied,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'No match found for "${_controller.text}".',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                'Try checking spelling, or search for a shorter part of the word.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _ResultCard(result: _results[i]),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final LookupResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final scorePct = (result.score * 100).round();
    final isExact = result.score >= 0.99;
    // Look up example sentences for this Awing word.
    final examples =
        ExampleSentenceService.instance.findByAwing(result.awing);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Awing + English row with speaker
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.awing,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.english,
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _Chip(
                            label: result.category,
                            color: Colors.blueGrey.shade100,
                          ),
                          const SizedBox(width: 6),
                          _Chip(
                            label: _difficultyLabel(result.difficulty),
                            color: _difficultyColor(result.difficulty),
                          ),
                          if (!isExact) ...[
                            const SizedBox(width: 6),
                            _Chip(
                              label: '$scorePct% match',
                              color: Colors.orange.shade100,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // v1.24.0: speaker when a human recorded it, microphone
                // inviting a recording when not. Never a dead speaker.
                AwingAudioButton(awing: result.awing, iconSize: 32),
                WrongTranslationReportButton(
                  english: result.english,
                  wrongAwing: result.awing,
                  context: 'word-translate',
                  isSingleWord: true,
                  iconSize: 20,
                ),
              ],
            ),
            // Example sentences
            if (examples.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.format_quote,
                      size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Example${examples.length > 1 ? "s" : ""}:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...examples.map((e) => _ExampleTile(example: e)),
            ] else ...[
              const SizedBox(height: 8),
              _CloudExampleSection(
                awing: result.awing,
                english: result.english,
                category: result.category,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _difficultyLabel(int d) {
    switch (d) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Medium';
      case 3:
        return 'Expert';
      default:
        return 'Beginner';
    }
  }

  Color _difficultyColor(int d) {
    switch (d) {
      case 1:
        return Colors.green.shade100;
      case 2:
        return Colors.orange.shade100;
      case 3:
        return Colors.red.shade100;
      default:
        return Colors.green.shade100;
    }
  }
}

class _ExampleTile extends StatelessWidget {
  final ExampleSentence example;
  const _ExampleTile({required this.example});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  example.awing,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  example.english,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          // An example sentence, not a word: the recorder is word-oriented,
          // so this says "no recording" rather than offering to make one.
          AwingAudioButton(
            awing: example.awing,
            iconSize: 22,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            offerToRecord: false,
          ),
        ],
      ),
    );
  }
}

/// Placeholder + Cloud-AI "generate example" button that appears under
/// a word when we have no bundled example sentence for it.
///
/// When the global AI toggle is OFF: just shows a hint pointing at the
/// toggle. When ON: shows a button that fires a single POST to the
/// CloudFlare Worker /example endpoint and renders the LLM-generated
/// example sentence + speaker.
class _CloudExampleSection extends StatefulWidget {
  final String awing;
  final String english;
  final String category;
  const _CloudExampleSection({
    required this.awing,
    required this.english,
    required this.category,
  });

  @override
  State<_CloudExampleSection> createState() => _CloudExampleSectionState();
}

class _CloudExampleSectionState extends State<_CloudExampleSection> {
  bool _loading = false;
  CloudExampleSentence? _example;
  String? _error;

  Future<void> _generate() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Retrieval now lives inside the CloudFlare Worker.
      //
      // NO-HALLUCINATED-AWING INVARIANT (Session 63):
      // The model is never trusted to produce Awing. It returns English;
      // the Awing line below is assembled token-by-token from dictionary
      // lookups via WordGloss, with "—" for anything absent. So every
      // Awing character that reaches a child is real, by construction.
      //
      // RetrievalService.findHallucinatedWords() still exists but is
      // deliberately NOT called: it would validate a string we built
      // ourselves out of dictionary entries, so it can only ever return
      // an empty list. It predates this design, when the model was asked
      // for Awing directly. Do not "restore" it — if the architecture
      // ever goes back to model-authored Awing, that is when it matters.
      //
      // preferOffline picks the on-device model when the Cloud toggle is
      // OFF and the model is downloaded + inference is wired up. If it
      // isn't, generateExample returns null and we fall through to the
      // dictionary-only path.
      final toggle = context.read<AIToggleService>();
      final result = await CloudAIService.instance.generateExample(
        awingWord: widget.awing,
        english: widget.english,
        category: widget.category,
        level: 'beginner',
        preferOffline: !toggle.cloudEnabled,
      );
      if (!mounted) return;
      // Enforcement of the invariant above. Today every parse branch
      // that fills `awing` also requires a non-empty `english`, so the
      // gloss always runs and always overwrites it — but that is an
      // emergent property of two conditions in two files lining up, not
      // something the type system protects. Start from null so a future
      // edit to CloudAIService.tryParse can never leak model-authored
      // Awing onto the screen; worst case the user sees the "no usable
      // example" message, which is the correct failure for this app.
      CloudExampleSentence? finalResult;
      if (result != null && result.english.isNotEmpty) {
        // NEW: word-by-word Awing translation, deterministic. Words not
        // in the dictionary render as "—". No hallucination possible.
        //
        // Stopwords ("of", "or", "the", "a", "and", ...) and proper
        // nouns get isStopword=true in WordGloss and their .translation
        // is set to the English source (to "preserve sentence
        // structure"). That's fine for Cloud AI (returns Awing-heavy
        // responses) but leaks English into the Awing line for Offline
        // AI (pure-English generator). Em-dash stopwords instead so the
        // Awing line is either real Awing or "—".
        final gloss = WordGloss.instance.glossEnglish(result.english);
        final awingLine = gloss.tokens.map((t) {
          // Punctuation preserved as-is.
          // Session 64 C2 fix: raw string \$ used to mean "match literal $",
          // so this regex never matched actual punctuation — the whole
          // "preserve punctuation" branch was dead code and punctuation
          // fell through to em-dash replacement. Now correctly matches
          // any Unicode punctuation-only token.
          if (RegExp(r'^[\p{P}]+$', unicode: true).hasMatch(t.source)) {
            return t.source;
          }
          // Stopwords (kept-as-is in gloss) become em-dashes in output.
          if (t.isStopword == true) {
            return '—';
          }
          if (t.translation != null && t.translation!.isNotEmpty) {
            return t.translation!;
          }
          return '—';
        }).join(' ');
        finalResult = CloudExampleSentence(
          awing: awingLine,
          english: result.english,
        );
      }
      setState(() {
        _loading = false;
        _example = finalResult;
        if (finalResult == null) {
          // Route the message to reality: if the user chose Offline
          // (Cloud toggle OFF), tell them exactly WHY offline didn't
          // produce anything - was the model not downloaded, still
          // downloading, failed to load, etc.
          if (!toggle.cloudEnabled) {
            _error = OnDeviceModelService.instance.diagnosticSummary;
          } else {
            _error = 'Cloud AI did not return a usable example. '
                'Check your internet connection and try again.';
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // Session 64 C1 fix: was '\$e' (literal string) — users saw
        // "Cloud AI call failed: $e" with no diagnostic. Now interpolates.
        _error = 'Cloud AI call failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final toggle = context.watch<AIToggleService>();

    // If we already have a result, show it.
    if (_example != null) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (context) {
                // When the example came from the on-device model (Cloud
                // toggle OFF), the awing field is empty (WordGloss on
                // the widget side fills it) and the label + color should
                // read "Offline AI" in green. Cloud path leaves the
                // original blue "Cloud AI" cloud icon.
                final toggle = context.read<AIToggleService>();
                final isOffline = !toggle.cloudEnabled;
                return Row(
                  children: [
                    Icon(
                      isOffline ? Icons.smartphone : Icons.cloud,
                      size: 16,
                      color: isOffline
                          ? Colors.green.shade700
                          : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOffline
                          ? 'Example (Offline AI):'
                          : 'Example (Cloud AI):',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isOffline
                            ? Colors.green.shade900
                            : Colors.blue.shade900,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              _example!.awing,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              _example!.english,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    // Watch the on-device model too — its Generate button appears
    // whenever the model FILE is downloaded and ready, even if the
    // cactus runtime hasn't loaded it into memory yet. Loading is
    // deferred to the first tap of Generate (isInferenceReady =
    // isReady && _lmLoaded, and _lmLoaded is only flipped by
    // _ensureLmLoaded() which runs inside generateEnglishSentence).
    // Gating on isInferenceReady would be a chicken-and-egg —
    // button never shows so lazy-load never runs.
    final onDevice = context.watch<OnDeviceModelService>();
    final offlineReady = onDevice.isReady;

    // Cloud OFF + on-device model NOT ready: hint pointing at the toggle.
    if (!toggle.cloudEnabled && !offlineReady) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline,
                size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Turn on Cloud AI (top-right) or download Offline AI to '
                'generate example sentences.',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Cloud is ON OR on-device model is ready — show the Generate button.
    final isOffline = !toggle.cloudEnabled && offlineReady;
    final buttonIcon = isOffline ? Icons.smartphone : Icons.cloud;
    final buttonLabel = isOffline
        ? 'Generate example with Offline AI'
        : 'Generate example with Cloud AI';
    final buttonColor = isOffline ? Colors.green.shade700 : Colors.blue.shade700;
    final buttonBorder =
        isOffline ? Colors.green.shade300 : Colors.blue.shade300;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _loading ? null : _generate,
          icon: _loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(buttonIcon, size: 18),
          label: Text(_loading ? 'Generating...' : buttonLabel),
          style: OutlinedButton.styleFrom(
            foregroundColor: buttonColor,
            side: BorderSide(color: buttonBorder),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(
            _error!,
            style: TextStyle(fontSize: 11, color: Colors.red.shade700),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
