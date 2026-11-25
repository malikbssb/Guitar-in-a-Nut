import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'click_samples.dart';
import 'click_voice.dart';
import 'pluck_clip.dart';

/// The metronome, run on the browser's audio clock.
///
/// Every beat is booked with the exact time the audio thread should play it,
/// a little before it is due. The Dart timer only wakes the booking loop up,
/// so a slow frame, a background tab or a garbage collection moves the clicks
/// not at all: they were already handed over.
web.AudioContext? _context;
final Map<ClickVoice, web.AudioBuffer> _buffers = {};
Future<void>? _decoded;
_Loop? _loop;

/// Bumped by every start and stop, so a start that was still decoding when
/// the player hit Stop does not fire a loop nobody asked for.
int _generation = 0;

/// How far ahead of the clock beats are booked, and how often the booking
/// loop wakes up to book more. The margin only has to beat the wake-up time.
const double _lookahead = 0.2;
const Duration _pumpEvery = Duration(milliseconds: 50);

/// The click is quieter than a strum on purpose: it repeats, and a full-scale
/// tick twice a second tires the ear. The stressed first beat is the same hit
/// a notch louder and a little higher, which is how a real metronome marks the
/// bar, and how a drum sample stays recognisable while still standing out.
const double _plainGain = 0.6;
const double _accentGain = 0.85;
const double _accentRate = 1.18;

/// Decode every voice once, at startup, so the first Start is not the one
/// that pays for it.
Future<void> prepareClickEngine() async {
  _context ??= web.AudioContext();
  await _decodeAll();
}

/// The one audio clock the whole app books its beats against, shared with the
/// drum machine so the two never drift apart.
web.AudioContext audioClock() => _context ??= web.AudioContext();

/// The decoded sample for [voice], or null while the first decode is running.
web.AudioBuffer? clickBuffer(ClickVoice voice) => _buffers[voice];

/// Decode every sampled voice, and the stick's rendered fallback with them.
Future<void> clickBuffers() => _decodeAll();

Future<void> _decodeAll() {
  final context = _context ??= web.AudioContext();
  return _decoded ??= Future.wait([
    for (final voice in ClickVoice.values) _decode(context, voice),
  ]).then((_) {});
}

Future<void> _decode(web.AudioContext context, ClickVoice voice) async {
  if (_buffers.containsKey(voice)) return;
  // The stick has no file behind it, so its samples are rendered and wrapped
  // here rather than in a second code path.
  final bytes =
      clickSampleBytes(voice) ?? encodeWavMono(PluckClip.click(voice));
  final copy = Uint8List.fromList(bytes);
  _buffers[voice] = await context.decodeAudioData(copy.buffer.toJS).toDart;
}

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
  final generation = ++_generation;
  final context = _context ??= web.AudioContext();
  await _decodeAll();
  // Browsers park a context that has not seen a tap yet, and this call comes
  // from one. Until it is running, its clock does not move.
  await context.resume().toDart;
  if (generation != _generation) return;
  _loop = _Loop(
    context: context,
    bpm: bpm,
    beatsPerBar: beatsPerBar,
    totalBeats: totalBeats,
    voice: voice,
    stress: stressFirstBeat,
    onBeat: onBeat,
    onEnd: onEnd,
  )..start();
}

void stopClickLoop() {
  _generation++;
  _loop?.stop();
  _loop = null;
}

/// Read by the booking loop, so a change lands on the next beat.
void setClickVoice(ClickVoice voice) => _loop?.voice = voice;

void setClickTempo(double bpm) => _loop?.bpm = bpm;

/// Beats booked a fifth of a second ago keep the setting they were booked
/// with, which is the shortest honest delay for a switch clicked mid-run.
void setClickStress(bool stress) => _loop?.stress = stress;

Future<void> previewClick(ClickVoice voice) async {
  final context = _context ??= web.AudioContext();
  await _decodeAll();
  await context.resume().toDart;
  _playOne(context, voice, _accentGain, context.currentTime + 0.02);
}

void _playOne(
  web.AudioContext context,
  ClickVoice voice,
  double gain,
  double at,
) {
  final buffer = _buffers[voice];
  if (buffer == null) return;
  final source = context.createBufferSource()..buffer = buffer;
  final volume = context.createGain()..gain.value = gain;
  source.connect(volume);
  volume.connect(context.destination);
  source.start(at);
}

class _Loop {
  final web.AudioContext context;
  final int beatsPerBar;
  final int? totalBeats;
  final void Function(int beat) onBeat;
  final void Function() onEnd;

  double bpm;
  ClickVoice voice;

  /// Beat one of the bar, louder and higher, unless the player turned it off.
  bool stress;

  /// Beats already handed to the audio thread, and when the next one is due.
  int _booked = 0;
  double _nextTime = 0;

  Timer? _pump;
  final List<Timer> _lights = [];
  final List<web.AudioBufferSourceNode> _sounding = [];

  _Loop({
    required this.context,
    required this.bpm,
    required this.beatsPerBar,
    required this.totalBeats,
    required this.voice,
    required this.stress,
    required this.onBeat,
    required this.onEnd,
  });

  double get _spacing => 60.0 / bpm;

  void start() {
    _nextTime = context.currentTime + 0.08;
    _pump = Timer.periodic(_pumpEvery, (_) => _book());
    _book();
  }

  void _book() {
    if (totalBeats != null && _booked >= totalBeats!) {
      _pump?.cancel();
      _pump = null;
      return;
    }
    // Each wake-up drops the lights that already shone, so a long run does
    // not keep a timer per beat.
    _lights.removeWhere((light) => !light.isActive);
    final horizon = context.currentTime + _lookahead;
    while (_nextTime < horizon &&
        (totalBeats == null || _booked < totalBeats!)) {
      _schedule(_nextTime, _booked);
      _booked++;
      _nextTime += _spacing;
    }
  }

  void _schedule(double at, int beat) {
    final buffer = _buffers[voice];
    if (buffer == null) return;
    final source = context.createBufferSource()..buffer = buffer;
    final accent = stress && beat % beatsPerBar == 0;
    if (accent) source.playbackRate.value = _accentRate;
    final volume = context.createGain()
      ..gain.value = accent ? _accentGain : _plainGain;
    source.connect(volume);
    volume.connect(context.destination);
    source.start(at);
    _sounding.add(source);
    source.onended = ((web.Event _) => _sounding.remove(source)).toJS;

    // The dot follows the sound, so it waits for the beat it belongs to
    // rather than lighting up when that beat was booked.
    final wait = ((at - context.currentTime) * 1000).round().clamp(0, 8000);
    _lights.add(
      Timer(Duration(milliseconds: wait), () {
        onBeat(beat);
        if (totalBeats != null && beat == totalBeats! - 1) {
          _pump?.cancel();
          _pump = null;
          onEnd();
        }
      }),
    );
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
