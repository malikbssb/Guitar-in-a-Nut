import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../audio/string_audio.dart';
import '../models/chords.dart';
import '../models/notes.dart';
import '../models/scales.dart';

/// One sound, played on tap, with the names it could have been.
class EarQuestion {
  final String prompt;
  final String kind;
  final VoidCallback play;
  final List<String> options;
  final int answerIndex;
  final String explanation;

  const EarQuestion({
    required this.prompt,
    required this.kind,
    required this.play,
    required this.options,
    required this.answerIndex,
    required this.explanation,
  });
}

/// The demos are always in E standard so the same clip means the same thing
/// whatever the visitor has selected in the top right.
const _open = <int>[40, 45, 50, 55, 59, 64];

/// How many sounds one round plays. The narrow rounds are capped by their own
/// pool: six strings, eight chords, ten neck notes.
int earRoundLength(EarMode mode) => switch (mode) {
  EarMode.openStrings => 6,
  EarMode.chords => 8,
  EarMode.neckNotes => 10,
  EarMode.everything => 12,
};

/// What the ear training round listens to. The first three narrow the sound
/// down to one skill; the last one mixes everything.
enum EarMode {
  openStrings(
    'Open strings only',
    'All six strings, played open, in a random order. Name the note.',
  ),
  chords(
    'Chords only',
    'Shapes straight off the CHORDS page, strummed one at a time.',
  ),
  neckNotes(
    'Notes across the neck',
    'A fretted note anywhere in the first twelve frets, on any string.',
  ),
  everything(
    'All in one',
    'Chords, notes, intervals, scales and meters, drawn from every pool.',
  );

  const EarMode(this.label, this.blurb);

  final String label;
  final String blurb;
}

/// A fresh round for [mode]: the pools are shuffled, so no two rounds play in
/// the same order or ask about the same sounds.
List<EarQuestion> earQuestionsFor(EarMode mode, {int? seed}) {
  final random = math.Random(seed);
  final count = earRoundLength(mode);

  return switch (mode) {
    EarMode.openStrings => _draw(_openStringPool(random), count, random),
    EarMode.chords => _draw(_chordPool(random), count, random),
    EarMode.neckNotes => _draw(_neckPool(random), count, random),
    EarMode.everything => _mix(
      [
        _openStringPool(random),
        _chordPool(random),
        _neckPool(random),
        _qualityPool(random),
        _intervalPool(random),
        _scalePool(random),
        _rhythmPool(random),
        _texturePool(random),
      ],
      count,
      random,
    ),
  };
}

/// How many sounds each mode can draw from, for the intro text.
int earPoolSize(EarMode mode) {
  final random = math.Random(3);
  return switch (mode) {
    EarMode.openStrings => _openStringPool(random).length,
    EarMode.chords => _chordPool(random).length,
    EarMode.neckNotes => _neckPool(random).length,
    EarMode.everything =>
      _openStringPool(random).length +
          _chordPool(random).length +
          _neckPool(random).length +
          _qualityPool(random).length +
          _intervalPool(random).length +
          _scalePool(random).length +
          _rhythmPool(random).length +
          _texturePool(random).length,
  };
}

List<EarQuestion> _draw(List<EarQuestion> pool, int count, math.Random random) {
  final shuffled = List<EarQuestion>.of(pool)..shuffle(random);
  return shuffled.take(math.min(count, shuffled.length)).toList();
}

/// Round-robin over the pools so a mixed round never ends up all chords.
List<EarQuestion> _mix(
  List<List<EarQuestion>> pools,
  int count,
  math.Random random,
) {
  final buckets = [
    for (final pool in pools)
      if (pool.isNotEmpty) List<EarQuestion>.of(pool)..shuffle(random),
  ];
  final round = <EarQuestion>[];
  while (round.length < count) {
    final before = round.length;
    for (final bucket in buckets) {
      if (round.length == count) break;
      if (bucket.isEmpty) continue;
      round.add(bucket.removeLast());
    }
    if (round.length == before) break;
  }
  return round..shuffle(random);
}

/// One answer plus three look-alikes, in a random order.
({List<String> options, int answerIndex}) _fourOptions(
  String answer,
  List<String> pool,
  math.Random random,
) {
  final distractors = pool.where((name) => name != answer).toList()
    ..shuffle(random);
  final options = [answer, ...distractors.take(3)]..shuffle(random);
  return (options: options, answerIndex: options.indexOf(answer));
}

/// The label above each string on the tuner: the two E names need to be told
/// apart because they are the same note an octave apart.
String _stringLabel(int index) => switch (index) {
  0 => 'E (low)',
  5 => 'E (high)',
  _ => PitchNames.of(_open[index]),
};

