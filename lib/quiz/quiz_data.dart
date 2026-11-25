import 'dart:math' as math;

import '../models/chords.dart';
import '../models/notes.dart';
import '../models/scales.dart';
import 'quiz_level.dart';

/// What a question tests, so one round never turns into ten interval questions.
enum QuizKind {
  shapes('Chord shapes'),
  spelling('Note spelling'),
  intervals('Intervals'),
  neck('The neck'),
  scales('Scales'),
  rhythm('Rhythm'),
  tunings('Tunings'),
  keys('Keys'),
  theory('Theory');

  const QuizKind(this.label);

  final String label;
}

class Question {
  final String prompt;
  final List<String> options;
  final int answerIndex;
  final String explanation;
  final QuizKind kind;

  /// When set, the quiz draws this shape above the question.
  final ChordShape? diagram;

  const Question({
    required this.prompt,
    required this.options,
    required this.answerIndex,
    required this.explanation,
    required this.kind,
    this.diagram,
  });

  /// Which tier of the site this question belongs to: 0 is the first week,
  /// 1 is the middle, 2 is the sharp end. Derived from what the question
  /// actually asks, so a new chord or tuning sorts itself in.
  int get tier => questionTier(this);

  String get answer => options[answerIndex];
}

/// The rule behind [Question.tier].
int questionTier(Question question) {
  final chord = question.diagram;
  if (chord != null) return chordTier(chord);

  final answer = question.options[question.answerIndex];

  // Reading a note off a string and a fret. The first five frets are the
  // beginner's ground; past them the neck starts to cost something.
  if (question.kind == QuizKind.neck) {
    final fret = int.tryParse(
      RegExp(r'at fret (\d+)').firstMatch(question.prompt)?.group(1) ?? '',
    );
    return fret == null
        ? 1
        : fret <= 5
        ? 0
        : 1;
  }

  // Naming the note above another one is arithmetic, even when the answer is
  // a bare note name.
  if (question.kind == QuizKind.intervals) {
    if (answer == 'half step' || answer == 'whole step') return 0;
    if (answer.contains('7') || answer.contains('9') || answer.contains('6')) {
      return 2;
    }
    return 1;
  }

  if (isBasicAnswer(answer)) return 0;

  return switch (question.kind) {
    QuizKind.shapes || QuizKind.spelling => 1,
    QuizKind.scales =>
      answer == 'minor pentatonic' || answer == 'major' ? 1 : 2,
    QuizKind.tunings =>
      answer.startsWith('Standard')
          ? 0
          : answer.startsWith('Open') || answer.contains('DADGAD')
          ? 2
          : 1,
    QuizKind.keys || QuizKind.rhythm || QuizKind.theory => 2,
    QuizKind.neck || QuizKind.intervals => 1,
  };
}

/// How many questions one round asks, out of a pool of several hundred.
const int quizLength = 10;

/// The written quiz always means E standard, whatever the visitor has
/// selected in the top right, so a question can never have two answers.
const _std = [40, 45, 50, 55, 59, 64];

/// Four options: the answer, then notes sitting either side of it on the
/// circle of fifths, so the wrong ones are genuinely tempting. Topped up from
/// the chromatic ring if the local pool runs dry (open tunings repeat notes).
({List<String> options, int answerIndex}) _nearOptions(
  String answer,
  List<String> ring,
  math.Random random,
) {
  final at = ring.indexOf(answer);
  final offsets = [1, -1, 2, -2, 3, -3]..shuffle(random);
  final options = <String>{answer};
  for (final offset in offsets) {
    options.add(ring[(at + offset + ring.length) % ring.length]);
  }
  for (final name in noteNames) {
    if (options.length == 4) break;
    options.add(name);
  }
  final picked = options.take(4).toList()..shuffle(random);
  return (options: picked, answerIndex: picked.indexOf(answer));
}

