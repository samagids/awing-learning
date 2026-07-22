import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/screens/medium/sentences_screen.dart'
    show AwingSentence, beginnerSentences;
import 'package:awing_ai_learning/services/pronunciation_service.dart';

/// Beginner-mode short everyday sentences (≤ 5 Awing words).
/// Sourced from the 2007 Awing English Dictionary, filtered by length.
class BeginnerSentencesScreen extends StatefulWidget {
  const BeginnerSentencesScreen({super.key});

  @override
  State<BeginnerSentencesScreen> createState() =>
      _BeginnerSentencesScreenState();
}

class _BeginnerSentencesScreenState extends State<BeginnerSentencesScreen> {
  int _index = 0;

  void _next() {
    setState(() {
      _index = (_index + 1) % beginnerSentences.length;
    });
  }

  void _prev() {
    setState(() {
      _index = (_index - 1 + beginnerSentences.length) %
          beginnerSentences.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (beginnerSentences.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Short Sentences')),
        body: const Center(
          child: Text('No beginner sentences available yet.'),
        ),
      );
    }

    final AwingSentence s = beginnerSentences[_index];
    final pron = Provider.of<PronunciationService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Short Sentences'),
        backgroundColor: Colors.green.shade400,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Sentence ${_index + 1} of ${beginnerSentences.length}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_index + 1) / beginnerSentences.length,
                backgroundColor: Colors.grey.shade200,
                color: Colors.green.shade400,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 3,
                        color: Colors.green.shade50,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Awing',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green)),
                              const SizedBox(height: 8),
                              SelectableText(
                                s.awing,
                                style: const TextStyle(
                                    fontSize: 28, height: 1.4),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => pron.speakAwing(s.awing),
                                icon: const Icon(Icons.volume_up),
                                label: const Text('Hear it'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade400,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 1,
                        color: Colors.blueGrey.shade50,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('English',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey)),
                              const SizedBox(height: 8),
                              SelectableText(
                                s.english,
                                style: const TextStyle(
                                    fontSize: 20, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _index > 0 ? _prev : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _next,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade400,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
