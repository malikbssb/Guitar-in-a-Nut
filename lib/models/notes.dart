import 'dart:math' as math;

/// Sharp spelling of the 12 chromatic notes, index 0 = C.
const noteNames = <String>[
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];

/// Semitone distances used throughout the site.
const int halfStep = 1;
const int wholeStep = 2;
const int minorThird = 3;
const int majorThird = 4;
const int perfectFourth = 5;
const int perfectFifth = 7;
const int octave = 12;

String intervalName(int semitones) {
  switch (semitones) {
    case halfStep:
      return 'half step';
    case wholeStep:
      return 'whole step';
    case minorThird:
      return 'minor 3rd';
    case majorThird:
      return 'major 3rd';
    case perfectFourth:
      return 'perfect 4th';
    case perfectFifth:
      return 'perfect 5th';
    case octave:
      return 'octave';
    default:
      return '$semitones semitones';
  }
}

/// A note name, its MIDI number and how far the measured pitch sits from it.
class NoteInfo {
  final String name;
  final int midi;
  final double cents;

  const NoteInfo({required this.name, required this.midi, required this.cents});

  bool get isIntoned => cents.abs() < 4;
}

class PitchNames {
  /// `midi` 60 is C4, the standard scientific pitch notation.
  static String of(int midi) => noteNames[midi % 12];

  static String withOctave(int midi) => '${of(midi)}${(midi ~/ 12) - 1}';

  static double frequencyOf(int midi) =>
      440.0 * math.pow(2.0, (midi - 69) / 12.0);

  static NoteInfo nearest(double frequency) {
    final exact = 69 + 12 * (math.log(frequency / 440.0) / math.ln2);
    final midi = exact.round();
    return NoteInfo(
      name: withOctave(midi),
      midi: midi,
      cents: (exact - midi) * 100,
    );
  }
}

/// Open-string notes of a tuning, from the lowest (6th) to the highest (1st).
class Tuning {
  final String name;

  /// Compact label shown above the six strings, e.g. "(E standard)".
  final String short;
  final String hint;
  final List<int> openMidis;

  const Tuning({
    required this.name,
    required this.short,
    required this.hint,
    required this.openMidis,
  });
}

const tunings = <Tuning>[
  Tuning(
    name: 'Standard (E A D G B E)',
    short: 'E standard',
    hint: 'The reference tuning, used on about 90 % of recordings.',
    openMidis: [40, 45, 50, 55, 59, 64],
  ),
  Tuning(
    name: 'Drop D',
    short: 'Drop D',
    hint: 'Only the 6th string drops a whole step: heavier low end.',
    openMidis: [38, 45, 50, 55, 59, 64],
  ),
  Tuning(
    name: 'Half step down',
    short: 'Eb standard',
    hint: 'Eb Ab Db Gb Bb Eb. Sits lower, makes singing easier.',
    openMidis: [39, 44, 49, 54, 58, 63],
  ),
  Tuning(
    name: 'D standard',
    short: 'D standard',
    hint: 'D G C F A D. Every string a whole step down; needs heavier strings.',
    openMidis: [38, 43, 48, 53, 57, 62],
  ),
  Tuning(
    name: 'Drop C',
    short: 'Drop C',
    hint: 'C G C F A D. One low note away from D standard, made for riffs.',
    openMidis: [36, 43, 48, 53, 57, 62],
  ),
  Tuning(
    name: 'DADGAD (modal)',
    short: 'DADGAD',
    hint: 'Open modal tuning, a staple of Celtic and folk guitar.',
    openMidis: [38, 45, 50, 55, 57, 62],
  ),
  Tuning(
    name: 'Open G (slide)',
    short: 'Open G',
    hint: 'Strum all six open strings and a G major chord rings out.',
    openMidis: [38, 43, 50, 55, 59, 62],
  ),
  Tuning(
    name: 'Open D',
    short: 'Open D',
    hint: 'D A D F# A D. Six open strings already spell a D major.',
    openMidis: [38, 45, 50, 54, 57, 62],
  ),
  Tuning(
    name: 'Open E',
    short: 'Open E',
    hint:
        'Slide up to fret 4 and that is Open C. Tense on the neck, huge '
        'in the room.',
    openMidis: [40, 47, 52, 56, 59, 64],
  ),
  Tuning(
    name: 'Open C',
    short: 'Open C',
    hint: 'C G C E G C. Deep and slow, the tuning of a lot of fingerstyle.',
    openMidis: [36, 43, 48, 52, 55, 60],
  ),
];

/// Guitar strings, numbered from the lowest pitched to the highest.
const stringNumbers = <int>[6, 5, 4, 3, 2, 1];

double targetFrequency(Tuning tuning, int stringIndex) =>
    PitchNames.frequencyOf(tuning.openMidis[stringIndex]);
