import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'click_engine_web.dart';
import 'click_voice.dart';

/// The drum machine, on the same audio clock as the metronome.
///
/// A step is a sixteenth note, so four steps make a beat. Each step is booked
/// a little before it is due, and the pattern is read at booking time rather
/// than handed over once: that is what lets a cell tapped mid-loop sound on
/// the next pass without stopping and restarting anything.
_DrumLoop? _loop;
int _generation = 0;

const double _lookahead = 0.2;
const Duration _pumpEvery = Duration(milliseconds: 50);

/// Where each lane sits in the mix. The samples are all cut to the same peak,
/// but a cymbal that keeps ringing covers a kick that lasts a tenth of a
/// second, so the long and bright lanes come in quieter.
const Map<ClickVoice, double> _laneGain = {
  ClickVoice.kick: 0.9,
  ClickVoice.snare: 0.75,
  ClickVoice.tom: 0.8,
  ClickVoice.cymbal: 0.42,
  ClickVoice.bell: 0.4,
  ClickVoice.clap: 0.7,
  ClickVoice.cowbell: 0.45,
  ClickVoice.stick: 0.6,
  ClickVoice.hatClosed: 0.38,
  ClickVoice.hatSemi: 0.42,
  ClickVoice.hatOpen: 0.3,
};

Future<void> startDrumLoop({
  required double bpm,
  required int steps,
  required List<ClickVoice> Function(int step) voicesAt,
  required void Function(int step) onStep,
}) async {
  stopDrumLoop();
  final generation = ++_generation;
  final context = audioClock();
  await clickBuffers();
  // The context only runs once something has been tapped, and this call comes
  // from the Play button.
  await context.resume().toDart;
  if (generation != _generation) return;
  _loop = _DrumLoop(
    context: context,
    bpm: bpm,
    steps: steps,
    voicesAt: voicesAt,
    onStep: onStep,
  )..start();
}

void stopDrumLoop() {
  _generation++;
  _loop?.stop();
  _loop = null;
}

void setDrumTempo(double bpm) => _loop?.bpm = bpm;

class _DrumLoop {
  final web.AudioContext context;
  final int steps;
  final List<ClickVoice> Function(int step) voicesAt;
  final void Function(int step) onStep;

  double bpm;

  int _booked = 0;
  double _nextTime = 0;

  Timer? _pump;
  final List<Timer> _lights = [];
  final List<web.AudioBufferSourceNode> _sounding = [];

  _DrumLoop({
    required this.context,
    required this.bpm,
    required this.steps,
    required this.voicesAt,
    required this.onStep,
  });

  double get _spacing => 60.0 / bpm / 4;

  void start() {
    _nextTime = context.currentTime + 0.08;
    _pump = Timer.periodic(_pumpEvery, (_) => _book());
    _book();
  }

  void _book() {
    // Each wake-up drops the lights that already shone, so a long run does
    // not keep a timer per step.
    _lights.removeWhere((light) => !light.isActive);
    final horizon = context.currentTime + _lookahead;
    while (_nextTime < horizon) {
      _schedule(_nextTime, _booked.remainder(steps));
      _booked++;
      _nextTime += _spacing;
    }
  }

  void _schedule(double at, int step) {
    for (final voice in voicesAt(step)) {
      final buffer = clickBuffer(voice);
      if (buffer == null) continue;
      final source = context.createBufferSource()..buffer = buffer;
      final volume = context.createGain()..gain.value = _laneGain[voice] ?? 0.7;
      source.connect(volume);
      volume.connect(context.destination);
      source.start(at);
      _sounding.add(source);
      source.onended = ((web.Event _) => _sounding.remove(source)).toJS;
    }

    // The playhead follows the sound, not the booking, so it never runs a
    // fifth of a second ahead of what the ear is hearing.
    final wait = ((at - context.currentTime) * 1000).round().clamp(0, 8000);
    _lights.add(Timer(Duration(milliseconds: wait), () => onStep(step)));
  }

  void stop() {
    _pump?.cancel();
    _pump = null;
    for (final light in _lights) {
      light.cancel();
    }
    _lights.clear();
    for (final source in _sounding) {
      source.stop();
    }
    _sounding.clear();
  }
}
