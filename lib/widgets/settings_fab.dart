import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import 'settings_sheet.dart';

/// Bottom-left gear that opens the settings sheet. The theme button stays
/// where it always was in the bottom right; this one adds language and a
/// second way to flip the palette.
class SettingsFab extends StatelessWidget {
  final ValueChanged<AppLang> onLang;
  final VoidCallback onToggleTheme;

  const SettingsFab({
    super.key,
    required this.onLang,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FloatingActionButton.small(
      tooltip: L.t(context, 'Settings'),
      heroTag: 'settings',
      onPressed: () => showSettingsSheet(
        context,
        onLang: onLang,
        onToggleTheme: onToggleTheme,
      ),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      foregroundColor: theme.colorScheme.onSurface,
      child: const Icon(Icons.settings_outlined),
    );
  }
}
