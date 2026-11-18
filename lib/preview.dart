import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'chords/chords_screen.dart';
import 'l10n/strings.dart';
import 'learn/learn_screen.dart';
import 'main.dart';
import 'metronome/metronome_screen.dart';
import 'models/chords.dart';
import 'models/notes.dart';
import 'models/scales.dart';
import 'neck/neck_screen.dart';
import 'quiz/ear_training_screen.dart';
import 'quiz/quiz_screen.dart';
import 'theory/theory_screen.dart';
import 'widgets/settings_sheet.dart';

/// Scratch entry used only to screenshot individual screens head-lessly.
///
/// The fragment picks the page, and an optional language in front of it:
/// `#/neck`, `#/fr/neck`, `#/fr/settings`.
void main() {
  runApp(const _PreviewApp());
}

class _PreviewApp extends StatefulWidget {
  const _PreviewApp();

  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  AppLang _lang = AppLang.en;
  String _page = '';
  bool _lightMode = false;

  @override
  void initState() {
    super.initState();
    final route = _read();
    _lang = route.lang;
    _page = route.page;
    _lightMode = _page == 'light';
  }

  ({AppLang lang, String page}) _read() {
    final segments = Uri.base.fragment
        .split('/')
        .where((part) => part.isNotEmpty)
        .toList();
    var lang = AppLang.en;
    var page = '';
    if (segments.isNotEmpty &&
        (segments.first == 'fr' || segments.first == 'en')) {
      lang = segments.first == 'fr' ? AppLang.fr : AppLang.en;
      page = segments.length > 1 ? segments[1] : '';
    } else if (segments.isNotEmpty) {
      page = segments.first;
    }
    return (lang: lang, page: page);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _lightMode ? lightAppTheme : appTheme,
      builder: (context, child) => L(lang: _lang, child: child!),
      home: _body(_page),
    );
  }

  Widget _body(String page) {
    if (page.isEmpty ||
        page == 'home' ||
        page == 'light' ||
        page == 'settings-light') {
      return AppShell(
        lightMode: _lightMode,
        onToggleTheme: () => setState(() => _lightMode = !_lightMode),
        onLang: (lang) => setState(() => _lang = lang),
      );
    }

    final tuning = tunings.first;
    void noop() {}

    Widget lesson(int? index) => LearnScreen(
      tuning: tuning,
      openLesson: index,
      onOpenTuner: noop,
      onOpenChords: noop,
      onOpenNeck: noop,
      onOpenQuiz: noop,
    );

    Widget neck({bool highlight = false, bool extended = false}) => NeckScreen(
      tuning: tuning,
      scale: commonScales.first,
      scaleRoot: tuning.openMidis.first + 12,
      highlightScale: highlight,
      extended: extended,
      onSelectScale: (_) {},
      onSelectRoot: (_) {},
      onToggleHighlight: (_) {},
    );

    final screen = switch (page) {
      'learn' => lesson(null),
      'learn-chord' => lesson(1),
      'learn-rhythm' => lesson(4),
      'learn-tabs' => lesson(6),
      'chords' => ChordsScreen(
        tuning: tuning,
        selected: commonChords.last,
        onSelect: (_) {},
        onOpenTuner: noop,
        scale: commonScales.first,
        onSelectScale: (_) {},
        onOpenNeckWithScale: noop,
      ),
      'ear' => const EarTrainingScreen(),
      'theory' => TheoryScreen(onContinue: () {}),
      'quiz' => const QuizScreen(),
      'metronome' => const MetronomeScreen(),
      'settings' => SettingsSheet(
        onLang: (lang) => setState(() => _lang = lang),
        onToggleTheme: () => setState(() => _lightMode = !_lightMode),
      ),
      'neck-scale' => neck(highlight: true),
      'neck24' => neck(extended: true),
      _ => neck(),
    };

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: screen,
        ),
      ),
    );
  }
}
