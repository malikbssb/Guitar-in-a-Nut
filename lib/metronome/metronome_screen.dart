import 'package:flutter/material.dart';

import '../audio/click_engine.dart';
import '../audio/click_voice.dart';
import '../l10n/strings.dart';

/// The metronome: a tempo, a bar length, and whichever click the player
/// hears best. The beats are booked by [click_engine], which runs them on the
/// audio clock so changing the tempo takes effect on the next beat without
/// dragging the one after it.
class MetronomeScreen extends StatefulWidget {
  const MetronomeScreen({super.key});

  @override
  State<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends State<MetronomeScreen> {
  static const int _minBpm = 40;
  static const int _maxBpm = 240;
  static const List<int> _beats = [2, 3, 4, 5, 6, 7, 12];

  /// Bars to play before stopping; null runs until the player says so.
  static const List<int?> _runs = [1, 2, 4, 8, null];

  int _bpm = 90;
  int _beatsPerBar = 4;
  int? _bars;
  ClickVoice _voice = ClickVoice.stick;
  bool _stress = true;

  bool _running = false;

  /// Beat inside the bar that last sounded, for the dots.
  int _current = -1;

  @override
  void dispose() {
    stopClickLoop();
    super.dispose();
  }

  void _start() {
    setState(() {
      _running = true;
      _current = -1;
    });
    startClickLoop(
      bpm: _bpm.toDouble(),
      beatsPerBar: _beatsPerBar,
      totalBeats: _bars == null ? null : _bars! * _beatsPerBar,
      voice: _voice,
      stressFirstBeat: _stress,
      onBeat: (beat) {
        if (mounted) setState(() => _current = beat % _beatsPerBar);
      },
      onEnd: _finished,
    );
  }

  /// The engine ran out of bars, so the button goes back to Start.
  void _finished() {
    if (!mounted) return;
    setState(() {
      _running = false;
      _current = -1;
    });
  }

  void _stop() {
    stopClickLoop();
    if (mounted) {
      setState(() {
        _running = false;
        _current = -1;
      });
    }
  }

  void _setBpm(int bpm) {
    final next = bpm.clamp(_minBpm, _maxBpm);
    if (next == _bpm) return;
    setState(() => _bpm = next);
    setClickTempo(next.toDouble());
  }

  /// The bar length and the run are counted from beat one, so the only honest
  /// way to change them mid-run is to start the count again.
  void _restartIfRunning() {
    if (!_running) return;
    stopClickLoop();
    _start();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(L.t(context, 'Metronome'), style: theme.textTheme.titleMedium),
          Text(
            L.t(context, 'Set the speed, count the bar, pick the click.'),
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
                  ],
                ),
                const SizedBox(height: 20),
                _BeatDots(
                  beats: _beatsPerBar,
                  current: _current,
                  stress: _stress,
                  color: scheme.primary,
                  dim: scheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 220,
                  child: FilledButton.icon(
                    onPressed: _running ? _stop : _start,
                    icon: Icon(_running ? Icons.stop : Icons.play_arrow),
                    label: Text(L.t(context, _running ? 'Stop' : 'Start')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            L.t(context, 'Beats per bar'),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final beats in _beats)
                ChoiceChip(
                  label: Text('$beats'),
                  selected: _beatsPerBar == beats,
                  onSelected: (_) {
                    setState(() {
                      _beatsPerBar = beats;
                      _current = -1;
                    });
                    _restartIfRunning();
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  L.t(context, 'Stress the first beat'),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(width: 14),
                Switch(
                  value: _stress,
                  onChanged: (on) {
                    setState(() => _stress = on);
                    setClickStress(on);
                  },
                ),
              ],
            ),
          ),
          Text(
            L.t(
              context,
              _stress
                  ? 'Beat one sounds louder and a touch higher, so the bar '
                        'counts itself.'
                  : 'Every beat sounds the same.',
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          Text(
            L.t(context, 'How many bars?'),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final bars in _runs)
                ChoiceChip(
                  label: Text(
                    bars == null
                        ? L.t(context, 'Forever')
                        : L.f(context, bars == 1 ? '{n} bar' : '{n} bars', {
                            'n': '$bars',
                          }),
                  ),
                  selected: _bars == bars,
                  onSelected: (_) {
                    setState(() => _bars = bars);
                    _restartIfRunning();
                  },
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(L.t(context, 'Click sound'), style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final voice in ClickVoice.values)
                ChoiceChip(
                  label: Text(L.t(context, voice.label)),
                  selected: _voice == voice,
                  onSelected: (_) {
                    setState(() => _voice = voice);
                    setClickVoice(voice);
                    previewClick(voice);
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  L.t(context, _voice.blurb),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => previewClick(_voice),
                icon: const Icon(Icons.volume_up),
                label: Text(L.t(context, 'Hear this sound')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One light per beat, the one that just sounded lit up. With the stress on,
/// beat one is the bigger dot, the same way it is the louder hit.
class _BeatDots extends StatelessWidget {
  final int beats;
  final int current;
  final bool stress;
  final Color color;
  final Color dim;

  const _BeatDots({
    required this.beats,
    required this.current,
    required this.stress,
    required this.color,
    required this.dim,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var beat = 0; beat < beats; beat++)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              width: beat == 0 && stress ? 26 : 20,
              height: beat == 0 && stress ? 26 : 20,
              decoration: BoxDecoration(
                color: beat == current ? color : dim,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.35),
                  width: 1.4,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
