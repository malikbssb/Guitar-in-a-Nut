import 'package:flutter/material.dart';

import '../l10n/strings.dart';

/// The page a beginner can point at and ask "where do I even start?". Four
/// steps, each one with the exact page in this app that teaches it.
///
/// It opens as the last lesson of the LEARN tab, which already shows the
/// question as its heading, so the framed plate here only carries the intro.
class RoadmapScreen extends StatelessWidget {
  final VoidCallback onOpenChords;
  final VoidCallback onOpenNeck;
  final VoidCallback onOpenQuiz;
  final VoidCallback onOpenEarTraining;
  final VoidCallback onOpenMetronome;
  final ValueChanged<int> onOpenLesson;

  const RoadmapScreen({
    super.key,
    required this.onOpenChords,
    required this.onOpenNeck,
    required this.onOpenQuiz,
    required this.onOpenEarTraining,
    required this.onOpenMetronome,
    required this.onOpenLesson,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _FancyFrame(
            child: Text(
              L.t(
                context,
                'Four things, and they come in this order. You do not '
                'need all of them at once: each one has a page in this '
                'app, and the link under every step takes you there.',
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 18),
          _Step(
            number: 1,
            title: L.t(context, 'Four or five chord shapes'),
            text: L.t(
              context,
              'C, G, D, A, E, Am and Em cover thousands of songs. Learn the '
              'shapes, then learn to move between two of them without '
              'stopping. A chord is only useful once your hand finds it '
              'without looking.',
            ),
            links: [
              _Link(
                L.t(context, 'Open the chord shapes'),
                onOpenChords,
                Icons.grid_view,
              ),
              _Link(
                L.t(context, 'What is a chord?'),
                () => onOpenLesson(1),
                Icons.school_outlined,
              ),
            ],
          ),
          _Step(
            number: 2,
            title: L.t(context, 'Finger independence and dexterity'),
            text: L.t(
              context,
              'The fingers do not obey yet, and that is normal. Slow, clean '
              'repetition is the only training: one note per string, each '
              'note heard clearly, hands relaxed. Speed is a side effect of '
              'accuracy, never the other way round.',
            ),
            links: [
              _Link(
                L.t(context, 'Walk the notes on the neck'),
                onOpenNeck,
                Icons.linear_scale,
              ),
              _Link(
                L.t(context, 'How to read tabs'),
                () => onOpenLesson(6),
                Icons.shortcut,
              ),
            ],
          ),
          _Step(
            number: 3,
            title: L.t(context, 'A few basic scales'),
            text: L.t(
              context,
              'Minor pentatonic first, then the major scale. A scale is one '
              'shape you can slide anywhere on the neck, and it is what '
              'solos, riffs and single-note lines are cut from.',
            ),
            links: [
              _Link(
                L.t(context, 'Hear every scale'),
                onOpenChords,
                Icons.linear_scale,
              ),
              _Link(
                L.t(context, 'What is a scale?'),
                () => onOpenLesson(2),
                Icons.school_outlined,
              ),
              _Link(
                L.t(context, 'Light up a scale on the neck'),
                onOpenNeck,
                Icons.brightness_1_outlined,
              ),
            ],
          ),
          _Step(
            number: 4,
            title: L.t(context, 'Rhythm, with a metronome'),
            text: L.t(
              context,
              'Strumming patterns, down-strokes on the beats and a count '
              'out loud. Then play against a click: it is the only honest '
              'way to hear whether you are actually together with the beat.',
            ),
            links: [
              _Link(
                L.t(context, 'Strumming and arpeggios'),
                () => onOpenLesson(1),
                Icons.waves,
              ),
              _Link(
                L.t(context, 'What are time signatures?'),
                () => onOpenLesson(4),
                Icons.av_timer,
              ),
              _Link(
                L.t(context, 'How to use a metronome'),
                () => onOpenLesson(7),
                Icons.school_outlined,
              ),
              _Link(
                L.t(context, 'Open the metronome'),
                onOpenMetronome,
                Icons.speed,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _FancyFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L.t(context, 'Then check what stuck'),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  L.t(
                    context,
                    'The written quiz asks about shapes, notes and tunings. '
                    'The ear training asks about sounds. Start on Easy, and '
                    'move up when the answers stop surprising you.',
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    _Link(
                      L.t(context, 'Take the quiz'),
                      onOpenQuiz,
                      Icons.quiz_outlined,
                    ),
                    _Link(
                      L.t(context, 'Train your ears'),
                      onOpenEarTraining,
                      Icons.hearing,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The step number, its name, why it matters and where to read more.
class _Step extends StatelessWidget {
  final int number;
  final String title;
  final String text;
  final List<_Link> links;

  const _Step({
    required this.number,
    required this.title,
    required this.text,
    required this.links,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        margin: EdgeInsets.zero,
        color: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: Text(
                      '$number',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(text, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 2,
                children: [for (final link in links) link],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small text link that jumps to another page of the app.
class _Link extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData icon;

  const _Link(this.label, this.onTap, this.icon);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(icon, size: 16, color: theme.colorScheme.primary),
      label: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
          decorationColor: theme.colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Double border and a warm inner plate, so the two framing pages read as the
/// cover and the last page of the app rather than another card.
class _FancyFrame extends StatelessWidget {
  final Widget child;

  const _FancyFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary, scheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.onSurface.withValues(alpha: 0.1)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: child,
        ),
      ),
    );
  }
}