/// Four options pulled from a flat pool, in a random order.
({List<String> options, int answerIndex}) _poolOptions(
  String answer,
  List<String> pool,
  math.Random random,
) {
  final distractors = pool.where((name) => name != answer).toList()
    ..shuffle(random);
  final options = [answer, ...distractors.take(3)]..shuffle(random);
  return (options: options, answerIndex: options.indexOf(answer));
}

/// Read straight off a diagram.
List<Question> _shapeQuestions(math.Random random) => [
  for (final chord in allChords)
    () {
      final choice = _poolOptions(chord.name, [
        for (final other in allChords) other.name,
      ], random);

      return Question(
        prompt: 'Which chord is drawn here?',
        kind: QuizKind.shapes,
        diagram: chord,
        options: choice.options,
        answerIndex: choice.answerIndex,
        explanation:
            '${chord.name} spells ${chord.spelledNotes()} across '
            '${chord.stringCount} strings. ${chord.blurb}',
      );
    }(),
];

List<Question> _spellingQuestions(math.Random random) => [
  for (final chord in allChords)
    if (chord.stringCount >= 4)
      () {
        final choice = _poolOptions(chord.spelledNotes(), [
          for (final other in allChords) other.spelledNotes(),
        ], random);

        return Question(
          prompt: 'Which notes ring out of this shape?',
          kind: QuizKind.spelling,
          diagram: chord,
          options: choice.options,
          answerIndex: choice.answerIndex,
          explanation:
              'Frets ${chord.fretLine} in E standard: '
              '${chord.spelledNotes()}.',
        );
      }(),
];

/// label, size in half steps, and the line the explanation leans on.
const _steps = <(String, int, String, bool)>[
  ('perfect 5th', 7, 'seven half steps, the sound of a power chord', true),
  ('major 3rd', 4, 'four half steps, the note that makes a chord major', true),
  ('minor 3rd', 3, 'three half steps, the sad one', true),
  (
    'perfect 4th',
    5,
    'five half steps, the gap most strings are tuned to',
    true,
  ),
  ('whole step', 2, 'two frets', false),
  ('half step', 1, 'one fret, the smallest jump on the neck', false),
];

List<Question> _intervalQuestions(math.Random random) => [
  for (var root = 0; root < 12; root++)
    for (final (label, size, why, ofChord) in _steps)
      () {
        final answer = noteNames[(root + size) % 12];
        final choice = _nearOptions(answer, noteNames, random);

        return Question(
          prompt: ofChord
              ? 'What is the $label of ${noteNames[root]}?'
              : 'Which note sits a $label above ${noteNames[root]}?',
          kind: QuizKind.intervals,
          options: choice.options,
          answerIndex: choice.answerIndex,
          explanation:
              '$label means $why, so ${noteNames[root]} plus $size frets '
              'lands on $answer.',
        );
      }(),
  for (final (label, size, why, _) in _steps)
    () {
      final choice = _poolOptions('$size', const [
        '1',
        '2',
        '3',
        '4',
        '5',
        '7',
        '12',
      ], random);

      return Question(
        prompt: 'How many half steps make a $label?',
        kind: QuizKind.intervals,
        options: choice.options,
        answerIndex: choice.answerIndex,
        explanation: '$size of them: a $label is $why.',
      );
    }(),
  const Question(
    prompt: 'How many half steps make up one octave?',
    kind: QuizKind.theory,
    options: ['7', '10', '12', '16'],
    answerIndex: 2,
    explanation:
        '12 half steps, and the frequency doubles. That is why the 12th fret '
        'usually carries two markers.',
  ),
];

