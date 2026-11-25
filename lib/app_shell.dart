import 'package:flutter/material.dart';

import 'chords/chords_screen.dart';
import 'drum/drum_machine_screen.dart';
import 'l10n/strings.dart';
import 'learn/learn_screen.dart';
import 'metronome/metronome_screen.dart';
import 'models/chords.dart';
import 'models/notes.dart';
import 'models/scales.dart';
import 'neck/neck_screen.dart';
import 'quiz/ear_training_screen.dart';
import 'quiz/quiz_data.dart';
import 'quiz/quiz_screen.dart';
import 'tuner/tuner_screen.dart';
import 'widgets/nav_rail.dart';
import 'widgets/settings_fab.dart';
import 'widgets/theme_fab.dart';
import 'widgets/wood_logo.dart';

/// Frame of the application: wooden logo on the top left, the tuning menu on
/// the right, and a rail on the left that widens when you tap it.
class AppShell extends StatefulWidget {
  final bool lightMode;
  final VoidCallback onToggleTheme;
  final ValueChanged<AppLang> onLang;

  const AppShell({
    super.key,
    required this.lightMode,
    required this.onToggleTheme,
    required this.onLang,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// null means the tuner, which is also the home screen.
  AppSection? _section;
  bool _railOpen = false;

  /// The lesson LEARN should open straight away, set by the tuner guide.
  int? _learnLesson;

  Tuning _tuning = tunings.first;
  int? _stringIndex;
  ChordShape? _chord;

  /// The scale the CHORDS page demos and the NECK page can light up.
  GuitarScale _scale = commonScales.first;
  int _scaleRoot = tunings.first.openMidis.first + 12;
  bool _highlightScale = false;

  void _go(AppSection? section, {int? lesson}) => setState(() {
    _section = section;
    _learnLesson = section == AppSection.learn ? lesson : null;
    // On a phone the opened rail covers most of the content, so it folds
    // back as soon as a choice is made.
    if (MediaQuery.sizeOf(context).width < 640) _railOpen = false;
  });

  String _tagline(BuildContext context) => switch (_section) {
    null => L.t(
      context,
      'Enable your microphone, pluck a string and get to tuning!',
    ),
    AppSection.chords => L.f(
      context,
      '{n} shapes, sorted by the key they fit '
      'in.',
      {'n': '${allChords.length}'},
    ),
    AppSection.neck => L.t(context, 'Every note of the neck, one tap away.'),
    AppSection.learn => L.t(
      context,
      'Short pages that answer the questions beginners ask.',
    ),
    AppSection.quiz => L.f(
      context,
      'Questions drawn from a pool of {n}. Pick the level and the length.',
      {'n': '${quizPool.length}'},
    ),
    AppSection.earTraining => L.t(
      context,
      'No names on screen. Listen, guess, then read why.',
    ),
    AppSection.metronome => L.t(
      context,
      'Set the speed, count the bar, pick the click.',
    ),
    AppSection.drumMachine => L.t(
      context,
      'Build a bar of drums, one step at a time.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: ThemeFab(
        lightMode: widget.lightMode,
        onPressed: widget.onToggleTheme,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 640;
                    final logo = WoodLogo(
                      onTap: () => _go(null),
                      height: compact ? 40 : 56,
                    );
                    final menu = _TuningMenu(
                      tuning: _tuning,
                      maxLabelWidth: compact ? 110 : 190,
                      onChanged: (tuning) => setState(() {
                        _tuning = tuning;
                        _stringIndex = null;
                      }),
                    );
                    final tagline = Text(
                      _tagline(context),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    );

                    return Container(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.12,
                            ),
                          ),
                        ),
                      ),
                      // A phone cannot fit logo, tagline and tuning menu side by
                      // side, so the tagline drops under them.
                      child: compact
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    logo,
                                    const SizedBox(width: 10),
                                    Expanded(child: menu),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                tagline,
                              ],
                            )
                          : Row(
                              children: [
                                logo,
                                const SizedBox(width: 20),
                                Expanded(child: tagline),
                                const SizedBox(width: 16),
                                menu,
                              ],
                            ),
                    );
                  },
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final rail = NavRail(
                        expanded: _railOpen,
                        current: _section,
                        onSelect: _go,
                        onToggle: () => setState(() => _railOpen = !_railOpen),
                      );
                      final sections = Center(
                        // Sections keep a readable column instead of stretching
                        // across a wide desktop window.
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 980),
                          child: IndexedStack(
                            index: _section == null ? 0 : _section!.index + 1,
                            children: [
                              TunerScreen(
                                tuning: _tuning,
                                stringIndex: _stringIndex,
                                chord: _chord,
                                onPickString: (index) => setState(() {
                                  _chord = null;
                                  _stringIndex = index;
                                }),
                                onOpenGuide: () =>
                                    _go(AppSection.learn, lesson: 0),
                              ),
                              ChordsScreen(
                                tuning: _tuning,
                                selected: _chord,
                                onSelect: (chord) =>
                                    setState(() => _chord = chord),
                                onOpenTuner: () => _go(null),
                                scale: _scale,
                                onSelectScale: (scale) =>
                                    setState(() => _scale = scale),
                                onOpenNeckWithScale: () => setState(() {
                                  _highlightScale = true;
                                  _go(AppSection.neck);
                                }),
                              ),
                              NeckScreen(
                                tuning: _tuning,
                                scale: _scale,
                                scaleRoot: _scaleRoot,
                                highlightScale: _highlightScale,
                                onSelectScale: (scale) =>
                                    setState(() => _scale = scale),
                                onSelectRoot: (midi) =>
                                    setState(() => _scaleRoot = midi),
                                onToggleHighlight: (on) =>
                                    setState(() => _highlightScale = on),
                              ),
                              LearnScreen(
                                tuning: _tuning,
                                openLesson: _learnLesson,
                                onOpenTuner: () => _go(null),
                                onOpenChords: () => _go(AppSection.chords),
                                onOpenNeck: () => _go(AppSection.neck),
                                onOpenQuiz: () => _go(AppSection.quiz),
                                onOpenEarTraining: () =>
                                    _go(AppSection.earTraining),
                                onOpenMetronome: () =>
                                    _go(AppSection.metronome),
                              ),
                              const QuizScreen(),
                              const EarTrainingScreen(),
                              const MetronomeScreen(),
                              const DrumMachineScreen(),
                            ],
                          ),
                        ),
                      );

                      // On a phone the opened menu floats over the page: pushing it
                      // aside would leave a few usable pixels for the content.
                      if (constraints.maxWidth < 640) {
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 62),
                                child: sections,
                              ),
                            ),
                            if (_railOpen)
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () =>
                                      setState(() => _railOpen = false),
                                  child: ColoredBox(
                                    color: Colors.black.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            Positioned.directional(
                              textDirection: Directionality.of(context),
                              start: 0,
                              top: 0,
                              bottom: 0,
                              child: rail,
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          rail,
                          Expanded(child: sections),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: SettingsFab(
              onLang: widget.onLang,
              onToggleTheme: widget.onToggleTheme,
            ),
          ),
        ],
      ),
    );
  }
}

class _TuningMenu extends StatelessWidget {
  final Tuning tuning;
  final ValueChanged<Tuning> onChanged;

  /// Long names are truncated at this width so the pill never pushes the top
  /// bar off a narrow screen.
  final double maxLabelWidth;

  const _TuningMenu({
    required this.tuning,
    required this.onChanged,
    this.maxLabelWidth = 190,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: tuning.name,
          isDense: true,
          borderRadius: BorderRadius.circular(14),
          dropdownColor: theme.colorScheme.surfaceContainerHighest,
          icon: Icon(Icons.expand_more, color: theme.colorScheme.onSurface),
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
          // Long names such as "Standard (E A D G B E)" are truncated so the
          // pill never pushes the top bar off a narrow screen.
          items: [
            for (final option in tunings)
              DropdownMenuItem(
                value: option.name,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxLabelWidth),
                  child: Text(
                    L.t(context, option.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
          onChanged: (name) =>
              onChanged(tunings.firstWhere((option) => option.name == name)),
        ),
      ),
    );
  }
}
