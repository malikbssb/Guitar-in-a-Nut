import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/notes.dart';
import 'lessons.dart';

/// The LEARN tab: a list of short pages, each one answer to a question a
/// beginner actually asks. Interactive lessons reuse the pages already in the
/// app, so nothing is taught twice.
class LearnScreen extends StatefulWidget {
  final Tuning tuning;

  /// Set when another screen asks for one specific lesson.
  final int? openLesson;

  final VoidCallback onOpenTuner;
  final VoidCallback onOpenChords;
  final VoidCallback onOpenNeck;
  final VoidCallback onOpenQuiz;

  const LearnScreen({
    super.key,
    required this.tuning,
    required this.openLesson,
    required this.onOpenTuner,
    required this.onOpenChords,
    required this.onOpenNeck,
    required this.onOpenQuiz,
  });

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  int? _open;

  @override
  void initState() {
    super.initState();
    _open = widget.openLesson;
  }

  @override
  void didUpdateWidget(LearnScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.openLesson != oldWidget.openLesson) {
      setState(() => _open = widget.openLesson);
    }
  }

  List<Lesson> _lessons() => learnLessons(
    tuning: widget.tuning,
    onOpenTuner: widget.onOpenTuner,
    onOpenChords: widget.onOpenChords,
    onOpenNeck: widget.onOpenNeck,
    onOpenQuiz: widget.onOpenQuiz,
  );

  @override
  Widget build(BuildContext context) {
    final lessons = _lessons();
    final index = _open;

    if (index == null || index >= lessons.length) {
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              L.f(
                context,
                '{n} short pages, each one an answer to a question '
                'beginners actually ask. Every page has something to listen '
                'to.',
                {'n': '${lessons.length}'},
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < lessons.length; i++)
              _LessonCard(
                lesson: lessons[i],
                number: i + 1,
                onTap: () => setState(() => _open = i),
              ),
          ],
        ),
      );
    }

    final lesson = lessons[index];

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: L.t(context, 'All lessons'),
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _open = null),
                ),
                Icon(lesson.icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lesson.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: lesson.body != null
                ? lesson.body!(context)
                : _LessonBlocks(blocks: lesson.blocks),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final int number;
  final VoidCallback onTap;

  const _LessonCard({
    required this.lesson,
    required this.number,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: Text('$number'),
        ),
        title: Text(lesson.title, style: theme.textTheme.titleSmall),
        subtitle: Text(lesson.blurb, style: theme.textTheme.bodySmall),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _LessonBlocks extends StatelessWidget {
  final List<LessonBlock> blocks;

  const _LessonBlocks({required this.blocks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        for (final block in blocks)
          switch (block) {
            Prose() => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(block.text, style: theme.textTheme.bodyMedium),
            ),
            Points() => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in block.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6, right: 10),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            FactTable() => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _Table(columns: block.columns, rows: block.rows),
              ),
            ),
            TabStaff() => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    block.lines.join('\n'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            Hear() => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final action in block.actions)
                    FilledButton.tonalIcon(
                      onPressed: action.play,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(action.label),
                    ),
                ],
              ),
            ),
            OpenSection() => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: block.onTap,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(block.label),
                ),
              ),
            ),
          },
      ],
    );
  }
}

class _Table extends StatelessWidget {
  final List<String> columns;
  final List<List<String>> rows;

  const _Table({required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _row(
              theme,
              columns,
              background: scheme.primaryContainer.withValues(alpha: 0.35),
              bold: true,
            ),
          ),
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _row(
                theme,
                rows[i],
                background: i.isEven
                    ? scheme.surfaceContainer
                    : scheme.surfaceContainerHighest,
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(
    ThemeData theme,
    List<String> cells, {
    Color? background,
    bool bold = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final cell in cells)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  cell,
                  style:
                      (bold
                              ? theme.textTheme.labelLarge
                              : theme.textTheme.bodySmall)
                          ?.copyWith(color: theme.colorScheme.onSurface),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
