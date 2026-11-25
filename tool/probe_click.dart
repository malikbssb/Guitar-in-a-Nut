// Describes a source one-shot — length, where the transient is, how the level
// falls away, and how bright it is over time — so a new metronome voice can be
// named and given an honest tail before trim_clicks.dart cuts it.
//
//   dart run tool/probe_click.dart <source.wav|source.aiff>
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'audio_input.dart';

void main(List<String> args) {
  final input = readAudioInput(args.first);
  final mono = input.mono;
  final rate = input.sampleRate;
  final n = mono.length;

  var peak = 0.0;
  for (final sample in mono) {
    peak = sample.abs() > peak ? sample.abs() : peak;
  }
  stdout.writeln(
    'rate=$rate seconds=${(n / rate).toStringAsFixed(3)} peak=${peak.toStringAsFixed(4)}',
  );
  if (peak == 0) {
    stderr.writeln('${args.first} is silent');
    exit(1);
  }

  var attack = 0;
  for (var i = 0; i < n; i++) {
    if (mono[i].abs() > peak * 0.08) {
      attack = i;
      break;
    }
  }
  stdout.writeln('attack=${(attack / rate * 1000).round()} ms');
  for (final limit in [0.25, 0.12, 0.06, 0.03, 0.01]) {
    var last = attack;
    for (var i = attack; i < n; i++) {
      if (mono[i].abs() > peak * limit) last = i;
    }
    stdout.writeln(
      'above ${(limit * 100).round()}% until ${(last / rate * 1000).round()} ms',
    );
  }

  // Band energies over the first two seconds, to tell a ping from a wash.
  final window = (0.05 * rate).round();
  final binHz = rate / window;
  for (var w = 0; w * window + window + attack <= n; w++) {
    final seg = Float64List(window);
    for (var i = 0; i < window; i++) {
      seg[i] = mono[attack + w * window + i];
    }
    final spectrum = _magnitudes(seg);
    double band(double lo, double hi) {
      var sum = 0.0;
      for (var k = 0; k < spectrum.length; k++) {
        final hz = k * binHz;
        if (hz >= lo && hz < hi) sum += spectrum[k];
      }
      return sum;
    }

    final total = band(0, rate / 2) + 1e-9;
    var centroid = 0.0;
    for (var k = 0; k < spectrum.length; k++) {
      centroid += k * binHz * spectrum[k];
    }
    centroid /= total;
    stdout.writeln(
      't=${(w * 50)} ms low=${(band(0, 1000) / total * 100).round()}% '
      'mid=${(band(1000, 4000) / total * 100).round()}% '
      'high=${(band(4000, 20000) / total * 100).round()}% '
      'centre=${centroid.round()}Hz',
    );
  }
}

Float64List _magnitudes(Float64List input) {
  final n = input.length;
  final out = Float64List(n ~/ 2);
  for (var k = 0; k < out.length; k++) {
    var re = 0.0;
    var im = 0.0;
    for (var t = 0; t < n; t++) {
      final angle = -2 * math.pi * k * t / n;
      re += input[t] * math.cos(angle);
      im += input[t] * math.sin(angle);
    }
    out[k] = math.sqrt(re * re + im * im) / n;
  }
  return out;
}