List<EarQuestion> _openStringPool(math.Random random) {
  final labels = [for (var i = 0; i < _open.length; i++) _stringLabel(i)];

  return [
    for (var index = 0; index < _open.length; index++)
      () {
        final midi = _open[index];
        final choice = _fourOptions(_stringLabel(index), labels, random);
        final gap = index == 0 ? 0 : midi - _open[index - 1];
        final where = gap == 0
            ? 'It is the thickest string, the one everything else is measured '
                  'from.'
            : 'It sits ${intervalName(gap)} above the '
                  '${stringNumbers[index - 1]} string, so comparing the two is '
                  'the fastest way to place it.';

        return EarQuestion(
          prompt: 'Which open string was plucked?',
          kind: 'note',
          play: () => playNote(midi),
          options: choice.options,
          answerIndex: choice.answerIndex,
          explanation:
              '${PitchNames.withOctave(midi)}, '
              '${PitchNames.frequencyOf(midi).toStringAsFixed(1)} Hz - the '
              'open ${stringNumbers[index]} string. $where',
        );
      }(),
  ];
}

List<EarQuestion> _chordPool(math.Random random) {
  final names = [for (final chord in allChords) chord.name];

  return [
    for (final chord in allChords)
      () {
        final choice = _fourOptions(chord.name, names, random);

        return EarQuestion(
          prompt: 'Which chord was strummed?',
          kind: 'chord',
          play: () => playChord(chord.soundingMidis(_open)),
          options: choice.options,
          answerIndex: choice.answerIndex,
          explanation:
              '${chord.name} spells out ${chord.spelledNotes()} on '
              '${chord.stringCount} strings. ${chord.blurb}',
        );
      }(),
  ];
}

/// Major, minor, seventh, suspended or power: the five things a strum can be.
List<EarQuestion> _qualityPool(math.Random random) {
  const answers = ['Major', 'Minor', 'Seventh', 'Suspended', 'Power chord'];

  return [
    for (final chord in allChords)
      () {
        final label = _qualityOf(chord);
        if (label == null) return null;
        final choice = _fourOptions(label, answers, random);

        return EarQuestion(
          prompt: 'What kind of chord was that?',
          kind: 'quality',
          play: () => playChord(chord.soundingMidis(_open)),
          options: choice.options,
          answerIndex: choice.answerIndex,
          explanation:
              '$label - and it is $label because ${chord.name} spells '
              '${chord.spelledNotes()}, built on '
              '${PitchNames.of(chord.soundingMidis(_open).first)}.',
        );
      }(),
  ].nonNulls.toList();
}

/// Sorted by the notes that actually ring, so nothing has to be trusted to
/// the chord name.
String? _qualityOf(ChordShape chord) {
  final midis = chord.soundingMidis(_open);
  final root = midis.first % 12;
  final classes = midis.map((midi) => midi % 12).toSet();
  final major = classes.contains((root + majorThird) % 12);
  final minor = classes.contains((root + minorThird) % 12);
  final fourth = classes.contains((root + perfectFourth) % 12);
  final flatSeventh = classes.contains((root + 10) % 12);

  if (classes.length <= 2) return 'Power chord';
  if (major && flatSeventh) return 'Seventh';
  if (major) return 'Major';
  if (minor) return 'Minor';
  if (fourth) return 'Suspended';
  return null;
}

List<EarQuestion> _neckPool(math.Random random) {
  final names = List<String>.of(noteNames);

  return [
    for (var string = 0; string < 6; string++)
      for (var fret = 1; fret <= 12; fret++)
        () {
          final midi = _open[string] + fret;
          final answer = PitchNames.of(midi);
          final choice = _fourOptions(answer, names, random);

          return EarQuestion(
            prompt: 'Which fretted note was plucked?',
            kind: 'note',
            play: () => playNote(midi),
            options: choice.options,
            answerIndex: choice.answerIndex,
            explanation:
                'That was ${PitchNames.withOctave(midi)}: $answer at fret '
                '$fret of the ${stringNumbers[string]} string. Find it on the '
                'neck page to hear it again in place.',
          );
        }(),
  ];
}

const _earIntervalSizes = [
  halfStep,
  wholeStep,
  minorThird,
  majorThird,
  perfectFourth,
  perfectFifth,
  octave,
];

List<EarQuestion> _intervalPool(math.Random random) {
  const names = [
    'Half step',
    'Whole step',
    'Minor 3rd',
    'Major 3rd',
    'Perfect 4th',
    'Perfect 5th',
    'Octave',
  ];

  return [
    for (var i = 0; i < _earIntervalSizes.length; i++) ...[
      () {
        final size = _earIntervalSizes[i];
        final root = _open[1];
        final choice = _fourOptions(names[i], names, random);

        return EarQuestion(
          prompt: 'Two notes, one after the other. Which interval?',
          kind: 'interval',
          play: () => playRun([root, root + size]),
          options: choice.options,
          answerIndex: choice.answerIndex,
          explanation:
              '${PitchNames.of(root)} up ${intervalName(size)} to '
              '${PitchNames.of(root + size)}: $size frets apart on the same '
              'string, which is the easiest way to find it again.',
        );
      }(),
      () {
        final size = _earIntervalSizes[i];
        final root = _open[3];
        final choice = _fourOptions(names[i], names, random);

        return EarQuestion(
          prompt: 'Same notes the other way round. Which interval?',
          kind: 'interval',
          play: () => playRun([root + size, root]),
          options: choice.options,
          answerIndex: choice.answerIndex,
          explanation:
              'Falling this time, ${intervalName(size)} from '
              '${PitchNames.of(root + size)} down to ${PitchNames.of(root)}. '
              'Direction changes the mood, not the distance.',
        );
      }(),
    ],
  ];
}

