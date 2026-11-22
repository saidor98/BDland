import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class QuadrilateralPainter extends CustomPainter {
  final double north;
  final double east;
  final double south;
  final double west;
  final double diagonal;
  final bool isValid;

  QuadrilateralPainter({
    required this.north,
    required this.east,
    required this.south,
    required this.west,
    required this.diagonal,
    required this.isValid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = AppColors.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaintT1 = Paint()
      ..color = AppColors.primaryGreen.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final fillPaintT2 = Paint()
      ..color = AppColors.secondaryGold.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final diagonalPaint = Paint()
      ..color = AppColors.accentCrimson
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final pointPaint = Paint()
      ..color = AppColors.primaryGreenDark
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final pad = 36.0;

    // Approximate quadrilateral vertices relative to canvas size
    // A (Top-Left / উত্তর-পশ্চিম), B (Top-Right / উত্তর-পূর্ব),
    // C (Bottom-Right / দক্ষিণ-পূর্ব), D (Bottom-Left / দক্ষিণ-পশ্চিম)
    final pA = Offset(pad + 20, pad + 15);
    final pB = Offset(w - pad - 10, pad + 25);
    final pC = Offset(w - pad - 25, h - pad - 15);
    final pD = Offset(pad + 10, h - pad - 10);

    // Path for Triangle 1 (A-B-C or B-D diagonal)
    // Diagonal connects B to D
    final pathT1 = Path()
      ..moveTo(pA.dx, pA.dy)
      ..lineTo(pB.dx, pB.dy)
      ..lineTo(pD.dx, pD.dy)
      ..close();

    final pathT2 = Path()
      ..moveTo(pB.dx, pB.dy)
      ..lineTo(pC.dx, pC.dy)
      ..lineTo(pD.dx, pD.dy)
      ..close();

    canvas.drawPath(pathT1, fillPaintT1);
    canvas.drawPath(pathT2, fillPaintT2);

    // Draw borders
    final borderPath = Path()
      ..moveTo(pA.dx, pA.dy)
      ..lineTo(pB.dx, pB.dy)
      ..lineTo(pC.dx, pC.dy)
      ..lineTo(pD.dx, pD.dy)
      ..close();
    canvas.drawPath(borderPath, borderPaint);

    // Draw dashed diagonal (B to D)
    _drawDashedLine(canvas, pB, pD, diagonalPaint);

    // Draw corner points
    final radius = 5.0;
    canvas.drawCircle(pA, radius, pointPaint);
    canvas.drawCircle(pB, radius, pointPaint);
    canvas.drawCircle(pC, radius, pointPaint);
    canvas.drawCircle(pD, radius, pointPaint);

    // Labels
    _drawText(canvas, 'উত্তর (North): ${north.toStringAsFixed(1)} ft',
        Offset(w / 2 - 40, pad - 10));
    _drawText(canvas, 'পূর্ব (East): ${east.toStringAsFixed(1)} ft',
        Offset(w - pad + 5, h / 2 - 10), alignRight: false);
    _drawText(canvas, 'দক্ষিণ (South): ${south.toStringAsFixed(1)} ft',
        Offset(w / 2 - 40, h - pad + 15));
    _drawText(canvas, 'পশ্চিম (West): ${west.toStringAsFixed(1)} ft',
        Offset(pad - 30, h / 2 - 10), alignRight: true);

    // Diagonal label
    _drawText(canvas, 'কর্ণ: ${diagonal.toStringAsFixed(1)} ft',
        Offset((pB.dx + pD.dx) / 2 - 30, (pB.dy + pD.dy) / 2 - 15),
        color: AppColors.accentCrimson);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final count = (distance / (dashWidth + dashSpace)).floor();
    final unitX = dx / distance;
    final unitY = dy / distance;

    for (int i = 0; i < count; i++) {
      final start = Offset(
        p1.dx + (unitX * i * (dashWidth + dashSpace)),
        p1.dy + (unitY * i * (dashWidth + dashSpace)),
      );
      final end = Offset(
        start.dx + (unitX * dashWidth),
        start.dy + (unitY * dashWidth),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset,
      {bool alignRight = false, Color color = AppColors.textPrimary}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Hind Siliguri',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final pos = alignRight ? Offset(offset.dx - tp.width, offset.dy) : offset;
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant QuadrilateralPainter oldDelegate) {
    return oldDelegate.north != north ||
        oldDelegate.east != east ||
        oldDelegate.south != south ||
        oldDelegate.west != west ||
        oldDelegate.diagonal != diagonal;
  }
}

class TrianglePainter extends CustomPainter {
  final double sideA;
  final double sideB;
  final double sideC;
  final bool isHeron;

  TrianglePainter({
    required this.sideA,
    required this.sideB,
    required this.sideC,
    required this.isHeron,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = AppColors.primaryGreen.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = AppColors.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pTop = Offset(size.width / 2, 28);
    final pLeft = Offset(30, size.height - 30);
    final pRight = Offset(size.width - 30, size.height - 30);

    final path = Path()
      ..moveTo(pTop.dx, pTop.dy)
      ..lineTo(pRight.dx, pRight.dy)
      ..lineTo(pLeft.dx, pLeft.dy)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    // Points
    final dotPaint = Paint()..color = AppColors.primaryGreenDark;
    canvas.drawCircle(pTop, 5, dotPaint);
    canvas.drawCircle(pLeft, 5, dotPaint);
    canvas.drawCircle(pRight, 5, dotPaint);

    // Labels
    _drawLabel(canvas, 'বাহু ১: ${sideA.toStringAsFixed(1)} ft',
        Offset(size.width / 4 - 30, size.height / 2 - 10));
    _drawLabel(canvas, 'বাহু ২: ${sideB.toStringAsFixed(1)} ft',
        Offset(size.width * 3 / 4 - 10, size.height / 2 - 10));
    _drawLabel(canvas, 'বাহু ৩: ${sideC.toStringAsFixed(1)} ft',
        Offset(size.width / 2 - 40, size.height - 18));
  }

  void _drawLabel(Canvas canvas, String text, Offset offset) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Hind Siliguri',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant TrianglePainter oldDelegate) => true;
}

class TrapezoidPainter extends CustomPainter {
  final double parallelA;
  final double parallelB;
  final double height;

  TrapezoidPainter({
    required this.parallelA,
    required this.parallelB,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fillPaint = Paint()
      ..color = AppColors.secondaryGold.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = AppColors.secondaryGoldDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final pTopLeft = Offset(w * 0.25, 35);
    final pTopRight = Offset(w * 0.75, 35);
    final pBottomRight = Offset(w * 0.90, h - 35);
    final pBottomLeft = Offset(w * 0.10, h - 35);

    final path = Path()
      ..moveTo(pTopLeft.dx, pTopLeft.dy)
      ..lineTo(pTopRight.dx, pTopRight.dy)
      ..lineTo(pBottomRight.dx, pBottomRight.dy)
      ..lineTo(pBottomLeft.dx, pBottomLeft.dy)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    // Height dashed line
    final heightPaint = Paint()
      ..color = AppColors.accentCrimson
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.5, 35),
      Offset(w * 0.5, h - 35),
      heightPaint,
    );

    // Labels
    _drawLabel(canvas, 'সমান্তরাল বাহু ১ (a): ${parallelA.toStringAsFixed(1)} ft',
        Offset(w * 0.25, 12));
    _drawLabel(canvas, 'সমান্তরাল বাহু ২ (b): ${parallelB.toStringAsFixed(1)} ft',
        Offset(w * 0.25, h - 22));
    _drawLabel(canvas, 'উচ্চতা (h): ${height.toStringAsFixed(1)} ft',
        Offset(w * 0.52, h * 0.5 - 10),
        color: AppColors.accentCrimson);
  }

  void _drawLabel(Canvas canvas, String text, Offset offset,
      {Color color = AppColors.textPrimary}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Hind Siliguri',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant TrapezoidPainter oldDelegate) => true;
}

class CirclePainter extends CustomPainter {
  final double radius;
  final double? angleDegrees;
  final bool isSector;

  CirclePainter({
    required this.radius,
    this.angleDegrees,
    required this.isSector,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final drawRadius = math.min(size.width, size.height) * 0.38;

    final fillPaint = Paint()
      ..color = AppColors.accentTeal.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = AppColors.accentTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    if (isSector && angleDegrees != null) {
      final sweepAngle = (angleDegrees! * math.pi) / 180.0;
      final rect = Rect.fromCircle(center: center, radius: drawRadius);

      canvas.drawArc(rect, 0, sweepAngle, true, fillPaint);
      canvas.drawArc(rect, 0, sweepAngle, true, strokePaint);
    } else {
      canvas.drawCircle(center, drawRadius, fillPaint);
      canvas.drawCircle(center, drawRadius, strokePaint);
    }

    // Center point and radius line
    canvas.drawCircle(center, 4, Paint()..color = AppColors.primaryGreenDark);
    final radiusPaint = Paint()
      ..color = AppColors.accentCrimson
      ..strokeWidth = 2.0;
    canvas.drawLine(center, Offset(center.dx + drawRadius, center.dy), radiusPaint);

    final tp = TextPainter(
      text: TextSpan(
        text: 'ব্যাসার্ধ (r): ${radius.toStringAsFixed(1)} ft',
        style: const TextStyle(
          color: AppColors.accentCrimson,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: 'Hind Siliguri',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx + 10, center.dy - 18));
  }

  @override
  bool shouldRepaint(covariant CirclePainter oldDelegate) => true;
}

class EarthworkCrossSectionPainter extends CustomPainter {
  final double topLength;
  final double topWidth;
  final double bottomWidth;
  final double depth;

  EarthworkCrossSectionPainter({
    required this.topLength,
    required this.topWidth,
    required this.bottomWidth,
    required this.depth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Cross-section trapezoid of pond / excavation
    final groundPaint = Paint()
      ..color = const Color(0xFF8D6E63) // Soil color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final soilFillPaint = Paint()
      ..color = const Color(0xFFD7CCC8).withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final waterFillPaint = Paint()
      ..color = Colors.lightBlue.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final pTopLeft = Offset(w * 0.15, h * 0.25);
    final pTopRight = Offset(w * 0.85, h * 0.25);
    final pBottomRight = Offset(w * 0.70, h * 0.75);
    final pBottomLeft = Offset(w * 0.30, h * 0.75);

    final pitPath = Path()
      ..moveTo(pTopLeft.dx, pTopLeft.dy)
      ..lineTo(pTopRight.dx, pTopRight.dy)
      ..lineTo(pBottomRight.dx, pBottomRight.dy)
      ..lineTo(pBottomLeft.dx, pBottomLeft.dy)
      ..close();

    canvas.drawPath(pitPath, soilFillPaint);
    canvas.drawPath(pitPath, waterFillPaint);
    canvas.drawPath(pitPath, groundPaint);

    // Ground level line on left and right
    canvas.drawLine(Offset(10, h * 0.25), pTopLeft, groundPaint);
    canvas.drawLine(pTopRight, Offset(w - 10, h * 0.25), groundPaint);

    // Depth line
    final depthPaint = Paint()
      ..color = AppColors.accentCrimson
      ..strokeWidth = 2.0;
    canvas.drawLine(
        Offset(w * 0.5, h * 0.25), Offset(w * 0.5, h * 0.75), depthPaint);

    // Labels
    _drawText(canvas, 'উপরের বিস্তার: ${topWidth.toStringAsFixed(1)} ft',
        Offset(w * 0.35, h * 0.15));
    _drawText(canvas, 'তলার বিস্তার: ${bottomWidth.toStringAsFixed(1)} ft',
        Offset(w * 0.35, h * 0.80));
    _drawText(canvas, 'গভীরতা: ${depth.toStringAsFixed(1)} ft',
        Offset(w * 0.52, h * 0.5 - 8),
        color: AppColors.accentCrimson);
  }

  void _drawText(Canvas canvas, String text, Offset offset,
      {Color color = AppColors.textPrimary}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Hind Siliguri',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant EarthworkCrossSectionPainter oldDelegate) => true;
}
