import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/services/history_service.dart';
import '../../history/models/calculation_history_item.dart';

class MouzaMapSimpleScreen extends StatefulWidget {
  const MouzaMapSimpleScreen({super.key});

  @override
  State<MouzaMapSimpleScreen> createState() => _MouzaMapSimpleScreenState();
}

class _MouzaMapSimpleScreenState extends State<MouzaMapSimpleScreen> {
  // Scale presets: feet per pixel in canvas space
  // On 16"=1 mile: 1 inch = 330 ft = 500 links. At ~100 dpi: 1 px ≈ 3.3 ft
  double _feetPerPixel = 1.65; // default 32" or scaled canvas
  String _selectedScale = '16" = 1 মাইল';

  final List<Offset> _measuredPoints = [
    const Offset(100, 120),
    const Offset(280, 120),
    const Offset(290, 240),
    const Offset(90, 230),
  ];

  double _totalAreaSqFt = 0.0;
  double _totalPerimeterFt = 0.0;

  @override
  void initState() {
    super.initState();
    _recompute();
  }

  void _onScaleChanged(String? scale) {
    if (scale == null) return;
    setState(() {
      _selectedScale = scale;
      if (scale.startsWith('16"')) {
        _feetPerPixel = 3.30;
      } else if (scale.startsWith('32"')) {
        _feetPerPixel = 1.65;
      } else if (scale.startsWith('64"')) {
        _feetPerPixel = 0.825;
      } else if (scale.startsWith('80"')) {
        _feetPerPixel = 0.66;
      }
      _recompute();
    });
  }

  void _recompute() {
    if (_measuredPoints.length < 3) {
      _totalAreaSqFt = 0;
      _totalPerimeterFt = 0;
      return;
    }

    double sum = 0.0;
    double perimPx = 0.0;
    for (int i = 0; i < _measuredPoints.length; i++) {
      final p1 = _measuredPoints[i];
      final p2 = _measuredPoints[(i + 1) % _measuredPoints.length];
      sum += (p1.dx * p2.dy) - (p2.dx * p1.dy);

      final dx = p2.dx - p1.dx;
      final dy = p2.dy - p1.dy;
      perimPx += math.sqrt(dx * dx + dy * dy);
    }

    final pixelArea = (sum.abs() / 2.0);
    // Area in sq ft = pixelArea * (_feetPerPixel ^ 2)
    _totalAreaSqFt = pixelArea * (_feetPerPixel * _feetPerPixel);
    _totalPerimeterFt = perimPx * _feetPerPixel;
  }

  String _generateReport() {
    final dec = _totalAreaSqFt / 435.60;
    final katha = _totalAreaSqFt / 720.00;
    final links = _totalPerimeterFt / 0.66;

    final buffer = StringBuffer();
    buffer.writeln('=== মৌজা ম্যাপ পরিমাপ (সহজ) রিপোর্ট ===');
    buffer.writeln('তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}');
    buffer.writeln('স্কেল: $_selectedScale');
    buffer.writeln('মোট পরিমাপকৃত পয়েন্ট: ${BanglaNumerals.toBangla(_measuredPoints.length)} টি');
    buffer.writeln('মোট পরিসীমা: ${BanglaFormatter.formatNumber(_totalPerimeterFt)} ফুট (${BanglaFormatter.formatNumber(links)} লিংক)');
    buffer.writeln('মোট ক্ষেত্রফল: ${BanglaFormatter.formatNumber(_totalAreaSqFt)} বর্গফুট');
    buffer.writeln('মোট শতাংশ: ${BanglaFormatter.formatNumber(dec, fractionDigits: 3)} শতক');
    buffer.writeln('মোট কাঠা: ${BanglaFormatter.formatNumber(katha, fractionDigits: 3)} কাঠা');
    buffer.writeln('বিস্তারিত: ${BanglaFormatter.formatLandBreakdown(_totalAreaSqFt)}');
    buffer.writeln('\nঅ্যাপ: BDLandPro - বাংলাদেশ ভূমি জরিপ');
    return buffer.toString();
  }

