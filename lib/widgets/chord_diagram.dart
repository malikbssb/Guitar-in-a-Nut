import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/chords.dart';

const double _markerHeight = 20;
const double _rowHeight = 26;
const double _sidePad = 12;

/// Vertical chord box: six strings, frets counted from the nut, a dot per
/// stopped string with the finger number inside it.
class ChordDiagram extends StatelessWidget {
  final ChordShape chord;
  final double width;
  final bool showName;

  const ChordDiagram({
    super.key,
    required this.chord,
    this.width = 96,
    this.showName = true,
  });

  int get _rows => math.max(3, chord.highestFret);

  double get height => _markerHeight + _rows * _rowHeight + (showName ? 24 : 6);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomPaint(
      size: Size(width, height),
      painter: _ChordDiagramPainter(
        chord: chord,
        rows: _rows,
        showName: showName,
        lineColor: theme.colorScheme.onSurface.withValues(alpha: 0.45),
        nutColor: theme.colorScheme.onSurface,
        dotColor: theme.colorScheme.primary,
        dotTextColor: theme.colorScheme.onPrimary,
        mutedColor: theme.colorScheme.error,
      ),
    );
  }
}

class _ChordDiagramPainter extends CustomPainter {
  final ChordShape chord;
  final int rows;
  final bool showName;
  final Color lineColor;
  final Color nutColor;
  final Color dotColor;
  final Color dotTextColor;
  final Color mutedColor;

  const _ChordDiagramPainter({
    required this.chord,
    required this.rows,
    required this.showName,
    required this.lineColor,
    required this.nutColor,
    required this.dotColor,
    required this.dotTextColor,
    required this.mutedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final columnWidth = (size.width - 2 * _sidePad) / 5;
    final top = _markerHeight;
    final bottom = top + rows * _rowHeight;

    double stringX(int index) => _sidePad + index * columnWidth;

    final stringPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2;
    for (var s = 0; s < 6; s++) {
      canvas.drawLine(
        Offset(stringX(s), top),
        Offset(stringX(s), bottom),
        stringPaint,
      );
    }

    final fretPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2;
    for (var r = 0; r <= rows; r++) {
      final y = top + r * _rowHeight;
      canvas.drawLine(Offset(stringX(0), y), Offset(stringX(5), y), fretPaint);
    }

    // The nut only means something when the shape starts on fret 1.
    if (chord.highestFret <= 4) {
      canvas.drawLine(
        Offset(stringX(0), top),
        Offset(stringX(5), top),
        Paint()
          ..color = nutColor
          ..strokeWidth = 4,
      );
    }

    for (var s = 0; s < 6; s++) {
      final fret = chord.frets[s];
      final finger = chord.fingers[s];
      final x = stringX(s);

      if (fret < 0) {
        _text(canvas, 'x', Offset(x, top - _markerHeight / 2), mutedColor, 13);
        continue;
      }
      if (fret == 0) {
        _text(canvas, 'o', Offset(x, top - _markerHeight / 2), nutColor, 13);
        continue;
      }

      final center = Offset(x, top + (fret - 0.5) * _rowHeight);
      canvas.drawCircle(center, 9, Paint()..color = dotColor);
      if (finger > 0) {
        _text(canvas, '$finger', center, dotTextColor, 11);
      }
    }

    if (showName) {
      _text(
        canvas,
        chord.name,
        Offset(size.width / 2, bottom + 14),
        nutColor,
        14,
        bold: true,
      );
    }
  }

  void _text(
    Canvas canvas,
    String value,
    Offset anchor,
    Color color,
    double fontSize, {
    bool bold = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(anchor.dx - painter.width / 2, anchor.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_ChordDiagramPainter oldDelegate) =>
      oldDelegate.chord != chord || oldDelegate.rows != rows;
}
