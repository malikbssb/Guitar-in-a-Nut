import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The rail glyphs Material's font has no equivalent for: a snare drum with
/// its sticks, a length of fretboard, and a pendulum metronome. All draw in a
/// 24 by 24 unit space and take their colour and size from the surrounding
/// [IconTheme], so the rail can treat them like any other icon.
class SnareGlyph extends StatelessWidget {
  const SnareGlyph({super.key});

  @override
  Widget build(BuildContext context) {
    final icon = IconTheme.of(context);
    return CustomPaint(
      size: Size.square(icon.size ?? 24),
      painter: _SnarePainter(icon.color ?? Theme.of(context).primaryColor),
    );
  }
}

class NeckGlyph extends StatelessWidget {
  const NeckGlyph({super.key});

  @override
  Widget build(BuildContext context) {
    final icon = IconTheme.of(context);
    return CustomPaint(
      size: Size.square(icon.size ?? 24),
      painter: _NeckPainter(icon.color ?? Theme.of(context).primaryColor),
    );
  }
}

class MetronomeGlyph extends StatelessWidget {
  const MetronomeGlyph({super.key});

  @override
  Widget build(BuildContext context) {
    final icon = IconTheme.of(context);
    return CustomPaint(
      size: Size.square(icon.size ?? 24),
      painter: _MetronomePainter(icon.color ?? Theme.of(context).primaryColor),
    );
  }
}

/// The shell is a cylinder seen from slightly above, so the batter head is an
/// ellipse and the two sticks lie across it.
class _SnarePainter extends CustomPainter {
  final Color color;

  _SnarePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);

    final head = Rect.fromCenter(
      center: const Offset(12, 11.5),
      width: 17,
      height: 6,
    );
    final foot = Rect.fromCenter(
      center: const Offset(12, 18),
      width: 17,
      height: 6,
    );
    final shell = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawOval(head, Paint()..color = color.withValues(alpha: 0.22));

    // The sticks sit on the head, so they are drawn before the rim only where
    // they must not be hidden — plain crossing above the drum reads better.
    canvas.drawLine(
      const Offset(2.5, 2.5),
      const Offset(14.5, 9.5),
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(21.5, 2.5),
      const Offset(9.5, 9.5),
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawOval(head, shell);
    canvas.drawLine(const Offset(3.5, 11.5), const Offset(3.5, 18), shell);
    canvas.drawLine(const Offset(20.5, 11.5), const Offset(20.5, 18), shell);
    canvas.drawArc(foot, 0, math.pi, false, shell);
  }

  @override
  bool shouldRepaint(_SnarePainter old) => old.color != color;
}

/// A neck laid diagonally, the only way it reads as an instrument at rail
/// size: headstock and pegs at one end, the nut, then six fret spaces down a
/// board that opens slightly towards the body.
class _NeckPainter extends CustomPainter {
  final Color color;

  _NeckPainter(this.color);

  /// Local space, drawn around the middle of the box: the headstock tip is at
  /// -10 and the end of the board at 10, with the nut where they meet.
  static const double _nut = -4.0;
  static const double _end = 10.0;

  double _left(double y) => -2.4 - 1.0 * (y - _nut) / (_end - _nut);

  double _right(double y) => 2.4 + 1.0 * (y - _nut) / (_end - _nut);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    canvas.translate(12, 12);
    canvas.rotate(-0.5);

    // Solid shapes rather than outlines: at 22 px a line drawing turns to
    // mush, but the gaps between the frets still read.
    final solid = Paint()..color = color;
    final board = Paint()..color = color.withValues(alpha: 0.85);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-3.2, -10, 3.2, -4.4),
        const Radius.circular(1.8),
      ),
      solid,
    );

    // The pegs stick out either side of the headstock.
    for (final y in [-8.6, -5.8]) {
      canvas.drawCircle(Offset(-4.4, y), 1.0, solid);
      canvas.drawCircle(Offset(4.4, y), 1.0, solid);
    }

    // The nut is the wide bar; the fret spaces below it shrink towards the
    // body the way real fret spacing does.
    canvas.drawRect(
      Rect.fromLTRB(_left(-4.0), -4.0, _right(-4.0), -3.1),
      solid,
    );
    const edges = [-3.1, -0.4, 2.2, 4.5, 6.5, 8.3, 10.0];
    for (var i = 0; i < edges.length - 1; i++) {
      final from = edges[i] + (i == 0 ? 0.0 : 0.55);
      final to = edges[i + 1] - 0.55;
      canvas.drawPath(
        Path()
          ..moveTo(_left(from), from)
          ..lineTo(_right(from), from)
          ..lineTo(_right(to), to)
          ..lineTo(_left(to), to)
          ..close(),
        board,
      );
    }
  }

  @override
  bool shouldRepaint(_NeckPainter old) => old.color != color;
}

/// The pyramid case, its foot, and the rod caught mid-swing with its weight
/// slid most of the way up.
class _MetronomePainter extends CustomPainter {
  final Color color;

  _MetronomePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);

    final solid = Paint()..color = color;
    final shell = Paint()..color = color.withValues(alpha: 0.85);

    canvas.drawPath(
      Path()
        ..moveTo(4.5, 19.5)
        ..lineTo(19.5, 19.5)
        ..lineTo(14.2, 4.5)
        ..lineTo(9.8, 4.5)
        ..close(),
      shell,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(3.2, 19.0, 20.8, 22.0),
        const Radius.circular(1.0),
      ),
      solid,
    );

    // The rod runs from the pivot at the foot out past the top of the case.
    const pivot = Offset(12, 18.6);
    const swing = 0.3;
    Offset along(double length) =>
        pivot + Offset(math.sin(swing) * length, -math.cos(swing) * length);

    canvas.drawLine(
      pivot,
      along(17.5),
      Paint()
        ..color = color
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    final weight = along(8.4);
    canvas.save();
    canvas.translate(weight.dx, weight.dy);
    canvas.rotate(swing);
    canvas.drawRect(const Rect.fromLTRB(-2.3, -1.1, 2.3, 1.1), solid);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MetronomePainter old) => old.color != color;
}