  void _copyReport() {
    Clipboard.setData(ClipboardData(text: _generateReport()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('মৌজা ম্যাপের রিপোর্ট কপি করা হয়েছে!'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  Future<void> _saveToHistory() async {
    final dec = _totalAreaSqFt / 435.60;
    final item = CalculationHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'মৌজা পরিমাপ ($_selectedScale - ${BanglaFormatter.formatNumber(dec, fractionDigits: 2)} শতক)',
      category: 'মৌজা স্কেল',
      timestamp: DateTime.now(),
      inputSummary: 'স্কেল: $_selectedScale, ${_measuredPoints.length} টি দাগ পয়েন্ট',
      resultSummary: '${BanglaFormatter.formatNumber(dec, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(_totalAreaSqFt)} বর্গফুট)',
      fullReportBangla: _generateReport(),
    );
    await HistoryService.instance.saveItem(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('হিস্ট্রিতে সংরক্ষিত হয়েছে!'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dec = _totalAreaSqFt / 435.60;
    final katha = _totalAreaSqFt / 720.00;
    final links = _totalPerimeterFt / 0.66;

    return Scaffold(
      appBar: AppBar(
        title: const Text('মৌজা ম্যাপ পরিমাপ (সহজ)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'কপি রিপোর্ট',
            onPressed: _measuredPoints.length >= 3 ? _copyReport : null,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'সেভ',
            onPressed: _measuredPoints.length >= 3 ? _saveToHistory : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Scale selector and quick results
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.straighten, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                const Text('স্কেল:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedScale,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: '16" = 1 মাইল', child: Text('১৬" = ১ মাইল (CS/SA/RS)')),
                      DropdownMenuItem(value: '32" = 1 মাইল', child: Text('৩২" = ১ মাইল (উপশহর/ঘন)')),
                      DropdownMenuItem(value: '64" = 1 মাইল', child: Text('৬৪" = ১ মাইল (পৌরসভা/বাজার)')),
                      DropdownMenuItem(value: '80" = 1 মাইল', child: Text('৮০" = ১ মাইল (সিটি জরিপ)')),
                    ],
                    onChanged: _onScaleChanged,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Output metrics banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.primaryGreenLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoBadge('শতাংশ', '${BanglaFormatter.formatNumber(dec, fractionDigits: 3)} শতক', isPrimary: true),
                _buildInfoBadge('কাঠা', '${BanglaFormatter.formatNumber(katha, fractionDigits: 3)} কাঠা'),
                _buildInfoBadge('বর্গফুট', '${BanglaFormatter.formatNumber(_totalAreaSqFt)} ft²'),
                _buildInfoBadge('পরিসীমা', '${BanglaFormatter.formatNumber(links)} লিংক'),
              ],
            ),
          ),

          // Mouza Sheet Canvas with Map Texture and Plotting
          Expanded(
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(40),
              minScale: 0.5,
              maxScale: 4.0,
              child: GestureDetector(
                onTapUp: (details) {
                  setState(() {
                    _measuredPoints.add(details.localPosition);
                    _recompute();
                  });
                },
                child: CustomPaint(
                  painter: _MouzaSheetPainter(
                    points: _measuredPoints,
                    scaleName: _selectedScale,
                    feetPerPixel: _feetPerPixel,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.cardBorderLight)),
            ),
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: _measuredPoints.isNotEmpty
                      ? () {
                          setState(() {
                            _measuredPoints.removeLast();
                            _recompute();
                          });
                        }
                      : null,
                  icon: const Icon(Icons.undo),
                  tooltip: 'পূর্বের পয়েন্ট মুছুন',
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () {
                    setState(() {
                      _measuredPoints.clear();
                      _recompute();
                    });
                  },
                  icon: const Icon(Icons.delete_sweep, color: AppColors.accentCrimson),
                  tooltip: 'সব পয়েন্ট মুছুন',
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _measuredPoints
                        ..clear()
                        ..addAll([
                          const Offset(100, 120),
                          const Offset(280, 120),
                          const Offset(290, 240),
                          const Offset(90, 230),
                        ]);
                      _recompute();
                    });
                  },
                  icon: const Icon(Icons.crop_free, size: 18),
                  label: const Text('নমুনা দাগ'),
                ),
                const Spacer(),
                Text(
                  'দাগ পয়েন্ট: ${BanglaNumerals.toBangla(_measuredPoints.length)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(String label, String value, {bool isPrimary = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: isPrimary ? 16 : 13,
            fontWeight: FontWeight.bold,
            color: isPrimary ? AppColors.primaryGreenDark : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _MouzaSheetPainter extends CustomPainter {
  final List<Offset> points;
  final String scaleName;
  final double feetPerPixel;

  _MouzaSheetPainter({
    required this.points,
    required this.scaleName,
    required this.feetPerPixel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Mouza Parchment Map Background
    final paperPaint = Paint()..color = const Color(0xFFFAF6EE);
    canvas.drawRect(Offset.zero & size, paperPaint);

    // Grid lines resembling cadastral survey sheet
    final gridLinePaint = Paint()
      ..color = const Color(0xFFE2D6C0)
      ..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridLinePaint);
    }
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridLinePaint);
    }

    // Draw realistic simulated survey cadastral plots (দাগ নম্বরসহ)
    final plotBorderPaint = Paint()
      ..color = const Color(0xFF6B583E).withOpacity(0.55)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // Simulated Mouza Dag 101, 102, 103, 104 borders
    canvas.drawRect(const Rect.fromLTWH(40, 40, 160, 140), plotBorderPaint);
    _drawDagLabel(canvas, 'দাগ ১০১', const Offset(110, 100));

    canvas.drawRect(const Rect.fromLTWH(200, 40, 180, 140), plotBorderPaint);
    _drawDagLabel(canvas, 'দাগ ১০২', const Offset(280, 100));

    canvas.drawRect(const Rect.fromLTWH(40, 180, 160, 160), plotBorderPaint);
    _drawDagLabel(canvas, 'দাগ ১০৩', const Offset(110, 250));

    canvas.drawRect(const Rect.fromLTWH(200, 180, 180, 160), plotBorderPaint);
    _drawDagLabel(canvas, 'দাগ ১০৪', const Offset(280, 250));

    // 2. Draw User Measurement Overlay Polygon
    if (points.isNotEmpty) {
      final polyPath = Path();
      polyPath.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        polyPath.lineTo(points[i].dx, points[i].dy);
      }
      if (points.length >= 3) {
        polyPath.close();
        final fillPaint = Paint()
          ..color = AppColors.primaryGreen.withOpacity(0.25)
          ..style = PaintingStyle.fill;
        canvas.drawPath(polyPath, fillPaint);
      }

      final strokePaint = Paint()
        ..color = AppColors.accentCrimson
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawPath(polyPath, strokePaint);

      // Points and side length in Links
      for (int i = 0; i < points.length; i++) {
        final p = points[i];
        canvas.drawCircle(p, 5.5, Paint()..color = AppColors.accentCrimson);
        canvas.drawCircle(p, 5.5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.0);

        if (points.length > 1) {
          final p2 = points[(i + 1) % points.length];
          if (i < points.length - 1 || points.length >= 3) {
            final distFt = (p2 - p).distance * feetPerPixel;
            final distLinks = distFt / 0.66;
            final mid = Offset((p.dx + p2.dx) / 2, (p.dy + p2.dy) / 2);
            _drawLinkBadge(canvas, '${BanglaNumerals.toBangla(distLinks.toStringAsFixed(0))}L (${BanglaNumerals.toBangla(distFt.toStringAsFixed(1))}\')', mid);
          }
        }
      }
    }
  }

  void _drawDagLabel(Canvas canvas, String text, Offset offset) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF795548),
          fontSize: 13,
          fontWeight: FontWeight.bold,
          fontFamily: 'Hind Siliguri',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(offset.dx - tp.width / 2, offset.dy - tp.height / 2));
  }

  void _drawLinkBadge(Canvas canvas, String text, Offset offset) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          fontFamily: 'Hind Siliguri',
          backgroundColor: Color(0xCC0B6623),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(offset.dx - tp.width / 2, offset.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MouzaSheetPainter oldDelegate) => true;
}
