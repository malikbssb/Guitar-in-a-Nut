import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../widgets/option_button.dart';
import 'ear_training_data.dart';
import 'level_picker.dart';
import 'quiz_level.dart';
import 'typed_answer.dart';

/// The second quiz: nothing is written down until you have guessed. Pick a
/// round - open strings, chords, notes on the neck, or everything mixed.
class EarTrainingScreen extends StatefulWidget {
  const EarTrainingScreen({super.key});

  @override
  State<EarTrainingScreen> createState() => _EarTrainingScreenState();
}

class _EarTrainingScreenState extends State<EarTrainingScreen> {
  static const _counts = [5, 10, 15, 20];

  bool _started = false;
  EarMode _mode = EarMode.everything;
  QuizLevel _level = QuizLevel.medium;
  int _count = 10;
  List<EarQuestion> _questions = const [];
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

  bool get _finished => _index >= _questions.length;
  bool get _isTyped => _level.isTyped;
  bool get _answered => _isTyped ? _typedReply != null : _picked != null;

  bool get _isRight =>
      _isTyped ? _typedRight : _picked == _questions[_index].answerIndex;

  void _start(EarMode mode) {
    setState(() {
      _mode = mode;
      _questions = earQuestionsFor(mode, count: _count, level: _level);
      _started = true;
      _index = 0;
      _score = 0;
      _picked = null;
      _typedReply = null;
      _typed.clear();
    });
    _playCurrent();
  }

  /// Sound only ever starts after a tap, which is also what the browser
  /// requires before it lets a clip play.
  void _playCurrent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_answered) _questions[_index].play();
    });
  }

  void _next() {
    setState(() {
      _index++;
      _picked = null;
      _typedReply = null;
      _typed.clear();
    });
    // Past the last sound the score page takes over and nothing plays.
    if (!_finished) _playCurrent();
  }

  /// An empty box is not an answer, so the round waits for a real attempt.
  void _checkTyped() {
    if (_answered || _typed.text.trim().isEmpty) return;
    final correct = typedAnswerMatches(_typed.text, _questions[_index].answer);
    setState(() {
      _typedReply = _typed.text;
      _typedRight = correct;
      if (correct) _score++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_started) {
      return SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.hearing,
                    size: 54,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    L.t(context, 'Ear training'),
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    L.t(
                      context,
                      'No diagrams and no names on screen. Listen, guess, and '
                      'the explanation tells you what to listen for next '
                      'time.',
                    ),
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  LevelPicker(
                    level: _level,
                    onChanged: (one) => setState(() => _level = one),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    L.t(context, 'How many sounds?'),
                    style: theme.textTheme.labelLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final one in _counts)
                        ChoiceChip(
                          label: Text('$one'),
                          selected: _count == one,
                          onSelected: (_) => setState(() => _count = one),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  for (final mode in EarMode.values) ...[
                    _ModeButton(
                      mode: mode,
                      level: _level,
                      count: _count,
                      onTap: () => _start(mode),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_finished) {
      final ratio = _score / _questions.length;
      final verdict = L.t(
        context,
        ratio >= 0.8
            ? 'Your ears are ahead of your hands. Try the written quiz too.'
            : ratio >= 0.5
            ? 'Good. Replay the ones you missed and listen for the 3rd.'
            : 'Play the sounds again slowly - comparison is what trains an '
                  'ear.',
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
                  '${L.t(context, _mode.label)} - ${L.t(context, _level.label)}',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(verdict, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _start(_mode),
                  icon: const Icon(Icons.replay),
                  label: Text(
                    L.f(context, 'Run {mode} again', {
                      'mode': L.t(context, _mode.label).toLowerCase(),
                    }),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _started = false),
                  icon: const Icon(Icons.list),
                  label: Text(L.t(context, 'Pick another round')),
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
                  L.f(context, 'Sound {i} of {n}', {
                    'i': '${_index + 1}',
                    'n': '${_questions.length}',
                  }),
                  style: theme.textTheme.labelLarge,
                ),
              ),
              Text(
                L.f(context, 'Score: {n}', {'n': '$_score'}),
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${L.t(context, _mode.label)} - '
            '${L.t(context, _level.label)} - ${L.t(context, question.kind)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: _index / _questions.length),
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            onPressed: question.play,
            icon: const Icon(Icons.volume_up),
            label: Text(
              L.t(context, _answered ? 'Hear it again' : 'Hear the sound'),
            ),
          ),
          const SizedBox(height: 18),
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
                      : 'Next sound',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One round of the ear trainer, labelled with what it actually listens to.
class _ModeButton extends StatelessWidget {
  final EarMode mode;
  final QuizLevel level;
  final int count;
  final VoidCallback onTap;

  const _ModeButton({
    required this.mode,
    required this.level,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        foregroundColor: theme.colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.16),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L.t(context, mode.label),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            L.t(context, mode.blurb),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            () {
              final pool = earPoolSize(mode, level: level);
              if (pool == 0) return L.t(context, 'Nothing at this level');
              if (pool > count) {
                return L.f(context, '{n} sounds, drawn fresh from {m}', {
                  'n': '$count',
                  'm': '$pool',
                });
              }
              return L.f(context, '{n} sounds from {m}, so they come back', {
                'n': '$count',
                'm': '$pool',
              });
            }(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}
