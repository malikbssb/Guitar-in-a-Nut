import 'package:flutter/material.dart';

import '../audio/string_audio.dart';
import '../models/chords.dart';
import '../models/notes.dart';
import '../models/scales.dart';
import '../roadmap/roadmap_screen.dart';
import '../theory/theory_screen.dart';

/// One "hear it" control inside a lesson.
class SoundAction {
  final String label;
  final VoidCallback play;

  const SoundAction(this.label, this.play);
}

/// The blocks a lesson page can be built from, so the writing stays in one
/// file and the layout stays in one widget.
sealed class LessonBlock {
  const LessonBlock();
}

class Prose extends LessonBlock {
  final String text;

  const Prose(this.text);
}

/// A title inside one lesson, used where a page covers more than one idea.
class SubHeading extends LessonBlock {
  final String text;

  const SubHeading(this.text);
}

class Points extends LessonBlock {
  final List<String> items;

  const Points(this.items);
}

class FactTable extends LessonBlock {
  final List<String> columns;
  final List<List<String>> rows;

  const FactTable({required this.columns, required this.rows});
}

/// A tab example, drawn exactly as it is written on paper.
class TabStaff extends LessonBlock {
  final List<String> lines;

  const TabStaff(this.lines);
}

class Hear extends LessonBlock {
  final List<SoundAction> actions;

  const Hear(this.actions);
}

class OpenSection extends LessonBlock {
  final String label;
  final VoidCallback onTap;

  const OpenSection(this.label, this.onTap);
}

class Lesson {
  final String title;
  final String blurb;
  final IconData icon;

  /// Lessons that need real interaction (the notes page) bring their own
  /// body instead of a list of blocks.
  final Widget Function(BuildContext context)? body;
  final List<LessonBlock> blocks;

  const Lesson._({
    required this.title,
    required this.blurb,
    required this.icon,
    required this.blocks,
    this.body,
  });

  static Lesson interactive({
    required String title,
    required String blurb,
    required IconData icon,
    required Widget Function(BuildContext context) body,
  }) => Lesson._(
    title: title,
    blurb: blurb,
    icon: icon,
    blocks: const [],
    body: body,
  );

  static Lesson reading({
    required String title,
    required String blurb,
    required IconData icon,
    required List<LessonBlock> blocks,
  }) => Lesson._(title: title, blurb: blurb, icon: icon, blocks: blocks);
}

ChordShape _chord(String name) =>
    commonChords.firstWhere((shape) => shape.name == name);

/// The strumming lessons ride on a shape that rings all six strings.
List<int> _sixStringChord(Tuning tuning) =>
    _chord('G').soundingMidis(tuning.openMidis);

/// Where the from-scratch plan sits inside [learnLessons], for anything that
/// has to open a lesson by number rather than by tapping the card.
const int roadmapLessonIndex = 8;

