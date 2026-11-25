import '../models/chords.dart';
import '../models/notes.dart';

/// How hard a round is, and whether the player picks or types.
///
/// The three first levels share the same rule: a round only asks about
/// material up to its own tier. Expert reads the whole pool but takes the
/// options away, so the answer has to be written down.
enum QuizLevel {
  easy(
    'Easy',
    'Open strings, the first chord shapes and the notes you already met.',
  ),
  medium(
    'Medium',
    'Intervals, tunings, keys and the neck up to the 12th fret.',
  ),
  hard('Hard', 'The whole site, including the borrowed and extended shapes.'),
  expert('Expert', 'No options to fall back on. Type what you hear or read.');

  const QuizLevel(this.label, this.blurb);

  final String label;
  final String blurb;

  /// The highest tier this level is allowed to ask about.
  int get topTier => switch (this) {
    QuizLevel.easy => 0,
    QuizLevel.medium => 1,
    QuizLevel.hard || QuizLevel.expert => 2,
  };

  bool get isTyped => this == QuizLevel.expert;
}

/// The shapes a beginner is handed first, before any barre or extension.
const _firstShapes = {'C', 'G', 'D', 'A', 'E', 'Am', 'Em', 'Dm'};

/// 0 for the first-week shapes, 1 for the rest of the open position, 2 for
/// barre chords, extensions and the shapes that live past fret 5.
int chordTier(ChordShape chord) {
  final name = chord.name;
  if (_firstShapes.contains(name)) return 0;
  final extended = RegExp(r'(7|9|sus|add|maj|dim|aug)').hasMatch(name);
  final highUp = chord.highestFret >= 5;
  final sharpRoot =
      name.startsWith('F#') || name.startsWith('C#') || name.startsWith('Bb');
  return extended || highUp || sharpRoot ? 2 : 1;
}

/// A bare note name or a number: the two answers nobody has to think about.
bool isBasicAnswer(String answer) =>
    noteNames.contains(answer) || RegExp(r'^\d+$').hasMatch(answer);

/// Answers short enough to be worth typing: a note, a chord, an interval, a
/// tuning, a number. Sentences are not, and neither are labels that need a
/// qualifier to be unique - `E (low)` and `E (high)` both become `e` once the
/// bracket goes away, so a typed `e` cannot be marked right or wrong.
bool isTypeable(String answer) {
  final text = answer.trim();
  if (text.isEmpty || text.length > 18) return false;
  if (text.split(RegExp(r'\s+')).length > 3) return false;
  if (text.contains(',') || text.contains(':') || text.contains('(')) {
    return false;
  }
  return RegExp(r"^[A-Za-z0-9#/'\- ]+$").hasMatch(text);
}

/// Lower case, punctuation and parenthetical labels away, so `E (low)`,
/// `e` and `F Sharp` all collapse onto what the player means.
String normalizeAnswer(String raw) {
  var text = raw.toLowerCase().trim();
  text = text.replaceAll('’', "'");
  text = text.replaceAll(RegExp(r'\(.*?\)'), ' ');
  text = text
      .replaceAll('sharp', '#')
      .replaceAll('dièse', '#')
      .replaceAll('sostenuto', '#');
  text = text.replaceAll(RegExp(r"[^a-z0-9#/ ]+"), ' ');
  text = text.replaceAll(RegExp(r'\s+#'), '#');
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

final _noteOnly = RegExp(r'^[a-g]#?$');
final _noteWithOctave = RegExp(r'^[a-g]#?\d$');

/// Whether a typed answer is the one the question was asking for. An octave
/// number on a note name is forgiven, because the app never plays two octaves.
bool typedAnswerMatches(String typed, String expected) {
  final given = normalizeAnswer(typed);
  final wanted = normalizeAnswer(expected);
  if (given.isEmpty || wanted.isEmpty) return false;
  if (given == wanted) return true;
  if (_noteOnly.hasMatch(wanted) && _noteWithOctave.hasMatch(given)) {
    return given[0] == wanted[0] &&
        (wanted.length == 1 || given[1] == wanted[1]);
  }
  return false;
}
