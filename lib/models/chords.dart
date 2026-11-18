import 'notes.dart';

/// One open-position chord, ready to be drawn as a diagram.
class ChordShape {
  final String name;
  final String blurb;

  /// Fret per string, index 0 = 6th (low) string, `-1` = muted.
  final List<int> frets;

  /// Finger per string: 0 = none, 1 = index … 4 = pinky.
  final List<int> fingers;

  const ChordShape({
    required this.name,
    required this.blurb,
    required this.frets,
    required this.fingers,
  });

  int get highestFret => frets.reduce((a, b) => a > b ? a : b);

  int get stringCount => frets.where((fret) => fret >= 0).length;

  /// MIDI values of the sounding notes, low string to high string.
  List<int> soundingMidis([
    List<int> openMidis = const [40, 45, 50, 55, 59, 64],
  ]) {
    final notes = <int>[];
    for (var i = 0; i < 6; i++) {
      if (frets[i] >= 0) notes.add(openMidis[i] + frets[i]);
    }
    return notes;
  }

  /// Note names played by the shape, e.g. C E G C E for a C major.
  String spelledNotes() => soundingMidis().map(PitchNames.of).join(' ');

  String get fretLine =>
      frets.map((fret) => fret < 0 ? 'x' : '$fret').join(' - ');
}