/// Everything the LEARN tab offers, in the order a beginner should meet it.
List<Lesson> learnLessons({
  required Tuning tuning,
  required VoidCallback onOpenTuner,
  required VoidCallback onOpenChords,
  required VoidCallback onOpenNeck,
  required VoidCallback onOpenQuiz,
  required VoidCallback onOpenEarTraining,
  required VoidCallback onOpenMetronome,
  required ValueChanged<int> onOpenLesson,
}) {
  final open = tuning.openMidis;
  final lowRoot = open.first + octave;
  final c = _chord('C');
  final strumMidis = _sixStringChord(tuning);
  final beat = 60.0 / 76;

  /// A full 4/4 bar chopped into notes of `length` beats.
  List<double> barOf(double length) => [
    for (var t = 0.0; t < 4 - 1e-9; t += length) length,
  ];

  return [
    Lesson.interactive(
      title: 'The four beginner questions',
      blurb: 'How to tune, which tuning, why it, and the twelve notes.',
      icon: Icons.piano,
      body: (context) => TheoryScreen(onContinue: onOpenTuner),
    ),
    Lesson.reading(
      title: 'What is a chord?',
      blurb:
          'The shape, the notes, and the two ways to play it: strummed or '
          'one note at a time.',
      icon: Icons.grid_view,
      blocks: [
        Prose(
          'A chord is three or more notes ringing together. On guitar you '
          'press a shape with the left hand and strum: the shape has a name, '
          'and the same name follows it wherever it sits on the neck.',
        ),
        const Points([
          'The note the shape is named after is the root.',
          'The 3rd decides the mood: a minor 3rd (3 frets) sounds sad, a '
              'major 3rd (4 frets) sounds bright.',
          'The 5th (7 frets above the root) just makes it stable.',
          'Drop the 3rd and you have a power chord: huge, and neither major '
              'nor minor.',
        ]),
        FactTable(
          columns: const ['Shape', 'Notes that ring', 'Strings'],
          rows: [
            for (final name in ['E', 'Em', 'A', 'Am', 'C', 'G', 'D'])
              [
                name,
                _chord(name).spelledNotes(),
                '${_chord(name).soundingMidis(open).length}',
              ],
          ],
        ),
        Hear([
          SoundAction(
            'Hear E major',
            () => playChord(_chord('E').soundingMidis(open)),
          ),
          SoundAction(
            'Hear E minor',
            () => playChord(_chord('Em').soundingMidis(open)),
          ),
          SoundAction(
            'Hear C one note at a time',
            () => playRun(c.soundingMidis(open)),
          ),
        ]),
        const SubHeading('Arpeggios: the same chord, opened up'),
        Prose(
          'Strummed, the notes of a chord hit at almost the same instant. '
          'Played one at a time they form an arpeggio, and suddenly the same '
          'chord sounds like a melody.',
        ),
        const Points([
          'Fingerstyle: thumb takes the bass, other fingers take the words.',
          'Travis picking alternates a bass note on 1 and 3 with the middle '
              'strings on 2 and 4.',
          'Any chord can be picked slowly to find out what it is made of.',
        ]),
        Hear([
          SoundAction(
            'Hear C strummed',
            () => playChord(c.soundingMidis(open)),
          ),
          SoundAction(
            'Hear C as an arpeggio',
            () => playRun(c.soundingMidis(open)),
          ),
          SoundAction(
            'Hear a bass-and-strings pattern',
            () => playRun(const [40, 59, 55, 52, 45, 59, 52, 55]),
          ),
        ]),
        const SubHeading('Strumming patterns'),
        Prose(
          'A pattern says which strokes land on which count. Down-strokes '
          'usually take the beats, up-strokes the "and" between them. Leave '
          'a stroke out and keep the hand moving: the missing strums are what '
          'make a groove breathe.',
        ),
        const FactTable(
          columns: ['Count', '1', 'and', '2', 'and', '3', 'and', '4', 'and'],
          rows: [
            ['All down', 'D', '-', 'D', '-', 'D', '-', 'D', '-'],
            ['Steady eighths', 'D', 'U', 'D', 'U', 'D', 'U', 'D', 'U'],
            ['The classic', 'D', '-', 'D', 'U', '-', 'U', 'D', 'U'],
            ['Folk swing', 'D', '-', 'U', 'U', 'D', '-', 'U', ''],
          ],
        ),
        Prose(
          'The same pattern over a different chord is a different song. Keep '
          'the count out loud while you play - the hand learns the words.',
        ),
        Hear([
          SoundAction(
            'Hear all down-strokes',
            () => playStrumPattern(strumMidis, [0, beat, 2 * beat, 3 * beat]),
          ),
          SoundAction(
            'Hear steady eighth notes',
            () => playStrumPattern(strumMidis, [
              0,
              -0.5 * beat,
              beat,
              -1.5 * beat,
              2 * beat,
              -2.5 * beat,
              3 * beat,
              -3.5 * beat,
            ]),
          ),
          SoundAction(
            'Hear the classic pattern',
            () => playStrumPattern(strumMidis, [
              0,
              beat,
              -1.5 * beat,
              -2.5 * beat,
              3 * beat,
              -3.5 * beat,
            ]),
          ),
        ]),
        OpenSection('Practise the shapes in CHORDS / SCALES', onOpenChords),
        OpenSection('See the notes on the neck', onOpenNeck),
        OpenSection('Check yourself in the quiz', onOpenQuiz),
      ],
    ),
    Lesson.reading(
      title: 'What is a scale?',
      blurb: 'The notes a song is allowed to use, in order.',
      icon: Icons.linear_scale,
      blocks: [
        Prose(
          'A scale is a run of notes that belong together. A song is usually '
          'written in one of them, its key, and a solo is made by walking up '
          'and down that same list.',
        ),
        Prose(
          'Only the gaps matter. The same pattern, started one fret higher, '
          'gives the same scale with a different name - which is why guitar '
          'players think in shapes instead of note names.',
        ),
        FactTable(
          columns: const ['Scale', 'Frets between degrees', 'Notes'],
          rows: [
            for (final scale in commonScales.take(4))
              [scale.name, scale.fretPattern, '${scale.steps.length}'],
          ],
        ),
        Hear([
          SoundAction(
            'Hear a minor pentatonic scale',
            () => playRun(commonScales.first.midisFrom(lowRoot)),
          ),
          SoundAction(
            'Hear a major scale',
            () => playRun(commonScales[1].midisFrom(lowRoot + minorThird)),
          ),
          SoundAction(
            'Hear the blues scale',
            () => playRun(commonScales[3].midisFrom(lowRoot)),
          ),
        ]),
        OpenSection('Hear every scale in CHORDS / SCALES', onOpenChords),
      ],
    ),
    Lesson.reading(
      title: 'How to tune',
      blurb: 'One string at a time, always arriving from below.',
      icon: Icons.tune,
      blocks: [
        const Points([
          'Start with the thick low E and work up to the thin high E.',
          'Pluck, read the letter, then turn the peg slowly.',
          'Tightening the string raises the pitch, loosening lowers it.',
          'Approach the note from below: coming down from a sharp pitch makes '
              'the string slip and go flat again.',
          'New strings stretch for a day, so retune often at first.',
        ]),
        Prose(
          'The tuner shows the closest note and how far off it is. Red means '
          'keep going, green means you have it. If the letter is right but '
          'the number is wildly different, you are an octave away.',
        ),
        FactTable(
          columns: const ['String', 'Note', 'Frequency'],
          rows: [
            for (var i = 0; i < 6; i++)
              [
                '${stringNumbers[i]}',
                PitchNames.withOctave(open[i]),
                '${PitchNames.frequencyOf(open[i]).toStringAsFixed(1)} Hz',
              ],
          ],
        ),
        Hear([SoundAction('Hear the six open strings', () => playRun(open))]),
        OpenSection('Open the tuner', onOpenTuner),
      ],
    ),
    Lesson.reading(
      title: 'What are time signatures?',
      blurb: 'How many beats in a bar, and what a beat is worth.',
      icon: Icons.av_timer,
      blocks: [
        Prose(
          'Music is cut into bars. The two stacked numbers of a time '
          'signature tell you how many beats fit in one bar, and which kind '
          'of note gets one beat.',
        ),
        const FactTable(
          columns: ['Signature', 'Count', 'You meet it in'],
          rows: [
            ['4/4', '1 2 3 4', 'rock, pop, blues'],
            ['3/4', '1 2 3', 'waltzes, ballads'],
            ['6/8', '1 2 3 4 5 6', 'folk, slow blues'],
            ['2/4', '1 2', 'marches, punk'],
          ],
        ),
        Prose(
          'The top number is the one you feel: it is how many times you tap '
          'your foot before the pattern restarts, and the accent falls on the '
          '1. In 6/8 those six eighths are felt as two groups of three.',
        ),
        Hear([
          SoundAction('Hear a bar of 4/4', () => playMetronome(84, beats: 4)),
          SoundAction('Hear a waltz in 3/4', () => playMetronome(84, beats: 3)),
          SoundAction('Hear 6/8', () => playMetronome(84, beats: 6)),
        ]),
      ],
    ),
    Lesson.reading(
      title: 'How long is a note?',
      blurb: 'Whole, half, quarter, eighth, sixteenth.',
      icon: Icons.schedule,
      blocks: [
        Prose(
          'Note names describe length, not pitch. They come from how much of '
          'a whole note they are worth, and in 4/4 a whole note fills an '
          'entire bar.',
        ),
        const FactTable(
          columns: ['Name', 'Beats in 4/4', 'You count it as'],
          rows: [
            ['Whole', '4', 'one note held for the whole bar'],
            ['Half', '2', 'one - two'],
            ['Quarter', '1', 'one - two - three - four'],
            ['Eighth', '1/2', 'one - and - two - and'],
            ['Sixteenth', '1/4', 'one - e - and - a'],
          ],
        ),
        const Points([
          'A dot after a note adds half of it again: a dotted quarter is '
              '1 and a half beats.',
          'Two notes joined by a tie are played as one long note.',
          'Strumming uses the same maths: eighth notes mean the pick changes '
              'direction on every "and".',
        ]),
        Hear([
          SoundAction(
            'Hear a bar of quarter notes',
            () => playTimeline(barOf(1)),
          ),
          SoundAction(
            'Hear a bar of eighth notes',
            () => playTimeline(barOf(0.5)),
          ),
          SoundAction(
            'Hear a bar of sixteenth notes',
            () => playTimeline(barOf(0.25)),
          ),
          SoundAction(
            'Hear a dotted rhythm',
            () => playTimeline(const [1.5, 0.5, 1, 1]),
          ),
        ]),
      ],
    ),
    Lesson.reading(
      title: 'How to read tabs',
      blurb: 'Six lines, numbers for frets, read left to right.',
      icon: Icons.shortcut,
      blocks: [
        Prose(
          'Tablature draws the strings instead of the pitch. The line at the '
          'top is the thin high E, the line at the bottom is the thick low '
          'E. A number is the fret to press on that string, and 0 means play '
          'it open. Read from left to right.',
        ),
        const TabStaff([
          'e|-----------------------0-1-0----|',
          'B|--------------1-3---------------|',
          'G|------0-2-----------------------|',
          'D|--------------------------------|',
          'A|--------------------------------|',
          'E|--------------------------------|',
        ]),
        const Points([
          'h - hammer-on: pluck once, then land a finger on the next fret.',
          'p - pull-off: sound the higher note by pulling the finger off.',
          '/ and \\ - slide along the string to the next fret.',
          'b - bend: push the string until the pitch rises.',
          'x - mute: touch the string without fretting a note.',
        ]),
        Prose(
          'Tab tells you where to put your fingers, not how long to hold '
          'anything. Rhythm still comes from listening to the song.',
        ),
        Hear([
          SoundAction(
            'Hear this riff',
            () => playRun(const [55, 57, 60, 62, 64, 65, 64]),
          ),
        ]),
        OpenSection('Find those notes on the neck', onOpenNeck),
      ],
    ),
    Lesson.reading(
      title: 'How to use a metronome',
      blurb: 'Slow enough to be clean, then a little faster.',
      icon: Icons.timer,
      blocks: [
        Prose(
          'A metronome is not a test, it is a ruler. Practise against it and '
          'you hear the exact speed where a passage stops being clean, and '
          'that speed is the one to work on.',
        ),
        const Points([
          'Find the speed where you play it perfectly, then drop 10 bpm.',
          'Four clean takes in a row, and only then go up 5 bpm.',
          'Clap or tap the count first - the hands follow the foot.',
          'Set the clicks to eighth notes occasionally to catch uneven '
              'picking.',
          'Stop when your hands tense up. Speed is learned relaxed.',
        ]),
        Hear([
          SoundAction('Click at 60 bpm', () => playMetronome(60)),
          SoundAction('Click at 90 bpm', () => playMetronome(90)),
          SoundAction('Click at 120 bpm', () => playMetronome(120)),
          SoundAction('Two bars at 100 bpm', () => playMetronome(100, bars: 2)),
        ]),
      ],
    ),
    // Last, because it is the page you read once you know what the others are
    // for: the plan that names each of them in order.
    Lesson.interactive(
      title: 'I want to become a guitarist from scratch, what do I do?',
      blurb: 'The four things to work on, in order, with the page for each.',
      icon: Icons.flag_outlined,
      body: (context) => RoadmapScreen(
        onOpenChords: onOpenChords,
        onOpenNeck: onOpenNeck,
        onOpenQuiz: onOpenQuiz,
        onOpenEarTraining: onOpenEarTraining,
        onOpenMetronome: onOpenMetronome,
        onOpenLesson: onOpenLesson,
      ),
    ),
  ];
}
