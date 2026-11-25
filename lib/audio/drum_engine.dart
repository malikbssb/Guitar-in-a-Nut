/// The clock the drum machine steps on.
///
/// Same shape as the metronome's engine, one call away from the grid: the
/// screen owns the pattern and the engine asks it what to sound on each step,
/// so a cell tapped mid-loop is heard on the next pass.
library;

export 'drum_engine_stub.dart'
    if (dart.library.js_interop) 'drum_engine_web.dart';
