/// The one place the rest of the app asks for sound.
///
/// The real player needs the browser's audio engine, so the web build gets
/// [string_audio_web.dart] and everything else - tests above all - gets the
/// silent stub. Callers never have to care which one they got.
library;

export 'string_audio_stub.dart'
    if (dart.library.js_interop) 'string_audio_web.dart';
