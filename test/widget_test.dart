import 'dart:io' show File;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:projet_ecole/app_shell.dart';
import 'package:projet_ecole/audio/click_samples.dart';
import 'package:projet_ecole/audio/click_voice.dart';
import 'package:projet_ecole/audio/pluck_clip.dart';
import 'package:projet_ecole/chords/chords_screen.dart';
import 'package:projet_ecole/drum/drum_machine_screen.dart';
import 'package:projet_ecole/drum/drum_patterns.dart';
import 'package:projet_ecole/learn/learn_screen.dart';
import 'package:projet_ecole/learn/lessons.dart';
import 'package:projet_ecole/main.dart';
import 'package:projet_ecole/metronome/metronome_screen.dart';
import 'package:projet_ecole/models/chords.dart';
import 'package:projet_ecole/models/notes.dart';
import 'package:projet_ecole/neck/neck_screen.dart';
import 'package:projet_ecole/quiz/ear_training_data.dart';
import 'package:projet_ecole/quiz/ear_training_screen.dart';
import 'package:projet_ecole/quiz/quiz_data.dart';
import 'package:projet_ecole/quiz/quiz_level.dart';
import 'package:projet_ecole/quiz/quiz_screen.dart';
import 'package:projet_ecole/roadmap/roadmap_screen.dart';
import 'package:projet_ecole/start/start_screen.dart';
import 'package:projet_ecole/theory/theory_screen.dart';
import 'package:projet_ecole/tuner/pitch_detector.dart';
import 'package:projet_ecole/tuner/tuner_screen.dart';
import 'package:projet_ecole/widgets/chord_diagram.dart';
import 'package:projet_ecole/widgets/option_button.dart';
import 'package:projet_ecole/widgets/settings_fab.dart';
import 'package:projet_ecole/widgets/theme_fab.dart';
import 'package:projet_ecole/widgets/wood_logo.dart';

/// Every section stays mounted inside the shell's IndexedStack, so text from a
/// hidden section is still in the tree. Scope finders to the screen.
Finder inScreen(Type screen, Finder matching) =>
    find.descendant(of: find.byType(screen), matching: matching);

