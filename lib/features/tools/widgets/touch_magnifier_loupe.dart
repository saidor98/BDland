import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';

class TouchMagnifierLoupe extends StatelessWidget {
  final Offset touchPosition;
  final double scaleFactor;
  final Widget child;

  const TouchMagnifierLoupe({
    super.key,
    required this.touchPosition,
    this.scaleFactor = 2.0,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const double loupeSize = 110.0;
    const double verticalOffset = 80.0;

    final loupeLeft = touchPosition.dx - (loupeSize / 2);
    final loupeTop = touchPosition.dy - verticalOffset - (loupeSize / 2);

    return Positioned(
      left: loupeLeft.clamp(10.0, MediaQuery.of(context).size.width - loupeSize - 10),
      top: loupeTop.clamp(10.0, MediaQuery.of(context).size.height - loupeSize - 80),
      child: IgnorePointer(
        child: Container(
          width: loupeSize,
          height: loupeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryGreen, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Stack(
              children: [
                // Magnified View
                Transform.translate(
                  offset: Offset(
                    -(touchPosition.dx * scaleFactor) + (loupeSize / 2),
                    -(touchPosition.dy * scaleFactor) + (loupeSize / 2),
                  ),
                  child: Transform.scale(
                    scale: scaleFactor,
                    alignment: Alignment.topLeft,
                    child: child,
                  ),
                ),

                // Precision Crosshairs
                Center(
                  child: CustomPaint(
                    size: const Size(loupeSize, loupeSize),
                    painter: _CrosshairPainter(),
                  ),
                ),

                // Coordinate Badge at bottom
                Positioned(
                  bottom: 4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '(${BanglaNumerals.toBangla(touchPosition.dx.toInt())}, ${BanglaNumerals.toBangla(touchPosition.dy.toInt())})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDC2626) // Precision Red
      ..strokeWidth = 1.2;

    final center = Offset(size.width / 2, size.height / 2);
    const armLength = 12.0;
    const gap = 3.0;

    // Horizontal crosshair with center gap
    canvas.drawLine(
      Offset(center.dx - armLength, center.dy),
      Offset(center.dx - gap, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + gap, center.dy),
      Offset(center.dx + armLength, center.dy),
      paint,
    );

    // Vertical crosshair with center gap
    canvas.drawLine(
      Offset(center.dx, center.dy - armLength),
      Offset(center.dx, center.dy - gap),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + gap),
      Offset(center.dx, center.dy + armLength),
      paint,
    );

    // Center target dot
    canvas.drawCircle(center, 1.5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
