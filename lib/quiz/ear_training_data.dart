import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../audio/string_audio.dart';
import '../models/chords.dart';
import '../models/notes.dart';
import '../models/scales.dart';
import 'quiz_level.dart';

/// One sound, played on tap, with the names it could have been.
class EarQuestion {
  final String prompt;
  final String kind;
  final VoidCallback play;
  final List<String> options;
  final int answerIndex;
  final String explanation;

  /// 0 for the sounds a beginner is expected to know, 1 for the open position
  /// and 2 for everything past it. See [QuizLevel.topTier].
  final int tier;

  const EarQuestion({
    required this.prompt,
    required this.kind,
    required this.play,
    required this.options,
    required this.answerIndex,
    required this.explanation,
    this.tier = 1,
  });

  String get answer => options[answerIndex];
}

/// The demos are always in E standard so the same clip means the same thing
/// whatever the visitor has selected in the top right.
const _open = <int>[40, 45, 50, 55, 59, 64];

/// How many sounds a round plays when the player does not choose. Rounds can
/// be longer than this; a pool that runs out simply repeats.
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
/// the same order or ask about the same sounds. A [count] longer than the
/// pool repeats sounds, never twice in a row.
List<EarQuestion> earQuestionsFor(
  EarMode mode, {
  int? seed,
  int? count,
  QuizLevel level = QuizLevel.medium,
}) {
  final random = math.Random(seed);
  final asked = count ?? earRoundLength(mode);
  final pools = _poolsFor(
    mode,
    random,
    level,
  ).where((p) => p.isNotEmpty).toList();
  if (pools.isEmpty) return const [];
  if (pools.length == 1) return _draw(pools.single, asked, random);
  return _mix(pools, asked, random);
}

/// The pools behind one mode, already cut down to what [level] allows.
List<List<EarQuestion>> _poolsFor(
  EarMode mode,
  math.Random random,
  QuizLevel level,
) {
  List<EarQuestion> keep(List<EarQuestion> pool) => _filter(pool, level);

  return switch (mode) {
    EarMode.openStrings => [keep(_openStringPool(random))],
    EarMode.chords => [keep(_chordPool(random))],
    EarMode.neckNotes => [keep(_neckPool(random))],
    EarMode.everything => [
      keep(_openStringPool(random)),
      keep(_chordPool(random)),
      keep(_neckPool(random)),
      keep(_qualityPool(random)),
      keep(_intervalPool(random)),
      keep(_scalePool(random)),
      keep(_rhythmPool(random)),
      keep(_texturePool(random)),
    ],
  };
}

/// How many sounds each mode can draw from, for the intro text.
int earPoolSize(EarMode mode, {QuizLevel level = QuizLevel.medium}) {
  final random = math.Random(3);
  var total = 0;
  for (final pool in _poolsFor(mode, random, level)) {
    total += pool.length;
  }
  return total;
}

List<EarQuestion> _filter(List<EarQuestion> pool, QuizLevel level) => [
  for (final question in pool)
    if (question.tier <= level.topTier &&
        (!level.isTyped || isTypeable(question.answer)))
      question,
];

List<EarQuestion> _draw(List<EarQuestion> pool, int count, math.Random random) {
  if (pool.isEmpty) return const [];
  final queue = List<EarQuestion>.of(pool)..shuffle(random);
  final round = <EarQuestion>[];
  while (round.length < count) {
    if (queue.isEmpty) {
      // The six open strings can still carry twenty questions: refill and
      // move the sound the player just heard away from the next draw.
      queue.addAll(pool);
      queue.shuffle(random);
      if (pool.length > 1 && identical(queue.last, round.last)) {
        queue.insert(0, queue.removeLast());
      }
    }
    round.add(queue.removeLast());
  }
  return round;
}

/// Round-robin over the pools so a mixed round never ends up all chords.
/// Pools that run dry are refilled, which is what makes a long round legal.
List<EarQuestion> _mix(
  List<List<EarQuestion>> pools,
  int count,
  math.Random random,
) {
  final buckets = [
    for (final pool in pools)
      if (pool.isNotEmpty)
        (pool: pool, drawn: List<EarQuestion>.of(pool)..shuffle(random)),
  ];
  if (buckets.isEmpty) return const [];
  final round = <EarQuestion>[];
  while (round.length < count) {
    for (final bucket in buckets) {
      if (round.length == count) break;
      if (bucket.drawn.isEmpty) {
        bucket.drawn.addAll(bucket.pool);
        bucket.drawn.shuffle(random);
      }
      round.add(bucket.drawn.removeLast());
    }
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
          tier: 0,
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
          tier: chordTier(chord),
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
          tier: label == 'Major' || label == 'Minor' ? 0 : 1,
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
            tier: fret <= 3
                ? 0
                : fret <= 7
                ? 1
                : 2,
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
          tier: size <= wholeStep ? 0 : 1,
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
          tier: size <= wholeStep ? 1 : 2,
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
    for (final (place, scale) in commonScales.indexed) ...[
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
          tier: place < 2 ? 1 : 2,
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
            tier: 2,
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
          tier: 2,
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
          tier: 2,
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
      tier: 2,
    );
  }

  return [
    for (final name in shapes) ...[
      one(name, strummed: false),
      one(name, strummed: true),
    ],
  ];
}
