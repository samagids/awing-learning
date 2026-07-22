import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awing_ai_learning/screens/medium/sentences_screen.dart'
    show AwingSentence, expertSentences;
import 'package:awing_ai_learning/services/pronunciation_service.dart';

/// Expert-mode long-form Awing proverbs & complex sentences.
/// Sourced from the 2007 Awing English Dictionary body pages.
/// Marked as difficulty=3 in `awingSentences` list.
class ExpertProverbsScreen extends StatefulWidget {
  const ExpertProverbsScreen({super.key});

  @override
  State<ExpertProverbsScreen> createState() => _ExpertProverbsScreenState();
}

class _ExpertProverbsScreenState extends State<ExpertProverbsScreen> {
  int _index = 0;

  void _next() {
    setState(() {
      _index = (_index + 1) % expertSentences.length;
    });
  }

  void _prev() {
    setState(() {
      _index = (_index - 1 + expertSentences.length) % expertSentences.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (expertSentences.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Awing Proverbs')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No expert proverbs available yet.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final AwingSentence s = expertSentences[_index];
    final pron = Provider.of<PronunciationService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Awing Proverbs'),
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Proverb ${_index + 1} of ${expertSentences.length}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_index + 1) / expertSentences.length,
                backgroundColor: Colors.grey.shade200,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 3,
                        color: Colors.red.shade50,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Awing',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange)),
                              const SizedBox(height: 8),
                              SelectableText(
                                s.awing,
                                style: const TextStyle(
                                    fontSize: 22, height: 1.4),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => pron.speakAwing(s.awing),
                                icon: const Icon(Icons.volume_up),
                                label: const Text('Hear it'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade400,
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
                                    fontSize: 18, height: 1.4),
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
                      backgroundColor: Colors.red.shade400,
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
