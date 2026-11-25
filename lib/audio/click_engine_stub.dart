import 'dart:async';

import 'click_voice.dart';

/// Silent stand-in for platforms without an audio clock, so widget tests can
/// still watch the dots light up and count the bars out.
///
/// It keeps the same shape as the web engine, including the beat index it
/// reports back, which is why the screen never has to know which one it got.
Timer? _timer;
int _played = 0;
double _bpm = 90;
int? _totalBeats;
void Function(int beat)? _onBeat;
void Function()? _onEnd;

Duration get _step => Duration(microseconds: (60e6 / _bpm).round());

Future<void> prepareClickEngine() async {}

Future<void> startClickLoop({
  required double bpm,
  required int beatsPerBar,
  int? totalBeats,
  required ClickVoice voice,
  required bool stressFirstBeat,
  required void Function(int beat) onBeat,
  required void Function() onEnd,
}) async {
  stopClickLoop();
  _bpm = bpm;
  _totalBeats = totalBeats;
  _onBeat = onBeat;
  _onEnd = onEnd;
  _played = 0;
  _tick();
  _timer = Timer.periodic(_step, (_) => _tick());
}

void _tick() {
  if (_totalBeats != null && _played >= _totalBeats!) {
    stopClickLoop();
    _onEnd?.call();
    return;
  }
  _onBeat?.call(_played);
  _played++;
}

void stopClickLoop() {
  _timer?.cancel();
  _timer = null;
}

void setClickTempo(double bpm) {
  _bpm = bpm;
  // A periodic timer keeps the spacing it was armed with, so re-arm it.
  if (_timer != null) {
    _timer!.cancel();
    _timer = Timer.periodic(_step, (_) => _tick());
  }
}

void setClickVoice(ClickVoice voice) {}

/// Nothing to stress: this engine makes no sound at all.
void setClickStress(bool stress) {}

Future<void> previewClick(ClickVoice voice) async {}
