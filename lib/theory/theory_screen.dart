import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/notes.dart';

/// Beginner page: the four questions a first visitor actually asks, each one
/// answered with what to do rather than with vocabulary.
class TheoryScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const TheoryScreen({super.key, required this.onContinue});

  @override
  State<TheoryScreen> createState() => _TheoryScreenState();
}

class _TheoryScreenState extends State<TheoryScreen> {
  /// C3 is low enough to stay comfortable on the neck but high enough to
  /// avoid clashing with the bass strings.
  static const int _baseMidi = 48;

  int _degree = 0;

  int get _midi => _baseMidi + _degree;

  String _up(int semitones) => PitchNames.of(_midi + semitones);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String t(String key) => L.t(context, key);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            t(
              'Four questions, in order. Answer them once and the rest of the '
              'app is only practice.',
            ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _Question(
            number: 1,
            title: t('How do I tune?'),
            children: [
              _Bullet(
                t(
                  'Tap the wooden logo in the top left. That is the tuner, and '
                  'it is always one tap away.',
                ),
              ),
              _Bullet(
                t('Press Start and let the browser use your microphone.'),
              ),
              _Bullet(
                t(
                  'Pluck one string, let it ring, and wait for a note name to '
                  'appear.',
                ),
              ),
              _Bullet(
                t(
                  'Turn the peg until the needle sits dead centre. Always '
                  'arrive from below: slip it past the note, then tune back '
                  'up, so the string settles instead of sliding flat again.',
                ),
              ),
              _Bullet(
                t(
                  'Work through the six strings, then check them a second '
                  'time. Tuning one string pulls on the others.',
                ),
              ),
            ],
          ),
          _Question(
            number: 2,
            title: t('Which tuning should I use?'),
            children: [
              _Bullet(
                t('Standard, from the thick string down to the thin one:'),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final midi in tunings.first.openMidis)
                    Chip(
                      label: Text(PitchNames.of(midi)),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              _Bullet(
                t(
                  'The menu in the top right holds the other tunings. Leave it '
                  'on standard while you learn.',
                ),
              ),
            ],
          ),
          _Question(
            number: 3,
            title: t('Why that one?'),
            children: [
              _Bullet(
                t(
                  'Almost every chord shape, tutorial and chord chart in the '
                  'world is written in it, so anything you learn carries over.',
                ),
              ),
              _Bullet(
                t(
                  'It spaces the open strings so the low E gives you a fat '
                  'bass note for riffs and the thin E gives you a singing top '
                  'note.',
                ),
              ),
              _Bullet(
                t(
                  'The other tunings exist for one specific sound each. They '
                  'are worth trying once your hands know the fretboard.',
                ),
              ),
            ],
          ),
          _Question(
            number: 4,
            title: t('How many notes are there?'),
            children: [
              _Bullet(
                t(
                  'Twelve, and only twelve. After the last one the list starts '
                  'again at the same name, one octave higher.',
                ),
              ),
              _Bullet(
                t(
                  'A # means one fret up, so the shape of the list never '
                  'changes wherever you start.',
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < noteNames.length; i++)
                    ChoiceChip(
                      label: Text(noteNames[i]),
                      selected: _degree == i,
                      onSelected: (_) => setState(() => _degree = i),
                    ),
                ],
              ),
              _Bullet(
                L.f(
                  context,
                  'Pick one. From {a}: one fret up is {b}, two '
                  'frets up is {c}, and twelve frets up is {d} again - '
                  'exactly double the frequency, from {e} Hz to {f} Hz. That '
                  'is why the 12th fret matters so much.',
                  {
                    'a': noteNames[_degree],
                    'b': _up(halfStep),
                    'c': _up(wholeStep),
                    'd': PitchNames.withOctave(_midi + octave),
                    'e': PitchNames.frequencyOf(_midi).toStringAsFixed(1),
                    'f': PitchNames.frequencyOf(_midi + octave)
                        .toStringAsFixed(1),
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            child: SizedBox(
              width: 340,
              child: FilledButton.icon(
                onPressed: widget.onContinue,
                icon: const Icon(Icons.build),
                label: Text(t('Now show me the tools')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One numbered question and the steps that answer it.
class _Question extends StatelessWidget {
  final int number;
  final String title;
  final List<Widget> children;

  const _Question({
    required this.number,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final child in children)
            Padding(padding: const EdgeInsets.only(bottom: 6), child: child),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('•  ', style: theme.textTheme.bodyMedium),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
