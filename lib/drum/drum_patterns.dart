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

/// A bar in the shape the drum machine edits it, where a [DrumPattern] is a
/// bar someone else wrote. The presets are const, so their hit sets cannot be
/// tapped on; copying one into a `DrumBar` gives the screen sets it may change.
class DrumBar {
  final Map<ClickVoice, Set<int>> hits;

  DrumBar(Map<ClickVoice, Set<int>> hits)
    : hits = {
        for (final lane in drumLanes) lane: {...hits[lane] ?? const <int>{}},
      };

  factory DrumBar.from(DrumPattern pattern) => DrumBar(pattern.hits);

  /// The step indices sound on the beat, so a bar can be judged by where its
  /// hits fall without counting them lane by lane.
  List<ClickVoice> voicesOn(int step) => [
    for (final lane in drumLanes)
      if (hits[lane]!.contains(step)) lane,
  ];

  /// How many lanes speak on a step, which is how bright its cell in the
  /// overview map gets.
  int soundsOn(int step) =>
      hits.values.where((lane) => lane.contains(step)).length;

  int get litCells => hits.values.fold(0, (sum, lane) => sum + lane.length);

  bool get empty => litCells == 0;

  void toggle(ClickVoice lane, int step) {
    final hits = this.hits[lane]!;
    if (hits.contains(step)) {
      hits.remove(step);
    } else {
      hits.add(step);
    }
  }

  void clear() {
    for (final lane in drumLanes) {
      hits[lane]!.clear();
    }
  }

  DrumBar copied() => DrumBar(hits);
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
