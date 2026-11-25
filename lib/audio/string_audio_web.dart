import 'dart:convert';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../models/notes.dart';
import 'pluck_clip.dart';

/// Synthesised guitar sound for the browser.
///
/// The samples are rendered in Dart, wrapped in a WAV and handed to an
/// `<audio>` element through a data URL. That keeps the whole pipeline inside
/// Dart, so the same code paths compile for tests and nothing has to be
/// fetched from the network.
void playNote(int midi) => _play(PluckClip.single(_hz(midi)));

void playChord(List<int> midis) => _play(PluckClip.chord(_hzAll(midis)));

void playRun(List<int> midis) => _play(PluckClip.run(_hzAll(midis)));

void playStrumPattern(List<int> midis, List<double> onsets) =>
    _play(PluckClip.pattern(_hzAll(midis), onsets));

void playMetronome(double bpm, {int beats = 4, int bars = 1}) =>
    _play(PluckClip.metronome(bpm, beats: beats, bars: bars));

void playTimeline(List<double> lengths, {double bpm = 84}) =>
    _play(PluckClip.timeline(lengths, bpm: bpm));

double _hz(int midi) => PitchNames.frequencyOf(midi);

List<double> _hzAll(List<int> midis) => [for (final midi in midis) _hz(midi)];

/// Elements can be collected while still playing, so the recent ones stay
/// reachable here.
final _live = <web.HTMLAudioElement>[];
const int _maxLive = 6;

void _play(Float32List samples, {double volume = 0.85}) =>
    _playBytes(encodeWavMono(samples), volume: volume);

void _playBytes(Uint8List wav, {required double volume}) {
  final audio = web.HTMLAudioElement()
    ..volume = volume
    ..src = 'data:audio/wav;base64,${base64Encode(wav)}';

  _live.add(audio);
  while (_live.length > _maxLive) {
    final oldest = _live.removeAt(0);
    oldest
      ..pause()
      ..src = '';
  }

  audio.play();
}
