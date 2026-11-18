import 'package:flutter/material.dart';

import '../audio/string_audio.dart';
import '../l10n/strings.dart';
import '../models/chords.dart';
import '../models/notes.dart';
import '../models/scales.dart';
import '../widgets/chord_diagram.dart';

/// The shapes and patterns worth memorising, sorted by the key they live in.
/// Picking a chord also feeds the tuner, which then shows the note of every
/// string for that chord.
class ChordsScreen extends StatefulWidget {
  final Tuning tuning;
  final ChordShape? selected;
  final ValueChanged<ChordShape> onSelect;
  final VoidCallback onOpenTuner;

  /// Shared with the neck page so a scale picked here can light up there.
  final GuitarScale? scale;
  final ValueChanged<GuitarScale> onSelectScale;
  final VoidCallback onOpenNeckWithScale;

  const ChordsScreen({
    super.key,
    required this.tuning,
    required this.selected,
    required this.onSelect,
    required this.onOpenTuner,
    required this.scale,
    required this.onSelectScale,
    required this.onOpenNeckWithScale,
  });

  @override
  State<ChordsScreen> createState() => _ChordsScreenState();
}

class _ChordsScreenState extends State<ChordsScreen> {
  /// The scale demos start an octave above the lowest open string, so the
  /// pattern stays inside the range the rest of the app talks about.
  int get _rootMidi => widget.tuning.openMidis.first + 12;

  void _pickChord(ChordShape chord) {
    playChord(chord.soundingMidis(widget.tuning.openMidis));
    widget.onSelect(chord);
  }

  void _pickScale(GuitarScale scale) {
    widget.onSelectScale(scale);
    _play(scale);
  }

  void _play(GuitarScale scale, {int octavesUp = 0}) =>
      playRun(scale.midisFrom(_rootMidi + octave * octavesUp));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = widget.scale;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            L.t(context, 'Chords, sorted by key'),
            style: theme.textTheme.titleMedium,
          ),
          Text(
            L.t(
              context,
              'A key is a family of notes, and only a handful of chords sit '
              'inside it. The word above each shape is its degree: I is the '
              'home chord, V is the one pulling back to it. Numbers are '
              'fingers, o means play the open string, x means keep it silent.',
            ),
            style: theme.textTheme.bodySmall,
          ),
          for (final group in chordGroups) ...[
            const SizedBox(height: 24),
            Text(L.t(context, group.name), style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(group.blurb, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  for (final entry in group.chords)
                    _ChordTile(
                      entry: entry,
                      selected: widget.selected == entry.chord,
                      onTap: () => _pickChord(entry.chord),
                    ),
                ],
              ),
            ),
          ],
          if (widget.selected != null) ...[
            const SizedBox(height: 16),
            _ChordDetail(
              chord: widget.selected!,
              tuning: widget.tuning,
              onOpenTuner: widget.onOpenTuner,
            ),
          ],
          const SizedBox(height: 28),
          Text(L.t(context, 'Scales'), style: theme.textTheme.titleMedium),
          Text(
            L.t(
              context,
              'A scale is a set of notes you can play over a chord or a whole '
              'song. What matters on the neck is the gap in frets between two '
              'degrees. Tap a pattern to hear it.',
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(34),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final shape in commonScales)
                      ChoiceChip(
                        label: Text(L.t(context, shape.name)),
                        selected: scale == shape,
                        onSelected: (_) => _pickScale(shape),
                      ),
                  ],
                ),
                if (scale != null) ...[
                  const SizedBox(height: 14),
                  Text(scale.blurb, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 14),
                  Text(
                    L.f(context, 'Frets between the degrees: {p}', {
                      'p': scale.fretPattern,
                    }),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    L.f(context, '{name} on {root}: {notes}', {
                      'name': L.t(context, scale.name),
                      'root': PitchNames.withOctave(_rootMidi),
                      'notes': scale.spelledFrom(_rootMidi),
                    }),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => _play(scale),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(L.t(context, 'Hear the scale')),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _play(scale, octavesUp: 1),
                        icon: const Icon(Icons.expand),
                        label: Text(L.t(context, 'One octave higher')),
                      ),
                      OutlinedButton.icon(
                        onPressed: widget.onOpenNeckWithScale,
                        icon: const Icon(Icons.grid_on),
                        label: Text(L.t(context, 'Light it up on the neck')),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChordTile extends StatelessWidget {
  final KeyChord entry;
  final bool selected;
  final VoidCallback onTap;

  const _ChordTile({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.14)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.degree,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            ChordDiagram(chord: entry.chord, width: 78),
          ],
        ),
      ),
    );
  }
}

class _ChordDetail extends StatelessWidget {
  final ChordShape chord;
  final Tuning tuning;
  final VoidCallback onOpenTuner;

  const _ChordDetail({
    required this.chord,
    required this.tuning,
    required this.onOpenTuner,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final midis = chord.soundingMidis(tuning.openMidis);
    final keys = groupsHolding(chord.name);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${chord.name} - ${chord.spelledNotes()}',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(chord.blurb),
          const SizedBox(height: 6),
          Text(
            L.f(context, 'Frets, string 6 to 1: {line}', {
              'line': chord.fretLine,
            }),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            L.f(context, 'On {tuning}, those strings play {notes}.', {
              'tuning': L.t(context, tuning.short),
              'notes': chord
                  .soundingMidis(tuning.openMidis)
                  .map(PitchNames.withOctave)
                  .join(', '),
            }),
            style: theme.textTheme.bodySmall,
          ),
          for (final group in keys)
            Text(
              L.f(context, 'In {group} it is the {degree}.', {
                'group': L.t(context, group.name),
                'degree': group.chords
                    .firstWhere((entry) => entry.chord.name == chord.name)
                    .degree,
              }),
              style: theme.textTheme.bodySmall,
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => playChord(midis),
                icon: const Icon(Icons.play_arrow),
                label: Text(L.t(context, 'Hear the chord')),
              ),
              OutlinedButton.icon(
                onPressed: () => playRun(midis),
                icon: const Icon(Icons.graphic_eq),
                label: Text(L.t(context, 'One note at a time')),
              ),
              FilledButton.tonalIcon(
                onPressed: onOpenTuner,
                icon: const Icon(Icons.mic),
                label: Text(L.t(context, 'Check it on the tuner')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
