import 'dart:math' as math;
import 'dart:typed_data';

import 'click_voice.dart';

/// Everything a plucked string needs, rendered as plain samples so the web
/// layer only has to hand a WAV file to the browser.
///
/// The tone uses the Karplus-Strong algorithm: a short burst of noise is put
/// in a delay line as long as one period of the note, then fed back through a
/// two-sample average. The average loses the high end exactly like a string
/// does, which is why it sounds plucked rather than played on a keyboard.
class PluckClip {
  static const int sampleRate = 44100;

  /// One note, with a little headroom so several strings can be added together.
  static Float32List single(double frequency, {double seconds = 1.8}) =>
      _normalize(_pluck(frequency, _samples(seconds)));

  /// All strings of a chord, a few milliseconds apart, like a real strum.
  static Float32List chord(
    List<double> frequencies, {
    double strumSeconds = 0.045,
    double seconds = 2.0,
  }) => _layered(
    [for (final frequency in frequencies) _pluck(frequency, _samples(seconds))],
    [for (var i = 0; i < frequencies.length; i++) _samples(i * strumSeconds)],
  );

  /// Notes one after the other: scales and arpeggios.
  static Float32List run(
    List<double> frequencies, {
    double gapSeconds = 0.22,
    double noteSeconds = 1.2,
  }) => _layered(
    [
      for (final frequency in frequencies)
        _pluck(frequency, _samples(noteSeconds)),
    ],
    [for (var i = 0; i < frequencies.length; i++) _samples(i * gapSeconds)],
  );

  /// Down-up strums of one chord, used by the strumming lesson.
  /// A negative onset means the same chord, struck a touch softer.
  static Float32List pattern(
    List<double> frequencies,
    List<double> onsets, {
    double seconds = 0.9,
  }) {
    final parts = <Float32List>[];
    final offsets = <int>[];
    for (final onset in onsets) {
      final loud = onset >= 0;
      for (var i = 0; i < frequencies.length; i++) {
        parts.add(
          _pluck(frequencies[i], _samples(seconds), gain: loud ? 1 : 0.7),
        );
        offsets.add(_samples(onset.abs() + i * 0.006));
      }
    }
    return _normalize(_mix(parts, offsets));
  }

  /// A click track: four beats, the first one higher.
  static Float32List metronome(double bpm, {int beats = 4, int bars = 1}) {
    final beatSeconds = 60.0 / bpm;
    final starts = [
      for (var i = 0; i < beats * bars; i++) _samples(i * beatSeconds),
    ];
    return _clicks(starts, _samples(beatSeconds * beats * bars + 0.4), (i) {
      return i % beats == 0 ? 1760.0 : 1180.0;
    });
  }

  /// Clicks spaced by a list of note lengths in beats, so a bar of eighth
  /// notes sounds different from a bar of quarter notes.
  static Float32List timeline(List<double> lengths, {double bpm = 84}) {
    final beatSeconds = 60.0 / bpm;
    var running = 0.0;
    final starts = <int>[];
    for (final length in lengths) {
      starts.add(_samples(running * beatSeconds));
      running += length;
    }
    return _clicks(starts, _samples(running * beatSeconds + 0.4), (i) {
      return i == 0 ? 1760.0 : 1180.0;
    });
  }

  static Float32List _clicks(
    List<int> starts,
    int total,
    double Function(int index) frequencyOf,
  ) {
    final out = Float32List(total);
    for (var i = 0; i < starts.length; i++) {
      final click = _click(frequencyOf(i));
      for (var s = 0; s < click.length && starts[i] + s < total; s++) {
        out[starts[i] + s] = click[s];
      }
    }
    return _normalize(out);
  }

  /// One click of the metronome, in the voice the player picked. [accent] is
  /// the first beat of the bar, which always sounds a little different so
  /// the ear can count without thinking.
  static Float32List click(ClickVoice voice, {bool accent = false}) {
    final out = switch (voice) {
      ClickVoice.stick => _click(accent ? 1760 : 1180),
      ClickVoice.snare => _snare(accent),
      ClickVoice.cymbal => _cymbal(accent),
      ClickVoice.clap => _clap(accent),
      ClickVoice.cowbell => _cowbell(accent),
    };
    return _normalize(out);
  }

  static Float32List _noise(int length, int seed) {
    final random = math.Random(seed);
    return Float32List(length)..setRange(0, length, [
      for (var i = 0; i < length; i++) random.nextDouble() * 2 - 1,
    ]);
  }

  /// White noise with a short body and a metallic ring on top.
  static Float32List _snare(bool accent) {
    final length = _samples(accent ? 0.24 : 0.2);
    final noise = _noise(length, 11);
    var previous = 0.0;
    final out = Float32List(length);
    for (var i = 0; i < length; i++) {
      final t = i / sampleRate;
      // Differencing removes the rumble, which is what makes a snare crack
      // instead of thud.
      final crack = noise[i] - previous;
      previous = noise[i];
      final ring = math.sin(2 * math.pi * 320 * t) * 0.25;
      out[i] = (crack * math.exp(-t * 26) + ring * math.exp(-t * 14)) * 0.8;
    }
    return out;
  }