const _em = ChordShape(
  name: 'Em',
  blurb: 'The easiest shape: two fingers, and it sounds in almost any song.',
  frets: [0, 2, 2, 0, 0, 0],
  fingers: [0, 2, 3, 0, 0, 0],
);
const _am = ChordShape(
  name: 'Am',
  blurb:
      'Same shape as Em, moved one string group over. Minor, so it sounds sad.',
  frets: [-1, 0, 2, 2, 1, 0],
  fingers: [0, 0, 2, 3, 1, 0],
);
const _e = ChordShape(
  name: 'E',
  blurb: 'Em with one more finger: that single half step turns it major.',
  frets: [0, 2, 2, 1, 0, 0],
  fingers: [0, 2, 3, 1, 0, 0],
);
const _a = ChordShape(
  name: 'A',
  blurb: 'Three fingers in one row, all on fret 2.',
  frets: [-1, 0, 2, 2, 2, 0],
  fingers: [0, 0, 1, 2, 3, 0],
);
const _d = ChordShape(
  name: 'D',
  blurb: 'A triangle pointing down. The 6th and 5th strings stay silent.',
  frets: [-1, -1, 0, 2, 3, 2],
  fingers: [0, 0, 0, 1, 3, 2],
);
const _c = ChordShape(
  name: 'C',
  blurb: 'The chord that opens most folk songs. Watch out for the 6th string.',
  frets: [-1, 3, 2, 0, 1, 0],
  fingers: [0, 3, 2, 0, 1, 0],
);
const _g = ChordShape(
  name: 'G',
  blurb: 'Uses all six strings. Pairs with C and D for thousands of songs.',
  frets: [3, 2, 0, 0, 0, 3],
  fingers: [2, 1, 0, 0, 0, 3],
);
const _dm = ChordShape(
  name: 'Dm',
  blurb: 'D squeezed one fret tighter: the F is what makes it minor.',
  frets: [-1, -1, 0, 2, 3, 1],
  fingers: [0, 0, 0, 1, 3, 2],
);
const _f = ChordShape(
  name: 'F',
  blurb: 'The first barre. One finger lays across six strings at fret 1.',
  frets: [1, 3, 3, 2, 1, 1],
  fingers: [1, 3, 4, 2, 1, 1],
);
const _bb = ChordShape(
  name: 'Bb',
  blurb: 'The same barre shape slid up one fret. Heavy on the hand at first.',
  frets: [-1, 1, 3, 3, 3, 1],
  fingers: [0, 1, 3, 2, 4, 1],
);
const _bm = ChordShape(
  name: 'Bm',
  blurb:
      'Minor version of the barre: the whole shape moves up and down as one.',
  frets: [-1, 2, 4, 4, 3, 2],
  fingers: [0, 1, 3, 4, 2, 1],
);
const _fs = ChordShape(
  name: 'F#m',
  blurb:
      'Sixth string root barre at fret 2. The shape every rock solo leans on.',
  frets: [2, 4, 4, 2, 2, 2],
  fingers: [1, 3, 4, 1, 1, 1],
);
const _cs = ChordShape(
  name: 'C#m',
  blurb: 'The same minor barre, four frets up. Keep the thumb low behind the neck.',
  frets: [-1, 4, 6, 6, 5, 4],
  fingers: [0, 1, 3, 4, 2, 1],
);
const _gm = ChordShape(
  name: 'Gm',
  blurb: 'Minor barre on fret 3, the key of a lot of funk horns.',
  frets: [3, 5, 5, 3, 3, 3],
  fingers: [1, 3, 4, 1, 1, 1],
);
const _c7 = ChordShape(
  name: 'C7',
  blurb: 'C with a Bb dropped in: the chord that wants to move to F.',
  frets: [-1, 3, 2, 3, 1, 0],
  fingers: [0, 3, 2, 4, 1, 0],
);
const _d7 = ChordShape(
  name: 'D7',
  blurb: 'One finger less than D major, twice the pull back to G.',
  frets: [-1, -1, 0, 2, 1, 2],
  fingers: [0, 0, 0, 2, 1, 3],
);
const _e7 = ChordShape(
  name: 'E7',
  blurb: 'E with the D on the open 4th string. The default blues V chord.',
  frets: [0, 2, 0, 1, 0, 0],
  fingers: [0, 2, 0, 1, 0, 0],
);
const _g7 = ChordShape(
  name: 'G7',
  blurb: 'G minus one finger on the high string: it now leans towards C.',
  frets: [3, 2, 0, 0, 0, 1],
  fingers: [3, 2, 0, 0, 0, 1],
);
const _a7 = ChordShape(
  name: 'A7',
  blurb: 'Lift the middle finger off A major and the G appears.',
  frets: [-1, 0, 2, 0, 2, 0],
  fingers: [0, 0, 1, 0, 2, 0],
);
const _b7 = ChordShape(
  name: 'B7',
  blurb: 'Crossed fingers, no barre. The V of E, so it is in every blues in E.',
  frets: [-1, 2, 1, 2, 0, 2],
  fingers: [0, 2, 1, 3, 0, 4],
);
const _em7 = ChordShape(
  name: 'Em7',
  blurb: 'Em with the D added: softer, jazzy, still two fingers.',
  frets: [0, 2, 2, 0, 3, 0],
  fingers: [0, 2, 3, 0, 4, 0],
);
const _am7 = ChordShape(
  name: 'Am7',
  blurb: 'Am with one finger lifted. The gentlest way into a minor song.',
  frets: [-1, 0, 2, 0, 1, 0],
  fingers: [0, 0, 2, 0, 1, 0],
);
const _dm7 = ChordShape(
  name: 'Dm7',
  blurb: 'Dm with the high strings on fret 1. The ii of a jazz turnaround.',
  frets: [-1, -1, 0, 2, 1, 1],
  fingers: [0, 0, 0, 2, 1, 1],
);
const _cadd9 = ChordShape(
  name: 'Cadd9',
  blurb:
      'C with the D stretched in. It rings like a bell and costs one finger.',
  frets: [-1, 3, 2, 0, 3, 3],
  fingers: [0, 2, 1, 0, 3, 4],
);
const _fmaj7 = ChordShape(
  name: 'Fmaj7',
  blurb: 'Four strings, no barre, and the dreamiest chord in the key of C.',
  frets: [-1, -1, 3, 2, 1, 0],
  fingers: [0, 0, 3, 2, 1, 0],
);
const _asus4 = ChordShape(
  name: 'Asus4',
  blurb: 'Add the D on top of A. Let it ring, then resolve to A.',
  frets: [-1, 0, 2, 2, 3, 0],
  fingers: [0, 0, 1, 2, 3, 0],
);
const _dsus4 = ChordShape(
  name: 'Dsus4',
  blurb: 'The D shape with the high string moved up one fret.',
  frets: [-1, -1, 0, 2, 3, 3],
  fingers: [0, 0, 0, 1, 2, 3],
);
const _dsus2 = ChordShape(
  name: 'Dsus2',
  blurb: 'The same string dropped open instead. Neither major nor minor.',
  frets: [-1, -1, 0, 2, 3, 0],
  fingers: [0, 0, 0, 1, 2, 0],
);
const _esus4 = ChordShape(
  name: 'Esus4',
  blurb: 'E with both middle fingers down. Rock intros live on this and Esus2.',
  frets: [0, 2, 2, 2, 0, 0],
  fingers: [0, 2, 3, 4, 0, 0],
);
const _e5 = ChordShape(
  name: 'E5',
  blurb: 'Root and 5th only. No 3rd, so distortion has nothing to fight.',
  frets: [0, 2, 2, -1, -1, -1],
  fingers: [0, 2, 3, 0, 0, 0],
);
const _a5 = ChordShape(
  name: 'A5',
  blurb: 'The same two-note idea on the 5th string.',
  frets: [-1, 0, 2, 2, -1, -1],
  fingers: [0, 0, 2, 3, 0, 0],
);
const _d5 = ChordShape(
  name: 'D5',
  blurb: 'Three notes, one shape, and it moves up the neck like a slide.',
  frets: [-1, -1, 0, 2, 3, -1],
  fingers: [0, 0, 0, 1, 3, 0],
);
const _g5 = ChordShape(
  name: 'G5',
  blurb: 'Power chord on the 6th string, three frets up.',
  frets: [3, 5, 5, -1, -1, -1],
  fingers: [1, 3, 4, 0, 0, 0],
);

