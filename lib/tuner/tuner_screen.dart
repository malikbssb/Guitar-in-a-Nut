import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../l10n/strings.dart';
import '../models/chords.dart';
import '../models/notes.dart';
import '../widgets/chord_diagram.dart';
import 'pitch_detector.dart';

/// How far the plucked note sits from what it should be.
class _Readout {
  final bool hasPitch;
  final String letter;
  final double distance; // semitones, negative means the note is flat
  final int arrows;

  const _Readout({
    required this.hasPitch,
    required this.letter,
    required this.distance,
    required this.arrows,
  });

  bool get inTune => hasPitch && distance.abs() < 0.04;
  bool get isFlat => distance < 0;
}

class TunerScreen extends StatefulWidget {
  final Tuning tuning;
  final int? stringIndex;
  final ChordShape? chord;
  final ValueChanged<int?> onPickString;
  final VoidCallback onOpenGuide;

  const TunerScreen({
    super.key,
    required this.tuning,
    required this.stringIndex,
    required this.chord,
    required this.onPickString,
    required this.onOpenGuide,
  });

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> {
  /// About 93 ms of audio at 44.1 kHz, so the detector runs ~10 times/s.
  static const int _chunkSamples = 4096;

  final AudioRecorder _recorder = AudioRecorder();
  final PitchDetector _detector = PitchDetector();
  final List<double> _buffer = <double>[];

  StreamSubscription<List<int>>? _subscription;

  bool _running = false;

  /// The status line is kept as a dictionary key so a language change can
  /// rewrite it without restarting the microphone.
  String _statusKey =
      'Enable your microphone, pluck a string and get to tuning!';
  Map<String, String> _statusArgs = const {};
  PitchReading _reading = PitchReading.silent;
  double? _exactMidi;

  @override
  void dispose() {
    _teardown();
    _recorder.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TunerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed =
        oldWidget.tuning != widget.tuning ||
        oldWidget.chord != widget.chord ||
        oldWidget.stringIndex != widget.stringIndex;
    if (changed) setState(() => _exactMidi = null);
  }

  Future<void> _start() async {
    if (_running) return;
    try {
      if (!await _recorder.hasPermission()) {
        setState(
          () => _statusKey =
              'Microphone blocked. Open the padlock in Chrome\'s address bar, '
              'allow the microphone, then press Start again.',
        );
        return;
      }
      final stream = await _recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 44100,
          numChannels: 1,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
        ),
      );
      _subscription = stream.listen(_onBytes);
      setState(() {
        _running = true;
        _reading = PitchReading.silent;
        _exactMidi = null;
        _statusArgs = const {};
        _statusKey = 'Listening - pluck one string and let it ring.';
      });
    } catch (error) {
      setState(() {
        _statusKey = 'The microphone did not start: {error}';
        _statusArgs = {'error': '$error'};
      });
    }
  }

  void _stop() {
    _teardown();
    if (mounted) setState(() => _running = false);
  }

  void _teardown() {
    _subscription?.cancel();
    _subscription = null;
    if (_running) _recorder.stop();
  }

  void _onBytes(List<int> bytes) {
    appendPcm16(bytes, _buffer);
    if (_buffer.length < _chunkSamples) return;
    if (_buffer.length > _chunkSamples * 2) {
      _buffer.removeRange(0, _buffer.length - _chunkSamples * 2);
    }

    final reading = _detector.analyze(_buffer);
    _buffer.clear();
    if (!mounted) return;

    setState(() {
      _reading = reading;
      if (reading.frequency > 0) {
        _exactMidi = 69 + 12 * (math.log(reading.frequency / 440) / math.ln2);
      }
    });
  }

  /// MIDI numbers that count as "right now": one string, or every note of the
  /// chosen chord.
  List<int> get _targets {
    if (widget.chord != null) {
      final classes = widget.chord!
          .soundingMidis(widget.tuning.openMidis)
          .map((midi) => midi % 12)
          .toSet();
      return [
        for (var midi = 24; midi < 100; midi++)
          if (classes.contains(midi % 12)) midi,
      ];
    }
    if (widget.stringIndex != null) {
      return [widget.tuning.openMidis[widget.stringIndex!]];
    }
    return widget.tuning.openMidis;
  }

  _Readout get _readout {
    final exact = _exactMidi;
    if (exact == null) {
      return const _Readout(
        hasPitch: false,
        letter: '-',
        distance: 0,
        arrows: 0,
      );
    }
    var best = _targets.first;
    for (final midi in _targets) {
      if ((midi - exact).abs() < (best - exact).abs()) best = midi;
    }
    final distance = exact - best;
    final arrows = distance.abs() < 0.04
        ? 0
        : math.min(4, math.max(1, distance.abs().ceil()));
    return _Readout(
      hasPitch: true,
      letter: PitchNames.of(exact.round()),
      distance: distance,
      arrows: arrows,
    );
  }

  String _advice(BuildContext context) {
    String t(String key, [Map<String, String> args = const {}]) =>
        L.f(context, key, args);

    if (!_running) return t(_statusKey, _statusArgs);
    if (_reading.level < 0.03) return t('Nothing loud enough: pluck a string.');
    if (_exactMidi == null) {
      return t('Too noisy to be sure - play louder, one string at a time.');
    }
    final readout = _readout;
    if (readout.inTune) {
      return widget.chord != null
          ? t('{chord} rings true. Next string?', {'chord': widget.chord!.name})
          : t('In tune. Move on to the next string.');
    }
    final howFar = t(readout.arrows == 1 ? 'a little' : 'a lot');
    return readout.isFlat
        ? t('Flat by {how}: tighten the string.', {'how': howFar})
        : t('Sharp by {how}: loosen the string.', {'how': howFar});
  }

  /// The six letters above the readout: open strings, or the chord's notes.
  List<String> get _stringLabels {
    final chord = widget.chord;
    if (chord == null) {
      return [for (final midi in widget.tuning.openMidis) PitchNames.of(midi)];
    }
    return [
      for (var i = 0; i < 6; i++)
        chord.frets[i] < 0
            ? 'x'
            : PitchNames.of(widget.tuning.openMidis[i] + chord.frets[i]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final readout = _readout;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ConstrainedBox(
              // The panel sits in the middle of the screen when there is room
              // for it, and scrolls instead when the window is short.
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: _panel(theme, scheme, readout),
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextButton(
                    onPressed: widget.onOpenGuide,
                    child: Text(
                      L.t(
                        context,
                        'Confused? Click here to get a quick guide to get you '
                        'started',
                      ),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _panel(ThemeData theme, ColorScheme scheme, _Readout readout) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 30),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(38),
      ),
      child: Column(
        children: [
          _StringRow(
            labels: _stringLabels,
            selectedIndex: widget.chord == null ? widget.stringIndex : null,
            onTap: (i) => widget.onPickString(i),
          ),
          const SizedBox(height: 8),
          Text(
            '(${widget.chord?.name ?? widget.tuning.short})',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 18),
          _Arrows(readout: readout),
          const SizedBox(height: 4),
          Text(
            readout.hasPitch
                ? L.f(context, '{hz} Hz - confidence {pct}%', {
                    'hz': _reading.frequency.toStringAsFixed(1),
                    'pct': '${(_reading.clarity * 100).round()}',
                  })
                : L.t(context, 'no pitch detected'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 210,
            child: FilledButton.icon(
              onPressed: _running ? _stop : _start,
              icon: Icon(_running ? Icons.stop : Icons.mic),
              label: Text(L.t(context, _running ? 'Stop' : 'Start')),
            ),
          ),
          const SizedBox(height: 14),
          Text(_advice(context), textAlign: TextAlign.center),
          if (widget.chord != null) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ChordDiagram(chord: widget.chord!, width: 84),
                const SizedBox(width: 14),
                TextButton.icon(
                  onPressed: () => widget.onPickString(null),
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(L.t(context, 'Back to single strings')),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StringRow extends StatelessWidget {
  final List<String> labels;
  final int? selectedIndex;
  final ValueChanged<int?> onTap;

  const _StringRow({
    required this.labels,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onTap(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: labels[i] == 'x'
                        ? theme.colorScheme.error
                        : (selectedIndex == i
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Chevrons whose count grows with the distance, pointing where the pitch has
/// to go.
class _Arrows extends StatelessWidget {
  final _Readout readout;

  const _Arrows({required this.readout});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = !readout.hasPitch
        ? scheme.onSurfaceVariant
        : readout.inTune
        ? const Color(0xFF3FC98A)
        : const Color(0xFFFF5C5C);
    final count = readout.arrows;
    final showNote = readout.hasPitch;

    Widget chevrons(bool pointRight) {
      if (count == 0) return const SizedBox(width: 30);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            Icon(
              pointRight
                  ? Icons.keyboard_arrow_right
                  : Icons.keyboard_arrow_left,
              size: 56,
              color: color,
            ),
        ],
      );
    }

    return SizedBox(
      height: 132,
      // Four chevrons next to a 108 pt letter is wider than a phone, so the
      // whole readout scales down instead of overflowing.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!readout.isFlat) chevrons(false) else const SizedBox(width: 30),
            SizedBox(
              width: 120,
              child: showNote
                  ? Text(
                      readout.letter,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 108,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    )
                  : Icon(Icons.music_note, size: 72, color: color),
            ),
            if (readout.isFlat) chevrons(true) else const SizedBox(width: 30),
          ],
        ),
      ),
    );
  }
}
