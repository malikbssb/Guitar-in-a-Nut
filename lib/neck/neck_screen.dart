import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../audio/string_audio.dart';
import '../l10n/strings.dart';
import '../models/notes.dart';
import '../models/scales.dart';

class _Cell {
  final int stringIndex; // 0 = 6th string, the lowest
  final int fret; // 0 = open string

  const _Cell(this.stringIndex, this.fret);
}

const double _labelWidth = 46;
const double _rowHeight = 40;

/// Strip above and below the board holding the fret numbers.
const double _numbersHeight = 20;

/// Smallest width a fret column gets before the board starts scrolling
/// sideways. Without it, twenty-four frets on a phone are unreadable.
const double _minCellWidth = 34;

/// Frets carrying a single inlay dot, and the two that carry a pair.
const Set<int> _singleDots = {3, 5, 7, 9, 15, 17, 19, 21};
const Set<int> _doubleDots = {12, 24};

/// Tappable map of the neck. The lowest string sits at the bottom, the way
/// the guitar looks when you hold it, and the scale switch paints one shape
/// over the neck.
class NeckScreen extends StatefulWidget {
  final Tuning tuning;

  /// Shared with the CHORDS page: the same scale is selected in both places.
  final GuitarScale scale;
  final int scaleRoot;
  final bool highlightScale;
  final ValueChanged<GuitarScale> onSelectScale;
  final ValueChanged<int> onSelectRoot;
  final ValueChanged<bool> onToggleHighlight;

  /// Whether the board starts out reaching all 24 frets.
  final bool extended;

  const NeckScreen({
    super.key,
    required this.tuning,
    required this.scale,
    required this.scaleRoot,
    required this.highlightScale,
    required this.onSelectScale,
    required this.onSelectRoot,
    required this.onToggleHighlight,
    this.extended = false,
  });

  @override
  State<NeckScreen> createState() => _NeckScreenState();
}

class _NeckScreenState extends State<NeckScreen> {
  _Cell? _cell;
  bool _showNotes = true;
  bool _showDots = true;

  /// Off shows the twelve frets a beginner needs, on reaches the whole neck.
  late bool _extended;

  @override
  void initState() {
    super.initState();
    _extended = widget.extended;
  }

  int get _fretsShown => _extended ? 24 : 12;

  int get _midi => widget.tuning.openMidis[_cell!.stringIndex] + _cell!.fret;

  /// Pitch classes of the selected scale, so the neck can light them up
  /// whatever string the visitor is tuning to.
  Set<int> get _scaleClasses => {
    for (final interval in widget.scale.intervals)
      (widget.scaleRoot + interval) % 12,
  };

  void _select(_Cell cell) {
    playNote(widget.tuning.openMidis[cell.stringIndex] + cell.fret);
    setState(() => _cell = cell);
  }

