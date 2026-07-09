import 'package:flutter/material.dart';
import 'package:awing_ai_learning/services/dictionary_lookup.dart';
import 'package:awing_ai_learning/services/example_sentences.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/widgets/ai_mode_toggle.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/services/ai_toggle_service.dart';
import 'package:awing_ai_learning/services/cloud_ai_service.dart';
import 'package:awing_ai_learning/services/on_device_model_service.dart';
import 'package:awing_ai_learning/services/retrieval_service.dart';
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
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
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
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
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
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.volume_up),
                  tooltip: 'Play pronunciation',
                  onPressed: () async {
                    try {
                      await PronunciationService().speakAwing(result.awing);
                    } catch (e) {
                      debugPrint('Play failed: $e');
                    }
                  },
                ),
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
                      fontSize: 13,
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
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            iconSize: 22,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.volume_up),
            tooltip: 'Play example',
            onPressed: () async {
              try {
                await PronunciationService().speakAwing(example.awing);
              } catch (_) {}
            },
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
  List<String> _hallucinated = const [];

  Future<void> _generate() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      _hallucinated = const [];
    });
    try {
      // Retrieval now lives inside the CloudFlare Worker. We still
      // build a client-side vocabulary set for the hallucination guard
      // — it costs nothing (local map lookups) and lets us flag any
      // Awing word in the response that isn't in our dictionary.
      final bundle = RetrievalService.instance.buildForWord(
        targetAwing: widget.awing,
        targetEnglish: widget.english,
        targetCategory: widget.category,
      );
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
      CloudExampleSentence? finalResult = result;
      if (result != null && result.english.isNotEmpty) {
        // NEW: word-by-word Awing translation, deterministic. Words not
        // in the dictionary render as "—". No hallucination possible.
        final gloss = WordGloss.instance.glossEnglish(result.english);
        final awingLine = gloss.tokens.map((t) {
          if (t.translation != null && t.translation!.isNotEmpty) {
            return t.translation!;
          }
          // Skip pure punctuation tokens.
          if (RegExp(r'^[\p{P}]+\$', unicode: true).hasMatch(t.source)) {
            return t.source;
          }
          return '—';
        }).join(' ');
        finalResult = CloudExampleSentence(
          awing: awingLine,
          english: result.english,
        );
      }
      // Hallucination guard is no longer needed — we build Awing from
      // dictionary lookups so every displayed word is real. Keep an
      // empty list so the warning strip never fires.
      setState(() {
        _loading = false;
        _example = finalResult;
        _hallucinated = const [];
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
        _error = 'Cloud AI call failed: \$e';
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
            Row(
              children: [
                Icon(Icons.cloud, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Text(
                  'Example (Cloud AI):',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
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
                fontSize: 13,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (_hallucinated.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber,
                        size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'AI may have invented: ${_hallucinated.take(4).join(", ")}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                  fontSize: 12,
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
