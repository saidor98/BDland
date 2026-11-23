import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/utils/bangla_formatter.dart';

class AnyShapeDividerScreen extends StatefulWidget {
  const AnyShapeDividerScreen({super.key});

  @override
  State<AnyShapeDividerScreen> createState() => _AnyShapeDividerScreenState();
}

class _AnyShapeDividerScreenState extends State<AnyShapeDividerScreen> {
  // Base polygon vertices (feet scale)
  final List<Offset> _polygon = [
    const Offset(60, 60),
    const Offset(280, 50),
    const Offset(300, 240),
    const Offset(40, 220),
  ];

  double _splitRatioA = 50.0; // percentage
  String _splitDirection = 'উত্তর-দক্ষিণ (Vertical)';

  @override
  Widget build(BuildContext context) {
    final totalAreaSqFt = _calculateArea(_polygon);
    final totalDec = totalAreaSqFt / 435.60;
    final totalKatha = totalAreaSqFt / 720.00;

    final portionADec = totalDec * (_splitRatioA / 100.0);
    final portionBDec = totalDec * ((100.0 - _splitRatioA) / 100.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AnyShape Divider (ভূমি বিভাজন)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'কপি রিপোর্ট',
            onPressed: () => _copyReport(totalDec, portionADec, portionBDec),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Split Summary Banner
            Card(
              color: AppColors.primaryGreenLight,
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('মোট জমি: ${BanglaFormatter.formatNumber(totalDec, fractionDigits: 3)} শতক',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('${BanglaFormatter.formatNumber(totalKatha, fractionDigits: 2)} কাঠা',
                            style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text('১ম অংশীদার (অংশ ক)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text('${BanglaFormatter.formatNumber(portionADec, fractionDigits: 3)} শতক',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGreenDark)),
                                Text('(${BanglaNumerals.toBangla(_splitRatioA.toInt())}%)', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryGold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text('২য় অংশীদার (অংশ খ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text('${BanglaFormatter.formatNumber(portionBDec, fractionDigits: 3)} শতক',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondaryGoldDark)),
                                Text('(${BanglaNumerals.toBangla((100 - _splitRatioA).toInt())}%)', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Visual Polygon Division Preview
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    const Text('বিভাজন নকশা ও সীমানা নির্ধারণ',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 230,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _AnyShapePainter(
                          polygon: _polygon,
                          splitRatio: _splitRatioA / 100.0,
                          isVertical: _splitDirection.startsWith('উত্তর'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Controls Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('বিভাজন নিয়ন্ত্রক ও অনুপাত', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('১ম অংশীদারের বণ্টন হার:'),
                        Text('${BanglaNumerals.toBangla(_splitRatioA.toInt())}% : ${BanglaNumerals.toBangla((100 - _splitRatioA).toInt())}%',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                      ],
                    ),
                    Slider(
                      value: _splitRatioA,
                      min: 10,
                      max: 90,
                      divisions: 16,
                      activeColor: AppColors.primaryGreen,
                      onChanged: (val) => setState(() => _splitRatioA = val),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _splitDirection,
                      decoration: const InputDecoration(
                        labelText: 'বিভাজন রেখার দিক (Direction)',
                        prefixIcon: Icon(Icons.explore, color: AppColors.primaryGreen),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'উত্তর-দক্ষিণ (Vertical)', child: Text('উত্তর-দক্ষিণ বরাবর বিভাজন')),
                        DropdownMenuItem(value: 'পূর্ব-পশ্চিম (Horizontal)', child: Text('পূর্ব-পশ্চিম বরাবর বিভাজন')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _splitDirection = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateArea(List<Offset> pts) {
    if (pts.length < 3) return 0.0;
    double sum = 0.0;
    for (int i = 0; i < pts.length; i++) {
      final p1 = pts[i];
      final p2 = pts[(i + 1) % pts.length];
      sum += (p1.dx * p2.dy) - (p2.dx * p1.dy);
    }
    return sum.abs() / 2.0;
  }

  void _copyReport(double total, double a, double b) {
    final text = '''
=== AnyShape Divider জমি বিভাজন রিপোর্ট ===
তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}
মোট জমির পরিমাণ: ${BanglaFormatter.formatNumber(total, fractionDigits: 3)} শতক
বিভাজনের দিক: $_splitDirection
• অংশীদার ক (${BanglaNumerals.toBangla(_splitRatioA.toInt())}%): ${BanglaFormatter.formatNumber(a, fractionDigits: 3)} শতক (${BanglaFormatter.formatLandBreakdown(a * 435.6)})
• অংশীদার খ (${BanglaNumerals.toBangla((100 - _splitRatioA).toInt())}%): ${BanglaFormatter.formatNumber(b, fractionDigits: 3)} শতক (${BanglaFormatter.formatLandBreakdown(b * 435.6)})
অ্যাপ: BDLandPro (বাংলাদেশ ভূমি জরিপ ও পরিমাপ)
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('বিভাজন রিপোর্ট কপি করা হয়েছে!')),
    );
  }
}

class _AnyShapePainter extends CustomPainter {
  final List<Offset> polygon;
  final double splitRatio;
  final bool isVertical;

  _AnyShapePainter({
    required this.polygon,
    required this.splitRatio,
    required this.isVertical,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (polygon.length < 3) return;

    // Draw base polygon outline
    final path = Path()..moveTo(polygon[0].dx, polygon[0].dy);
    for (int i = 1; i < polygon.length; i++) {
      path.lineTo(polygon[i].dx, polygon[i].dy);
    }
    path.close();

    // Fill Base Polygon with gradient
    canvas.drawPath(path, Paint()..color = const Color(0xFFE2E8F0));

    // Calculate dividing line along direction
    // Linear interpolation between opposite edges
    final cutStart = isVertical
        ? Offset.lerp(polygon[0], polygon[1], splitRatio)!
        : Offset.lerp(polygon[0], polygon[3], splitRatio)!;

    final cutEnd = isVertical
        ? Offset.lerp(polygon[3], polygon[2], splitRatio)!
        : Offset.lerp(polygon[1], polygon[2], splitRatio)!;

    // Shaded portion A
    final pathA = Path();
    if (isVertical) {
      pathA.moveTo(polygon[0].dx, polygon[0].dy);
      pathA.lineTo(cutStart.dx, cutStart.dy);
      pathA.lineTo(cutEnd.dx, cutEnd.dy);
      pathA.lineTo(polygon[3].dx, polygon[3].dy);
    } else {
      pathA.moveTo(polygon[0].dx, polygon[0].dy);
      pathA.lineTo(polygon[1].dx, polygon[1].dy);
      pathA.lineTo(cutEnd.dx, cutEnd.dy);
      pathA.lineTo(cutStart.dx, cutStart.dy);
    }
    pathA.close();
    canvas.drawPath(pathA, Paint()..color = AppColors.primaryGreen.withOpacity(0.35));

    // Polygon border
    canvas.drawPath(path, Paint()..color = AppColors.primaryGreenDark..strokeWidth = 2.5..style = PaintingStyle.stroke);

    // Draw Cut line (লাল বিভাজন রেখা)
    final cutPaint = Paint()
      ..color = AppColors.accentCrimson
      ..strokeWidth = 3.0;
    canvas.drawLine(cutStart, cutEnd, cutPaint);

    // Labels
    _drawText(canvas, 'অংশ ক', isVertical ? Offset((polygon[0].dx + cutStart.dx) / 2, (polygon[0].dy + polygon[3].dy) / 2) : Offset((polygon[0].dx + polygon[1].dx) / 2, (polygon[0].dy + cutStart.dy) / 2), AppColors.primaryGreenDark);
    _drawText(canvas, 'অংশ খ', isVertical ? Offset((polygon[1].dx + cutStart.dx) / 2, (polygon[1].dy + polygon[2].dy) / 2) : Offset((polygon[3].dx + polygon[2].dx) / 2, (cutEnd.dy + polygon[2].dy) / 2), AppColors.secondaryGoldDark);
    _drawText(canvas, 'কাটিং লাইন (${BanglaNumerals.toBangla((cutEnd - cutStart).distance.toStringAsFixed(1))}\')', Offset((cutStart.dx + cutEnd.dx) / 2, (cutStart.dy + cutEnd.dy) / 2 - 12), AppColors.accentCrimson);
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Hind Siliguri'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(offset.dx - tp.width / 2, offset.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _AnyShapePainter oldDelegate) => true;
}