List<EarQuestion> _scalePool(math.Random random) {
  final names = [for (final scale in commonScales) scale.name];
  final ways = [
    for (final scale in commonScales) ...[
      '${scale.name}, up the neck',
      '${scale.name}, down the neck',
    ],
  ];

  return [
    for (final scale in commonScales) ...[
      () {
        final root = _open[2] + octave;
        final choice = _fourOptions(scale.name, names, random);

        return EarQuestion(
          prompt: 'Which scale ran up the neck?',
          kind: 'scale',
          play: () => playRun(scale.midisFrom(root)),
          options: choice.options,
          answerIndex: choice.answerIndex,
          explanation:
              '${scale.name}, from ${PitchNames.withOctave(root)}: '
              '${scale.spelledFrom(root)}. ${scale.blurb}',
        );
      }(),
      for (final ascending in [true, false])
        () {
          final root = _open[0] + octave;
          final midis = scale.midisFrom(root);
          final choice = _fourOptions(
            '${scale.name}, ${ascending ? 'up' : 'down'} the neck',
            ways,
            random,
          );

          return EarQuestion(
            prompt: 'Which scale, and which way?',
            kind: 'direction',
            play: () => playRun(ascending ? midis : midis.reversed.toList()),
            options: choice.options,
            answerIndex: choice.answerIndex,
            explanation: ascending
                ? 'Up: ${scale.name} climbing from '
                      '${PitchNames.withOctave(root)}: '
                      '${scale.spelledFrom(root)}.'
                : 'Down: ${scale.name} falling from '
                      '${PitchNames.withOctave(root + octave)} back to its '
                      'root. The same notes upward are what you practise '
                      'first.',
          );
        }(),
    ],
  ];
}

List<EarQuestion> _rhythmPool(math.Random random) {
  const meters = <(int, String)>[
    (4, '4/4'),
    (3, '3/4'),
    (6, '6/8'),
    (2, '2/4'),
  ];
  const names = ['4/4', '3/4', '6/8', '2/4'];
  // Three different clicks, so the four meters never sound like the same bar
  // repeated: only the count changes.
  const tempos = [96.0, 120.0, 76.0, 108.0];

  return [
    for (var meter = 0; meter < meters.length; meter++)
      () {
        final (beats, label) = meters[meter];
        final choice = _fourOptions(label, names, random);

        return EarQuestion(
          prompt: 'Which meter did you hear?',
          kind: 'rhythm',
          play: () => playMetronome(tempos[meter], beats: beats),
          options: choice.options,
          answerIndex: choice.answerIndex,
          explanation:
              '$label at ${tempos[meter].toInt()} bpm: $beats clicks with the '
              'accent on the first. '
              '${switch (label) {
                '4/4' => 'Rock, pop and blues live here.',
                '3/4' => 'ONE two three, the waltz.',
                '6/8' => 'Two groups of three, which is why it swings.',
                _ => 'ONE two, a march.',
              }}',
        );
      }(),
    for (final bpm in const [60, 84, 112])
      () {
        const pool = ['60 bpm', '84 bpm', '112 bpm', '140 bpm'];
        final choice = _fourOptions('$bpm bpm', pool, random);

        return EarQuestion(
          prompt: 'How fast was that click?',
          kind: 'rhythm',
          play: () => playMetronome(bpm.toDouble(), beats: 4),
          options: choice.options,
          answerIndex: choice.answerIndex,
          explanation:
              '$bpm beats a minute. 60 is one click per second; the faster it '
              'goes, the less time you have between strums.',
        );
      }(),
  ];
}

List<EarQuestion> _texturePool(math.Random random) {
  const shapes = ['C', 'G', 'Em', 'Am7', 'D'];
  const ways = [
    'Strummed all at once',
    'Picked one note at a time',
    'One string ringing alone',
    'Two notes, a 5th apart',
  ];

  EarQuestion one(String name, {required bool strummed}) {
    final choice = _fourOptions(strummed ? ways[0] : ways[1], ways, random);

    return EarQuestion(
      prompt: 'How was that chord played?',
      kind: 'texture',
      play: strummed
          ? () => playChord(chordByName(name).soundingMidis(_open))
          : () => playRun(chordByName(name).soundingMidis(_open)),
      options: choice.options,
      answerIndex: choice.answerIndex,
      explanation: strummed
          ? 'All at once: $name as one block. A strum hides its own notes, '
                'which is why the chord round is harder than the note round.'
          : 'An arpeggio: the notes of $name arriving in a row, so you can '
                'hear the shape inside the chord.',
    );
  }

  return [
    for (final name in shapes) ...[
      one(name, strummed: false),
      one(name, strummed: true),
    ],
  ];
}
