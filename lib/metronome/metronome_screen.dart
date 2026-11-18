import 'dart:async';

import 'package:flutter/material.dart';

import '../audio/click_voice.dart';
import '../audio/string_audio.dart';
import '../l10n/strings.dart';

/// The metronome: a tempo, a bar length, and whichever click the player
/// hears best. Beats are scheduled one by one rather than rendered as one
/// long clip, so changing the tempo mid-run takes effect on the next tick.
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

  Timer? _timer;
  bool _running = false;

  /// Beats played since Start, used to stop after the bars the player asked
  /// for.
  int _played = 0;

  /// Beat inside the bar that last sounded, for the dots.
  int _current = -1;

  int get _totalBeats => _bars == null ? 0 : _bars! * _beatsPerBar;

  /// One beat at the current tempo.
  Duration get _step => Duration(microseconds: (60e6 / _bpm).round());

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _running = true;
      _played = 0;
      _current = -1;
    });
    _tick();
    _timer = Timer.periodic(_step, (_) => _tick());
  }

  void _tick() {
    if (!_running) return;
    if (_bars != null && _played >= _totalBeats) {
      _stop();
      return;
    }
    final insideBar = _played % _beatsPerBar;
    playClick(_voice, accent: insideBar == 0);
    if (mounted) {
      setState(() {
        _current = insideBar;
        _played++;
      });
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
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
    // A running timer keeps its old spacing, so restart the clock instead of
    // waiting for the next tick to land late or early.
    if (_running) {
      _timer?.cancel();
      _timer = Timer.periodic(_step, (_) => _tick());
    }
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
                  onSelected: (_) => setState(() {
                    _beatsPerBar = beats;
                    _current = -1;
                    _played = 0;
                  }),
                ),
            ],
          ),
          Text(
            L.t(context, 'The first beat of the bar sounds louder.'),
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
                  onSelected: (_) => setState(() => _bars = bars),
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
                    playClick(voice, accent: true);
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
                onPressed: () => playClick(_voice, accent: true),
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

/// One light per beat, the one that just sounded lit up.
class _BeatDots extends StatelessWidget {
  final int beats;
  final int current;
  final Color color;
  final Color dim;

  const _BeatDots({
    required this.beats,
    required this.current,
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
              width: beat == 0 ? 26 : 20,
              height: beat == 0 ? 26 : 20,
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
