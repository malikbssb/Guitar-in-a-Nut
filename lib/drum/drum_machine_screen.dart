import 'package:flutter/material.dart';

import '../audio/click_voice.dart';
import '../audio/drum_engine.dart';
import '../l10n/strings.dart';
import 'drum_patterns.dart';

/// The drum machine: bars of sixteenth notes, one lane per sample the
/// metronome already ships. Tapping a cell puts a drum on that step, the grid
/// shows the bar being written, and Play runs every bar in order on a loop.
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

  /// The song, in the order Play runs it. The rock beat opens it, so the first
  /// tap of Play is not silence.
  final List<DrumBar> _bars = [DrumBar.from(drumPresets.first)];

  /// Which bar the grid is showing and tapping edits.
  int _writing = 0;

  /// The playhead as an index into the whole song, so the strip and the grid
  /// can both light from one number. Minus one once stopped.
  int _cursor = -1;

  int get _sounding => _cursor < 0 ? -1 : _cursor ~/ drumSteps;

  int get _stepInBar => _cursor < 0 ? -1 : _cursor % drumSteps;

  @override
  void dispose() {
    stopDrumLoop();
    super.dispose();
  }

  /// The engine hands over a step of the song, not of a bar, and asks again
  /// for each booking, so the bars may grow and shrink while it runs.
  List<ClickVoice> _voicesAt(int step) {
    final bar = step ~/ drumSteps;
    if (bar >= _bars.length) return const [];
    return _bars[bar].voicesOn(step % drumSteps);
  }

  void _start() {
    setState(() => _playing = true);
    startDrumLoop(
      bpm: _bpm.toDouble(),
      stepCount: () => _bars.length * drumSteps,
      voicesAt: _voicesAt,
      onStep: (step) {
        if (mounted) setState(() => _cursor = step);
      },
    );
  }

  void _stop() {
    stopDrumLoop();
    setState(() {
      _playing = false;
      _cursor = -1;
    });
  }

  void _setBpm(int bpm) {
    final next = bpm.clamp(_minBpm, _maxBpm);
    if (next == _bpm) return;
    setState(() => _bpm = next);
    setDrumTempo(next.toDouble());
  }

  void _toggle(ClickVoice lane, int step) {
    setState(() => _bars[_writing].toggle(lane, step));
  }

  void _load(DrumPattern pattern) {
    setState(() => _bars[_writing] = DrumBar.from(pattern));
  }

  void _clear() {
    setState(() => _bars[_writing].clear());
  }

  /// A fresh bar lands after the one being written, not at the end of the
  /// song, so bars can be inserted into the middle of a running order.
  void _addBar({DrumBar? copy}) {
    setState(() {
      _bars.insert(_writing + 1, copy ?? DrumBar({}));
      _writing += 1;
    });
  }

  void _deleteBar() {
    if (_bars.length == 1) return;
    setState(() {
      _bars.removeAt(_writing);
      if (_writing >= _bars.length) _writing = _bars.length - 1;
      // The song is shorter than the pass the engine booked, so the playhead
      // is parked until the next one arrives.
      _cursor = -1;
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
          Row(
            children: [
              Expanded(
                child: Text(
                  L.t(context, 'Bars'),
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text('${_bars.length}', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 6),
          _BarStrip(
            bars: _bars,
            writing: _writing,
            sounding: _sounding,
            stepInBar: _stepInBar,
            onSelect: (index) => setState(() => _writing = index),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                key: const Key('add-bar'),
                avatar: const Icon(Icons.add),
                label: Text(L.t(context, 'Add bar')),
                onPressed: () => _addBar(),
              ),
              ActionChip(
                key: const Key('copy-bar'),
                avatar: const Icon(Icons.copy_all_outlined),
                label: Text(L.t(context, 'Copy bar')),
                onPressed: () => _addBar(copy: _bars[_writing].copied()),
              ),
              if (_bars.length > 1)
                ActionChip(
                  key: const Key('delete-bar'),
                  avatar: const Icon(Icons.delete_outline),
                  label: Text(L.t(context, 'Delete bar')),
                  onPressed: _deleteBar,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            L.t(
              context,
              'Play runs the bars in order, then loops back. A preset or Clear '
              'only touches the bar being written.',
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
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
          _Grid(
            hits: _bars[_writing].hits,
            current: _sounding == _writing ? _stepInBar : -1,
            onTapCell: _toggle,
          ),
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

/// The song as a row of cards: the bar being written is outlined, and the one
/// the playhead has reached lights up step by step.
class _BarStrip extends StatelessWidget {
  static const double _cellWidth = 5;
  static const double _cellGap = 2;

  final List<DrumBar> bars;
  final int writing;
  final int sounding;
  final int stepInBar;
  final ValueChanged<int> onSelect;

  const _BarStrip({
    required this.bars,
    required this.writing,
    required this.sounding,
    required this.stepInBar,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('drum-bars'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < bars.length; index++)
            Padding(
              padding: EdgeInsets.only(right: index + 1 == bars.length ? 0 : 8),
              child: _BarCard(
                key: Key('bar-card-$index'),
                index: index,
                bar: bars[index],
                title: '${L.t(context, 'Bar')} ${index + 1}',
                selected: index == writing,
                sounding: index == sounding,
                current: index == sounding ? stepInBar : -1,
                onTap: () => onSelect(index),
              ),
            ),
        ],
      ),
    );
  }
}

/// A bar at a glance: the map under the number is one cell per step, and a
/// cell is as bright as there are drums on that step.
class _BarCard extends StatelessWidget {
  static const double _cell = _BarStrip._cellWidth;
  static const double _gap = _BarStrip._cellGap;

  /// Sixteen cells at five points with a two-point gap between them.
  static double get _mapWidth => drumSteps * _cell + (drumSteps - 1) * _gap;

  final int index;
  final DrumBar bar;
  final String title;
  final bool selected;
  final bool sounding;
  final int current;
  final VoidCallback onTap;

  const _BarCard({
    super.key,
    required this.index,
    required this.bar,
    required this.title,
    required this.selected,
    required this.sounding,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.12)
              : scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: sounding
                ? scheme.onSurface
                : scheme.primary.withValues(alpha: selected ? 0.8 : 0.18),
            width: sounding ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? scheme.primary : null,
                fontWeight: selected ? FontWeight.w700 : null,
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: _mapWidth,
              child: Row(
                spacing: _gap,
                children: [
                  for (var step = 0; step < drumSteps; step++)
                    Container(
                      key: Key('bar-$index-$step'),
                      width: _cell,
                      height: step % 4 == 0 ? 13 : 9,
                      decoration: BoxDecoration(
                        color: bar.soundsOn(step) == 0
                            ? scheme.onSurface.withValues(alpha: 0.08)
                            : scheme.primary.withValues(
                                alpha: switch (bar.soundsOn(step)) {
                                  1 => 0.45,
                                  2 => 0.7,
                                  _ => 1,
                                },
                              ),
                        borderRadius: BorderRadius.circular(2),
                        // The step the song is on, marked without changing the
                        // width of the map.
                        border: step == current
                            ? Border.all(color: scheme.onSurface, width: 1.5)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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