/// The chords a beginner meets in almost every song.
const commonChords = <ChordShape>[_em, _am, _e, _a, _d, _c, _g];

/// A chord doing a job inside one key: I, ii, V, and so on.
class KeyChord {
  final ChordShape chord;

  /// Roman numeral as chord sheets write it. Capital means major.
  final String degree;

  const KeyChord(this.chord, this.degree);
}

/// The shapes that belong to one key, plus the extra colours borrowed from it.
class ChordGroup {
  final String name;
  final String blurb;
  final List<KeyChord> chords;

  const ChordGroup({
    required this.name,
    required this.blurb,
    required this.chords,
  });

  List<ChordShape> get shapes => [for (final entry in chords) entry.chord];
}

/// The five keys that cover most of the beginner repertoire, then the shapes
/// that live outside them. A major key and its minor relative share every
/// note, which is why they are listed together.
const chordGroups = <ChordGroup>[
  ChordGroup(
    name: 'Key of C major / A minor',
    blurb:
        'No sharps, no flats: the seven white notes. The first six shapes '
        'use only those notes; the rest are the colours the blues and the '
        'parallel minor borrow.',
    chords: [
      KeyChord(_c, 'I'),
      KeyChord(_dm, 'ii'),
      KeyChord(_em, 'iii'),
      KeyChord(_f, 'IV'),
      KeyChord(_g, 'V'),
      KeyChord(_am, 'vi'),
      KeyChord(_cadd9, 'I add9'),
      KeyChord(_fmaj7, 'IV maj7'),
      KeyChord(_am7, 'vi7'),
      KeyChord(_dm7, 'ii7'),
      KeyChord(_g7, 'V7'),
      KeyChord(_c7, 'I7 blues'),
      KeyChord(_bb, 'bVII borrowed'),
    ],
  ),
  ChordGroup(
    name: 'Key of G major / E minor',
    blurb:
        'One sharp (F#) and the friendliest key for singing: the open G, C, D '
        'and Em shapes all sit under one hand.',
    chords: [
      KeyChord(_g, 'I'),
      KeyChord(_am, 'ii'),
      KeyChord(_bm, 'iii'),
      KeyChord(_c, 'IV'),
      KeyChord(_d, 'V'),
      KeyChord(_em, 'vi'),
      KeyChord(_d7, 'V7'),
      KeyChord(_em7, 'vi7'),
      KeyChord(_cadd9, 'IV add9'),
      KeyChord(_gm, 'iv minor borrowed'),
    ],
  ),
  ChordGroup(
    name: 'Key of D major / B minor',
    blurb:
        'Two sharps, F# and C#. The open D and A shapes ring bright, and the '
        'relative minor Bm is the first barre most people fight with.',
    chords: [
      KeyChord(_d, 'I'),
      KeyChord(_em, 'ii'),
      KeyChord(_fs, 'iii'),
      KeyChord(_g, 'IV'),
      KeyChord(_a, 'V'),
      KeyChord(_bm, 'vi'),
      KeyChord(_a7, 'V7'),
      KeyChord(_d7, 'I7 blues'),
      KeyChord(_dsus4, 'I sus4'),
      KeyChord(_em7, 'ii7'),
    ],
  ),
  ChordGroup(
    name: 'Key of A major / F# minor',
    blurb:
        'Three sharps. Most of it lives on the middle four strings, so the '
        'barre shapes on the low strings are what make it hard.',
    chords: [
      KeyChord(_a, 'I'),
      KeyChord(_bm, 'ii'),
      KeyChord(_cs, 'iii'),
      KeyChord(_d, 'IV'),
      KeyChord(_e, 'V'),
      KeyChord(_fs, 'vi'),
      KeyChord(_e7, 'V7'),
      KeyChord(_asus4, 'I sus4'),
      KeyChord(_d7, 'IV7 blues'),
      KeyChord(_am7, 'i7 from A minor'),
    ],
  ),
  ChordGroup(
    name: 'Key of E major / C# minor',
    blurb:
        'Four sharps, and the loudest key on a guitar: every open string is '
        'in it. Capos at fret 7 turn it into B, which is why it is so common.',
    chords: [
      KeyChord(_e, 'I'),
      KeyChord(_fs, 'ii'),
      KeyChord(_cs, 'iii'),
      KeyChord(_a, 'IV'),
      KeyChord(_b7, 'V7'),
      KeyChord(_am, 'iv minor borrowed'),
      KeyChord(_esus4, 'I sus4'),
      KeyChord(_em7, 'i7 from E minor'),
      KeyChord(_a7, 'IV7 blues'),
    ],
  ),
  ChordGroup(
    name: 'Dominant 7ths: the blues set',
    blurb:
        'A 12-bar blues in E asks for E7, A7 and B7; one in A asks for A7, D7 '
        'and E7. These six shapes cover both, and the rest by moving them.',
    chords: [
      KeyChord(_e7, 'V7 of A'),
      KeyChord(_a7, 'V7 of D'),
      KeyChord(_b7, 'V7 of E'),
      KeyChord(_d7, 'V7 of G'),
      KeyChord(_g7, 'V7 of C'),
      KeyChord(_c7, 'V7 of F'),
    ],
  ),
  ChordGroup(
    name: 'Sus and add: colours, not resolutions',
    blurb:
        'These keep the root and drop or stretch one note, so they sound open '
        'instead of happy or sad. Most of them are one finger away from a '
        'shape you already know.',
    chords: [
      KeyChord(_asus4, 'sus4'),
      KeyChord(_dsus4, 'sus4'),
      KeyChord(_dsus2, 'sus2'),
      KeyChord(_esus4, 'sus4'),
      KeyChord(_cadd9, 'add9'),
      KeyChord(_fmaj7, 'maj7'),
    ],
  ),
  ChordGroup(
    name: 'Power chords: root and 5th',
    blurb:
        'Two notes, no 3rd, so nothing is major or minor. Every one of these '
        'is the same shape, and moving it up two frets raises the chord a '
        'whole step.',
    chords: [
      KeyChord(_e5, 'E'),
      KeyChord(_a5, 'A'),
      KeyChord(_d5, 'D'),
      KeyChord(_g5, 'G'),
    ],
  ),
];

/// Every shape on the site, deduplicated, in the order the groups list them.
List<ChordShape> get allChords {
  final seen = <String>{};
  return [
    for (final group in chordGroups)
      for (final chord in group.shapes)
        if (seen.add(chord.name)) chord,
  ];
}

ChordShape chordByName(String name) =>
    allChords.firstWhere((chord) => chord.name == name);

/// Which keys a chord belongs to, used by the detail panel and the quiz.
List<ChordGroup> groupsHolding(String name) => chordGroups
    .where((group) => group.chords.any((e) => e.chord.name == name))
    .toList();