/// A tall surface: each section is a ListView and never builds what falls below
/// the viewport, and the buttons we tap sit at the bottom.
Future<void> pumpApp(
  WidgetTester tester, {
  Size size = const Size(900, 1800),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(const GuitarInANutApp());
  await tester.pumpAndSettle();
}

Future<void> skipToTools(WidgetTester tester) async {
  await tester.tap(find.text('No, take me to the tools'));
  await tester.pumpAndSettle();
}

/// The rail starts as a hamburger strip; open it to reach the labels.
Future<void> openRail(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
}

/// Straight from the entry screen to one section of the shell.
Future<void> openSection(WidgetTester tester, String label) async {
  await pumpApp(tester);
  await skipToTools(tester);
  await openRail(tester);
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Sections build lazily inside their ListView, so anything below the fold has
/// to be scrolled into view before it can be tapped.
Future<void> scrollIn(WidgetTester tester, Type screen, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    360,
    scrollable: find
        .descendant(of: find.byType(screen), matching: find.byType(Scrollable))
        .first,
  );
  await tester.pumpAndSettle();
}

/// Both quizzes draw random rounds, so the tests read the buttons themselves
/// to find the right or the wrong answer instead of a fixed question list.
Future<void> tapAnswer(
  WidgetTester tester,
  Type screen, {
  bool correctly = true,
}) async {
  final buttons = tester
      .widgetList<OptionButton>(inScreen(screen, find.byType(OptionButton)))
      .toList();
  expect(buttons, hasLength(4));

  final wanted = buttons.firstWhere((button) => button.isAnswer == correctly);
  await tester.tap(
    inScreen(screen, find.widgetWithText(OptionButton, wanted.text)),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('notes and intervals', () {
    test('A4 is 440 Hz and one octave up doubles it', () {
      expect(PitchNames.frequencyOf(69), closeTo(440.0, 0.001));
      expect(PitchNames.frequencyOf(69 + octave), closeTo(880.0, 0.001));
    });

    test('names use C D E F G A B, not Do Re Mi', () {
      expect(PitchNames.of(60), 'C');
      expect(PitchNames.withOctave(60), 'C4');
      expect(PitchNames.withOctave(40), 'E2');
      expect(PitchNames.of(40 + perfectFifth), 'B');
    });

    test('the 12th fret of the low string is the same note an octave up', () {
      final open = tunings.first.openMidis.first;
      expect(
        PitchNames.frequencyOf(open + octave),
        closeTo(PitchNames.frequencyOf(open) * 2, 0.01),
      );
    });

    test('a low E measured at 82.41 Hz reads back as E2', () {
      final note = PitchNames.nearest(82.41);
      expect(note.midi, 40);
      expect(note.name, 'E2');
      expect(note.cents.abs(), lessThan(2));
    });

    test('interval names match their semitone counts', () {
      expect(intervalName(halfStep), 'half step');
      expect(intervalName(wholeStep), 'whole step');
      expect(intervalName(minorThird), 'minor 3rd');
      expect(intervalName(majorThird), 'major 3rd');
      expect(intervalName(perfectFifth), 'perfect 5th');
      expect(intervalName(octave), 'octave');
    });

    test('every tuning carries the short label shown on the tuner', () {
      expect(tunings.first.short, 'E standard');
      expect(tunings.length, greaterThanOrEqualTo(10));

      for (final tuning in tunings) {
        expect(tuning.short, isNotEmpty);
        expect(tuning.hint, isNotEmpty);
        expect(tuning.openMidis.length, 6);
        // Six descending strings, all inside a guitar's range.
        for (var i = 1; i < 6; i++) {
          expect(
            tuning.openMidis[i],
            greaterThan(tuning.openMidis[i - 1]),
            reason: tuning.name,
          );
        }
        expect(tuning.openMidis.first, greaterThanOrEqualTo(33));
        expect(tuning.openMidis.last, lessThanOrEqualTo(69));
      }

      expect(
        tunings.map((tuning) => tuning.name).toSet(),
        hasLength(tunings.length),
      );
      expect(
        tunings.map((tuning) => tuning.short).toSet(),
        hasLength(tunings.length),
      );
    });

    test('the added tunings really are what they say', () {
      expect(chordByName('C').fretLine, 'x - 3 - 2 - 0 - 1 - 0');

      List<int> open(String short) =>
          tunings.firstWhere((tuning) => tuning.short == short).openMidis;

      // Drop tunings lower only the sixth string, one whole step at a time.
      expect(open('E standard').first, 40);
      expect(open('Drop D').first, 38);
      expect(open('Drop C').first, 36);
      expect(open('Eb standard').first, 39);
      expect(open('Drop C').skip(1), open('D standard').skip(1));
      expect(open('D standard'), [for (final m in open('E standard')) m - 2]);

      // An open tuning spells one major triad with no fingers down. Dart
      // compares sets by identity, so the check has to be by content.
      Set<int> classes(List<int> midis) => {for (final m in midis) m % 12};
      bool same(Set<int> a, Set<int> b) =>
          a.length == b.length && a.containsAll(b);
      for (final name in ['Open G', 'Open D', 'Open E', 'Open C']) {
        final midis = classes(open(name));
        final roots = [
          for (var root = 0; root < 12; root++)
            if (same(midis, {
              root,
              (root + majorThird) % 12,
              (root + perfectFifth) % 12,
            }))
              root,
        ];
        expect(roots, hasLength(1), reason: name);
      }

      // DADGAD rings D - A - G - A - D: a suspended colour, not a triad.
      expect(open('DADGAD'), [38, 45, 50, 55, 57, 62]);
      expect(same(classes(open('DADGAD')), {2, 7, 9}), isTrue);
    });
  });

  group('chord shapes', () {
    test('C major spells C E G C E over five strings', () {
      final c = commonChords.firstWhere((chord) => chord.name == 'C');
      expect(c.spelledNotes(), 'C E G C E');
      expect(c.soundingMidis().length, 5);
    });

    test('G is the only shape here that rings all six strings', () {
      final g = commonChords.firstWhere((chord) => chord.name == 'G');
      expect(g.soundingMidis().length, 6);
      expect(g.spelledNotes(), 'G B D G B G');
    });

    test('Em is the two-finger shape on fret 2', () {
      final em = commonChords.firstWhere((chord) => chord.name == 'Em');
      expect(em.highestFret, 2);
      expect(em.spelledNotes(), 'E B E G B E');
    });

    test('a 5th is always 7 frets above the root', () {
      expect(PitchNames.of(45 + perfectFifth), 'E');
      expect(PitchNames.of(48 + perfectFifth), 'G');
      expect(PitchNames.of(40 + perfectFifth), 'B');
    });

    test('the library is sorted by the key each shape fits', () {
      expect(allChords.length, greaterThanOrEqualTo(30));
      expect(commonChords.map((chord) => chord.name).toList(), [
        'Em',
        'Am',
        'E',
        'A',
        'D',
        'C',
        'G',
      ]);
      expect(chordGroups, hasLength(8));
      expect(
        allChords.map((chord) => chord.name).toSet(),
        hasLength(allChords.length),
        reason: 'the flat list must not repeat a shape',
      );

      for (final group in chordGroups) {
        expect(group.name, isNotEmpty);
        expect(group.blurb, isNotEmpty);
        expect(group.shapes, hasLength(group.chords.length));
        expect(
          group.shapes.map((chord) => chord.name).toSet(),
          hasLength(group.chords.length),
          reason: group.name,
        );
        for (final entry in group.chords) {
          expect(entry.degree, isNotEmpty, reason: entry.chord.name);
          expect(
            allChords.map((chord) => chord.name),
            contains(entry.chord.name),
          );
        }
      }

      // A degree question needs one answer, so only the sus colours, which are
      // never quizzed by degree, may share a label inside one group.
      for (final group in chordGroups) {
        final degrees = group.chords.map((entry) => entry.degree).toList();
        if (degrees.toSet().length != degrees.length) {
          expect(
            group.name,
            startsWith('Sus and add'),
            reason: '${group.name} repeats a degree',
          );
        }
      }
    });

    test('the six diatonic shapes of a key are all triads', () {
      const numerals = ['I', 'ii', 'iii', 'IV', 'V', 'vi'];

      bool isTriad(Set<int> classes) {
        if (classes.length != 3) return false;
        for (final root in classes) {
          final rest = {
            for (final c in classes)
              if (c != root) (c - root + 12) % 12,
          };
          if (rest.length == 2 &&
              rest.contains(perfectFifth) &&
              (rest.contains(minorThird) || rest.contains(majorThird))) {
            return true;
          }
        }
        return false;
      }

      for (final group in chordGroups.where(
        (g) => g.name.startsWith('Key of'),
      )) {
        final diatonic = group.chords
            .where((entry) => numerals.contains(entry.degree))
            .toList();
        expect(diatonic.length, greaterThanOrEqualTo(4), reason: group.name);

        for (final entry in diatonic) {
          expect(
            isTriad({
              for (final midi in entry.chord.soundingMidis()) midi % 12,
            }),
            isTrue,
            reason: '${group.name} - ${entry.chord.name}',
          );
        }

        // Borrowed shapes are the ones allowed a note outside the key.
        final plain = {
          for (final entry in diatonic)
            for (final midi in entry.chord.soundingMidis()) midi % 12,
        };
        expect(plain.length, lessThanOrEqualTo(7), reason: group.name);
      }
    });

    test('a shape knows every key it belongs to', () {
      expect(chordByName('E5').stringCount, 3);
      expect(chordByName('E5').spelledNotes(), 'E B E');
      expect(chordByName('Cadd9').spelledNotes(), 'C E G D G');
      expect(chordByName('G5').fretLine, '3 - 5 - 5 - x - x - x');

      expect(
        groupsHolding('C').map((group) => group.name).toList(),
        containsAll(['Key of C major / A minor', 'Key of G major / E minor']),
      );
      expect(groupsHolding('Em7'), hasLength(3));
      expect(groupsHolding('Dsus2'), hasLength(1));
      expect(groupsHolding('Zzz'), isEmpty);
    });
  });

  group('pitch detection', () {
    test('a pure 110 Hz sine reads as 110 Hz', () {
      final samples = List<double>.generate(
        4410,
        (i) => 0.4 * math.sin(2 * math.pi * 110 * i / 44100),
        growable: false,
      );

      final reading = PitchDetector().analyze(samples);

      expect(reading.isUsable, isTrue);
      expect(reading.frequency, closeTo(110.0, 2.0));
    });

    test('a window too short returns no pitch', () {
      expect(PitchDetector().analyze(const [0.1, -0.1, 0.2]).frequency, 0);
    });

    test('silence is reported as unusable', () {
      final reading = PitchDetector().analyze(
        List<double>.filled(PitchDetector.window * 2, 0),
      );
      expect(reading.isUsable, isFalse);
    });
  });

  group('navigation', () {
    testWidgets('the entry screen sends a beginner to the theory page', (
      tester,
    ) async {
      await pumpApp(tester);

      // The brand plate is the logo itself, not a note icon and not a
      // headline that repeats it.
      expect(find.byType(WoodLogo), findsOneWidget);
      expect(find.text('Guitar in a Nut'), findsNothing);
      expect(find.text('Are you a complete beginner?'), findsOneWidget);

      await tester.tap(find.text('Yes, teach me the basics first'));
      await tester.pumpAndSettle();

      expect(find.text('How do I tune?'), findsOneWidget);
      expect(find.text('Which tuning should I use?'), findsOneWidget);
      expect(find.text('How many notes are there?'), findsOneWidget);

      // Interval names belong to the chord lesson, not to this page.
      expect(find.textContaining('3rd'), findsNothing);
      expect(find.textContaining('5th'), findsNothing);

      // Picking another root must rewrite the closing line.
      await tester.tap(inScreen(TheoryScreen, find.text('A#')));
      await tester.pumpAndSettle();

      expect(find.textContaining('From A#: one fret up is B'), findsOneWidget);
      expect(find.textContaining('233.1 Hz to 466.2 Hz'), findsOneWidget);

      await tester.tap(find.text('Now show me the tools'));
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
      expect(inScreen(TunerScreen, find.text('Start')), findsOneWidget);
    });

    testWidgets('the hamburger strip widens into the menu', (tester) async {
      await pumpApp(tester);
      await skipToTools(tester);

      expect(find.text('CHORDS / SCALES'), findsNothing);

      await openRail(tester);

      expect(find.text('CHORDS / SCALES'), findsOneWidget);
      expect(find.text('NECK'), findsOneWidget);
      expect(find.text('LEARN'), findsOneWidget);
      expect(find.text('QUIZ'), findsOneWidget);

      await tester.tap(find.text('QUIZ'));
      await tester.pumpAndSettle();

      expect(
        inScreen(QuizScreen, find.text('A different quiz every time')),
        findsOneWidget,
      );
    });

    testWidgets('the wooden logo returns to the tuner', (tester) async {
      await pumpApp(tester);
      await skipToTools(tester);
      await openRail(tester);
      await tester.tap(find.text('NECK'));
      await tester.pumpAndSettle();

      expect(inScreen(NeckScreen, find.text('note names')), findsOneWidget);

      await tester.tap(find.text('GUITAR'));
      await tester.pumpAndSettle();

      expect(inScreen(TunerScreen, find.text('Start')), findsOneWidget);
    });

    testWidgets('the from-scratch plan lives in LEARN and walks into the '
        'pages it names', (tester) async {
      await openSection(tester, 'LEARN');

      // The banner on top of the list, not a tab of its own.
      expect(inScreen(LearnScreen, find.text('START HERE')), findsOneWidget);
      expect(inScreen(LearnScreen, find.text('Open the plan')), findsOneWidget);
      await scrollIn(
        tester,
        LearnScreen,
        find.text('I want to become a guitarist from scratch, what do I do?'),
      );
      await tester.tap(
        inScreen(
          LearnScreen,
          find.text('I want to become a guitarist from scratch, what do I do?'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        inScreen(RoadmapScreen, find.text('Four or five chord shapes')),
        findsOneWidget,
      );

      // A lesson link lands on the merged chord page, strumming included.
      await tester.tap(inScreen(RoadmapScreen, find.text('What is a chord?')));
      await tester.pumpAndSettle();
      await scrollIn(tester, LearnScreen, find.text('Strumming patterns'));
      expect(
        inScreen(LearnScreen, find.text('Strumming patterns')),
        findsOneWidget,
      );
    });

    testWidgets('the rhythm step opens the metronome', (tester) async {
      await openSection(tester, 'LEARN');
      await scrollIn(
        tester,
        LearnScreen,
        find.text('I want to become a guitarist from scratch, what do I do?'),
      );
      await tester.tap(
        inScreen(
          LearnScreen,
          find.text('I want to become a guitarist from scratch, what do I do?'),
        ),
      );
      await tester.pumpAndSettle();

      await scrollIn(tester, RoadmapScreen, find.text('Open the metronome'));
      await tester.tap(
        inScreen(RoadmapScreen, find.text('Open the metronome')),
      );
      await tester.pumpAndSettle();

      expect(inScreen(MetronomeScreen, find.text('90')), findsOneWidget);
    });
  });

  group('tuner', () {
    testWidgets('the six open strings are printed above the readout', (
      tester,
    ) async {
      await pumpApp(tester);
      await skipToTools(tester);

      for (final letter in ['E', 'A', 'D', 'G', 'B']) {
        expect(
          inScreen(TunerScreen, find.text(letter)),
          findsWidgets,
          reason: '$letter should head one string',
        );
      }
      expect(inScreen(TunerScreen, find.text('(E standard)')), findsOneWidget);
      expect(
        inScreen(
          TunerScreen,
          find.text(
            'Enable your microphone, pluck a string and get to tuning!',
          ),
        ),
        findsOneWidget,
      );
      expect(
        inScreen(
          TunerScreen,
          find.text(
            'Confused? Click here to get a quick guide to get you started',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the tuning menu changes the target notes', (tester) async {
      await pumpApp(tester);
      await skipToTools(tester);

      await tester.tap(find.text('Standard (E A D G B E)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Drop D').last);
      await tester.pumpAndSettle();

      expect(inScreen(TunerScreen, find.text('(Drop D)')), findsOneWidget);

      await tester.tap(find.text('Drop D'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Half step down').last);
      await tester.pumpAndSettle();

      expect(inScreen(TunerScreen, find.text('(Eb standard)')), findsOneWidget);
      expect(
        inScreen(TunerScreen, find.text('Standard (E A D G B E)')),
        findsNothing,
      );
    });

    testWidgets('the quick guide link opens the theory section', (
      tester,
    ) async {
      await pumpApp(tester);
      await skipToTools(tester);

      await tester.tap(
        inScreen(
          TunerScreen,
          find.text(
            'Confused? Click here to get a quick guide to get you started',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Why that one?'), findsOneWidget);
    });
  });

  group('chords and neck', () {
    Future<void> openChords(WidgetTester tester) async {
      await pumpApp(tester);
      await skipToTools(tester);
      await openRail(tester);
      await tester.tap(find.text('CHORDS / SCALES'));
      await tester.pumpAndSettle();
    }

    testWidgets('a shape spells itself out when tapped', (tester) async {
      await openChords(tester);

      expect(find.text('Chords, sorted by key'), findsOneWidget);
      expect(find.text('Key of C major / A minor'), findsOneWidget);
      expect(inScreen(ChordsScreen, find.byType(ChordDiagram)), findsWidgets);

      // The C group leads the page, and C is its home chord.
      await tester.tap(inScreen(ChordsScreen, find.byType(ChordDiagram)).first);
      await tester.pumpAndSettle();

      await scrollIn(tester, ChordsScreen, find.text('C - C E G C E'));
      expect(
        find.textContaining('Frets, string 6 to 1: x - 3 - 2 - 0 - 1 - 0'),
        findsOneWidget,
      );

      await scrollIn(
        tester,
        ChordsScreen,
        find.textContaining('In Key of C major / A minor it is the I.'),
      );
      expect(
        find.textContaining('In Key of G major / E minor it is the IV.'),
        findsOneWidget,
      );

      // The page keeps going: the last group is the power chords, and their
      // detail says which key family they came from.
      await scrollIn(
        tester,
        ChordsScreen,
        find.text('Power chords: root and 5th'),
      );
      await tester.tap(inScreen(ChordsScreen, find.byType(ChordDiagram)).last);
      await tester.pumpAndSettle();

      await scrollIn(tester, ChordsScreen, find.text('G5 - G D G'));
      expect(
        find.textContaining('In Power chords: root and 5th it is the G.'),
        findsOneWidget,
      );
    });

    testWidgets('a chosen chord loads its string notes onto the tuner', (
      tester,
    ) async {
      await openChords(tester);

      // C leads the first group: x - 3 - 2 - 0 - 1 - 0.
      await tester.tap(inScreen(ChordsScreen, find.byType(ChordDiagram)).first);
      await tester.pumpAndSettle();

      await scrollIn(tester, ChordsScreen, find.text('Check it on the tuner'));
      await tester.tap(find.text('Check it on the tuner'));
      await tester.pumpAndSettle();

      expect(inScreen(TunerScreen, find.text('(C)')), findsOneWidget);
      expect(inScreen(TunerScreen, find.text('x')), findsOneWidget);
      expect(inScreen(TunerScreen, find.text('G')), findsWidgets);
    });

    testWidgets('tapping the neck gives the note, its 5th and its octave', (
      tester,
    ) async {
      await pumpApp(tester);
      await skipToTools(tester);
      await openRail(tester);
      await tester.tap(find.text('NECK'));
      await tester.pumpAndSettle();

      final board = find.byKey(const Key('fretboard'));
      final origin = tester.getTopLeft(board);
      // 13 columns (open string plus 12 frets) after a 46 px label gutter,
      // and a 20 px strip of fret numbers above the first row.
      final cellWidth = (tester.getSize(board).width - 46) / 13;
      // Bottom row is the lowest string: 6th string, fret 2.
      await tester.tapAt(origin + Offset(46 + cellWidth * 2.5, 20 + 40 * 5.5));
      await tester.pumpAndSettle();

      expect(find.text('String 6 - fret 2'), findsOneWidget);
      expect(find.textContaining('F#2 - 92.5 Hz'), findsOneWidget);
      expect(
        find.textContaining('Its 5th is C# and its octave is F#3'),
        findsOneWidget,
      );

      // Top row is the thin string, so the map reads the way the guitar does.
      await tester.tapAt(origin + Offset(46 + cellWidth * 2.5, 20 + 40 * 0.5));
      await tester.pumpAndSettle();

      expect(find.text('String 1 - fret 2'), findsOneWidget);
      expect(find.textContaining('F#4 - 370.0 Hz'), findsOneWidget);
    });

    testWidgets('the scale switch lights the notes of one scale', (
      tester,
    ) async {
      await openSection(tester, 'NECK');

      expect(inScreen(NeckScreen, find.text('root note')), findsNothing);

      await tester.tap(inScreen(NeckScreen, find.byType(Switch)).last);
      await tester.pumpAndSettle();

      expect(inScreen(NeckScreen, find.text('root note')), findsOneWidget);
      expect(
        inScreen(
          NeckScreen,
          find.textContaining('Minor pentatonic on E3: E G A B D E'),
        ),
        findsOneWidget,
      );

      // A different root has to rewrite every lit cell.
      await tester.tap(inScreen(NeckScreen, find.text('A#')).last);
      await tester.pumpAndSettle();

      expect(
        inScreen(
          NeckScreen,
          find.textContaining('Minor pentatonic on A#3: A# C# D# F G# A#'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a scale heard on the chords page can be opened on the neck', (
      tester,
    ) async {
      await openSection(tester, 'CHORDS / SCALES');

      await scrollIn(tester, ChordsScreen, find.text('Scales'));
      await tester.tap(inScreen(ChordsScreen, find.text('Blues')));
      await tester.pumpAndSettle();

      await scrollIn(
        tester,
        ChordsScreen,
        find.text('Light it up on the neck'),
      );
      await tester.tap(
        inScreen(ChordsScreen, find.text('Light it up on the neck')),
      );
      await tester.pumpAndSettle();

      expect(
        inScreen(
          NeckScreen,
          find.textContaining('Blues on E3: E G A A# B D E'),
        ),
        findsOneWidget,
      );
    });
  });

  group('quiz', () {
    Future<void> openQuiz(WidgetTester tester) async {
      await pumpApp(tester);
      await skipToTools(tester);
      await openRail(tester);
      await tester.tap(find.text('QUIZ'));
      await tester.pumpAndSettle();
    }

    testWidgets('the intro draws a round of the length you pick', (
      tester,
    ) async {
      await openQuiz(tester);

      expect(
        inScreen(QuizScreen, find.text('A different quiz every time')),
        findsOneWidget,
      );
      expect(inScreen(QuizScreen, find.text('Question 1 of 5')), findsNothing);

      await tester.tap(inScreen(QuizScreen, find.text('5')));
      await tester.pumpAndSettle();
      expect(
        inScreen(QuizScreen, find.text('Draw 5 questions')),
        findsOneWidget,
      );

      await tester.tap(inScreen(QuizScreen, find.text('Draw 5 questions')));
      await tester.pumpAndSettle();

      expect(
        inScreen(QuizScreen, find.text('Question 1 of 5')),
        findsOneWidget,
      );
      expect(inScreen(QuizScreen, find.byType(OptionButton)), findsNWidgets(4));
      expect(inScreen(QuizScreen, find.text('Score: 0')), findsOneWidget);
    });

    testWidgets('the level decides how many questions there are to ask', (
      tester,
    ) async {
      await openQuiz(tester);

      String poolLine() => tester
          .widget<Text>(
            inScreen(QuizScreen, find.textContaining('The app builds')),
          )
          .data!;

      expect(poolLine(), contains('${quizPoolSizeFor(QuizLevel.medium)}'));

      await tester.tap(inScreen(QuizScreen, find.text('Easy')));
      await tester.pumpAndSettle();
      expect(
        poolLine(),
        contains('${quizPoolSizeFor(QuizLevel.easy)} questions at this level'),
      );

      await tester.tap(inScreen(QuizScreen, find.text('Expert')));
      await tester.pumpAndSettle();
      expect(poolLine(), contains('${quizPoolSizeFor(QuizLevel.expert)}'));
      expect(
        inScreen(QuizScreen, find.textContaining('No options to fall back on')),
        findsOneWidget,
      );
    });

    testWidgets('expert swaps the four options for a typed answer', (
      tester,
    ) async {
      await openQuiz(tester);

      await tester.tap(inScreen(QuizScreen, find.text('Expert')));
      await tester.pumpAndSettle();
      await tester.tap(inScreen(QuizScreen, find.text('5')));
      await tester.pumpAndSettle();
      await tester.tap(inScreen(QuizScreen, find.text('Draw 5 questions')));
      await tester.pumpAndSettle();

      expect(inScreen(QuizScreen, find.byType(OptionButton)), findsNothing);
      final field = inScreen(QuizScreen, find.byKey(const Key('typed-answer')));
      expect(field, findsOneWidget);
      expect(inScreen(QuizScreen, find.text('Expert')), findsOneWidget);

      await tester.enterText(field, 'a sentence nobody types');
      await tester.tap(inScreen(QuizScreen, find.text('Check that answer')));
      await tester.pumpAndSettle();

      expect(
        inScreen(QuizScreen, find.textContaining('Answer:')),
        findsOneWidget,
      );
      expect(
        inScreen(QuizScreen, find.textContaining('You wrote')),
        findsOneWidget,
      );
      expect(inScreen(QuizScreen, find.text('Score: 0')), findsOneWidget);
      expect(tester.widget<TextField>(field).enabled, isFalse);

      await tester.tap(inScreen(QuizScreen, find.text('Next question')));
      await tester.pumpAndSettle();

      expect(
        inScreen(QuizScreen, find.text('Question 2 of 5')),
        findsOneWidget,
      );
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      expect(tester.widget<TextField>(field).enabled, isTrue);
    });

    testWidgets('the right option scores and moves on', (tester) async {
      await openQuiz(tester);
      await tester.tap(inScreen(QuizScreen, find.text('Draw 10 questions')));
      await tester.pumpAndSettle();

      await tapAnswer(tester, QuizScreen);

      expect(inScreen(QuizScreen, find.text('Correct')), findsOneWidget);
      expect(inScreen(QuizScreen, find.text('Score: 1')), findsOneWidget);

      await tester.tap(find.text('Next question'));
      await tester.pumpAndSettle();

      expect(
        inScreen(QuizScreen, find.text('Question 2 of 10')),
        findsOneWidget,
      );
      expect(inScreen(QuizScreen, find.text('Score: 1')), findsOneWidget);
    });

    testWidgets('a wrong answer reveals the expected one', (tester) async {
      await openQuiz(tester);
      await tester.tap(inScreen(QuizScreen, find.text('Draw 10 questions')));
      await tester.pumpAndSettle();

      await tapAnswer(tester, QuizScreen, correctly: false);

      expect(
        inScreen(QuizScreen, find.textContaining('Answer:')),
        findsOneWidget,
      );
      expect(inScreen(QuizScreen, find.text('Score: 0')), findsOneWidget);
    });

    testWidgets('the round ends on a score and a fresh draw', (tester) async {
      await openQuiz(tester);
      await tester.tap(inScreen(QuizScreen, find.text('5')));
      await tester.pumpAndSettle();
      await tester.tap(inScreen(QuizScreen, find.text('Draw 5 questions')));
      await tester.pumpAndSettle();

      for (var i = 0; i < 5; i++) {
        await tapAnswer(tester, QuizScreen);
        await tester.tap(
          inScreen(
            QuizScreen,
            find.text(i == 4 ? 'See my score' : 'Next question'),
          ),
        );
        await tester.pumpAndSettle();
      }

      expect(inScreen(QuizScreen, find.text('5 / 5')), findsOneWidget);
      expect(find.textContaining('Strong.'), findsOneWidget);

      await tester.tap(inScreen(QuizScreen, find.text('New round')));
      await tester.pumpAndSettle();

      expect(
        inScreen(QuizScreen, find.text('Question 1 of 5')),
        findsOneWidget,
      );
      expect(inScreen(QuizScreen, find.text('Score: 0')), findsOneWidget);
    });

    test('the pool is wide, self-consistent and covers every kind', () {
      expect(quizPool.length, greaterThan(200));
      expect(
        quizPool.map((question) => question.kind).toSet(),
        QuizKind.values.toSet(),
      );

      for (final question in quizPool) {
        expect(question.prompt, isNotEmpty);
        expect(question.explanation, isNotEmpty);
        expect(question.options, hasLength(4), reason: question.prompt);
        expect(question.options.toSet(), hasLength(4), reason: question.prompt);
        expect(
          question.answerIndex,
          inInclusiveRange(0, 3),
          reason: question.prompt,
        );
      }
    });

    test('a draw is repeatable, wide and never the same twice in a row', () {
      final first = quizRound(count: 5, seed: 3);
      expect(
        first.map((question) => question.prompt),
        quizRound(count: 5, seed: 3).map((question) => question.prompt),
      );

      final wide = quizRound(count: 12, seed: 5);
      expect(wide, hasLength(12));
      expect(wide.map((question) => question.prompt).toSet(), hasLength(12));
      expect(
        wide.map((question) => question.kind).toSet().length,
        greaterThan(4),
      );

      // The options get shuffled again on every draw, so the answer moves.
      final slots = <int>{
        for (var seed = 0; seed < 12; seed++)
          quizRound(count: 5, seed: seed).first.answerIndex,
      };
      expect(slots.length, greaterThan(1));

      final draws = <String>{
        for (var seed = 0; seed < 12; seed++)
          quizRound(count: 5, seed: seed).map((q) => q.prompt).join('|'),
      };
      expect(draws.length, greaterThan(4));
    });

    test('every level draws only what it is allowed to ask about', () {
      expect(quizPoolSizeFor(QuizLevel.hard), quizPool.length);
      expect(
        quizPoolSizeFor(QuizLevel.easy),
        lessThan(quizPoolSizeFor(QuizLevel.medium)),
      );
      expect(
        quizPoolSizeFor(QuizLevel.expert),
        lessThan(quizPoolSizeFor(QuizLevel.hard)),
      );

      for (final level in QuizLevel.values) {
        final round = quizRound(count: 10, seed: 11, level: level);
        expect(round, hasLength(10), reason: level.name);
        for (final question in round) {
          expect(
            question.tier,
            lessThanOrEqualTo(level.topTier),
            reason: '${level.name} - ${question.prompt}',
          );
          final answer = question.options[question.answerIndex];
          if (level.isTyped) {
            expect(isTypeable(answer), isTrue, reason: question.prompt);
          }
        }
      }
    });

    test('a typed answer is forgiven for case, octave and spelling', () {
      expect(typedAnswerMatches('c', 'C'), isTrue);
      expect(typedAnswerMatches(' C4 ', 'C'), isTrue);
      expect(typedAnswerMatches('c sharp', 'C#'), isTrue);
      expect(typedAnswerMatches('C#', 'Db'), isFalse);
      expect(typedAnswerMatches('', 'Am7'), isFalse);
      expect(typedAnswerMatches('am7', 'Am7'), isTrue);
      expect(typedAnswerMatches('minor 3rd', 'Minor 3rd'), isTrue);
      expect(typedAnswerMatches('3rd', 'Minor 3rd'), isFalse);
    });
  });

  group('scales and learn', () {
    testWidgets('a scale shows its fret pattern and can be heard', (
      tester,
    ) async {
      await openSection(tester, 'CHORDS / SCALES');

      await scrollIn(tester, ChordsScreen, find.text('Scales'));
      expect(inScreen(ChordsScreen, find.text('Scales')), findsOneWidget);

      await tester.tap(inScreen(ChordsScreen, find.text('Minor pentatonic')));
      await tester.pumpAndSettle();

      expect(
        inScreen(
          ChordsScreen,
          find.textContaining('Frets between the degrees: 3 - 2 - 2 - 3 - 2'),
        ),
        findsOneWidget,
      );

      await scrollIn(tester, ChordsScreen, find.text('Hear the scale'));
      await tester.tap(inScreen(ChordsScreen, find.text('Hear the scale')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('the learn tab opens a lesson and its sound buttons', (
      tester,
    ) async {
      await openSection(tester, 'LEARN');

      expect(
        inScreen(LearnScreen, find.text('What is a chord?')),
        findsOneWidget,
      );
      expect(
        inScreen(LearnScreen, find.text('What are time signatures?')),
        findsOneWidget,
      );

      await tester.tap(inScreen(LearnScreen, find.text('What is a chord?')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('three or more notes ringing together'),
        findsOneWidget,
      );

      await tester.tap(inScreen(LearnScreen, find.text('Hear E major')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(inScreen(LearnScreen, find.byIcon(Icons.arrow_back)));
      await tester.pumpAndSettle();
      expect(
        inScreen(LearnScreen, find.text('What is a scale?')),
        findsOneWidget,
      );
    });

    testWidgets('the first lesson is the interactive notes page', (
      tester,
    ) async {
      await openSection(tester, 'LEARN');

      await tester.tap(
        inScreen(LearnScreen, find.text('The four beginner questions')),
      );
      await tester.pumpAndSettle();

      expect(find.text('How do I tune?'), findsOneWidget);
      expect(find.text('How many notes are there?'), findsOneWidget);
    });

    test('the from-scratch plan is the last lesson of LEARN', () {
      final lessons = learnLessons(
        tuning: tunings.first,
        onOpenTuner: () {},
        onOpenChords: () {},
        onOpenNeck: () {},
        onOpenQuiz: () {},
        onOpenEarTraining: () {},
        onOpenMetronome: () {},
        onOpenLesson: (_) {},
      );

      expect(roadmapLessonIndex, lessons.length - 1);
      expect(
        lessons[roadmapLessonIndex].title,
        'I want to become a guitarist from scratch, what do I do?',
      );
    });
  });

  group('ear training and theme', () {
    testWidgets('the intro offers four rounds and an answer scores', (
      tester,
    ) async {
      await openSection(tester, 'EAR TRAINING');

      for (final label in [
        'Open strings only',
        'Chords only',
        'Notes across the neck',
        'All in one',
      ]) {
        expect(inScreen(EarTrainingScreen, find.text(label)), findsOneWidget);
      }
      // Every round states the length that was picked.
      expect(
        inScreen(EarTrainingScreen, find.textContaining('10 sounds')),
        findsNWidgets(4),
      );
      // The difficulty and the length are picked once and apply to all four
      // rounds.
      for (final one in QuizLevel.values) {
        expect(
          inScreen(EarTrainingScreen, find.text(one.label)),
          findsOneWidget,
          reason: one.name,
        );
      }

      await tester.tap(inScreen(EarTrainingScreen, find.text('All in one')));
      await tester.pumpAndSettle();

      expect(
        inScreen(EarTrainingScreen, find.text('Sound 1 of 10')),
        findsOneWidget,
      );

      await tapAnswer(tester, EarTrainingScreen);

      expect(inScreen(EarTrainingScreen, find.text('Correct')), findsOneWidget);
      expect(
        inScreen(EarTrainingScreen, find.text('Score: 1')),
        findsOneWidget,
      );

      await tester.tap(inScreen(EarTrainingScreen, find.text('Next sound')));
      await tester.pumpAndSettle();

      expect(
        inScreen(EarTrainingScreen, find.text('Sound 2 of 10')),
        findsOneWidget,
      );
    });

    testWidgets('a round can be longer than the six open strings', (
      tester,
    ) async {
      await openSection(tester, 'EAR TRAINING');

      await tester.tap(inScreen(EarTrainingScreen, find.text('20')));
      await tester.pumpAndSettle();
      await tester.tap(
        inScreen(EarTrainingScreen, find.text('Open strings only')),
      );
      await tester.pumpAndSettle();

      expect(
        inScreen(EarTrainingScreen, find.text('Sound 1 of 20')),
        findsOneWidget,
      );

      // Walk the whole round: every sound has four options to choose from and
      // the last one ends on the score page.
      for (var i = 1; i <= 20; i++) {
        expect(
          inScreen(EarTrainingScreen, find.text('Sound $i of 20')),
          findsOneWidget,
          reason: '$i',
        );
        await tapAnswer(tester, EarTrainingScreen);
        await tester.tap(
          inScreen(
            EarTrainingScreen,
            find.text(i == 20 ? 'See my score' : 'Next sound'),
          ),
        );
        await tester.pumpAndSettle();
      }

      expect(inScreen(EarTrainingScreen, find.text('20 / 20')), findsOneWidget);
    });

    testWidgets('expert asks for a typed answer instead of four options', (
      tester,
    ) async {
      await openSection(tester, 'EAR TRAINING');

      await tester.tap(inScreen(EarTrainingScreen, find.text('Expert')));
      await tester.pumpAndSettle();
      await tester.tap(inScreen(EarTrainingScreen, find.text('5')));
      await tester.pumpAndSettle();
      await tester.tap(
        inScreen(EarTrainingScreen, find.text('Open strings only')),
      );
      await tester.pumpAndSettle();

      expect(
        inScreen(EarTrainingScreen, find.byType(OptionButton)),
        findsNothing,
      );
      expect(
        inScreen(EarTrainingScreen, find.byKey(const Key('typed-answer'))),
        findsOneWidget,
      );
      expect(
        inScreen(EarTrainingScreen, find.text('Check that answer')),
        findsOneWidget,
      );

      // At this level the open string round only asks for A, D or G, so one
      // of those three is always right and the other two reveal the answer.
      final notes = inScreen(
        EarTrainingScreen,
        find.byKey(const Key('typed-answer')),
      );
      await tester.tap(notes);
      await tester.enterText(notes, 'A');
      await tester.pumpAndSettle();
      await tester.tap(
        inScreen(EarTrainingScreen, find.text('Check that answer')),
      );
      await tester.pumpAndSettle();

      final correct = inScreen(
        EarTrainingScreen,
        find.textContaining('Correct'),
      ).evaluate().isNotEmpty;
      if (correct) {
        expect(
          inScreen(EarTrainingScreen, find.text('Score: 1')),
          findsOneWidget,
        );
      } else {
        expect(
          inScreen(EarTrainingScreen, find.textContaining('Answer:')),
          findsOneWidget,
        );
        expect(
          inScreen(EarTrainingScreen, find.textContaining('You wrote')),
          findsOneWidget,
        );
        expect(
          inScreen(EarTrainingScreen, find.text('Score: 0')),
          findsOneWidget,
        );
      }
      expect(tester.widget<TextField>(notes).controller!.text, 'A');
      expect(tester.widget<TextField>(notes).enabled, isFalse);
    });

    test('each generated round asks about four options of its own kind', () {
      final strings = earQuestionsFor(EarMode.openStrings, seed: 7);
      expect(strings, hasLength(earRoundLength(EarMode.openStrings)));
      for (final question in strings) {
        expect(question.options, hasLength(4));
        expect(question.options.toSet(), hasLength(4));
        expect(
          question.options[question.answerIndex],
          anyOf('E (low)', 'E (high)', 'A', 'D', 'G', 'B'),
        );
      }

      final chords = earQuestionsFor(EarMode.chords, seed: 7);
      expect(chords, hasLength(earRoundLength(EarMode.chords)));
      for (final question in chords) {
        expect(question.options, hasLength(4));
        expect(question.options.toSet(), hasLength(4), reason: question.prompt);
        expect(
          allChords.map((chord) => chord.name),
          contains(question.options[question.answerIndex]),
          reason: question.prompt,
        );
      }

      final neck = earQuestionsFor(EarMode.neckNotes, seed: 7);
      expect(neck, hasLength(earRoundLength(EarMode.neckNotes)));
      for (final question in neck) {
        expect(question.options, hasLength(4));
        expect(question.options.toSet(), hasLength(4), reason: question.prompt);
        expect(noteNames, contains(question.options[question.answerIndex]));
      }

      final mixed = earQuestionsFor(EarMode.everything, seed: 7);
      expect(mixed, hasLength(earRoundLength(EarMode.everything)));
      expect(
        mixed.map((question) => question.kind).toSet().length,
        greaterThan(3),
      );

      // Every mode, over several seeds: four unique options, one answer and a
      // sentence that explains the sound.
      for (final mode in EarMode.values) {
        for (final seed in [7, 21, 88, 500]) {
          final round = earQuestionsFor(mode, seed: seed);
          expect(round, hasLength(earRoundLength(mode)), reason: mode.name);
          for (final question in round) {
            expect(
              question.options,
              hasLength(4),
              reason: '${mode.name} - ${question.prompt}',
            );
            expect(
              question.options.toSet(),
              hasLength(4),
              reason: '${mode.name} - ${question.prompt} - ${question.options}',
            );
            expect(
              question.answerIndex,
              inInclusiveRange(0, 3),
              reason: question.prompt,
            );
            expect(question.explanation, isNotEmpty, reason: question.prompt);
          }
        }
      }

      // The pools are big enough for a fresh order every time.
      expect(
        earPoolSize(EarMode.chords, level: QuizLevel.hard),
        greaterThanOrEqualTo(30),
      );
      expect(
        earPoolSize(EarMode.neckNotes, level: QuizLevel.hard),
        greaterThanOrEqualTo(60),
      );
      String answers(EarMode mode, int seed) => earQuestionsFor(
        mode,
        seed: seed,
      ).map((q) => '${q.prompt} ${q.options.join()}').join(' | ');

      for (final mode in EarMode.values) {
        // A fixed seed replays the exact same round.
        expect(answers(mode, 7), answers(mode, 7));
        // And a different seed lands on different sounds.
        expect(answers(mode, 7), isNot(answers(mode, 1234)), reason: mode.name);
      }
    });

    test('the difficulty levels narrow what the ear can be asked about', () {
      for (final mode in EarMode.values) {
        final easy = earPoolSize(mode, level: QuizLevel.easy);
        final medium = earPoolSize(mode, level: QuizLevel.medium);
        final hard = earPoolSize(mode, level: QuizLevel.hard);
        expect(easy, greaterThan(0), reason: mode.name);
        expect(easy, lessThanOrEqualTo(medium), reason: mode.name);
        expect(medium, lessThanOrEqualTo(hard), reason: mode.name);
      }

      final easyRound = earQuestionsFor(
        EarMode.everything,
        seed: 9,
        count: 20,
        level: QuizLevel.easy,
      );
      expect(easyRound, hasLength(20));
      for (final question in easyRound) {
        expect(question.tier, 0, reason: question.answer);
      }

      // Expert reads the whole pool but keeps only the answers worth typing.
      final typed = earQuestionsFor(
        EarMode.everything,
        seed: 4,
        count: 12,
        level: QuizLevel.expert,
      );
      expect(typed, hasLength(12));
      for (final question in typed) {
        expect(isTypeable(question.answer), isTrue, reason: question.answer);
      }
    });

    test('a long round repeats sounds but never twice in a row', () {
      final strings = earQuestionsFor(EarMode.openStrings, seed: 3, count: 20);
      expect(strings, hasLength(20));
      for (var i = 1; i < strings.length; i++) {
        expect(identical(strings[i], strings[i - 1]), isFalse, reason: '$i');
      }
      expect(strings.map((q) => q.answer).toSet().length, greaterThan(1));

      final chords = earQuestionsFor(
        EarMode.chords,
        seed: 5,
        count: 40,
        level: QuizLevel.hard,
      );
      expect(chords, hasLength(40));
      for (var i = 1; i < chords.length; i++) {
        expect(identical(chords[i], chords[i - 1]), isFalse, reason: '$i');
      }
    });

    testWidgets('the bottom right button switches to light mode', (
      tester,
    ) async {
      await pumpApp(tester);

      // The start screen sits outside the shell, so it needs its own button.
      ThemeData entryTheme() =>
          Theme.of(tester.element(find.byType(StartScreen)));
      expect(entryTheme().brightness, Brightness.dark);

      await tester.tap(find.byType(ThemeFab));
      await tester.pumpAndSettle();

      expect(entryTheme().brightness, Brightness.light);

      await tester.tap(find.text('No, take me to the tools'));
      await tester.pumpAndSettle();

      ThemeData shellTheme() => Theme.of(tester.element(find.byType(AppShell)));
      expect(shellTheme().brightness, Brightness.light);
      expect(
        shellTheme().scaffoldBackgroundColor,
        lightAppTheme.scaffoldBackgroundColor,
      );

      await tester.tap(find.byType(ThemeFab));
      await tester.pumpAndSettle();

      expect(shellTheme().brightness, Brightness.dark);
      expect(
        shellTheme().scaffoldBackgroundColor,
        appTheme.scaffoldBackgroundColor,
      );
      expect(inScreen(TunerScreen, find.text('Start')), findsOneWidget);
    });
  });

  group('settings and language', () {
    testWidgets('the bottom left gear opens the settings sheet', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.text('Settings'), findsNothing);

      await tester.tap(find.byType(SettingsFab));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      // The two choices are the only things in there.
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
    });

    testWidgets('the sheet re-renders the interface in French', (tester) async {
      await pumpApp(tester);
      await skipToTools(tester);
      await openRail(tester);

      expect(find.text('NECK'), findsOneWidget);

      // The chords page is the one with the most words on it.
      await tester.tap(find.text('CHORDS / SCALES'));
      await tester.pumpAndSettle();
      expect(find.text('Chords, sorted by key'), findsOneWidget);

      await tester.tap(find.byType(SettingsFab));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();

      // The sheet sits above the navigator, so it translates with the rest.
      expect(find.text('Réglages'), findsOneWidget);
      // The note under the language picker says what the switch covers.
      expect(
        find.textContaining('Seule l\'interface est traduite'),
        findsOneWidget,
      );

      // And the page behind it follows the same switch.
      expect(find.text('Accords, classés par tonalité'), findsOneWidget);
      expect(find.text('Tonalité de C majeur / A mineur'), findsOneWidget);
      // The note names survive the switch, and the story under each group is
      // lesson content, so it keeps English.
      expect(find.textContaining('No sharps, no flats'), findsOneWidget);

      // The rail, still open behind the sheet, renamed every section.
      expect(find.text('MANCHE'), findsOneWidget);
      expect(find.text('NECK'), findsNothing);
      expect(find.text('MÉTRONOME'), findsOneWidget);
      expect(find.text('OREILLE'), findsOneWidget);

      // Dismissing the sheet leaves the whole app in French.
      await tester.tapAt(const Offset(600, 40));
      await tester.pumpAndSettle();

      expect(find.text('Accords, classés par tonalité'), findsOneWidget);
    });

    testWidgets('the sheet holds the light mode switch too', (tester) async {
      await pumpApp(tester);
      await skipToTools(tester);

      ThemeData shellTheme() => Theme.of(tester.element(find.byType(AppShell)));
      expect(shellTheme().brightness, Brightness.dark);

      await tester.tap(find.byType(SettingsFab));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      expect(shellTheme().brightness, Brightness.light);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(shellTheme().brightness, Brightness.dark);
    });
  });

  group('neck display options', () {
    /// Tap one cell of the board. The thin string (1) is drawn on top and the
    /// low E (6) at the bottom, under a 20 px strip of fret numbers.
    Future<void> fretTap(
      WidgetTester tester, {
      required int string,
      required int fret,
      required int frets,
    }) async {
      final board = find.byKey(const Key('fretboard'));
      final origin = tester.getTopLeft(board);
      final cellWidth = (tester.getSize(board).width - 46) / (frets + 1);
      await tester.tapAt(
        origin +
            Offset(46 + cellWidth * (fret + 0.5), 20 + 40 * (string - 0.5)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the board stretches to 24 frets and folds back', (
      tester,
    ) async {
      await openSection(tester, 'NECK');

      expect(inScreen(NeckScreen, find.text('24 frets')), findsOneWidget);
      expect(
        inScreen(NeckScreen, find.textContaining('up to fret 12')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('frets-switch')));
      await tester.pumpAndSettle();

      expect(
        inScreen(NeckScreen, find.textContaining('up to fret 24')),
        findsOneWidget,
      );

      // Fret 14 of the low string is on the board now: F#3.
      await fretTap(tester, string: 6, fret: 14, frets: 24);
      expect(
        inScreen(NeckScreen, find.text('String 6 - fret 14')),
        findsOneWidget,
      );
      expect(
        inScreen(NeckScreen, find.textContaining('F#3 - 185.0 Hz')),
        findsOneWidget,
      );

      // Folding back drops the selection along with the extra frets.
      await tester.tap(find.byKey(const Key('frets-switch')));
      await tester.pumpAndSettle();

      expect(
        inScreen(NeckScreen, find.textContaining('up to fret 12')),
        findsOneWidget,
      );
      expect(
        inScreen(NeckScreen, find.text('String 6 - fret 14')),
        findsNothing,
      );
    });

    testWidgets('the inlay dots can be switched off', (tester) async {
      await openSection(tester, 'NECK');

      final dots = find.byKey(const Key('dots-switch'));
      expect(tester.widget<Switch>(dots).value, isTrue);

      await tester.tap(dots);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(dots).value, isFalse);
      // The board keeps answering taps without its inlays.
      await fretTap(tester, string: 1, fret: 2, frets: 12);
      expect(
        inScreen(NeckScreen, find.text('String 1 - fret 2')),
        findsOneWidget,
      );
    });
  });

  group('metronome', () {
    testWidgets('tempo, bar length and click are all the player\'s', (
      tester,
    ) async {
      await openSection(tester, 'METRONOME');

      expect(inScreen(MetronomeScreen, find.text('90')), findsOneWidget);

      // A preset rewrites the big readout.
      await tester.tap(inScreen(MetronomeScreen, find.text('120')));
      await tester.pumpAndSettle();
      expect(inScreen(MetronomeScreen, find.text('120')), findsNWidgets(2));

      await tester.tap(inScreen(MetronomeScreen, find.text('3')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(
              find.ancestor(
                of: inScreen(MetronomeScreen, find.text('3')),
                matching: find.byType(ChoiceChip),
              ),
            )
            .selected,
        isTrue,
      );

      await tester.tap(inScreen(MetronomeScreen, find.text('2 bars')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(
              find.ancestor(
                of: inScreen(MetronomeScreen, find.text('2 bars')),
                matching: find.byType(ChoiceChip),
              ),
            )
            .selected,
        isTrue,
      );

      // Every click voice comes with a sentence saying what it sounds like.
      expect(
        inScreen(
          MetronomeScreen,
          find.text('A short wood block tick, the classic metronome sound.'),
        ),
        findsOneWidget,
      );

      await tester.tap(inScreen(MetronomeScreen, find.text('Cymbal')));
      await tester.pumpAndSettle();

      expect(
        inScreen(
          MetronomeScreen,
          find.text('A ride cymbal: the ping rings on past the beat.'),
        ),
        findsOneWidget,
      );
      expect(
        inScreen(MetronomeScreen, find.text('Hear this sound')),
        findsOneWidget,
      );
    });

    testWidgets('beat one is stressed until the player says otherwise', (
      tester,
    ) async {
      await openSection(tester, 'METRONOME');
      final stress = inScreen(MetronomeScreen, find.byType(Switch));

      expect(tester.widget<Switch>(stress).value, isTrue);
      expect(
        inScreen(
          MetronomeScreen,
          find.text(
            'Beat one sounds louder and a touch higher, so the bar counts '
            'itself.',
          ),
        ),
        findsOneWidget,
      );

      await tester.tap(stress);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(stress).value, isFalse);
      expect(
        inScreen(MetronomeScreen, find.text('Every beat sounds the same.')),
        findsOneWidget,
      );

      // The count itself does not care what beat one sounds like.
      await tester.tap(inScreen(MetronomeScreen, find.text('1 bar')));
      await tester.pumpAndSettle();
      await tester.tap(inScreen(MetronomeScreen, find.text('Start')));
      await tester.pump();

      expect(inScreen(MetronomeScreen, find.text('Stop')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pumpAndSettle();

      expect(inScreen(MetronomeScreen, find.text('Start')), findsOneWidget);
    });

    testWidgets('start counts the beats and stop silences the click', (
      tester,
    ) async {
      await openSection(tester, 'METRONOME');

      // Two bars of four at 120 is eight beats, then the player stops itself.
      await tester.tap(inScreen(MetronomeScreen, find.text('120')));
      await tester.pumpAndSettle();
      await tester.tap(inScreen(MetronomeScreen, find.text('2 bars')));
      await tester.pumpAndSettle();

      await tester.tap(inScreen(MetronomeScreen, find.text('Start')));
      await tester.pump();

      expect(inScreen(MetronomeScreen, find.text('Stop')), findsOneWidget);

      // Halfway: eight beats at 120 need four seconds, so it is still going.
      await tester.pump(const Duration(milliseconds: 2500));
      expect(inScreen(MetronomeScreen, find.text('Stop')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pumpAndSettle();

      expect(inScreen(MetronomeScreen, find.text('Start')), findsOneWidget);
    });
  });

  group('drum machine', () {
    Finder cell(ClickVoice lane, int step) =>
        inScreen(DrumMachineScreen, find.byKey(Key('drum-${lane.name}-$step')));

    Color cellColor(WidgetTester tester, ClickVoice lane, int step) {
      final box = tester
          .widget<AnimatedContainer>(
            find.descendant(
              of: cell(lane, step),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .decoration;
      return (box as BoxDecoration).color!;
    }

    /// How many cells across the whole grid are lit up as a hit.
    int litCells(WidgetTester tester, Color primary) {
      var lit = 0;
      for (final lane in drumLanes) {
        for (var step = 0; step < drumSteps; step++) {
          if (cellColor(tester, lane, step) == primary) lit++;
        }
      }
      return lit;
    }

    Finder barCard(int index) =>
        inScreen(DrumMachineScreen, find.byKey(Key('bar-card-$index')));

    /// The card whose bar the playhead has reached wears a heavier border.
    bool barIsSounding(WidgetTester tester, int index) {
      final box =
          tester
                  .widget<AnimatedContainer>(
                    find.descendant(
                      of: barCard(index),
                      matching: find.byType(AnimatedContainer),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      return box.border!.top.width > 1.5;
    }

    /// How many of a bar's sixteen steps hold at least one drum, read off the
    /// little map on its card.
    int barSteps(WidgetTester tester, int index) {
      final blank = Theme.of(tester.element(find.byType(DrumMachineScreen)))
          .colorScheme
          .onSurface
          .withValues(alpha: 0.08);
      var lit = 0;
      for (var step = 0; step < drumSteps; step++) {
        final box =
            tester
                    .widget<Container>(
                      inScreen(
                        DrumMachineScreen,
                        find.byKey(Key('bar-$index-$step')),
                      ),
                    )
                    .decoration
                as BoxDecoration;
        if (box.color != blank) lit++;
      }
      return lit;
    }

    testWidgets('the rail opens a grid of every sample', (tester) async {
      await openSection(tester, 'DRUM MACHINE');
      final dim = Theme.of(tester.element(find.byType(DrumMachineScreen)))
          .colorScheme
          .surfaceContainerHighest;

      for (final lane in drumLanes) {
        expect(
          inScreen(DrumMachineScreen, find.text(lane.label)),
          findsOneWidget,
          reason: '${lane.name} should head a lane',
        );
      }

      // Eight lanes, sixteen steps, and the beat every fourth cell. The tom
      // lane is empty in the pattern the page ships with, so its cells show
      // the grid itself.
      expect(cell(ClickVoice.kick, 0), findsOneWidget);
      expect(cell(ClickVoice.stick, drumSteps - 1), findsOneWidget);
      expect(cellColor(tester, ClickVoice.tom, 0), dim);
      expect(cellColor(tester, ClickVoice.tom, 1), dim.withValues(alpha: 0.45));
    });

    testWidgets('a tapped cell stays lit until you tap it again', (
      tester,
    ) async {
      await openSection(tester, 'DRUM MACHINE');
      final scheme = Theme.of(tester.element(find.byType(DrumMachineScreen)))
          .colorScheme;

      // Two kicks, two snares and four cymbals come with the page, so the
      // first Play is never silence.
      final shipped = litCells(tester, scheme.primary);
      expect(shipped, 8);

      await tester.tap(cell(ClickVoice.snare, 6));
      await tester.pumpAndSettle();

      expect(cellColor(tester, ClickVoice.snare, 6), scheme.primary);
      expect(litCells(tester, scheme.primary), shipped + 1);

      await tester.tap(cell(ClickVoice.snare, 6));
      await tester.pumpAndSettle();

      expect(litCells(tester, scheme.primary), shipped);
    });

    testWidgets('a preset fills the grid and Clear empties it again', (
      tester,
    ) async {
      await openSection(tester, 'DRUM MACHINE');
      final scheme = Theme.of(tester.element(find.byType(DrumMachineScreen)))
          .colorScheme;

      // The rock beat is two kicks, two snares and four cymbals.
      await tester.tap(inScreen(DrumMachineScreen, find.text('Rock beat')));
      await tester.pumpAndSettle();

      expect(litCells(tester, scheme.primary), 8);
      expect(cellColor(tester, ClickVoice.kick, 10), scheme.primary);
      expect(cellColor(tester, ClickVoice.snare, 4), scheme.primary);
      expect(cellColor(tester, ClickVoice.cymbal, 8), scheme.primary);
      expect(cellColor(tester, ClickVoice.tom, 4), isNot(scheme.primary));

      // Loading another pattern replaces it instead of piling on top.
      await tester.tap(
        inScreen(DrumMachineScreen, find.text('Four on the floor')),
      );
      await tester.pumpAndSettle();

      // Four kicks, two claps, four bells, and the rock beat gone.
      expect(litCells(tester, scheme.primary), 10);
      expect(cellColor(tester, ClickVoice.clap, 12), scheme.primary);
      expect(cellColor(tester, ClickVoice.snare, 4), isNot(scheme.primary));

      await tester.tap(inScreen(DrumMachineScreen, find.text('Clear')));
      await tester.pumpAndSettle();

      expect(litCells(tester, scheme.primary), 0);
    });

    testWidgets('play walks the playhead and stop leaves the grid alone', (
      tester,
    ) async {
      await openSection(tester, 'DRUM MACHINE');
      final scheme = Theme.of(tester.element(find.byType(DrumMachineScreen)))
          .colorScheme;
      final dim = scheme.surfaceContainerHighest;

      await tester.tap(inScreen(DrumMachineScreen, find.byTooltip('Slower')));
      await tester.pumpAndSettle();

      // 95 beats a minute, so one of the sixteen steps lasts about 158 ms.
      expect(inScreen(DrumMachineScreen, find.text('95')), findsOneWidget);

      await tester.tap(inScreen(DrumMachineScreen, find.text('Play')));
      await tester.pump();

      expect(inScreen(DrumMachineScreen, find.text('Stop')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 120));

      expect(
        cellColor(tester, ClickVoice.tom, 0),
        scheme.primary.withValues(alpha: 0.22),
      );

      await tester.pump(const Duration(milliseconds: 160));

      expect(
        cellColor(tester, ClickVoice.tom, 1),
        scheme.primary.withValues(alpha: 0.22),
      );
      expect(cellColor(tester, ClickVoice.tom, 0), dim);

      await tester.tap(inScreen(DrumMachineScreen, find.text('Stop')));
      await tester.pumpAndSettle();

      expect(inScreen(DrumMachineScreen, find.text('Play')), findsOneWidget);
      // Stopping parks the playhead but leaves the written pattern alone.
      expect(litCells(tester, scheme.primary), 8);
      expect(cellColor(tester, ClickVoice.tom, 1), dim.withValues(alpha: 0.45));
    });

    testWidgets('a new bar is empty and only it changes', (tester) async {
      await openSection(tester, 'DRUM MACHINE');
      final scheme = Theme.of(tester.element(find.byType(DrumMachineScreen)))
          .colorScheme;

      // The page ships with the one bar the rock beat fills.
      expect(barCard(0), findsOneWidget);
      expect(barCard(1), findsNothing);
      expect(barSteps(tester, 0), 5);

      await tester.tap(inScreen(DrumMachineScreen, find.text('Add bar')));
      await tester.pumpAndSettle();

      expect(barCard(1), findsOneWidget);
      // The new bar is the one being written, so the grid under it is empty
      // while the first card keeps its five steps of rock beat.
      expect(litCells(tester, scheme.primary), 0);
      expect(barSteps(tester, 1), 0);
      expect(barSteps(tester, 0), 5);

      await tester.tap(cell(ClickVoice.tom, 3));
      await tester.pumpAndSettle();

      expect(barSteps(tester, 1), 1);
      expect(barSteps(tester, 0), 5);
      expect(litCells(tester, scheme.primary), 1);
    });

    testWidgets('Copy bar repeats the written one and the cards switch', (
      tester,
    ) async {
      await openSection(tester, 'DRUM MACHINE');
      final scheme = Theme.of(tester.element(find.byType(DrumMachineScreen)))
          .colorScheme;

      await tester.tap(inScreen(DrumMachineScreen, find.text('Copy bar')));
      await tester.pumpAndSettle();

      // The copy lands selected, so the grid still holds the eight rock cells.
      expect(barSteps(tester, 1), 5);
      expect(litCells(tester, scheme.primary), 8);

      // Editing the copy does not reach back into the bar it came from.
      await tester.tap(cell(ClickVoice.tom, 3));
      await tester.pumpAndSettle();

      expect(barSteps(tester, 1), 6);
      expect(barSteps(tester, 0), 5);

      await tester.tap(barCard(0));
      await tester.pumpAndSettle();

      expect(litCells(tester, scheme.primary), 8);
      expect(cellColor(tester, ClickVoice.tom, 3), isNot(scheme.primary));
    });

    testWidgets('the last bar cannot be deleted, and the other survives', (
      tester,
    ) async {
      await openSection(tester, 'DRUM MACHINE');
      final scheme = Theme.of(tester.element(find.byType(DrumMachineScreen)))
          .colorScheme;

      // One bar is the whole song, so there is nothing to throw away yet.
      expect(
        inScreen(DrumMachineScreen, find.text('Delete bar')),
        findsNothing,
      );

      await tester.tap(inScreen(DrumMachineScreen, find.text('Add bar')));
      await tester.pumpAndSettle();
      await tester.tap(inScreen(DrumMachineScreen, find.text('Delete bar')));
      await tester.pumpAndSettle();

      expect(barCard(1), findsNothing);
      expect(
        inScreen(DrumMachineScreen, find.text('Delete bar')),
        findsNothing,
      );
      // Back on the first bar, which the detour left untouched.
      expect(litCells(tester, scheme.primary), 8);
    });

    testWidgets('play runs one bar and then the next', (tester) async {
      await openSection(tester, 'DRUM MACHINE');
      final scheme = Theme.of(tester.element(find.byType(DrumMachineScreen)))
          .colorScheme;
      final dim = scheme.surfaceContainerHighest;

      /// Whether the grid is showing the bar the playhead is inside.
      bool playheadInGrid(WidgetTester tester) => List.generate(
        drumSteps,
        (step) => cellColor(tester, ClickVoice.tom, step),
      ).contains(scheme.primary.withValues(alpha: 0.22));

      await tester.tap(inScreen(DrumMachineScreen, find.text('Add bar')));
      await tester.pumpAndSettle();

      // The grid is showing bar 2, the empty one, while bar 1 plays.
      await tester.tap(inScreen(DrumMachineScreen, find.byTooltip('Slower')));
      await tester.pumpAndSettle();
      await tester.tap(inScreen(DrumMachineScreen, find.text('Play')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(barIsSounding(tester, 0), isTrue);
      expect(barIsSounding(tester, 1), isFalse);
      expect(playheadInGrid(tester), isFalse);
      expect(cellColor(tester, ClickVoice.tom, 0), dim);

      // A bar of steps at 95 BPM is about two and a half seconds, so the
      // playhead has moved on to the bar the grid is showing.
      await tester.pump(const Duration(milliseconds: 2700));

      expect(barIsSounding(tester, 0), isFalse);
      expect(barIsSounding(tester, 1), isTrue);
      expect(playheadInGrid(tester), isTrue);

      await tester.tap(inScreen(DrumMachineScreen, find.text('Stop')));
      await tester.pumpAndSettle();

      expect(barIsSounding(tester, 0), isFalse);
      expect(barIsSounding(tester, 1), isFalse);
    });

    testWidgets('a phone gets the steps in a sideways scroll', (tester) async {
      // The screen on its own, at thumb size: the shell's own phone behaviour
      // is covered by the navigation tests.
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: const Scaffold(body: DrumMachineScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final scheme = Theme.of(tester.element(find.byType(DrumMachineScreen)))
          .colorScheme;
      final steps = find.byKey(const Key('drum-steps'));
      final last = cell(ClickVoice.tom, drumSteps - 1);
      final label = inScreen(DrumMachineScreen, find.text('Kick'));

      // The tempo card keeps both of its buttons, even here.
      expect(
        tester
            .getTopRight(inScreen(DrumMachineScreen, find.byTooltip('Faster')))
            .dx,
        lessThan(420),
      );

      expect(
        tester.widget<SingleChildScrollView>(steps).scrollDirection,
        Axis.horizontal,
      );

      // Sixteen steps cannot share 420 px, so the far end starts off screen.
      expect(
        tester.getTopLeft(last).dx,
        greaterThan(tester.getTopRight(steps).dx),
      );

      final labelLeft = tester.getTopLeft(label);
      Scrollable.ensureVisible(tester.element(last));
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(last).dx,
        lessThan(tester.getTopRight(steps).dx),
      );
      // The lane names keep their column; only the steps scroll sideways. The
      // eleven lanes do push the grid past the bottom of a phone, so the page
      // can still slide vertically here.
      expect(tester.getTopLeft(label).dx, labelLeft.dx);

      await tester.tap(last);
      await tester.pumpAndSettle();

      expect(cellColor(tester, ClickVoice.tom, drumSteps - 1), scheme.primary);
    });
  });

  group('pluck synth', () {
    double peak(List<double> samples) {
      var highest = 0.0;
      for (final sample in samples) {
        highest = math.max(highest, sample.abs());
      }
      return highest;
    }

    test('a single pluck has the requested length and a full signal', () {
      final samples = PluckClip.single(110, seconds: 0.5);

      expect(samples.length, (0.5 * PluckClip.sampleRate).round());
      expect(peak(samples), greaterThan(0.6));
      expect(peak(samples), lessThan(1.0));
    });

    test('a strummed chord layers every string without clipping', () {
      final samples = PluckClip.chord([82.4, 110.0, 146.8, 196.0]);

      expect(samples.length, greaterThan(PluckClip.single(82.4).length));
      expect(peak(samples), lessThanOrEqualTo(0.9));
    });

    test('every click voice renders a usable beat', () {
      for (final voice in ClickVoice.values) {
        final samples = PluckClip.click(voice, accent: true);
        expect(samples, isNotEmpty, reason: voice.label);

        var highest = 0.0;
        for (final sample in samples) {
          highest = math.max(highest, sample.abs());
        }
        expect(highest, greaterThan(0.5), reason: voice.label);
        expect(highest, lessThanOrEqualTo(1.0), reason: voice.label);
      }
    });

    test('the metronome spaces its clicks by the tempo', () {
      final clicks = PluckClip.metronome(60, beats: 4);

      expect(clicks.length, closeTo(4.4 * PluckClip.sampleRate, 4410));
      expect(peak(clicks), greaterThan(0.5));
    });

    test('the encoded file is a 16-bit mono wav', () {
      final samples = PluckClip.single(220, seconds: 0.05);
      final wav = encodeWavMono(samples);

      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      expect(String.fromCharCodes(wav.sublist(36, 40)), 'data');
      expect(wav.length, 44 + samples.length * 2);
    });
  });

  group('recorded clicks', () {
    // Only the web layer plays these files, so the tests read the bytes
    // behind the paths instead.
    test('every sampled voice ships a short, audible pcm file', () {
      expect(clickSamplePaths.keys, isNot(contains(ClickVoice.stick)));
      expect(clickSamplePaths.length, ClickVoice.values.length - 1);

      final lengths = <ClickVoice, double>{};
      for (final entry in clickSamplePaths.entries) {
        final bytes = File(entry.value).readAsBytesSync();
        final wav = ByteData.sublistView(bytes);

        expect(
          String.fromCharCodes(bytes.sublist(0, 4)),
          'RIFF',
          reason: entry.key.label,
        );
        expect(
          wav.getUint16(20, Endian.little),
          1,
          reason: '${entry.value}: pcm',
        );
        expect(
          wav.getUint16(22, Endian.little),
          1,
          reason: '${entry.value}: mono',
        );
        expect(wav.getUint32(24, Endian.little), 44100, reason: entry.value);
        expect(wav.getUint16(34, Endian.little), 16, reason: entry.value);
        expect(bytes.length, lessThan(150 * 1024), reason: entry.value);

        // Tight enough that one beat does not hide the next, and the ride is
        // the one voice allowed to keep ringing.
        lengths[entry.key] = (bytes.length - 44) / 2 / 44100;
        expect(lengths[entry.key], lessThan(1.2), reason: entry.value);

        var peak = 0;
        for (var i = 44; i + 1 < bytes.length; i += 2) {
          peak = math.max(peak, wav.getInt16(i, Endian.little).abs());
        }
        expect(peak, greaterThan(8000), reason: '${entry.value}: silent');
      }
      expect(
        lengths[ClickVoice.cymbal],
        greaterThan(lengths[ClickVoice.snare]!),
      );
      // Both cymbals outlast the drum cuts; the bell is the shorter of the
      // two, which is what makes it read as a ping and not a wash.
      expect(lengths[ClickVoice.bell], greaterThan(lengths[ClickVoice.snare]!));
      expect(lengths[ClickVoice.bell], lessThan(lengths[ClickVoice.cymbal]!));
      expect(lengths[ClickVoice.kick], greaterThan(lengths[ClickVoice.clap]!));
    });

    test('the pubspec carries the folder the loader reads', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      expect(pubspec, contains('- assets/clicks/'));
      for (final path in clickSamplePaths.values) {
        expect(path, startsWith('assets/clicks/'));
      }
    });
  });
}