List<Question> _neckQuestions(math.Random random) => [
  for (var string = 0; string < 6; string++)
    for (final fret in const [1, 3, 5, 7, 9, 12])
      () {
        final midi = _std[string] + fret;
        final answer = PitchNames.of(midi);
        final choice = _nearOptions(answer, noteNames, random);

        return Question(
          prompt:
              'In E standard, which note do you get on the '
              '${stringNumbers[string]} string at fret $fret?',
          kind: QuizKind.neck,
          options: choice.options,
          answerIndex: choice.answerIndex,
          explanation:
              'The open ${stringNumbers[string]} string is '
              '${PitchNames.of(_std[string])}; $fret frets up is $answer, '
              'which is ${PitchNames.withOctave(midi)} at '
              '${PitchNames.frequencyOf(midi).toStringAsFixed(1)} Hz.',
        );
      }(),
  for (var string = 0; string < 5; string++)
    () {
      final gap = _std[string + 1] - _std[string];
      final answer = intervalName(gap);
      final choice = _poolOptions(answer, const [
        'half step',
        'whole step',
        'minor 3rd',
        'major 3rd',
        'perfect 4th',
        'perfect 5th',
      ], random);

      return Question(
        prompt:
            'In E standard, how far apart are the open '
            '${stringNumbers[string]} and ${stringNumbers[string + 1]} strings?',
        kind: QuizKind.neck,
        options: choice.options,
        answerIndex: choice.answerIndex,
        explanation:
            '${PitchNames.of(_std[string])} to '
            '${PitchNames.of(_std[string + 1])} is $gap frets, a $answer. '
            'Four of the five gaps on a guitar are perfect 4ths; the one '
            'between the 2nd and 1st strings is the exception.',
      );
    }(),
];

List<Question> _scaleQuestions(math.Random random) => [
  for (final scale in commonScales) ...[
    () {
      final choice = _poolOptions('${scale.intervals.length}', const [
        '4',
        '5',
        '6',
        '7',
        '8',
        '12',
      ], random);

      return Question(
        prompt:
            'How many notes does the ${scale.name.toLowerCase()} scale use?',
        kind: QuizKind.scales,
        options: choice.options,
        answerIndex: choice.answerIndex,
        explanation:
            '${scale.intervals.length}, the octave included. ${scale.blurb}',
      );
    }(),
    () {
      final choice = _poolOptions(scale.fretPattern, [
        for (final other in commonScales) other.fretPattern,
      ], random);

      return Question(
        prompt:
            'Which gap pattern builds the ${scale.name.toLowerCase()} scale?',
        kind: QuizKind.scales,
        options: choice.options,
        answerIndex: choice.answerIndex,
        explanation:
            '${scale.fretPattern} frets between the degrees, and the gaps '
            'always add up to 12. ${scale.blurb}',
      );
    }(),
    Question(
      prompt:
          'Where does the ${scale.name.toLowerCase()} pattern start on the '
          'neck?',
      kind: QuizKind.scales,
      options: const [
        'on the note it is named after',
        'always on the low E string',
        'on the 5th fret, whatever the key',
        'on the highest open string',
      ],
      answerIndex: 0,
      explanation:
          'A pattern is a shape: move it so its first note lands on the root '
          'you want and it becomes that key. ${scale.spelledFrom(52)}',
    ),
  ],
  const Question(
    prompt: 'Which scale is usually the first one a guitarist learns?',
    kind: QuizKind.scales,
    options: ['minor pentatonic', 'harmonic minor', 'Mixolydian', 'Dorian'],
    answerIndex: 0,
    explanation:
        'Five notes, two per string, and no wrong ones. The minor pentatonic '
        'fits over most rock and blues backing tracks straight away.',
  ),
  const Question(
    prompt: 'What makes the blues scale different from the minor pentatonic?',
    kind: QuizKind.scales,
    options: [
      'one extra chromatic note',
      'one note fewer',
      'a raised root',
      'it starts on the 5th',
    ],
    answerIndex: 0,
    explanation:
        'It is the five pentatonic notes plus the flat 5th, six in total. '
        'That single passing note is the whole blues sound.',
  ),
];

const _meters = <(String, String, String)>[
  ('4/4', '1 2 3 4', 'rock, pop and blues'),
  ('3/4', '1 2 3', 'waltzes and ballads'),
  ('6/8', '1 2 3 4 5 6', 'folk and slow blues'),
  ('2/4', '1 2', 'marches and punk'),
];

const _noteValues = <(String, String)>[
  ('whole note', 'four beats'),
  ('half note', 'two beats'),
  ('quarter note', 'one beat'),
  ('eighth note', 'half a beat'),
  ('dotted quarter note', 'one and a half beats'),
];

