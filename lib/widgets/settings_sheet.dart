import 'package:flutter/material.dart';

import '../l10n/strings.dart';

/// Settings panel: which language the interface speaks and which palette it
/// wears. Both choices live above the app, so the sheet only reports taps and
/// reads the current values back from the theme and from [L].
class SettingsSheet extends StatelessWidget {
  final ValueChanged<AppLang> onLang;
  final VoidCallback onToggleTheme;

  const SettingsSheet({
    super.key,
    required this.onLang,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = L.of(context);
    final lightMode = theme.brightness == Brightness.light;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(L.t(context, 'Settings'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Text(L.t(context, 'Language'), style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            SegmentedButton<AppLang>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: AppLang.en,
                  label: Text(L.t(context, 'English')),
                ),
                ButtonSegment(value: AppLang.fr, label: const Text('Français')),
              ],
              selected: {lang},
              onSelectionChanged: (picked) => onLang(picked.first),
            ),
            const SizedBox(height: 8),
            Text(
              L.t(
                context,
                'Only the interface is translated. Lessons, chord stories '
                'and quiz questions stay in English.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    L.t(
                      context,
                      'The French side is a machine pass nobody has proofread. '
                      'Wordings can be off, so English stays the recommended '
                      'language.',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: lang == AppLang.fr
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(L.t(context, 'Theme'), style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: false,
                  icon: const Icon(Icons.dark_mode_outlined, size: 18),
                  label: Text(L.t(context, 'Dark')),
                ),
                ButtonSegment(
                  value: true,
                  icon: const Icon(Icons.light_mode_outlined, size: 18),
                  label: Text(L.t(context, 'Light')),
                ),
              ],
              selected: {lightMode},
              onSelectionChanged: (picked) {
                if (picked.first != lightMode) onToggleTheme();
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showSettingsSheet(
  BuildContext context, {
  required ValueChanged<AppLang> onLang,
  required VoidCallback onToggleTheme,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
    builder: (_) => SettingsSheet(onLang: onLang, onToggleTheme: onToggleTheme),
  );
}
