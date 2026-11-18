import 'notes.dart';

/// A scale described the way guitarists actually learn it: the gap in frets
/// between one degree and the next. The gaps always add up to 12.
class GuitarScale {
  final String name;
  final String short;
  final String blurb;

  /// Frets between consecutive degrees, starting from the root.
  final List<int> steps;

  const GuitarScale({
    required this.name,
    required this.short,
    required this.blurb,
    required this.steps,
  });

  /// Semitones above the root for every degree, root included.
  List<int> get intervals {
    final result = <int>[0];
    var running = 0;
    for (final step in steps) {
      running += step;
      result.add(running);
    }
    return result;
  }

  /// The notes of the scale, ending on the octave so it sounds finished.
  List<int> midisFrom(int rootMidi) => [
    for (final interval in intervals) rootMidi + interval,
  ];

  String get fretPattern => steps.map((step) => '$step').join(' - ');

  String spelledFrom(int rootMidi) =>
      midisFrom(rootMidi).map(PitchNames.withOctave).join(' ');
}

/// The seven shapes a beginner meets in almost every lesson book.
const commonScales = <GuitarScale>[
  GuitarScale(
    name: 'Minor pentatonic',
    short: '5 notes',
    blurb:
        'The first scale most players learn. Five notes, no clashing ones, '
        'so solos made of it always sound intentional.',
    steps: [3, 2, 2, 3, 2],
  ),
  GuitarScale(
    name: 'Major',
    short: 'ionian',
    blurb:
        'The reference scale. Every other mode is this pattern started on a '
        'different note.',
    steps: [2, 2, 1, 2, 2, 2, 1],
  ),
  GuitarScale(
    name: 'Natural minor',
    short: 'aeolian',
    blurb:
        'The major scale with the 6th and 7th pulled down a half step. Sad, '
        'but in a calm way.',
    steps: [2, 1, 2, 2, 1, 2, 2],
  ),
  GuitarScale(
    name: 'Blues',
    short: '6 notes',
    blurb:
        'Minor pentatonic plus one extra note, the flat 5th. That single '
        'chromatic passing note is the whole blues sound.',
    steps: [3, 2, 1, 1, 3, 2],
  ),
  GuitarScale(
    name: 'Dorian',
    short: 'minor with a lift',
    blurb:
        'Natural minor with a raised 6th: still dark, but it swings. The '
        'scale behind a lot of funk and folk.',
    steps: [2, 1, 2, 2, 2, 1, 2],
  ),
  GuitarScale(
    name: 'Mixolydian',
    short: 'dominant',
    blurb:
        'Major with a flat 7th. Built for the V chord, which is why rock and '
        'country riffs live here.',
    steps: [2, 2, 1, 2, 2, 1, 2],
  ),
  GuitarScale(
    name: 'Harmonic minor',
    short: 'classical tension',
    blurb:
        'Natural minor with a raised 7th. That big gap before the octave is '
        'what makes it sound so dramatic.',
    steps: [2, 1, 2, 2, 1, 3, 1],
  ),
];
