import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../widgets/settings_fab.dart';
import '../widgets/theme_fab.dart';

/// First screen: decides whether the visitor needs the theory page.
class StartScreen extends StatelessWidget {
  final bool lightMode;
  final VoidCallback onToggleTheme;
  final ValueChanged<AppLang> onLang;
  final VoidCallback onBeginner;
  final VoidCallback onReady;

  const StartScreen({
    super.key,
    required this.lightMode,
    required this.onToggleTheme,
    required this.onLang,
    required this.onBeginner,
    required this.onReady,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: ThemeFab(
        lightMode: lightMode,
        onPressed: onToggleTheme,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.music_note,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Guitar in a Nut',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          L.t(
                            context,
                            'A tuner, the chords you actually need, and a '
                            'quiz to check what stuck.',
                          ),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 36),
                        Text(
                          L.t(context, 'Are you a complete beginner?'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: onBeginner,
                          icon: const Icon(Icons.school),
                          label: Text(
                            L.t(context, 'Yes, teach me the basics first'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: onReady,
                          icon: const Icon(Icons.tune),
                          label: Text(L.t(context, 'No, take me to the tools')),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          L.t(
                            context,
                            'You can open the same page later from the menu.',
                          ),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: SettingsFab(onLang: onLang, onToggleTheme: onToggleTheme),
          ),
        ],
      ),
    );
  }
}
