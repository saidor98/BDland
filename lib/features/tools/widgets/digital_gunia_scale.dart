import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';

class DigitalGuniaScale extends StatefulWidget {
  final double pixelsPer100Links; // Scale calibration
  final VoidCallback onClose;

  const DigitalGuniaScale({
    super.key,
    required this.pixelsPer100Links,
    required this.onClose,
  });

  @override
  State<DigitalGuniaScale> createState() => _DigitalGuniaScaleState();
}

class _DigitalGuniaScaleState extends State<DigitalGuniaScale> {
  Offset _position = const Offset(40, 100);
  double _rotationAngle = 0.0; // In radians

  @override
  Widget build(BuildContext context) {
    // Standard Gunia has 10 large divisions = 1,000 links
    // Width corresponds to 1,000 links
    final scaleWidth = (widget.pixelsPer100Links * 10).clamp(240.0, 420.0);
    const scaleHeight = 58.0;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: Transform.rotate(
        angle: _rotationAngle,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _position += details.delta;
            });
          },
          child: Material(
            elevation: 8,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: scaleWidth,
              height: scaleHeight,
              decoration: BoxDecoration(
                // Translucent acrylic ivory/amber Gunia look
                color: const Color(0xCCFFFBEB),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFD97706), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Ticks & Graduations Painter
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GuniaTicksPainter(divisions: 10),
                    ),
                  ),

                  // Center Controls: Title + Rotate + Close
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade400, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'গুনিয়া স্কেল (১০০০ লিংক)',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Rotate Handle
                            GestureDetector(
                              onPanUpdate: (details) {
                                setState(() {
                                  _rotationAngle += details.delta.dx * 0.02;
                                });
                              },
                              child: const Icon(
                                Icons.rotate_right,
                                size: 16,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Close Button
                            GestureDetector(
                              onTap: widget.onClose,
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuniaTicksPainter extends CustomPainter {
  final int divisions; // 10 chains = 1000 links

  _GuniaTicksPainter({required this.divisions});

  @override
  void paint(Canvas canvas, Size size) {
    final majorTickPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 1.4;

    final minorTickPaint = Paint()
      ..color = const Color(0xFF92400E)
      ..strokeWidth = 0.8;

    final subMinorTickPaint = Paint()
      ..color = const Color(0xFFB45309).withOpacity(0.7)
      ..strokeWidth = 0.5;

    final stepX = size.width / divisions;

    // Draw Top Edge Graduations (20-link ticks, 100-link major)
    for (int i = 0; i <= divisions; i++) {
      final x = i * stepX;

      // Major tick (100 links)
      canvas.drawLine(Offset(x, 0), Offset(x, 16), majorTickPaint);

      // Label major ticks
      if (i % 2 == 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: BanglaNumerals.toBangla(i * 100),
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Color(0xFF78350F),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - (tp.width / 2), 17));
      }

      // 5 subdivisions between each 100 links = 20 links each
      if (i < divisions) {
        final subStep = stepX / 5;
        for (int j = 1; j < 5; j++) {
          final subX = x + (j * subStep);
          final tickH = (j == 2 || j == 3) ? 10.0 : 7.0;
          canvas.drawLine(Offset(subX, 0), Offset(subX, tickH), minorTickPaint);
        }
      }
    }

    // Draw Bottom Edge Graduations (Fine 10-link ticks)
    final fineStep = size.width / (divisions * 10);
    for (int k = 0; k <= divisions * 10; k++) {
      final x = k * fineStep;
      final isMajor = k % 10 == 0;
      final isMid = k % 5 == 0;

      final tickH = isMajor ? 14.0 : (isMid ? 9.0 : 5.0);
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, size.height - tickH),
        isMajor ? majorTickPaint : (isMid ? minorTickPaint : subMinorTickPaint),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GuniaTicksPainter oldDelegate) =>
      oldDelegate.divisions != divisions;
}