List<Question> _rhythmQuestions(math.Random random) => [
  for (final (signature, count, where) in _meters) ...[
    () {
      final choice = _poolOptions(signature.split('/').first, const [
        '2',
        '3',
        '4',
        '6',
        '12',
      ], random);

      return Question(
        prompt: 'How many beats does a bar of $signature hold?',
        kind: QuizKind.rhythm,
        options: choice.options,
        answerIndex: choice.answerIndex,
        explanation:
            'The top number says how many, so $signature counts $count. You '
            'meet it in $where.',
      );
    }(),
    () {
      final choice = _poolOptions(signature, const [
        '4/4',
        '3/4',
        '6/8',
        '2/4',
      ], random);

      return Question(
        prompt: 'Which meter counts "$count"?',
        kind: QuizKind.rhythm,
        options: choice.options,
        answerIndex: choice.answerIndex,
        explanation: '$signature, the one you meet in $where.',
      );
    }(),
  ],
  for (final (value, length) in _noteValues)
    () {
      final choice = _poolOptions(length, [
        for (final entry in _noteValues) entry.$2,
      ], random);

      return Question(
        prompt: 'In 4/4, how long does a $value last?',
        kind: QuizKind.rhythm,
        options: choice.options,
        answerIndex: choice.answerIndex,
        explanation: value == 'dotted quarter note'
            ? 'The dot adds half the note again: one beat plus half a beat. '
                  'It is the reason a lyric can start on the "and".'
            : 'A $value holds $length in 4/4, and four quarter notes fill '
                  'the bar.',
      );
    }(),
  const Question(
    prompt: 'What does the top line of a tab staff show?',
    kind: QuizKind.rhythm,
    options: [
      'the thin high E string',
      'the thick low E string',
      'whatever string is easiest',
      'the melody note only',
    ],
    answerIndex: 0,
    explanation:
        'Tab is drawn like the neck lying on your lap: the line closest to '
        'the floor, the high E, sits on top. Numbers are frets.',
  ),
  const Question(
    prompt: 'An arpeggio is a chord played...',
    kind: QuizKind.rhythm,
    options: [
      'one note after another',
      'with all six strings muted',
      'an octave lower than written',
      'as a strummed block',
    ],
    answerIndex: 0,
    explanation:
        'Same notes, no longer at the same time. Picking a chord apart is how '
        'fingerstyle songs sound like a melody and a bass at once.',
  ),
];

/// Open-string label the way the tuner writes it: the two E strings share a
/// letter, so they are told apart by size.
String _stringNote(Tuning tuning, int index) {
  final name = PitchNames.of(tuning.openMidis[index]);
  if (name != 'E') return name;
  return index <= 2 ? 'E (low)' : 'E (high)';
}

List<Question> _tuningQuestions(math.Random random) => [
  for (final tuning in tunings)
    for (var string = 0; string < 6; string++)
      () {
        final midi = tuning.openMidis[string];
        final labels = [for (var i = 0; i < 6; i++) _stringNote(tuning, i)];
        final choice = _nearOptions(labels[string], labels, random);

        return Question(
          prompt:
              'In ${tuning.name}, which note does the open '
              '${stringNumbers[string]} string play?',
          kind: QuizKind.tunings,
          options: choice.options,
          answerIndex: choice.answerIndex,
          explanation:
              'String ${stringNumbers[string]} is tuned to '
              '${PitchNames.withOctave(midi)}, '
              '${PitchNames.frequencyOf(midi).toStringAsFixed(1)} Hz. '
              '${tuning.hint}',
        );
      }(),
  const Question(
    prompt: 'What changes when a guitar goes from E standard to Drop D?',
    kind: QuizKind.tunings,
    options: [
      'only the lowest string',
      'every string drops a whole step',
      'the top two strings',
      'the string order swaps',
    ],
    answerIndex: 0,
    explanation:
        'One string, two frets down: D2. The rest of the tuning is untouched, '
        'which is why every shape you know still works on five strings.',
  ),
  const Question(
    prompt: 'Why do players tune down a half step to Eb?',
    kind: QuizKind.tunings,
    options: [
      'singing the same lines gets easier',
      'the strings stay in tune better',
      'it makes the guitar louder',
      'chords become simpler to finger',
    ],
    answerIndex: 0,
    explanation:
        'Everything sits a semitone lower, so a key that is awkward to sing '
        'drops into reach. The tension on the neck drops with it.',
  ),
  const Question(
    prompt: 'What do open tunings like Open G or Open D give you for free?',
    kind: QuizKind.tunings,
    options: [
      'a full chord just by strumming all six strings',
      'more frets on the neck',
      'lighter string tension only',
      'the ability to skip tuning',
    ],
    answerIndex: 0,
    explanation:
        'The six open notes are the notes of one chord, which is why a slide '
        'or one flat finger across a fret turns the whole neck into a chord.',
  ),
];

