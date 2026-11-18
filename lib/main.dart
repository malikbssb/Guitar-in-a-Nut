import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'l10n/strings.dart';
import 'start/start_screen.dart';
import 'theory/theory_screen.dart';
import 'widgets/settings_fab.dart';
import 'widgets/theme_fab.dart';

void main() {
  runApp(const GuitarInANutApp());
}

/// Near-black base with a single blue accent, so the diagrams stay readable.
ThemeData get appTheme => ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF4C9AFF),
    onPrimary: Color(0xFF04101F),
    primaryContainer: Color(0xFF1B4E82),
    onPrimaryContainer: Color(0xFFE7F3FF),
    secondary: Color(0xFF7FC8FF),
    onSecondary: Color(0xFF04101F),
    secondaryContainer: Color(0xFF143A5E),
    onSecondaryContainer: Color(0xFFD6EBFF),
    surface: Color(0xFF071018),
    onSurface: Color(0xFFE7EEF6),
    onSurfaceVariant: Color(0xFF9EB2C6),
    error: Color(0xFFFF6B6B),
    surfaceContainer: Color(0xFF0B1B2E),
    surfaceContainerHighest: Color(0xFF132334),
    outline: Color(0xFF3A5068),
  ),
  scaffoldBackgroundColor: const Color(0xFF04070C),
);

/// The same palette the other way round, for a bright room or a projector.
ThemeData get lightAppTheme => ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF1257A6),
    onPrimary: Color(0xFFF2F8FF),
    primaryContainer: Color(0xFFCFE4FF),
    onPrimaryContainer: Color(0xFF06284F),
    secondary: Color(0xFF0E6E8C),
    onSecondary: Color(0xFFF2FBFF),
    secondaryContainer: Color(0xFFCDE9F3),
    onSecondaryContainer: Color(0xFF04303F),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF0B1B2E),
    onSurfaceVariant: Color(0xFF4B627B),
    error: Color(0xFFB3261E),
    surfaceContainer: Color(0xFFEDF3FB),
    surfaceContainerHighest: Color(0xFFDEE9F6),
    outline: Color(0xFF93A7BC),
  ),
  scaffoldBackgroundColor: const Color(0xFFF7FAFE),
);

class GuitarInANutApp extends StatefulWidget {
  const GuitarInANutApp({super.key});

  @override
  State<GuitarInANutApp> createState() => _GuitarInANutAppState();
}

class _GuitarInANutAppState extends State<GuitarInANutApp> {
  bool _lightMode = false;
  AppLang _lang = AppLang.en;

  /// Every screen reads the gear's callback, which is the only way to change
  /// the language.
  void _setLang(AppLang lang) => setState(() => _lang = lang);

  void _toggleTheme() => setState(() => _lightMode = !_lightMode);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guitar in a Nut',
      theme: _lightMode ? lightAppTheme : appTheme,
      // Mounted above the navigator so dialogs, sheets and the sections that
      // stay alive in the shell all rebuild when the language flips.
      builder: (context, child) => L(lang: _lang, child: child!),
      home: AppEntry(
        lightMode: _lightMode,
        onToggleTheme: _toggleTheme,
        onLang: _setLang,
      ),
    );
  }
}

/// Asks once whether the visitor needs the theory page.
class AppEntry extends StatefulWidget {
  final bool lightMode;
  final VoidCallback onToggleTheme;
  final ValueChanged<AppLang> onLang;

  const AppEntry({
    super.key,
    required this.lightMode,
    required this.onToggleTheme,
    required this.onLang,
  });

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _insideApp = false;

  Widget _settingsFab() =>
      SettingsFab(onLang: widget.onLang, onToggleTheme: widget.onToggleTheme);

  void _openTheory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (routeContext) => Scaffold(
          appBar: AppBar(title: Text(L.t(routeContext, 'The basics'))),
          floatingActionButton: ThemeFab(
            lightMode: widget.lightMode,
            onPressed: widget.onToggleTheme,
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: TheoryScreen(
                  onContinue: () {
                    Navigator.of(routeContext).pop();
                    setState(() => _insideApp = true);
                  },
                ),
              ),
              Positioned(left: 12, bottom: 12, child: _settingsFab()),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_insideApp) {
      return AppShell(
        lightMode: widget.lightMode,
        onToggleTheme: widget.onToggleTheme,
        onLang: widget.onLang,
      );
    }

    return StartScreen(
      lightMode: widget.lightMode,
      onToggleTheme: widget.onToggleTheme,
      onLang: widget.onLang,
      onBeginner: _openTheory,
      onReady: () => setState(() => _insideApp = true),
    );
  }
}