  /// Roots stay inside the octave the rest of the app demos scales in, so
  /// tapping twelve chips in a row never walks the highlight off the neck.
  int _rootAt(int pitch) {
    final base = widget.tuning.openMidis.first + octave;
    return base + ((pitch - base % 12 + 12) % 12);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                L.f(context, '{short} up to fret {n}', {
                  'short': L.t(context, widget.tuning.short),
                  'n': '$_fretsShown',
                }),
                style: theme.textTheme.titleMedium,
              ),
              Text(
                L.t(context, 'note names'),
                style: theme.textTheme.bodySmall,
              ),
              Switch(
                key: const Key('notes-switch'),
                value: _showNotes,
                onChanged: (v) => setState(() => _showNotes = v),
              ),
              Text(L.t(context, '24 frets'), style: theme.textTheme.bodySmall),
              Switch(
                key: const Key('frets-switch'),
                value: _extended,
                onChanged: (v) => setState(() {
                  _extended = v;
                  // A fret past the shortened neck would fall off the board.
                  if (v == false && (_cell?.fret ?? 0) > 12) {
                    _cell = null;
                  }
                }),
              ),
              Text(
                L.t(context, 'inlay dots'),
                style: theme.textTheme.bodySmall,
              ),
              Switch(
                key: const Key('dots-switch'),
                value: _showDots,
                onChanged: (v) => setState(() => _showDots = v),
              ),
              Text(L.t(context, 'scale'), style: theme.textTheme.bodySmall),
              Switch(
                key: const Key('scale-switch'),
                value: widget.highlightScale,
                onChanged: widget.onToggleHighlight,
              ),
            ],
          ),
          if (widget.highlightScale) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final shape in commonScales)
                  ChoiceChip(
                    label: Text(L.t(context, shape.name)),
                    selected: widget.scale == shape,
                    onSelected: (_) => widget.onSelectScale(shape),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              L.f(context, '{name} on {root}: {notes}', {
                'name': L.t(context, widget.scale.name),
                'root': PitchNames.withOctave(widget.scaleRoot),
                'notes': widget.scale
                    .midisFrom(widget.scaleRoot)
                    .map(PitchNames.of)
                    .join(' '),
              }),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(L.t(context, 'root note'), style: theme.textTheme.bodySmall),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var pitch = 0; pitch < 12; pitch++)
                  ChoiceChip(
                    label: Text(noteNames[pitch]),
                    selected: widget.scaleRoot % 12 == pitch,
                    onSelected: (_) => widget.onSelectRoot(_rootAt(pitch)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              L.t(
                context,
                'Every dot of that colour is one of those notes, on every '
                'string. The brighter dots are the root.',
              ),
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          Text(
            L.t(
              context,
              'Tap any position to hear it and read its name. The left column '
              'sits behind the nut, so it is the string played open.',
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              children: [
                _Fretboard(
                  tuning: widget.tuning,
                  fretsShown: _fretsShown,
                  showNotes: _showNotes,
                  showDots: _showDots,
                  selected: _cell,
                  scaleClasses: widget.highlightScale
                      ? _scaleClasses
                      : const {},
                  scaleRoot: widget.highlightScale
                      ? widget.scaleRoot % 12
                      : null,
                  onTapCell: _select,
                ),
                if (_cell != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    L.f(context, 'String {n} - {pos}', {
                      'n': '${stringNumbers[_cell!.stringIndex]}',
                      'pos': _cell!.fret == 0
                          ? L.t(context, 'open')
                          : L.f(context, 'fret {n}', {'n': '${_cell!.fret}'}),
                    }),
                    style: theme.textTheme.titleSmall,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          '${PitchNames.withOctave(_midi)} - '
                          '${PitchNames.frequencyOf(_midi).toStringAsFixed(1)} Hz',
                        ),
                      ),
                      IconButton(
                        tooltip: L.t(context, 'Play again'),
                        icon: const Icon(Icons.volume_up),
                        onPressed: () => playNote(_midi),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    L.f(context, 'Its 5th is {a} and its octave is {b}.', {
                      'a': PitchNames.of(_midi + perfectFifth),
                      'b': PitchNames.withOctave(_midi + octave),
                    }),
                    style: theme.textTheme.bodySmall,
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

class _Fretboard extends StatelessWidget {
  final Tuning tuning;
  final int fretsShown;
  final bool showNotes;
  final bool showDots;
  final _Cell? selected;
  final Set<int> scaleClasses;
  final int? scaleRoot;
  final ValueChanged<_Cell> onTapCell;

  const _Fretboard({
    required this.tuning,
    required this.fretsShown,
    required this.showNotes,
    required this.showDots,
    required this.selected,
    required this.scaleClasses,
    required this.scaleRoot,
    required this.onTapCell,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = fretsShown + 1;
        final width = math.max(
          constraints.maxWidth,
          _labelWidth + columns * _minCellWidth,
        );
        final cellWidth = (width - _labelWidth) / columns;
        final height = _numbersHeight * 2 + _rowHeight * 6;

        // Twenty-four frets never fit a phone, so the board keeps its
        // readable cell width and the reader scrolls to the high notes.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: GestureDetector(
              key: const Key('fretboard'),
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final col =
                    ((details.localPosition.dx - _labelWidth) / cellWidth)
                        .floor();
                final row =
                    ((details.localPosition.dy - _numbersHeight) / _rowHeight)
                        .floor();
                if (col < 0 || col >= columns || row < 0 || row >= 6) return;
                // The lowest string is drawn last, so the top row is the
                // thin one.
                onTapCell(_Cell(5 - row, col));
              },
              child: CustomPaint(
                size: Size(width, height),
                painter: _FretboardPainter(
                  tuning: tuning,
                  columns: columns,
                  fretsShown: fretsShown,
                  cellWidth: cellWidth,
                  showNotes: showNotes,
                  showDots: showDots,
                  selected: selected,
                  scaleClasses: scaleClasses,
                  scaleRoot: scaleRoot,
                  colors: Theme.of(context).colorScheme,
                  stringLabel: (number) =>
                      L.f(context, 'str {n}', {'n': '$number'}),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FretboardPainter extends CustomPainter {
  final Tuning tuning;
  final int columns;
  final int fretsShown;
  final double cellWidth;
  final bool showNotes;
  final bool showDots;
  final _Cell? selected;
  final Set<int> scaleClasses;
  final int? scaleRoot;
  final ColorScheme colors;
  final String Function(int stringNumber) stringLabel;

  _FretboardPainter({
    required this.tuning,
    required this.columns,
    required this.fretsShown,
    required this.cellWidth,
    required this.showNotes,
    required this.showDots,
    required this.selected,
    required this.scaleClasses,
    required this.scaleRoot,
    required this.colors,
    required this.stringLabel,
  });

  /// The thin string on top, the bass at the bottom.
  double _stringY(int stringIndex) =>
      _numbersHeight + _rowHeight * (5 - stringIndex + 0.5);

  double _columnX(int fret) => _labelWidth + (fret + 0.5) * cellWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final boardTop = _numbersHeight;
    final boardBottom = size.height - _numbersHeight;
    final lineColor = colors.onSurface.withValues(alpha: 0.45);
    final stringPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.4;
    final fretPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.4;
    final nutPaint = Paint()
      ..color = colors.onSurface
      ..strokeWidth = 5;

    for (var s = 0; s < 6; s++) {
      final y = _stringY(s);
      canvas.drawLine(
        Offset(_labelWidth, y),
        Offset(size.width - 4, y),
        stringPaint,
      );
    }

    for (var c = 0; c < columns; c++) {
      final x = _labelWidth + c * cellWidth;
      canvas.drawLine(
        Offset(x, boardTop + _rowHeight * 0.5),
        Offset(x, boardBottom - _rowHeight * 0.5),
        c == 0 ? nutPaint : fretPaint,
      );
    }

    _inlays(canvas);

    // Fret numbers on both sides of the board, so they stay readable while
    // you follow a shape with your eye.
    for (var c = 1; c < columns; c++) {
      for (final y in [
        boardTop - _numbersHeight / 2,
        boardBottom + _numbersHeight / 2,
      ]) {
        _label(
          canvas,
          '$c',
          Offset(_columnX(c), y),
          color: colors.onSurfaceVariant,
          fontSize: 11,
        );
      }
    }

    final dot = math.min(11.0, cellWidth * 0.36);
    final bigDot = math.min(13.0, cellWidth * 0.42);
    final scaleDot = math.min(11.5, cellWidth * 0.38);
    final openDot = math.min(5.0, cellWidth * 0.17);

    for (var s = 0; s < 6; s++) {
      final y = _stringY(s);
      _label(
        canvas,
        stringLabel(stringNumbers[s]),
        Offset(_labelWidth - 8, y),
        color: colors.onSurfaceVariant,
        fontSize: 11,
        alignRight: true,
      );

      for (var c = 0; c < columns; c++) {
        final midi = tuning.openMidis[s] + c;
        final centerX = _columnX(c);
        final isSelected =
            selected != null &&
            selected!.stringIndex == s &&
            selected!.fret == c;
        final inScale = scaleClasses.contains(midi % 12);
        final isRoot = inScale && scaleRoot == midi % 12;
        final dimmed = scaleRoot != null && !inScale;

        canvas.drawCircle(
          Offset(centerX, y),
          c == 0
              ? openDot
              : isSelected || isRoot
              ? bigDot
              : inScale
              ? scaleDot
              : dimmed
              ? 4.5
              : dot,
          Paint()
            ..color = isSelected || isRoot
                ? colors.primary
                : inScale
                ? colors.tertiary
                : colors.surfaceContainerHighest.withValues(
                    alpha: dimmed ? 0.35 : 1,
                  ),
        );

        if (c > 0 && (showNotes || inScale)) {
          _label(
            canvas,
            PitchNames.of(midi),
            Offset(centerX, y),
            color: isSelected || isRoot
                ? colors.onPrimary
                : inScale
                ? colors.onTertiary
                : dimmed
                ? colors.onSurface.withValues(alpha: 0.3)
                : colors.onSurface,
            fontSize: 10,
          );
        }
      }
    }
  }

  /// The dots a player uses to find their place without counting.
  void _inlays(Canvas canvas) {
    if (!showDots) return;
    final mid = _numbersHeight + _rowHeight * 3;
    final upper = _numbersHeight + _rowHeight * 2;
    final lower = _numbersHeight + _rowHeight * 4;
    final paint = Paint()..color = colors.onSurface.withValues(alpha: 0.22);

    for (var fret = 1; fret <= fretsShown; fret++) {
      if (_singleDots.contains(fret)) {
        canvas.drawCircle(Offset(_columnX(fret), mid), 4.5, paint);
      } else if (_doubleDots.contains(fret)) {
        canvas.drawCircle(Offset(_columnX(fret), upper), 4.5, paint);
        canvas.drawCircle(Offset(_columnX(fret), lower), 4.5, paint);
      }
    }
  }

  void _label(
    Canvas canvas,
    String text,
    Offset anchor, {
    required Color color,
    required double fontSize,
    bool alignRight = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        alignRight ? anchor.dx - painter.width : anchor.dx - painter.width / 2,
        anchor.dy - painter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_FretboardPainter oldDelegate) =>
      oldDelegate.tuning != tuning ||
      oldDelegate.showNotes != showNotes ||
      oldDelegate.showDots != showDots ||
      oldDelegate.selected != selected ||
      oldDelegate.cellWidth != cellWidth ||
      oldDelegate.fretsShown != fretsShown ||
      oldDelegate.scaleRoot != scaleRoot ||
      !setEquals(oldDelegate.scaleClasses, scaleClasses);
}
