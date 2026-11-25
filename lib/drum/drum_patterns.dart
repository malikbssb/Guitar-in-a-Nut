import '../audio/click_voice.dart';

/// How many cells one pass of the grid holds: a bar of four beats, chopped
/// into sixteenth notes.
const int drumSteps = 16;

/// The lanes, top to bottom. Drums first, then the metal ones, because that
/// is the order a beginner reaches for them.
const List<ClickVoice> drumLanes = [
  ClickVoice.kick,
  ClickVoice.snare,
  ClickVoice.tom,
  ClickVoice.clap,
  ClickVoice.cowbell,
  ClickVoice.hatClosed,
  ClickVoice.hatSemi,
  ClickVoice.hatOpen,
  ClickVoice.cymbal,
  ClickVoice.bell,
  ClickVoice.stick,
];

/// A bar someone else already wrote, to start from rather than from silence.
class DrumPattern {
  final String name;
  final Map<ClickVoice, Set<int>> hits;

  const DrumPattern(this.name, this.hits);

  bool isOn(ClickVoice lane, int step) => hits[lane]?.contains(step) ?? false;
}

const List<DrumPattern> drumPresets = [
  DrumPattern('Rock beat', {
    ClickVoice.kick: {0, 10},
    ClickVoice.snare: {4, 12},
    ClickVoice.cymbal: {0, 4, 8, 12},
  }),
  DrumPattern('Four on the floor', {
    ClickVoice.kick: {0, 4, 8, 12},
    ClickVoice.clap: {4, 12},
    ClickVoice.bell: {2, 6, 10, 14},
  }),
  DrumPattern('Funk', {
    ClickVoice.kick: {0, 6, 10},
    ClickVoice.snare: {4, 12},
    ClickVoice.stick: {2, 8, 14},
    ClickVoice.cowbell: {0, 8},
  }),
];
