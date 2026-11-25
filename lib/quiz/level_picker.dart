import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import 'quiz_level.dart';

/// The four difficulty levels as chips, with the chosen one explained
/// underneath. The written quiz and the ear trainer share it so a round means
/// the same thing on either side.
class LevelPicker extends StatelessWidget {
  final QuizLevel level;
  final ValueChanged<QuizLevel> onChanged;

  const LevelPicker({super.key, required this.level, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          L.t(context, 'How hard?'),
          style: theme.textTheme.labelLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final one in QuizLevel.values)
              ChoiceChip(
                label: Text(L.t(context, one.label)),
                selected: level == one,
                onSelected: (_) => onChanged(one),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          L.t(context, level.blurb),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
