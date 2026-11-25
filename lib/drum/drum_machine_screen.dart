import 'package:flutter/material.dart';

import '../audio/click_voice.dart';
import '../audio/drum_engine.dart';
import '../l10n/strings.dart';
import 'drum_patterns.dart';

/// The drum machine: a bar of sixteenth notes drawn as a grid, one lane per
/// sample the metronome already ships. Tapping a cell puts a drum on that
/// step, and the loop keeps running while you do it.
class DrumMachineScreen extends StatefulWidget {
  const DrumMachineScreen({super.key});

  @override
  State<DrumMachineScreen> createState() => _DrumMachineScreenState();
}

class _DrumMachineScreenState extends State<DrumMachineScreen> {
  static const int _minBpm = 40;
  static const int _maxBpm = 200;

  int _bpm = 100;
  bool _playing = false;
  int _current = -1;

  /// Which steps each lane sounds on. The engine reads this while it books,
  /// so an edit lands on the next pass of the loop. The rock beat comes in
  /// with the page, so the first tap of Play is not silence.
  final Map<ClickVoice, Set<int>> _hits = {
    for (final lane in drumLanes)
      lane: {...drumPresets.first.hits[lane] ?? const <int>{}},
  };

  @override
  void dispose() {
    stopDrumLoop();
    super.dispose();
  }

  List<ClickVoice> _voicesAt(int step) => [
    for (final lane in drumLanes)
      if (_hits[lane]!.contains(step)) lane,
  ];

  void _start() {
    setState(() => _playing = true);
    startDrumLoop(
      bpm: _bpm.toDouble(),
      steps: drumSteps,
      voicesAt: _voicesAt,
      onStep: (step) {
        if (mounted) setState(() => _current = step);
      },
    );
  }

  void _stop() {
    stopDrumLoop();
    setState(() {
      _playing = false;
      _current = -1;
    });
  }

  void _setBpm(int bpm) {
    final next = bpm.clamp(_minBpm, _maxBpm);
    if (next == _bpm) return;
    setState(() => _bpm = next);
    setDrumTempo(next.toDouble());
  }

  void _toggle(ClickVoice lane, int step) {
    setState(() {
      final hits = _hits[lane]!;
      if (hits.contains(step)) {
        hits.remove(step);
      } else {
        hits.add(step);
      }
    });
  }

  void _load(DrumPattern pattern) {
    setState(() {
      for (final lane in drumLanes) {
        _hits[lane]!
          ..clear()
          ..addAll(pattern.hits[lane] ?? const <int>{});
      }
    });
  }

  void _clear() {
    setState(() {
      for (final lane in drumLanes) {
        _hits[lane]!.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            L.t(context, 'Drum machine'),
            style: theme.textTheme.titleMedium,
          ),
          Text(
            L.t(context, 'Tap a cell to put a drum on that step.'),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$_bpm',
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text('BPM', style: theme.textTheme.titleMedium),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: L.t(context, 'Slower'),
                      onPressed: () => _setBpm(_bpm - 5),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    IconButton(
                      tooltip: L.t(context, 'Faster'),
                      onPressed: () => _setBpm(_bpm + 5),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                Slider(
                  value: _bpm.toDouble(),
                  min: _minBpm.toDouble(),
                  max: _maxBpm.toDouble(),
                  divisions: _maxBpm - _minBpm,
                  label: '$_bpm',
                  onChanged: (value) => _setBpm(value.round()),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final preset in [60, 80, 100, 120, 160])
                      ChoiceChip(
                        label: Text('$preset'),
                        selected: _bpm == preset,
                        onSelected: (_) => _setBpm(preset),
                      ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _playing ? _stop : _start,
                      icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
                      label: Text(L.t(context, _playing ? 'Stop' : 'Play')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(L.t(context, 'Start from'), style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final pattern in drumPresets)
                ActionChip(
                  label: Text(L.t(context, pattern.name)),
                  onPressed: () => _load(pattern),
                ),
              ActionChip(label: Text(L.t(context, 'Clear')), onPressed: _clear),
            ],
          ),
          const SizedBox(height: 18),
          _Grid(hits: _hits, current: _current, onTapCell: _toggle),
          const SizedBox(height: 10),
          Text(
            L.t(context, 'Four cells to a beat, sixteen to a bar.'),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// The lanes down the left, the steps across, and the beat every fourth cell.
class _Grid extends StatelessWidget {
  /// Wide enough that even 'Semi-closed Hi-hat' keeps to one line.
  static const double _labelWidth = 120;
  static const double _cellHeight = 30;
  static const double _rowGap = 4;

  /// Below this a cell is too small for a thumb, so the steps scroll sideways
  /// instead of shrinking further. The lane names stay put on the left.
  static const double _minCellWidth = 40;

  final Map<ClickVoice, Set<int>> hits;
  final int current;
  final void Function(ClickVoice lane, int step) onTapCell;

  const _Grid({
    required this.hits,
    required this.current,
    required this.onTapCell,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final room = constraints.maxWidth - _labelWidth;
        final cell = (room / drumSteps) < _minCellWidth
            ? _minCellWidth
            : room / drumSteps;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                for (final lane in drumLanes)
                  SizedBox(
                    width: _labelWidth,
                    height: _cellHeight + _rowGap,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        L.t(context, lane.label),
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(
              width: room,
              height: drumLanes.length * (_cellHeight + _rowGap),
              child: SingleChildScrollView(
                key: const Key('drum-steps'),
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: [
                    for (final lane in drumLanes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: _rowGap),
                        child: Row(
                          children: [
                            for (var step = 0; step < drumSteps; step++)
                              SizedBox(
                                width: cell,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: 2,
                                    right: step % 4 == 3 ? 6 : 2,
                                  ),
                                  child: _Cell(
                                    key: Key('drum-${lane.name}-$step'),
                                    on: hits[lane]!.contains(step),
                                    beat: step % 4 == 0,
                                    playing: step == current,
                                    color: scheme.primary,
                                    dim: scheme.surfaceContainerHighest,
                                    onTap: () => onTapCell(lane, step),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  final bool on;
  final bool beat;
  final bool playing;
  final Color color;
  final Color dim;
  final VoidCallback onTap;

  const _Cell({
    super.key,
    required this.on,
    required this.beat,
    required this.playing,
    required this.color,
    required this.dim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        height: 30,
        decoration: BoxDecoration(
          // The beat cells keep their full colour and the three steps after
          // them fade back, so the eye reads the grid four cells at a time.
          color: on
              ? color
              : playing
              ? color.withValues(alpha: 0.22)
              : beat
              ? dim
              : dim.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: playing
                ? scheme.onSurface
                : color.withValues(alpha: on ? 0.5 : 0.16),
            width: playing ? 2 : 1,
          ),
        ),
      ),
    );
  }
}
