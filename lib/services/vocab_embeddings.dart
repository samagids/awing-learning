// vocab_embeddings.dart
// ---------------------------------------------------------------
// v1.16.0 — Reads precomputed 384-dim sentence embeddings for every
// vocabulary entry (key = 'awing|english'). The blob is generated
// offline by scripts/precompute_embeddings.py and bundled in the
// PAD asset pack as vocab_embeddings.bin (~14 MB).
//
// Binary format (little-endian):
//   uint32 N                            (number of entries)
//   repeated N times:
//     uint32 keyLen
//     bytes  key                        (UTF-8 'awing|english')
//     float32 × 384                     (L2-normalized embedding)
//
// Why precompute instead of running the model 9000 times at startup:
//   * Inference for 9000 entries at ~50ms each = ~7.5 min on a phone.
//     Even on a desktop with the full model it takes ~30s.
//   * The vocabulary is static between app builds, so the embeddings
//     are stable. Recomputing each install is pure waste.
//   * The model file is STILL bundled (~43 MB) for cases where the
//     app needs an embedding for a word NOT in the precompute table
//     (e.g. "Find similar words" for a user-typed query).
// ---------------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:awing_ai_learning/services/asset_pack_service.dart';
import 'package:awing_ai_learning/services/model_service.dart';

class VocabEmbeddings {
  static final VocabEmbeddings instance = VocabEmbeddings._();
  VocabEmbeddings._();

  /// Key = 'awing|english'. Value = 384-element Float32List.
  Map<String, Float32List>? _embeds;
  bool _loadFailed = false;
  String? _lastError;
  Completer<void>? _loadCompleter;

  bool get isLoaded => _embeds != null;
  bool get loadFailed => _loadFailed;
  String? get lastError => _lastError;
  int get count => _embeds?.length ?? 0;

  /// Load the binary blob from PAD. Idempotent.
  Future<void> load() async {
    if (isLoaded) return;
    if (_loadFailed) {
      throw StateError(_lastError ?? 'Embeddings load previously failed');
    }
    if (_loadCompleter != null) return _loadCompleter!.future;
    _loadCompleter = Completer<void>();
    try {
      final bytes =
          await AssetPackService().getAssetBytes('vocab_embeddings.bin');
      if (bytes == null) {
        throw StateError('vocab_embeddings.bin not found in PAD pack');
      }
      _embeds = _parse(bytes);
      _loadCompleter!.complete();
      if (kDebugMode) {
        print('VocabEmbeddings: ${_embeds!.length} entries loaded');
      }
    } catch (e) {
      _loadFailed = true;
      _lastError = e.toString();
      _loadCompleter!.completeError(e);
      if (kDebugMode) print('VocabEmbeddings load failed: $e');
      rethrow;
    }
  }

  Map<String, Float32List> _parse(Uint8List bytes) {
    final bd = ByteData.sublistView(bytes);
    int offset = 0;
    final n = bd.getUint32(offset, Endian.little);
    offset += 4;
    final result = <String, Float32List>{};
    for (int i = 0; i < n; i++) {
      final keyLen = bd.getUint32(offset, Endian.little);
      offset += 4;
      final keyBytes = bytes.sublist(offset, offset + keyLen);
      offset += keyLen;
      final key = String.fromCharCodes(keyBytes); // UTF-8 = bytes for ASCII; for non-ASCII we need utf8 decode
      // The vocab has Awing chars (ɛ, ɔ, ə, ɨ, ŋ + tone diacritics)
      // which are multi-byte UTF-8. Decode properly.
      final keyDecoded = _utf8Decode(keyBytes);
      // 384 × float32 = 1536 bytes
      final vec = Float32List(ModelService.embeddingDim);
      for (int d = 0; d < ModelService.embeddingDim; d++) {
        vec[d] = bd.getFloat32(offset, Endian.little);
        offset += 4;
      }
      result[keyDecoded] = vec;
    }
    return result;
  }

  static String _utf8Decode(Uint8List bytes) {
    try {
      return const Utf8Decoder().convert(bytes);
    } catch (_) {
      // Last-resort ASCII view if blob is somehow malformed
      return String.fromCharCodes(bytes);
    }
  }

  /// Look up the precomputed embedding for [awing] + [english].
  /// Returns null if not in the precompute table.
  Float32List? getEmbedding(String awing, String english) {
    if (_embeds == null) return null;
    return _embeds!['$awing|$english'];
  }

  /// Find the [k] nearest vocabulary entries to [seedEmbedding] by
  /// cosine similarity. Returns a list of (key, similarity) tuples
  /// sorted descending. Excludes any keys in [excludeKeys].
  List<MapEntry<String, double>> nearestNeighbors(
    List<double> seedEmbedding, {
    int k = 5,
    Set<String> excludeKeys = const {},
  }) {
    if (_embeds == null) return [];
    if (seedEmbedding.length != ModelService.embeddingDim) return [];

    // Convert to Float32List for faster math
    final seed = Float32List.fromList(seedEmbedding.map((e) => e).toList());

    final scored = <MapEntry<String, double>>[];
    _embeds!.forEach((key, vec) {
      if (excludeKeys.contains(key)) return;
      double dot = 0.0;
      for (int i = 0; i < ModelService.embeddingDim; i++) {
        dot += seed[i] * vec[i];
      }
      scored.add(MapEntry(key, dot));
    });
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(k).toList();
  }
}

