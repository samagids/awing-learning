import 'package:flutter/material.dart';
import 'package:awing_ai_learning/widgets/ai_mode_toggle.dart';
import 'package:awing_ai_learning/screens/translate/word_translate.dart';
import 'package:awing_ai_learning/screens/translate/sentence_translate.dart';
import 'package:awing_ai_learning/screens/translate/grade_attempt.dart';

/// Translate hub — reached from the Translate mode card on the home
/// screen. Shows three tiles matching the app's difficulty tiers.
///
/// Each mode's Home screen ALSO has a direct tile to its specific
/// Translate screen (Beginner → Word, Medium → Sentence, Expert →
/// Grade), so this hub is only used as an overview / picker.
class TranslateHome extends StatelessWidget {
  const TranslateHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Translate')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CloudDataBanner(),
          const Align(
            alignment: Alignment.centerRight,
            child: AIModeToggle(compact: true),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _TileCard(
                  title: 'Word Translate',
                  subtitle: 'English ↔ Awing, one word at a time',
                  icon: Icons.translate,
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WordTranslateScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _TileCard(
                  title: 'Sentence Translate',
                  subtitle: 'Type a sentence, get word-by-word Awing',
                  icon: Icons.chat_bubble_outline,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SentenceTranslateScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _TileCard(
                  title: 'Grade My Attempt',
                  subtitle: 'Try translating, get instant feedback per word',
                  icon: Icons.check_circle_outline,
                  color: Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GradeAttemptScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TileCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TileCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
