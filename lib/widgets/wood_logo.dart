import 'package:flutter/material.dart';

/// Walnut badge that doubles as the home button. The cream name plate is the
/// nut itself: a bone strip with one V-slot per string along its top edge.
class WoodLogo extends StatelessWidget {
  /// Null on screens where the badge is a title, not a home button.
  final VoidCallback? onTap;
  final double height;

  const WoodLogo({super.key, this.onTap, this.height = 64});

  static const double _boxWidth = 178;

  @override
  Widget build(BuildContext context) {
    final ratio = height / 64;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18 * ratio),
      child: Container(
        width: _boxWidth * ratio,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18 * ratio),
          image: const DecorationImage(
            image: AssetImage('assets/images/wood.jpg'),
            fit: BoxFit.cover,
            // The grain is warm; darken it so the blue theme stays dominant.
            colorFilter: ColorFilter.mode(
              Color(0x59000000),
              BlendMode.multiply,
            ),
          ),
          border: Border.all(
            color: const Color(0xFFF2DCC0).withValues(alpha: 0.35),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 122 * ratio,
              height: 32 * ratio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: _NutPainter()),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 9 * ratio, bottom: 1 * ratio),
                    child: Text(
                      'GUITAR',
                      style: TextStyle(
                        color: const Color(0xFF2A170C),
                        fontSize: 15 * ratio,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.4 * ratio,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 3 * ratio),
            Text(
              'in a Nut',
              style: TextStyle(
                color: const Color(0xFFF2E4CE),
                fontSize: 11 * ratio,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Six V-shaped cuts along the top edge of the name plate, so the plate reads
/// as a nut with one slot per string instead of a plain label.
class _NutPainter extends CustomPainter {
  static const int _slots = 6;

  const _NutPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final depth = size.height * 0.26;
    const radius = 6.0;
    final slotWidth = size.width / (_slots * 2.4);
    final spacing = size.width / (_slots + 1);

    final plate = Path()..moveTo(0, 0);
    for (var i = 0; i < _slots; i++) {
      final center = spacing * (i + 1);
      final topHalf = slotWidth / 2;
      // Narrow at the bottom so each cut reads as a V-slot, not a stripe.
      final bottomHalf = topHalf * 0.28;
      plate
        ..lineTo(center - topHalf, 0)
        ..lineTo(center - bottomHalf, depth)
        ..lineTo(center + bottomHalf, depth)
        ..lineTo(center + topHalf, 0);
    }
    plate
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - radius)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width - radius,
        size.height,
      )
      ..lineTo(radius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - radius)
      ..close();

    canvas.drawShadow(plate, Colors.black, 2.5, false);
    canvas.drawPath(plate, Paint()..color = const Color(0xFFF2E4CE));
    canvas.drawPath(
      plate,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = const Color(0xFF8C7F6A),
    );
  }

  @override
  bool shouldRepaint(_NutPainter oldDelegate) => false;
}
