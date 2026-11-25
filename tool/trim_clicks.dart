// Cuts the downloaded one-shots down to the metronome clicks the app ships:
// mono, 44.1 kHz, 16-bit, the attack plus a short tail, peak normalised to the
// same headroom the synthesised clicks use.
//
//   dart run tool/trim_clicks.dart <source.wav|source.aiff> <out.wav> <tail-seconds>
import 'dart:io';
import 'dart:typed_data';

import 'audio_input.dart';

const int outRate = 44100;
const double peak = 0.82;

void main(List<String> args) {
  if (args.length != 3) {
    stderr.writeln('usage: trim_clicks.dart <source> <out.wav> <tail>');
    exit(64);
  }
  final source = args[0];
  final out = File(args[1]);
  final tail = double.parse(args[2]);

  final input = readAudioInput(source);
  final samples = _resample(input.mono, input.sampleRate, outRate);

  var loudest = 0.0;
  for (final sample in samples) {
    loudest = sample.abs() > loudest ? sample.abs() : loudest;
  }
  if (loudest == 0) {
    stderr.writeln('$source is silent');
    exit(1);
  }

  // A couple of milliseconds before the transient, so the attack is not
  // clipped by the cut itself.
  final preRoll = (0.002 * outRate).round();
  var attack = 0;
  for (var i = 0; i < samples.length; i++) {
    if (samples[i].abs() > loudest * 0.08) {
      attack = i;
      break;
    }
  }
  final start = (attack - preRoll).clamp(0, samples.length);
  final end = (attack + tail * outRate).round().clamp(start, samples.length);
  final clip = samples.sublist(start, end);

  final fade = (0.015 * outRate).round();
  for (var i = 0; i < fade && i < clip.length; i++) {
    clip[clip.length - 1 - i] *= i / fade;
  }
  for (var i = 0; i < clip.length; i++) {
    clip[i] = clip[i] / loudest * peak;
  }

  out.createSync(recursive: true);
  out.writeAsBytesSync(_encodeWavMono(clip));
  stdout.writeln(
    '${out.path} ${(clip.length / outRate * 1000).round()} ms '
    '${(out.lengthSync() / 1024).round()} KB',
  );
}

Float64List _resample(Float64List input, int from, int to) {
  if (from == to) return input;
  final out = Float64List((input.length * to / from).round());
  final step = from / to;
  for (var i = 0; i < out.length; i++) {
    final position = i * step;
    final low = position.floor().clamp(0, input.length - 1);
    final high = (low + 1).clamp(0, input.length - 1);
    final mix = position - low;
    out[i] = input[low] * (1 - mix) + input[high] * mix;
  }
  return out;
}

Uint8List _encodeWavMono(Float64List samples) {
  final bytes = ByteData(44 + samples.length * 2);
  void ascii(int at, String text) {
    for (var i = 0; i < text.length; i++) {
      bytes.setUint8(at + i, text.codeUnitAt(i));
    }
  }

  final dataLength = samples.length * 2;
  ascii(0, 'RIFF');
  bytes.setUint32(4, 36 + dataLength, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, outRate, Endian.little);
  bytes.setUint32(28, outRate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  bytes.setUint32(40, dataLength, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final clamped = samples[i].clamp(-1.0, 1.0);
    bytes.setInt16(44 + i * 2, (clamped * 32767).round(), Endian.little);
  }
  return bytes.buffer.asUint8List();
}
