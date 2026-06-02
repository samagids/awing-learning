// model_service.dart
// ---------------------------------------------------------------
// v1.16.0 — On-device TFLite sentence embedding service.
//
// Model: sentence-transformers/all-MiniLM-L6-v2 (~43 MB)
// Loaded LAZILY from the PAD asset pack the first time inference is
// requested, so app startup is unaffected. The full model + tokenizer
// load takes ~600-900 ms on a mid-range Android phone; subsequent
// inferences are ~30-50 ms each.
//
// Inputs (shape [1, 128]):
//   - input_ids
//   - attention_mask
//   - token_type_ids
// Output (shape [1, 128, 384]):
//   - token-level embeddings
//
// For sentence-level embeddings we mean-pool the token embeddings
// weighted by attention mask. That's the standard sentence-
// transformers post-processing.
// ---------------------------------------------------------------

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:awing_ai_learning/services/asset_pack_service.dart';
import 'package:awing_ai_learning/services/bert_tokenizer.dart';

class ModelService {
  static final ModelService instance = ModelService._();
  ModelService._();

  Interpreter? _interpreter;
  bool _loadAttempted = false;
  bool _loadFailed = false;
  String? _lastError;
  Completer<void>? _loadCompleter;
  DateTime? _loadedAt;

  /// True if model is loaded and ready for inference.
  bool get isLoaded => _interpreter != null;

  /// True if we tried to load and failed (model file missing).
  bool get loadFailed => _loadFailed;

  /// Error message from last failed load attempt.
  String? get lastError => _lastError;

  /// Time the model was loaded (for status display).
  DateTime? get loadedAt => _loadedAt;

  /// Embedding dimension (matches MiniLM-L6 output).
  static const int embeddingDim = 384;
  static const int maxSeqLen = 128;

  /// Load the TFLite model from the PAD pack. Idempotent — concurrent
  /// callers share the same load Future.
  Future<void> loadModel() async {
    if (isLoaded) return;
    if (_loadAttempted && _loadFailed) {
      // Don't retry on every call — flag failure once, let caller decide.
      throw StateError(_lastError ?? 'Model load previously failed');
    }
    if (_loadCompleter != null) return _loadCompleter!.future;
    _loadCompleter = Completer<void>();

    try {
      _loadAttempted = true;

      // Load tokenizer in parallel — both depend on PAD only.
      final tokenizerFuture = BertTokenizer.instance.load();

      // Load model bytes from PAD pack
      final bytes = await AssetPackService().getAssetBytes('model.tflite');
      if (bytes == null) {
        throw StateError('model.tflite not found in PAD pack');
      }

      // Wait for tokenizer too
      await tokenizerFuture;

      // Build interpreter from buffer (NOT from asset — bypasses
      // Flutter's main bundle, reads from PAD instead).
      final options = InterpreterOptions()..threads = 2;
      _interpreter = Interpreter.fromBuffer(bytes, options: options);
      _loadedAt = DateTime.now();
      _loadFailed = false;
      _loadCompleter!.complete();
      if (kDebugMode) print('ModelService: loaded ${bytes.length} bytes');
    } catch (e, st) {
      _loadFailed = true;
      _lastError = e.toString();
      if (kDebugMode) {
        print('ModelService load failed: $e\n$st');
      }
      _loadCompleter!.completeError(e);
      rethrow;
    }
  }

  /// Compute a 384-dim sentence embedding for [text].
  /// Mean-pooled over token embeddings, attention-mask weighted, then
  /// L2-normalized. Throws if model not loaded.
  List<double> embed(String text) {
    if (_interpreter == null) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }
    final tok = BertTokenizer.instance.encode(text, maxSeqLen: maxSeqLen);

    // tflite_flutter expects nested List<List<int>> for [1, 128] int inputs.
    final inputIds = [tok.inputIds];
    final attentionMask = [tok.attentionMask];
    final tokenTypeIds = [List<int>.filled(maxSeqLen, 0)];

    // Output buffer: [1, 128, 384] doubles
    final output = List.generate(
      1,
      (_) => List.generate(
        maxSeqLen,
        (_) => List<double>.filled(embeddingDim, 0.0),
      ),
    );

    _interpreter!.runForMultipleInputs(
      [inputIds, attentionMask, tokenTypeIds],
      {0: output},
    );

    // Mean-pool over the sequence dimension, weighted by attention mask.
    final pooled = List<double>.filled(embeddingDim, 0.0);
    int activeTokens = 0;
    for (int t = 0; t < maxSeqLen; t++) {
      if (tok.attentionMask[t] == 0) continue;
      activeTokens++;
      final tokenVec = output[0][t];
      for (int d = 0; d < embeddingDim; d++) {
        pooled[d] += tokenVec[d];
      }
    }
    if (activeTokens > 0) {
      for (int d = 0; d < embeddingDim; d++) {
        pooled[d] /= activeTokens;
      }
    }
    // L2-normalize for cosine similarity
    double norm = 0.0;
    for (final v in pooled) {
      norm += v * v;
    }
    norm = math.sqrt(norm);
    if (norm > 1e-9) {
      for (int d = 0; d < embeddingDim; d++) {
        pooled[d] /= norm;
      }
    }
    return pooled;
  }

  /// Cosine similarity between two L2-normalized embeddings.
  /// Returns a value in [-1, 1]; higher = more similar.
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    double dot = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
    }
    return dot;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
