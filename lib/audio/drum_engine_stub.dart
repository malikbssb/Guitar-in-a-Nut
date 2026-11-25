import 'dart:async';

import 'click_voice.dart';

/// Silent stand-in for platforms without an audio clock, so widget tests can
/// watch the playhead walk across the grid and count the steps.
///
/// Four steps to a beat, exactly like the web engine, because the grid is a
/// bar of sixteenth notes either way. Nothing is heard here, which is why the
/// pattern callback is accepted and then left alone.
Timer? _timer;
int _step = 0;
int _steps = 16;
double _bpm = 90;
void Function(int step)? _onStep;

Duration get _spacing => Duration(microseconds: (60e6 / _bpm / 4).round());

Future<void> startDrumLoop({
  required double bpm,
  required int steps,
  required List<ClickVoice> Function(int step) voicesAt,
  required void Function(int step) onStep,
}) async {
  stopDrumLoop();
  _bpm = bpm;
  _steps = steps;
  _onStep = onStep;
  _step = 0;
  _tick();
  _timer = Timer.periodic(_spacing, (_) => _tick());
}

void _tick() {
  _onStep?.call(_step);
  _step = (_step + 1) % _steps;
}

void stopDrumLoop() {
  _timer?.cancel();
  _timer = null;
}

void setDrumTempo(double bpm) {
  _bpm = bpm;
  // A periodic timer keeps the spacing it was armed with, so re-arm it.
  if (_timer != null) {
    _timer!.cancel();
    _timer = Timer.periodic(_spacing, (_) => _tick());
  }
}