List<Question> _keyQuestions(math.Random random) => [
  for (final group in chordGroups) ...[
    () {
      final hit = group.chords[random.nextInt(group.chords.length)];
      final outsiders =
          allChords
              .where(
                (chord) =>
                    !groupsHolding(chord.name)
                        .any((other) => other.name == group.name),
              )
              .toList()
            ..shuffle(random);
      final options = [
        hit.chord.name,
        for (final chord in outsiders.take(3)) chord.name,
      ]..shuffle(random);

      return Question(
        prompt: 'Which of these chords belongs to ${group.name}?',
        kind: QuizKind.keys,
        options: options,
        answerIndex: options.indexOf(hit.chord.name),
        explanation:
            '${hit.chord.name} is the ${hit.degree} there, and it spells '
            '${hit.chord.spelledNotes()}. ${group.blurb}',
      );
    }(),
    for (final entry in group.chords)
      // Groups list a degree once per chord; sus4 and the like repeat, and a
      // question with three right answers is not a question.
      if (group.chords.where((other) => other.degree == entry.degree).length ==
          1)
        () {
          final choice = _poolOptions(entry.chord.name, [
            for (final other in allChords) other.name,
          ], random);

          return Question(
            prompt: 'In ${group.name}, which chord is the ${entry.degree}?',
            kind: QuizKind.keys,
            options: choice.options,
            answerIndex: choice.answerIndex,
            explanation:
                '${entry.chord.name}: ${entry.chord.spelledNotes()}. '
                '${group.blurb}',
          );
        }(),
  ],
  const Question(
    prompt: 'Why do a major key and its relative minor use the same chords?',
    kind: QuizKind.keys,
    options: [
      'they are built from the same seven notes',
      'they share the same root',
      'minor chords always have one note fewer',
      'the tuning stays the same',
    ],
    answerIndex: 0,
    explanation:
        'C major and A minor both use only the white notes, just counted from '
        'a different starting point, so every chord fits in both.',
  ),
];

List<Question> _theoryQuestions(math.Random random) => [
  const Question(
    prompt:
        'E major and E minor use almost the same shape. What makes them '
        'different?',
    kind: QuizKind.theory,
    options: ['the 3rd', 'the root', 'the 5th', 'the tuning'],
    answerIndex: 0,
    explanation:
        'Both are built on E and both have a B. One finger moves the 3rd from '
        'G# to G, and the mood changes completely.',
  ),
  const Question(
    prompt: 'A power chord is built from...',
    kind: QuizKind.theory,
    options: [
      'the root and its 5th',
      'the root and its 3rd',
      'the 3rd and the 5th',
      'three notes an octave apart',
    ],
    answerIndex: 0,
    explanation:
        'Root plus 5th, seven half steps apart. No 3rd means neither major '
        'nor minor, so nothing clashes when you add distortion.',
  ),
  const Question(
    prompt: 'Twelve frets up from any note is...',
    kind: QuizKind.theory,
    options: [
      'the same note, at twice the frequency',
      'the note a 5th above',
      'the next string over',
      'the same note, at half the frequency',
    ],
    answerIndex: 0,
    explanation:
        'An octave. The 12th fret harmonic rings the same note as the open '
        'string because its frequency is exactly double.',
  ),
  const Question(
    prompt:
        'The tuner reads 12 cents flat just under the note. Best way onto it?',
    kind: QuizKind.theory,
    options: [
      'keep going up, then settle back down onto the note',
      'slacken the string a full turn first',
      'leave it, flat is close enough',
      'tighten it another half turn and stop',
    ],
    answerIndex: 0,
    explanation:
        'Arrive at the note from below: the winding settles and holds. Tuning '
        'down onto a note leaves slack in the coil and it drifts flat again.',
  ),
  const Question(
    prompt: 'A# and Bb on a guitar are...',
    kind: QuizKind.theory,
    options: [
      'the same fret, spelled two ways',
      'a half step apart',
      'on different strings',
      'only both correct on a piano',
    ],
    answerIndex: 0,
    explanation:
        'Enharmonic notes: same fret, same frequency, different letter '
        'depending on the key. This app writes the sharp names.',
  ),
];

