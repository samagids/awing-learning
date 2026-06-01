import 'dart:io';
import 'dart:typed_data';

/// Minimal WAV (PCM 16-bit) decoder + linear resampler. Used by the
/// Phase 1B pronunciation grader smoke test to feed a sideloaded test
/// WAV (typically 22050 Hz) into the MMS-FA ONNX model (16000 Hz mono).
///
/// Not a general-purpose WAV reader. Handles the specific case the test
/// data uses: WAV/RIFF container, PCM s16le, 1 or 2 channels, any
/// sample rate.
class WavDecoder {
  /// Decode the WAV file at [path], return mono Float32 PCM at the
  /// target sample rate (default 16000). Throws if the file isn't a
  /// PCM WAV.
  static Future<Float32List> decodeFile(String path, {int targetSampleRate = 16000}) async {
    final bytes = await File(path).readAsBytes();
    return decodeBytes(bytes, targetSampleRate: targetSampleRate);
  }

  static Float32List decodeBytes(Uint8List bytes, {int targetSampleRate = 16000}) {
    if (bytes.length < 44) {
      throw FormatException('Too small to be a WAV file (${bytes.length} bytes)');
    }
    final bd = ByteData.sublistView(bytes);

    // RIFF header
    if (bytes[0] != 0x52 || bytes[1] != 0x49 || bytes[2] != 0x46 || bytes[3] != 0x46) {
      throw FormatException('Not a RIFF file');
    }
    if (bytes[8] != 0x57 || bytes[9] != 0x41 || bytes[10] != 0x56 || bytes[11] != 0x45) {
      throw FormatException('Not a WAVE file');
    }

    // Walk chunks looking for 'fmt ' and 'data'
    int offset = 12;
    int? fmtOffset;
    int? dataOffset;
    int? dataSize;
    while (offset + 8 <= bytes.length) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = bd.getUint32(offset + 4, Endian.little);
      if (chunkId == 'fmt ') {
        fmtOffset = offset + 8;
      } else if (chunkId == 'data') {
        dataOffset = offset + 8;
        dataSize = chunkSize;
        break;
      }
      offset += 8 + chunkSize;
      if (chunkSize.isOdd) offset++; // pad byte
    }
    if (fmtOffset == null || dataOffset == null || dataSize == null) {
      throw FormatException('Missing fmt or data chunk');
    }

    // fmt chunk: format(2) channels(2) rate(4) byteRate(4) blockAlign(2) bits(2)
    final audioFormat = bd.getUint16(fmtOffset, Endian.little);
    final channels = bd.getUint16(fmtOffset + 2, Endian.little);
    final sampleRate = bd.getUint32(fmtOffset + 4, Endian.little);
    final bitsPerSample = bd.getUint16(fmtOffset + 14, Endian.little);

    if (audioFormat != 1) {
      throw FormatException('Only PCM (format 1) supported, got $audioFormat');
    }
    if (bitsPerSample != 16) {
      throw FormatException('Only 16-bit PCM supported, got $bitsPerSample');
    }

    // Decode int16 → float32 in [-1.0, 1.0], averaging channels if stereo
    final sampleCount = dataSize ~/ (2 * channels);
    final mono = Float32List(sampleCount);
    var src = dataOffset;
    for (var i = 0; i < sampleCount; i++) {
      var sum = 0;
      for (var c = 0; c < channels; c++) {
        sum += bd.getInt16(src, Endian.little);
        src += 2;
      }
      mono[i] = (sum / channels) / 32768.0;
    }

    if (sampleRate == targetSampleRate) {
      return mono;
    }
    return _resample(mono, sampleRate, targetSampleRate);
  }

  /// Linear-interpolation resampler. Good enough for speech grading —
  /// the MMS Wav2Vec2 front-end is robust to mild aliasing artifacts.
  /// For production, swap for polyphase / sinc-interp if quality issues
  /// surface in real-device testing.
  static Float32List _resample(Float32List src, int srcRate, int dstRate) {
    if (srcRate == dstRate) return src;
    final ratio = dstRate / srcRate;
    final dstLen = (src.length * ratio).round();
    final out = Float32List(dstLen);
    final step = srcRate / dstRate;
    for (var i = 0; i < dstLen; i++) {
      final pos = i * step;
      final i0 = pos.floor();
      final i1 = i0 + 1;
      final frac = pos - i0;
      final s0 = src[i0.clamp(0, src.length - 1)];
      final s1 = src[i1.clamp(0, src.length - 1)];
      out[i] = s0 + (s1 - s0) * frac;
    }
    return out;
  }
}
