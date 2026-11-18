import 'package:flutter/material.dart';

import '../l10n/strings.dart';

/// Bottom-right button that flips the whole app between the two palettes.
/// Every screen shows it, so the choice is never one tap away from a page
/// that has no way back.
class ThemeFab extends StatelessWidget {
  final bool lightMode;
  final VoidCallback onPressed;

  const ThemeFab({super.key, required this.lightMode, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FloatingActionButton.small(
      heroTag: 'theme',
      tooltip: L.t(
        context,
        lightMode ? 'Back to the dark theme' : 'Switch to light mode',
      ),
      onPressed: onPressed,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      foregroundColor: theme.colorScheme.onSurface,
      child: Icon(lightMode ? Icons.dark_mode : Icons.light_mode),
    );
  }
}
