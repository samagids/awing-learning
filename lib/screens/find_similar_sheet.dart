// find_similar_sheet.dart
// ---------------------------------------------------------------
// v1.17.0 — "Find Similar Words" feature.
//
// Opens a bottom sheet showing the top-5 semantically nearest Awing
// vocabulary entries to a given (awing, english) seed.
//
// Flow:
//   1. Look up the seed's embedding in the precomputed vocab_embeddings
//      blob (fast — 8911-entry hash map).
//   2. If the seed isn't in the precompute table (e.g. a user-typed
//      query), compute its embedding LIVE via ModelService (43 MB
//      TFLite sentence-transformer model, ~50 ms inference).
//   3. Find top-5 cosine-similarity matches across the vocab.
//   4. Render mini-cards with image + Awing + English + audio.
//
// Fails gracefully if:
//   - vocab_embeddings.bin missing from PAD → shows friendly message
//   - model.tflite missing AND seed not in precompute table →
//     can't do anything for that specific seed (UI shows "couldn't
//     find similar words"). The vast majority of seeds WILL be in
//     the precompute table, so live model is rarely needed.
// ---------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:awing_ai_learning/services/model_service.dart';
import 'package:awing_ai_learning/services/vocab_embeddings.dart';
import 'package:awing_ai_learning/services/pronunciation_service.dart';
import 'package:awing_ai_learning/components/pack_image.dart';

/// Show the Find Similar Words bottom sheet for [awing] / [english].
void showFindSimilarSheet(
  BuildContext context, {
  required String awing,
  required String english,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FindSimilarSheet(awing: awing, english: english),
  );
}

class _FindSimilarSheet extends StatefulWidget {
  final String awing;
  final String english;
  const _FindSimilarSheet({required this.awing, required this.english});

  @override
  State<_FindSimilarSheet> createState() => _FindSimilarSheetState();
}

class _FindSimilarSheetState extends State<_FindSimilarSheet> {
  final PronunciationService _pronunciation = PronunciationService();
  bool _loading = true;
  String? _error;
  List<MapEntry<String, double>> _neighbors = [];

  @override
  void initState() {
    super.initState();
    _pronunciation.init();
    _findNeighbors();
  }

  Future<void> _findNeighbors() async {
    final embeds = VocabEmbeddings.instance;
    if (!embeds.isLoaded) {
      // Trigger load now if not ready yet
      try {
        await embeds.load();
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = "The semantic map isn't loaded yet. Try again in a moment.";
            _loading = false;
          });
        }
        return;
      }
    }

    // 1) Try the precomputed table first (fast — 99% of vocab words hit)
    final precomp = embeds.getEmbedding(widget.awing, widget.english);
    List<double>? seedEmbedding;
    if (precomp != null) {
      seedEmbedding = List<double>.from(precomp);
    } else {
      // 2) Fall back to live inference via the on-device TFLite model
      try {
        if (!ModelService.instance.isLoaded) {
          await ModelService.instance.loadModel();
        }
        seedEmbedding = ModelService.instance.embed(widget.english);
      } catch (e) {
        if (mounted) {
          setState(() {
            _error =
                "Couldn't find similar words for this entry (live AI model not available on this device yet).";
            _loading = false;
          });
        }
        return;
      }
    }

    final excludeKey = '${widget.awing}|${widget.english}';
    final neighbors = embeds.nearestNeighbors(
      seedEmbedding,
      k: 5,
      excludeKeys: {excludeKey},
    );

    if (mounted) {
      setState(() {
        _neighbors = neighbors;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.psychology_alt,
                      color: Colors.deepPurple.shade400, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Words like '${widget.awing}'",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.english,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildBody(scrollController)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Finding similar words…',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(_error!,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
              textAlign: TextAlign.center),
        ),
      );
    }
    if (_neighbors.isEmpty) {
      return const Center(
        child: Text(
          'No similar words found.',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _neighbors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final entry = _neighbors[i];
        final parts = entry.key.split('|');
        if (parts.length != 2) return const SizedBox.shrink();
        final aw = parts[0];
        final en = parts[1];
        // similarity is in [-1, 1]; map to percent for display
        final pct = ((entry.value + 1.0) / 2.0 * 100).clamp(0, 100).toInt();
        return Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _pronunciation.speakAwing(aw),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: PackImage(
                        awingWord: aw,
                        english: en,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(aw,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(en,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'AI match $pct%',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.deepPurple.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Hear it',
                    icon: Icon(Icons.volume_up,
                        color: Colors.deepPurple.shade400),
                    onPressed: () => _pronunciation.speakAwing(aw),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
