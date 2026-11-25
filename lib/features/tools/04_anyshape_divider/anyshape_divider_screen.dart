import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/services/history_service.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/utils/polygon_geometry.dart';
import '../../history/models/calculation_history_item.dart';

class AnyShapeDividerScreen extends StatefulWidget {
  const AnyShapeDividerScreen({super.key});

  @override
  State<AnyShapeDividerScreen> createState() => _AnyShapeDividerScreenState();
}

class _AnyShapeDividerScreenState extends State<AnyShapeDividerScreen> {
  // Interactive polygon vertices (feet space)
  List<Offset> _polygon = [
    const Offset(0, 0),
    const Offset(220, -10),
    const Offset(240, 180),
    const Offset(-20, 160),
  ];

  double _splitRatioA = 50.0; // percentage 10..90
  String _splitDirection = 'উত্তর-দক্ষিণ (Vertical)';
  final _targetLandScaleCtrl = TextEditingController();

  @override
  void dispose() {
    _targetLandScaleCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveToHistory(double totalDec, double portionA, double portionB) async {
    await HistoryService.instance.saveItem(
      CalculationHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'AnyShape বণ্টন (${BanglaFormatter.formatNumber(totalDec, fractionDigits: 2)} শতক)',
        category: 'জ্যামিতি',
        timestamp: DateTime.now(),
        inputSummary: 'অনুপাত ${BanglaNumerals.toBangla(_splitRatioA.toInt())}% : ${BanglaNumerals.toBangla((100 - _splitRatioA).toInt())}% | $_splitDirection',
        resultSummary: 'ক: ${BanglaFormatter.formatNumber(portionA, fractionDigits: 2)} শতক | খ: ${BanglaFormatter.formatNumber(portionB, fractionDigits: 2)} শতক',
        fullReportBangla: _buildReport(totalDec, portionA, portionB),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('বণ্টন হিসাব হিস্ট্রিতে সংরক্ষিত হয়েছে!'), backgroundColor: AppColors.primaryGreen),
    );
  }