  /// A long, bright wash with the inharmonic partials of a real cymbal.
  static Float32List _cymbal(bool accent) {
    final length = _samples(accent ? 0.55 : 0.45);
    final noise = _noise(length, 5);
    var previous = 0.0;
    final out = Float32List(length);
    const partials = [3418.0, 4201.0, 5321.0, 6712.0];
    for (var i = 0; i < length; i++) {
      final t = i / sampleRate;
      final hiss = noise[i] - previous;
      previous = noise[i];
      var shimmer = 0.0;
      for (final frequency in partials) {
        shimmer += math.sin(2 * math.pi * frequency * t);
      }
      out[i] =
          hiss * math.exp(-t * 5.5) * 0.9 +
          shimmer / partials.length * math.exp(-t * 7) * 0.35;
    }
    return out;
  }

  /// Three slaps a few milliseconds apart, then a small room tail.
  static Float32List _clap(bool accent) {
    final length = _samples(0.4);
    final noise = _noise(length, 3);
    final out = Float32List(length);
    var previous = 0.0;
    final slaps = accent ? [0.0, 0.011, 0.022, 0.034] : [0.0, 0.012, 0.024];
    for (var i = 0; i < length; i++) {
      final t = i / sampleRate;
      previous = previous * 0.55 + noise[i] * 0.45; // one-pole lowpass
      var envelope = 0.0;
      for (final slap in slaps) {
        if (t >= slap) {
          envelope = math.max(envelope, math.exp(-(t - slap) * 42));
        }
      }
      out[i] = previous * envelope;
    }
    return out;
  }

  /// The two square-ish pitches a cowbell is cut from.
  static Float32List _cowbell(bool accent) {
    final length = _samples(0.3);
    final low = accent ? 587.0 : 540.0;
    final high = accent ? 880.0 : 800.0;
    final out = Float32List(length);
    // A hard start clicks, so open the square wave with the same short ramp
    // the plucked strings use.
    final attack = math.min(length, _samples(0.002));
    for (var i = 0; i < length; i++) {
      final t = i / sampleRate;
      final envelope = math.exp(-t * 12) * (i < attack ? i / attack : 1.0);
      double square(double wave) => wave >= 0 ? 0.35 : -0.35;
      final tone =
          square(math.sin(2 * math.pi * low * t)) +
          square(math.sin(2 * math.pi * high * t));
      out[i] = tone * envelope;
    }
    return out;
  }

  static int _samples(double seconds) => (seconds * sampleRate).round();

  /// Karplus-Strong for one frequency.
  static Float32List _pluck(double frequency, int length, {double gain = 1.0}) {
    final period = math.max(2, (sampleRate / frequency).round());
    final delay = Float64List(period);
    final random = math.Random(period);
    for (var i = 0; i < period; i++) {
      delay[i] = random.nextDouble() * 2 - 1;
    }

    final out = Float32List(length);
    var index = 0;
    for (var i = 0; i < length; i++) {
      final next = (delay[index] + delay[(index + 1) % period]) * 0.5 * 0.9958;
      out[i] = delay[index] * gain;
      delay[index] = next;
      index = (index + 1) % period;
    }

    // A hard start clicks, so fade the first few milliseconds in.
    final attack = math.min(length, _samples(0.004));
    for (var i = 0; i < attack; i++) {
      out[i] *= i / attack;
    }
    return out;
  }

  static Float32List _click(double frequency) {
    const length = 2205; // 50 ms
    final out = Float32List(length);
    for (var i = 0; i < length; i++) {
      final t = i / sampleRate;
      final envelope = math.exp(-t * 45);
      out[i] = math.sin(2 * math.pi * frequency * t) * envelope;
    }
    return out;
  }

  static Float32List _layered(List<Float32List> parts, List<int> offsets) =>
      _normalize(_mix(parts, offsets));

  static Float32List _mix(List<Float32List> parts, List<int> offsets) {
    var longest = 0;
    for (var i = 0; i < parts.length; i++) {
      longest = math.max(longest, offsets[i] + parts[i].length);
    }
    final out = Float32List(longest);
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      for (var s = 0; s < part.length; s++) {
        out[offsets[i] + s] += part[s];
      }
    }
    return out;
  }

  static Float32List _normalize(Float32List samples) {
    var peak = 0.0;
    for (final sample in samples) {
      peak = math.max(peak, sample.abs());
    }
    if (peak < 1e-6) return samples;
    final scale = 0.82 / peak;
    final out = Float32List(samples.length);
    for (var i = 0; i < samples.length; i++) {
      out[i] = samples[i] * scale;
    }
    // Release the last few milliseconds instead of cutting the tail off.
    final fade = math.min(out.length, _samples(0.05));
    for (var i = 0; i < fade; i++) {
      out[out.length - 1 - i] *= i / fade;
    }
    return out;
  }
}

/// 16-bit PCM mono WAV, the one container every browser decodes instantly.
Uint8List encodeWavMono(Float32List samples, {int sampleRate = 44100}) {
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
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * 2, Endian.little);
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
