// Reads a one-shot the way the tool scripts need it: mono samples plus the
// sample rate. Both the RIFF wav files the app ships and the AIFF files audio
// editors hand back are accepted, big-endian and 24-bit included.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

class AudioInput {
  final int sampleRate;
  final Float64List mono;

  AudioInput(this.sampleRate, this.mono);

  double get seconds => mono.length / sampleRate;
}

AudioInput readAudioInput(String path) {
  final bytes = File(path).readAsBytesSync();
  String tag(int at) => String.fromCharCodes(bytes.sublist(at, at + 4));
  final head = tag(0);
  if (head == 'RIFF' && tag(8) == 'WAVE') return _readWav(bytes);
  if (head == 'FORM' && (tag(8) == 'AIFF' || tag(8) == 'AIFC')) {
    return _readAiff(bytes, tag);
  }
  throw '$path is neither a wav nor an aiff';
}

class _RawAudio {
  int channels = 0;
  int frames = 0;
  int bits = 0;
  int rate = 0;
  int dataAt = 0;
  Endian endian = Endian.little;
}

AudioInput _finish(_RawAudio raw, Uint8List bytes) {
  if (raw.rate == 0 || raw.channels == 0 || raw.frames == 0) {
    throw 'unreadable header';
  }
  final width = (raw.bits / 8).round();
  final view = ByteData.sublistView(bytes, raw.dataAt);
  final out = Float64List(raw.frames);
  for (var i = 0; i < raw.frames; i++) {
    var sum = 0.0;
    for (var channel = 0; channel < raw.channels; channel++) {
      sum += _sample(
        view,
        (i * raw.channels + channel) * width,
        raw.bits,
        raw.endian,
      );
    }
    out[i] = sum / raw.channels;
  }
  return AudioInput(raw.rate, out);
}

double _sample(ByteData data, int at, int bits, Endian endian) {
  if (bits == 8) return (data.getUint8(at) - 128) / 128;
  if (bits == 16) return data.getInt16(at, endian) / 32768;
  if (bits == 24) {
    final raw = endian == Endian.little
        ? data.getUint8(at) |
              data.getUint8(at + 1) << 8 |
              data.getUint8(at + 2) << 16
        : data.getUint8(at) << 16 |
              data.getUint8(at + 1) << 8 |
              data.getUint8(at + 2);
    final signed = raw & 0x800000 != 0 ? raw - 0x1000000 : raw;
    return signed / 8388608;
  }
  if (bits == 32) return data.getInt32(at, endian) / 4294967296;
  throw 'unsupported bit depth $bits';
}

AudioInput _readWav(Uint8List bytes) {
  final view = ByteData.sublistView(bytes);
  String tag(int at) => String.fromCharCodes(bytes.sublist(at, at + 4));

  final raw = _RawAudio();
  var at = 12;
  while (at + 8 <= bytes.length) {
    final id = tag(at);
    final size = view.getUint32(at + 4, Endian.little);
    if (id == 'fmt ') {
      raw.channels = view.getUint16(at + 10, Endian.little);
      raw.rate = view.getUint32(at + 12, Endian.little);
      raw.bits = view.getUint16(at + 22, Endian.little);
      final format = view.getUint16(at + 8, Endian.little);
      if (format == 3 || format == 0xFFFE) {
        throw 'float wavs are not supported here, export 16 or 24 bit pcm';
      }
    } else if (id == 'data') {
      raw.dataAt = at + 8;
      raw.frames = size ~/ ((raw.bits / 8).round() * raw.channels);
      break;
    }
    at += 8 + size + (size.isOdd ? 1 : 0);
  }
  return _finish(raw, bytes);
}

/// The 80-bit IEEE extended number AIFF stores its sample rate in. The
/// mantissa is an unsigned 64-bit integer with the binary point below its top
/// bit, so it is worth 2^63 rather than the 2^64 the literal would suggest —
/// and 2^63 is not a representable Dart int.
double _extended(ByteData data, int at) {
  final sign = data.getUint8(at) & 0x80 != 0 ? -1.0 : 1.0;
  final exponent = ((data.getUint8(at) & 0x7f) << 8) | data.getUint8(at + 1);
  if (exponent == 0) return 0.0;
  var mantissa = 0.0;
  for (var i = 0; i < 8; i++) {
    mantissa = mantissa * 256 + data.getUint8(at + 2 + i);
  }
  return sign *
      (mantissa / ((1 << 62) * 2.0)) *
      math.pow(2.0, exponent - 16383);
}

AudioInput _readAiff(Uint8List bytes, String Function(int) tag) {
  final view = ByteData.sublistView(bytes);
  final raw = _RawAudio()..endian = Endian.big;

  var commAt = 0;
  var commSize = 0;
  var at = 12;
  while (at + 8 <= bytes.length) {
    final id = tag(at);
    final size = view.getUint32(at + 4, Endian.big);
    if (id == 'COMM') {
      commAt = at + 8;
      commSize = size;
    } else if (id == 'SSND') {
      // The chunk carries its own playback offset and block size before the
      // samples start.
      raw.dataAt = at + 8 + view.getUint32(at + 8, Endian.big).toInt();
    }
    at += 8 + size + (size.isOdd ? 1 : 0);
  }
  if (commAt == 0 || raw.dataAt == 0) throw 'no COMM or SSND chunk';
  // Channel count, frame count, bit depth, then the 80-bit rate. AIFC adds its
  // compression fields after that, which an uncompressed export leaves as the
  // plain PCM values read here.
  if (commSize < 18) throw 'short COMM chunk';

  raw.channels = view.getUint16(commAt, Endian.big);
  raw.frames = view.getUint32(commAt + 2, Endian.big);
  raw.bits = view.getUint16(commAt + 6, Endian.big);
  raw.rate = _extended(view, commAt + 8).round();
  if (raw.rate < 8000 || raw.rate > 192000) {
    throw 'unreadable sample rate in the COMM chunk';
  }

  final expected =
      (bytes.length - raw.dataAt) ~/ ((raw.bits / 8).round() * raw.channels);
  if (raw.frames > expected) raw.frames = expected;
  return _finish(raw, bytes);
}