/// Everything the written quiz can ask, generated once from the models so a
/// new chord, tuning or key group adds questions without touching this file.
final List<Question> quizPool = () {
  final random = math.Random(11);
  return [
    ..._shapeQuestions(random),
    ..._spellingQuestions(random),
    ..._intervalQuestions(random),
    ..._neckQuestions(random),
    ..._scaleQuestions(random),
    ..._rhythmQuestions(random),
    ..._tuningQuestions(random),
    ..._keyQuestions(random),
    ..._theoryQuestions(random),
  ];
}();

/// The questions one level is allowed to ask. Expert also drops anything
/// whose answer is too long to type.
List<Question> _poolFor(QuizLevel level) => [
  for (final question in quizPool)
    if (question.tier <= level.topTier &&
        (!level.isTyped || isTypeable(question.options[question.answerIndex])))
      question,
];

/// How many questions a level can offer, which caps the round length.
int quizPoolSizeFor(QuizLevel level) => _poolFor(level).length;

/// A fresh round: questions taken one kind at a time so the mix stays wide,
/// with the options shuffled again so the right answer never sits in the same
/// slot twice.
List<Question> quizRound({
  int count = quizLength,
  int? seed,
  QuizLevel level = QuizLevel.medium,
}) {
  final random = math.Random(seed);
  final buckets = <QuizKind, List<Question>>{};
  for (final question in _poolFor(level)) {
    (buckets[question.kind] ??= <Question>[]).add(question);
  }
  for (final bucket in buckets.values) {
    bucket.shuffle(random);
  }

  final kinds = buckets.keys.toList()..shuffle(random);
  final round = <Question>[];
  final asked = <String>{};
  var allowRepeats = false;

  // One question per kind per pass keeps the mix wide. Diagram questions
  // share their prompt - "Which chord is drawn here?" for thirty shapes - so
  // a round prefers a prompt it has not used yet and only repeats a wording
  // once the level has nothing left that is new.
  while (round.length < count && buckets.values.any((b) => b.isNotEmpty)) {
    var taken = 0;
    for (final kind in kinds) {
      if (round.length == count) break;
      final bucket = buckets[kind]!;
      final waiting = <Question>[];
      while (bucket.isNotEmpty) {
        final candidate = bucket.removeLast();
        if (!allowRepeats && asked.contains(candidate.prompt)) {
          waiting.add(candidate);
          continue;
        }
        asked.add(candidate.prompt);
        round.add(_freshen(candidate, random));
        taken++;
        break;
      }
      bucket.addAll(waiting);
    }
    if (taken == 0) allowRepeats = true;
  }
  return round;
}

Question _freshen(Question question, math.Random random) {
  final answer = question.options[question.answerIndex];
  final options = List<String>.of(question.options)..shuffle(random);
  return Question(
    prompt: question.prompt,
    kind: question.kind,
    diagram: question.diagram,
    options: options,
    answerIndex: options.indexOf(answer),
    explanation: question.explanation,
  );
}
