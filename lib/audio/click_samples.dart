import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import 'click_voice.dart';

/// The voices that ship as real recordings, each one cut to the shortest tail
/// that still sounds like the instrument by `tool/trim_clicks.dart`. The stick
/// stays synthesised: the set had no wood block, and the classic tick is the
/// one sound nothing else replaces.
const clickSamplePaths = {
  ClickVoice.kick: 'assets/clicks/kick.wav',
  ClickVoice.snare: 'assets/clicks/snare.wav',
  ClickVoice.tom: 'assets/clicks/tom.wav',
  ClickVoice.cymbal: 'assets/clicks/cymbal.wav',
  ClickVoice.bell: 'assets/clicks/bell.wav',
  ClickVoice.clap: 'assets/clicks/clap.wav',
  ClickVoice.cowbell: 'assets/clicks/cowbell.wav',
  ClickVoice.hatClosed: 'assets/clicks/hat-closed.wav',
  ClickVoice.hatSemi: 'assets/clicks/hat-semi.wav',
  ClickVoice.hatOpen: 'assets/clicks/hat-open.wav',
};

final _bytes = <ClickVoice, Uint8List>{};

/// Read at startup, so no beat ever waits on a fetch.
Future<void> loadClickSamples() async {
  for (final entry in clickSamplePaths.entries) {
    _bytes[entry.key] = (await rootBundle.load(entry.value)).buffer
        .asUint8List();
  }
}

/// The WAV file for [voice], or null when that voice is still synthesised.
Uint8List? clickSampleBytes(ClickVoice voice) => _bytes[voice];