  void _showScaleTotalAreaDialog(double currentDec) {
    _targetLandScaleCtrl.text = currentDec.toStringAsFixed(2);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('মোট জমি কাস্টম সেট করুন'),
        content: TextField(
          controller: _targetLandScaleCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'প্লটের প্রকৃত মোট জমি (শতক)',
            border: OutlineInputBorder(),
            suffixText: 'শতক',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () {
              final targetDec = double.tryParse(_targetLandScaleCtrl.text.trim()) ?? 0;
              if (targetDec > 0 && currentDec > 0) {
                final scale = math.sqrt(targetDec / currentDec);
                setState(() {
                  _polygon = _polygon.map((p) => p * scale).toList();
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('প্রয়োগ করুন'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalAreaSqFt = PolygonGeometry.calculateArea(_polygon);
    final totalDec = totalAreaSqFt / 435.60;
    final totalKatha = totalAreaSqFt / 720.00;

    final isVerticalCut = _splitDirection.startsWith('উত্তর');
    final targetAreaA = totalAreaSqFt * (_splitRatioA / 100.0);
    final cutRes = PolygonGeometry.findAreaBisectionCutLine(
      polygon: _polygon,
      targetArea: targetAreaA,
      horizontalCut: !isVerticalCut,
      fromStart: true,
    );

    final portionADec = totalDec * (_splitRatioA / 100.0);
    final portionBDec = totalDec * ((100.0 - _splitRatioA) / 100.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AnyShape Divider (ভূমি বিভাজন)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'মোট শতক পরিবর্তন',
            onPressed: () => _showScaleTotalAreaDialog(totalDec),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'সেভ',
            onPressed: () => _saveToHistory(totalDec, portionADec, portionBDec),
          ),
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
                        InkWell(
                          onTap: () => _showScaleTotalAreaDialog(totalDec),
                          child: Row(
                            children: [
                              Text(
                                'মোট জমি: ${BanglaFormatter.formatNumber(totalDec, fractionDigits: 3)} শতক',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit, size: 15, color: AppColors.primaryGreenDark),
                            ],
                          ),
                        ),
                        Text(
                          '${BanglaFormatter.formatNumber(totalKatha, fractionDigits: 2)} কাঠা',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
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

            // Visual Polygon Division Preview (auto-fitted to viewport)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'নিখুঁত ক্ষেত্রফল-ভিত্তিক বিভাজন নকশা',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                        ),
                        if (cutRes != null)
                          Text(
                            'কাট দৈর্ঘ্য: ${BanglaFormatter.formatNumber(cutRes.cutLength, fractionDigits: 1)}\'',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.accentCrimson),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 240,
                      width: double.infinity,
                      child: LayoutBuilder(
                        builder: (ctx, box) {
                          return GestureDetector(
                            onPanUpdate: (details) {
                              // Drag closest vertex using canvas transform inverse
                              final tx = _AnyShapePainter.computeTransform(_polygon, Size(box.maxWidth, box.maxHeight));
                              final localPt = (details.localPosition - tx.offset) / tx.scale;
                              int? closest;
                              double best = 36.0 / tx.scale;
                              for (int i = 0; i < _polygon.length; i++) {
                                final d = (_polygon[i] - localPt).distance;
                                if (d < best) {
                                  best = d;
                                  closest = i;
                                }
                              }
                              if (closest != null) {
                                setState(() {
                                  _polygon[closest!] = localPt;
                                });
                              }
                            },
                            child: CustomPaint(
                              painter: _AnyShapePainter(
                                polygon: _polygon,
                                cutResult: cutRes,
                                isVerticalCut: isVerticalCut,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            if (_polygon.isEmpty) return;
                            final cx = _polygon.map((p) => p.dx).reduce((a, b) => a + b) / _polygon.length;
                            final cy = _polygon.map((p) => p.dy).reduce((a, b) => a + b) / _polygon.length;
                            final last = _polygon.last;
                            final first = _polygon.first;
                            final mid = Offset((last.dx + first.dx) / 2, (last.dy + first.dy) / 2);
                            final out = mid - Offset(cx, cy);
                            final norm = out.distance > 1e-6 ? out / out.distance : const Offset(1, 0);
                            setState(() {
                              _polygon.add(mid + norm * 25.0);
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 15, color: AppColors.primaryGreen),
                          label: const Text('+ কোণ যোগ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        ),
                        TextButton.icon(
                          onPressed: _polygon.length > 3
                              ? () => setState(() => _polygon.removeLast())
                              : null,
                          icon: const Icon(Icons.remove_circle_outline, size: 15, color: AppColors.accentCrimson),
                          label: const Text('− কোণ', style: TextStyle(fontSize: 11.5)),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _polygon = [
                                const Offset(0, 0),
                                const Offset(220, -10),
                                const Offset(240, 180),
                                const Offset(-20, 160),
                              ];
                            });
                          },
                          icon: const Icon(Icons.refresh, size: 15),
                          label: const Text('রিসেট', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'টিপস: কোণ ড্র্যাগ করুন বা "+ কোণ যোগ" দিয়ে ৫-১০ কোণী জমি মাপুন',
                        style: TextStyle(fontSize: 10.5, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

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

  String _buildReport(double total, double a, double b) {
    return '''
=== AnyShape Divider জমি বিভাজন রিপোর্ট ===
তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}
মোট জমির পরিমাণ: ${BanglaFormatter.formatNumber(total, fractionDigits: 3)} শতক
বিভাজনের দিক: $_splitDirection
• অংশীদার ক (${BanglaNumerals.toBangla(_splitRatioA.toInt())}%): ${BanglaFormatter.formatNumber(a, fractionDigits: 3)} শতক (${BanglaFormatter.formatLandBreakdown(a * 435.6)})
• অংশীদার খ (${BanglaNumerals.toBangla((100 - _splitRatioA).toInt())}%): ${BanglaFormatter.formatNumber(b, fractionDigits: 3)} শতক (${BanglaFormatter.formatLandBreakdown(b * 435.6)})
অ্যাপ: BDLandPro (বাংলাদেশ ভূমি জরিপ ও পরিমাপ)
''';
  }

  void _copyReport(double total, double a, double b) {
    Clipboard.setData(ClipboardData(text: _buildReport(total, a, b)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('বিভাজন রিপোর্ট কপি করা হয়েছে!')),
    );
  }
}

class _FitTransform {
  final double scale;
  final Offset offset;
  const _FitTransform(this.scale, this.offset);
}

class _AnyShapePainter extends CustomPainter {
  final List<Offset> polygon;
  final BisectionCutResult? cutResult;
  final bool isVerticalCut;

  _AnyShapePainter({
    required this.polygon,
    required this.cutResult,
    required this.isVerticalCut,
  });

  static _FitTransform computeTransform(List<Offset> polygon, Size size) {
    double minX = polygon[0].dx, maxX = polygon[0].dx;
    double minY = polygon[0].dy, maxY = polygon[0].dy;
    for (final p in polygon) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    const pad = 28.0;
    final w = (maxX - minX).abs().clamp(1.0, 1e9);
    final h = (maxY - minY).abs().clamp(1.0, 1e9);
    final availW = (size.width - pad * 2).clamp(20.0, 1e9);
    final availH = (size.height - pad * 2).clamp(20.0, 1e9);
    final scale = math.min(availW / w, availH / h);
    final offset = Offset(
      (size.width - w * scale) / 2.0 - minX * scale,
      (size.height - h * scale) / 2.0 - minY * scale,
    );
    return _FitTransform(scale, offset);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (polygon.length < 3) return;
    final tx = computeTransform(polygon, size);
    Offset toScreen(Offset p) => p * tx.scale + tx.offset;

    final screenPoly = polygon.map(toScreen).toList();
    final path = Path()..moveTo(screenPoly[0].dx, screenPoly[0].dy);
    for (int i = 1; i < screenPoly.length; i++) {
      path.lineTo(screenPoly[i].dx, screenPoly[i].dy);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = const Color(0xFFE2E8F0));

    // Exact area-bisected half shading
    if (cutResult != null) {
      final cutA = cutResult!.cutStart;
      final cutB = cutResult!.cutEnd;
      final bool keepLeft = isVerticalCut;
      final halfPoly = PolygonGeometry.clipPolygonByHalfPlane(
        polygon,
        cutA,
        cutB,
        keepLeft: keepLeft,
      );
      if (halfPoly.length >= 3) {
        final sHalf = halfPoly.map(toScreen).toList();
        final pathA = Path()..moveTo(sHalf[0].dx, sHalf[0].dy);
        for (int i = 1; i < sHalf.length; i++) {
          pathA.lineTo(sHalf[i].dx, sHalf[i].dy);
        }
        pathA.close();
        canvas.drawPath(pathA, Paint()..color = AppColors.primaryGreen.withOpacity(0.32));
      }
    }

    canvas.drawPath(path, Paint()..color = AppColors.primaryGreenDark..strokeWidth = 2.5..style = PaintingStyle.stroke);

    // Draw vertices
    for (final sp in screenPoly) {
      canvas.drawCircle(sp, 5, Paint()..color = Colors.white);
      canvas.drawCircle(sp, 5, Paint()..color = AppColors.primaryGreenDark..strokeWidth = 1.5..style = PaintingStyle.stroke);
    }

    if (cutResult != null) {
      final cs = toScreen(cutResult!.cutStart);
      final ce = toScreen(cutResult!.cutEnd);
      canvas.drawLine(cs, ce, Paint()..color = AppColors.accentCrimson..strokeWidth = 3.0);
      _drawText(
        canvas,
        'কাটিং লাইন (${BanglaNumerals.toBangla(cutResult!.cutLength.toStringAsFixed(1))}\')',
        Offset((cs.dx + ce.dx) / 2, (cs.dy + ce.dy) / 2 - 12),
        AppColors.accentCrimson,
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.bold, fontFamily: 'Hind Siliguri'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(offset.dx - tp.width / 2, offset.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _AnyShapePainter oldDelegate) => true;
}
