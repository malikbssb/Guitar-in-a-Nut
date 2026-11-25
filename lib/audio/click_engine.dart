/// The metronome's clock.
///
/// A beat has to land where the ear expects it, and a Dart timer cannot
/// promise that: it decides when to *ask* for a sound, while the browser
/// decides when the sound actually starts. The web build therefore books each
/// beat against the audio hardware clock ahead of time, and everything else,
/// tests above all, gets a stand-in with the same shape.
library;

export 'click_engine_stub.dart'
    if (dart.library.js_interop) 'click_engine_web.dart';
