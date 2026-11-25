import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../widgets/chord_diagram.dart';
import '../widgets/option_button.dart';
import 'level_picker.dart';
import 'quiz_data.dart';
import 'quiz_level.dart';
import 'typed_answer.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const _lengths = [5, 10, 15, 20];

  /// Empty until a round is drawn, which keeps the intro on screen.
  List<Question> _questions = const [];
  bool _done = false;
  int _length = quizLength;
  QuizLevel _level = QuizLevel.medium;
  int _index = 0;
  int _score = 0;
  int? _picked;

  /// Expert rounds: what was typed, and whether it was right.
  final _typed = TextEditingController();
  String? _typedReply;
  bool _typedRight = false;

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  Question get _question => _questions[_index];

  bool get _isTyped => _level.isTyped;

  bool get _answered => _isTyped ? _typedReply != null : _picked != null;

  bool get _isRight =>
      _isTyped ? _typedRight : _picked == _question.answerIndex;

  void _start() => setState(() {
    _questions = quizRound(count: _length, level: _level);
    _done = false;
    _index = 0;
    _score = 0;
    _picked = null;
    _typedReply = null;
    _typed.clear();
  });

  void _next() => setState(() {
    if (_index + 1 >= _questions.length) {
      _done = true;
    } else {
      _index++;
    }
    _picked = null;
    _typedReply = null;
    _typed.clear();
  });

  /// An empty box is not an answer, so the round waits for a real attempt.
  void _checkTyped() {
    if (_answered || _typed.text.trim().isEmpty) return;
    final correct = typedAnswerMatches(_typed.text, _question.answer);
    setState(() {
      _typedReply = _typed.text;
      _typedRight = correct;
      if (correct) _score++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_questions.isEmpty) {
      return SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  L.t(context, 'A different quiz every time'),
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  L.f(
                    context,
                    'The app builds {n} questions at this level from the '
                    'diagrams, the tunings and the key groups on these pages, '
                    'then draws a fresh set. Nothing repeats in the same '
                    'order.',
                    {'n': '${quizPoolSizeFor(_level)}'},
                  ),
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                LevelPicker(
                  level: _level,
                  onChanged: (one) => setState(() => _level = one),
                ),
                const SizedBox(height: 20),
                Text(
                  L.t(context, 'How many questions?'),
                  style: theme.textTheme.labelLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final length in _lengths)
                      ChoiceChip(
                        label: Text('$length'),
                        selected: _length == length,
                        onSelected: (_) => setState(() => _length = length),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.shuffle),
                  label: Text(
                    L.f(context, 'Draw {n} questions', {'n': '$_length'}),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_done) {
      final ratio = _score / _questions.length;
      final verdict = L.t(
        context,
        ratio >= 0.8
            ? 'Strong. You could tune someone else now.'
            : ratio >= 0.5
            ? 'Solid start. Another pass through LEARN and it clicks.'
            : 'Go back to Chords, then try again.',
      );
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_score / ${_questions.length}',
                  style: theme.textTheme.displayMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  L.t(context, _level.label),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(verdict, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.shuffle),
                  label: Text(L.t(context, 'New round')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = _questions[_index];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  L.f(context, 'Question {i} of {n}', {
                    'i': '${_index + 1}',
                    'n': '${_questions.length}',
                  }),
                  style: theme.textTheme.labelLarge,
                ),
              ),
              Text(
                L.t(context, question.kind.label),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: 10),
              Text(
                L.t(context, _level.label),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                L.f(context, 'Score: {n}', {'n': '$_score'}),
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: _index / _questions.length),
          if (question.diagram != null) ...[
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  ChordDiagram(chord: question.diagram!, showName: false),
                  Text(
                    L.t(context, 'strings 6 → 1'),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(question.prompt, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          if (_isTyped)
            TypedAnswerField(
              controller: _typed,
              canType: !_answered,
              onSubmit: _checkTyped,
            )
          else
            for (var i = 0; i < question.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OptionButton(
                  text: question.options[i],
                  isAnswer: i == question.answerIndex,
                  isPicked: i == _picked,
                  revealed: _answered,
                  onTap: () => setState(() {
                    if (_picked == null && i == question.answerIndex) _score++;
                    _picked = i;
                  }),
                ),
              ),
          if (_answered) ...[
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isRight
                          ? L.t(context, 'Correct')
                          : L.f(context, 'Answer: {a}', {
                              'a': question.options[question.answerIndex],
                            }),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    if (_typedReply != null && !_isRight)
                      Text(
                        L.f(context, 'You wrote {a}', {
                          'a': '“${_typedReply!.trim()}”',
                        }),
                      ),
                    Text(question.explanation),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _next,
              child: Text(
                L.t(
                  context,
                  _index + 1 == _questions.length
                      ? 'See my score'
                      : 'Next question',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
