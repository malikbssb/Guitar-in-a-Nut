import 'dart:math' as math;
import 'dart:typed_data';

class PitchReading {
  /// Detected fundamental in Hz, or 0 when nothing is trustworthy.
  final double frequency;

  /// How periodic the signal is, between 0 and 1.
  final double clarity;

  /// Normalised peak-to-peak level of the signal, between 0 and 1.
  final double level;

  const PitchReading({
    required this.frequency,
    required this.clarity,
    required this.level,
  });

  static const silent = PitchReading(frequency: 0, clarity: 0, level: 0);

  bool get isUsable => frequency > 0 && clarity > PitchDetector.clarityGate;
}

/// Pitch detection by normalised cross-correlation (NCCF).
///
/// The signal is decimated by 2 first: that halves the cost without losing the
/// useful range, since an open guitar string stays under ~330 Hz.
class PitchDetector {
  final int sampleRate;

  PitchDetector({this.sampleRate = 44100});

  static const double minFreq = 70;
  static const double maxFreq = 420;
  static const double clarityGate = 0.72;

  /// Samples kept after decimation.
  static const int window = 1024;

  late final int _halfRate = sampleRate ~/ 2;
  late final int _minLag = math.max(2, (_halfRate / maxFreq).ceil());
  late final int _maxLag = math.min(window - 2, (_halfRate / minFreq).floor());

  /// [pcm]: float samples between -1 and 1, at [sampleRate].
  PitchReading analyze(List<double> pcm) {
    if (pcm.length < window * 2) {
      return _levelOnly(pcm);
    }

    final start = pcm.length - window * 2;
    final x = Float64List(window);
    double peak = 0;
    for (var i = 0; i < window; i++) {
      // Averaging pairs also rolls off the high frequencies.
      final a = pcm[start + i * 2];
      final b = pcm[start + i * 2 + 1];
      final v = (a + b) * 0.5;
      x[i] = v;
      final absV = v.abs();
      if (absV > peak) peak = absV;
    }

    final level = math.min(1.0, peak);
    if (level < 0.02) {
      return PitchReading(frequency: 0, clarity: 0, level: level);
    }

    // Removing the DC offset: it skews the correlation.
    var mean = 0.0;
    for (var i = 0; i < window; i++) {
      mean += x[i];
    }
    mean /= window;

    // Prefix sums of squares, so each lag normalises in O(1).
    final squares = Float64List(window + 1);
    for (var i = 0; i < window; i++) {
      final v = x[i] - mean;
      x[i] = v;
      squares[i + 1] = squares[i] + v * v;
    }

    var bestLag = 0;
    var bestScore = -1.0;

    for (var lag = _minLag; lag <= _maxLag; lag++) {
      var r = 0.0;
      final limit = window - lag;
      for (var i = 0; i < limit; i++) {
        r += x[i] * x[i + lag];
      }
      final energyA = squares[limit];
      final energyB = squares[window] - squares[lag];
      final denom = math.sqrt(energyA * energyB);
      if (denom <= 0) continue;
      final score = r / denom;
      if (score > bestScore) {
        bestScore = score;
        bestLag = lag;
      }
    }

    if (bestLag < _minLag || bestScore < clarityGate) {
      return PitchReading(frequency: 0, clarity: bestScore, level: level);
    }

    final refined = _interpolate(x, squares, bestLag);
    return PitchReading(
      frequency: _halfRate / refined,
      clarity: bestScore,
      level: level,
    );
  }

  /// Parabolic interpolation around the peak: a fraction of a sample of extra
  /// precision, which brings the error down to a few cents.
  double _interpolate(Float64List x, Float64List squares, int lag) {
    double scoreAt(int k) {
      var r = 0.0;
      final limit = window - k;
      for (var i = 0; i < limit; i++) {
        r += x[i] * x[i + k];
      }
      final denom = math.sqrt(squares[limit] * (squares[window] - squares[k]));
      return denom <= 0 ? 0 : r / denom;
    }

    if (lag <= _minLag || lag >= _maxLag) return lag.toDouble();
    final y0 = scoreAt(lag - 1);
    final y1 = scoreAt(lag);
    final y2 = scoreAt(lag + 1);
    final denom = y0 - 2 * y1 + y2;
    if (denom.abs() < 1e-9) return lag.toDouble();
    final shift = (0.5 * (y0 - y2) / denom).clamp(-0.5, 0.5);
    return lag + shift;
  }

  PitchReading _levelOnly(List<double> pcm) {
    var peak = 0.0;
    for (final v in pcm) {
      final abs = v.abs();
      if (abs > peak) peak = abs;
    }
    return PitchReading(frequency: 0, clarity: 0, level: math.min(1.0, peak));
  }
}

/// Converts little-endian signed 16-bit PCM bytes into -1..1 floats.
void appendPcm16(List<int> bytes, List<double> out, {int byteOffset = 0}) {
  var i = byteOffset.isOdd ? 1 : 0;
  for (; i + 1 < bytes.length; i += 2) {
    var value = bytes[i] | (bytes[i + 1] << 8);
    if (value >= 0x8000) value -= 0x10000;
    out.add(value / 32768.0);
  }
}
