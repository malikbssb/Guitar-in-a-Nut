/// Silent stand-in for platforms without a browser audio engine, so widget
/// tests can still tap every "hear it" button.
void playNote(int midi) {}

void playChord(List<int> midis) {}

void playRun(List<int> midis) {}

void playStrumPattern(List<int> midis, List<double> onsets) {}

void playMetronome(double bpm, {int beats = 4, int bars = 1}) {}

void playTimeline(List<double> lengths, {double bpm = 84}) {}
