import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/services/history_service.dart';
import '../../history/models/calculation_history_item.dart';

class GoogleMapSurveyScreen extends StatefulWidget {
  const GoogleMapSurveyScreen({super.key});

  @override
  State<GoogleMapSurveyScreen> createState() => _GoogleMapSurveyScreenState();
}

class _GoogleMapSurveyScreenState extends State<GoogleMapSurveyScreen> {
  // Vertices in local coordinate space (in feet)
  final List<Offset> _points = [
    const Offset(50, 50),
    const Offset(220, 60),
    const Offset(240, 200),
    const Offset(40, 180),
  ];

  int? _draggedIndex;
  bool _isSatelliteMode = true;
  double _scale = 1.0; // scale factor (feet per pixel)

  // Computed metrics
  double _areaSqFt = 0.0;
  double _perimeterFt = 0.0;

  @override
  void initState() {
    super.initState();
    _recompute();
  }

  void _recompute() {
    if (_points.length < 3) {
      _areaSqFt = 0.0;
      _perimeterFt = 0.0;
      return;
    }

    // Shoelace formula for polygon area
    double sum = 0.0;
    double perim = 0.0;
    for (int i = 0; i < _points.length; i++) {
      final p1 = _points[i];
      final p2 = _points[(i + 1) % _points.length];
      sum += (p1.dx * p2.dy) - (p2.dx * p1.dy);

      final dx = p2.dx - p1.dx;
      final dy = p2.dy - p1.dy;
      perim += math.sqrt(dx * dx + dy * dy);
    }
    _areaSqFt = (sum.abs() / 2.0);
    _perimeterFt = perim;
  }

  void _addPoint(Offset localPos) {
    setState(() {
      _points.add(localPos);
      _recompute();
    });
  }

  void _removeLastPoint() {
    if (_points.isEmpty) return;
    setState(() {
      _points.removeLast();
      _recompute();
    });
  }

  void _clearPoints() {
    setState(() {
      _points.clear();
      _recompute();
    });
  }

  void _resetToSample() {
    setState(() {
      _points
        ..clear()
        ..addAll([
          const Offset(50, 50),
          const Offset(220, 60),
          const Offset(240, 200),
          const Offset(40, 180),
        ]);
      _recompute();
    });
  }

  String _generateKml() {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buffer.writeln('<Document>');
    buffer.writeln('<name>BDLandPro_Survey_Polygon</name>');
    buffer.writeln('<Placemark>');
    buffer.writeln('<name>Plotted Land Area</name>');
    buffer.writeln('<Polygon><outerBoundaryIs><LinearRing><coordinates>');
    for (final p in _points) {
      // Projected simulated lat/long (centered around Dhaka, 23.8103, 90.4125)
      final lat = 23.8103 + (p.dy * 0.000003);
      final lng = 90.4125 + (p.dx * 0.000003);
      buffer.writeln('$lng,$lat,0');
    }
    if (_points.isNotEmpty) {
      final p = _points.first;
      final lat = 23.8103 + (p.dy * 0.000003);
      final lng = 90.4125 + (p.dx * 0.000003);
      buffer.writeln('$lng,$lat,0');
    }
    buffer.writeln('</coordinates></LinearRing></outerBoundaryIs></Polygon>');
    buffer.writeln('</Placemark>');
    buffer.writeln('</Document></kml>');
    return buffer.toString();
  }

  String _generateReport() {
    final dec = _areaSqFt / 435.60;
    final katha = _areaSqFt / 720.00;
    final bigha = dec / 33.00;
    final acre = dec / 100.00;
    final links = _perimeterFt / 0.66;

    final buffer = StringBuffer();
    buffer.writeln('=== গুগল ম্যাপে জমি পরিমাপ রিপোর্ট ===');
    buffer.writeln('তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}');
    buffer.writeln('মোট শীর্ষবিন্দু (Vertices): ${BanglaNumerals.toBangla(_points.length)} টি');
    buffer.writeln('পরিসীমা: ${BanglaFormatter.formatNumber(_perimeterFt)} ফুট (${BanglaFormatter.formatNumber(links)} লিংক)');
    buffer.writeln('মোট ক্ষেত্রফল: ${BanglaFormatter.formatNumber(_areaSqFt)} বর্গফুট');
    buffer.writeln('মোট শতাংশ: ${BanglaFormatter.formatNumber(dec, fractionDigits: 3)} শতক');
    buffer.writeln('মোট কাঠা: ${BanglaFormatter.formatNumber(katha, fractionDigits: 3)} কাঠা');
    buffer.writeln('মোট বিঘা: ${BanglaFormatter.formatNumber(bigha, fractionDigits: 4)} বিঘা');
    buffer.writeln('মোট একর: ${BanglaFormatter.formatNumber(acre, fractionDigits: 4)} একর');
    buffer.writeln('বিস্তারিত হিসাব: ${BanglaFormatter.formatLandBreakdown(_areaSqFt)}');
    buffer.writeln('\nঅ্যাপ: BDLandPro - পেশাদার বাংলাদেশ ভূমি জরিপ');
    return buffer.toString();
  }

  void _copyReport() {
    Clipboard.setData(ClipboardData(text: _generateReport()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('পরিমাপ রিপোর্ট ক্লিপবোর্ডে কপি করা হয়েছে!'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _exportKml() {
    final kml = _generateKml();
    Clipboard.setData(ClipboardData(text: kml));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('KML কোড ক্লিপবোর্ডে কপি করা হয়েছে! (Google Earth-এ সরাসরি ওপেনযোগ্য)'),
        backgroundColor: AppColors.accentTeal,
      ),
    );
  }

  Future<void> _saveToHistory() async {
    final dec = _areaSqFt / 435.60;
    final item = CalculationHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'গুগল ম্যাপে পরিমাপ (${BanglaFormatter.formatNumber(dec, fractionDigits: 2)} শতক)',
      category: 'জ্যামিতি',
      timestamp: DateTime.now(),
      inputSummary: '${_points.length} টি শীর্ষবিন্দুর বহুভুজ প্লট',
      resultSummary: '${BanglaFormatter.formatNumber(dec, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(_areaSqFt)} বর্গফুট)',
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
    final dec = _areaSqFt / 435.60;
    final katha = _areaSqFt / 720.00;
    final bigha = dec / 33.00;
    final links = _perimeterFt / 0.66;

    return Scaffold(
      appBar: AppBar(
        title: const Text('গুগল ম্যাপে জমি পরিমাপ'),
        actions: [
          IconButton(
            icon: Icon(_isSatelliteMode ? Icons.map : Icons.satellite_alt),
            tooltip: _isSatelliteMode ? 'সাধারণ ম্যাপ' : 'স্যাটেলাইট ভিউ',
            onPressed: () => setState(() => _isSatelliteMode = !_isSatelliteMode),
          ),
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'KML এক্সপোর্ট',
            onPressed: _points.length >= 3 ? _exportKml : null,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'কপি রিপোর্ট',
            onPressed: _points.length >= 3 ? _copyReport : null,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'সেভ',
            onPressed: _points.length >= 3 ? _saveToHistory : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Live Results Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.primaryGreenDark,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCol('শতাংশ (শতক)', '${BanglaFormatter.formatNumber(dec, fractionDigits: 3)} শতক', isPrimary: true),
                _buildMetricCol('কাঠা', '${BanglaFormatter.formatNumber(katha, fractionDigits: 3)} কাঠা'),
                _buildMetricCol('বর্গফুট', '${BanglaFormatter.formatNumber(_areaSqFt)} ft²'),
                _buildMetricCol('পরিসীমা', '${BanglaFormatter.formatNumber(_perimeterFt)} ft (${BanglaFormatter.formatNumber(links)} L)'),
              ],
            ),
          ),

          // Interactive Canvas Map
          Expanded(
            child: GestureDetector(
              onTapDown: (details) {
                // Check if tapping close to an existing point to select, else add
                final tapPos = details.localPosition;
                int? foundIndex;
                for (int i = 0; i < _points.length; i++) {
                  if ((_points[i] - tapPos).distance < 24.0) {
                    foundIndex = i;
                    break;
                  }
                }
                if (foundIndex != null) {
                  setState(() => _draggedIndex = foundIndex);
                } else {
                  _addPoint(tapPos);
                }
              },
              onPanUpdate: (details) {
                if (_draggedIndex != null && _draggedIndex! < _points.length) {
                  setState(() {
                    _points[_draggedIndex!] = details.localPosition;
                    _recompute();
                  });
                }
              },
              onPanEnd: (_) => setState(() => _draggedIndex = null),
              child: CustomPaint(
                painter: _MapCanvasPainter(
                  points: _points,
                  isSatellite: _isSatelliteMode,
                  draggedIndex: _draggedIndex,
                ),
                size: Size.infinite,
              ),
            ),
          ),

          // Action Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.cardBorderLight)),
            ),
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: _points.isNotEmpty ? _removeLastPoint : null,
                  icon: const Icon(Icons.undo),
                  tooltip: 'পূর্বের পয়েন্ট বাতিল',
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _clearPoints,
                  icon: const Icon(Icons.delete_sweep, color: AppColors.accentCrimson),
                  tooltip: 'সব মুছুন',
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _resetToSample,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('নমুনা প্লট'),
                ),
                const Spacer(),
                Text(
                  'পয়েন্ট: ${BanglaNumerals.toBangla(_points.length)} টি',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, {bool isPrimary = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: isPrimary ? AppColors.secondaryGold : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isPrimary ? 15 : 13,
          ),
        ),
      ],
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  final List<Offset> points;
  final bool isSatellite;
  final int? draggedIndex;

  _MapCanvasPainter({
    required this.points,
    required this.isSatellite,
    required this.draggedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Background
    if (isSatellite) {
      // Satellite terrain effect
      final bgPaint = Paint()..color = const Color(0xFF1E2F23);
      canvas.drawRect(Offset.zero & size, bgPaint);

      // Simulated field lines / terrain texture
      final roadPaint = Paint()
        ..color = const Color(0xFF2C3E2D)
        ..strokeWidth = 2.0;
      for (double y = 0; y < size.height; y += 40) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y + 10), roadPaint);
      }
      for (double x = 0; x < size.width; x += 50) {
        canvas.drawLine(Offset(x, 0), Offset(x + 15, size.height), roadPaint);
      }
    } else {
      // Clean Engineering Grid
      final bgPaint = Paint()..color = const Color(0xFFF8FAFC);
      canvas.drawRect(Offset.zero & size, bgPaint);

      final gridPaint = Paint()
        ..color = Colors.blueGrey.withOpacity(0.12)
        ..strokeWidth = 1.0;
      for (double x = 0; x < size.width; x += 25) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y < size.height; y += 25) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    if (points.isEmpty) {
      final textSpan = TextSpan(
        text: 'স্ক্রিনে আঙুল দিয়ে পরপর পয়েন্ট বসিয়ে প্লট তৈরি করুন।\nপয়েন্ট ড্র্যাগ করে সীমানা রদবদল করা যায়।',
        style: TextStyle(
          color: isSatellite ? Colors.white70 : AppColors.textSecondary,
          fontSize: 14,
          fontFamily: 'Hind Siliguri',
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr, textAlign: TextAlign.center)..layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height / 2 - 20));
      return;
    }

    // 2. Draw Polygon
    final polyPath = Path();
    polyPath.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      polyPath.lineTo(points[i].dx, points[i].dy);
    }
    if (points.length >= 3) {
      polyPath.close();

      final fillPaint = Paint()
        ..color = (isSatellite ? AppColors.secondaryGold : AppColors.primaryGreen).withOpacity(0.25)
        ..style = PaintingStyle.fill;
      canvas.drawPath(polyPath, fillPaint);
    }

    // Border line
    final borderPaint = Paint()
      ..color = isSatellite ? const Color(0xFFFFD54F) : AppColors.primaryGreen
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(polyPath, borderPaint);

    // 3. Side length labels & vertices
    final vertexPaint = Paint()..color = isSatellite ? Colors.white : AppColors.primaryGreenDark;
    final vertexBorder = Paint()
      ..color = isSatellite ? const Color(0xFFFFD54F) : Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length; i++) {
      final p1 = points[i];
      final isSelected = draggedIndex == i;

      // Draw side length label between p1 and p2
      if (points.length > 1) {
        final p2 = points[(i + 1) % points.length];
        if (i < points.length - 1 || points.length >= 3) {
          final dist = (p2 - p1).distance;
          final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
          _drawLabel(canvas, '${BanglaNumerals.toBangla(dist.toStringAsFixed(1))}\'', mid, isSatellite);
        }
      }

      // Draw point circle
      canvas.drawCircle(p1, isSelected ? 9.0 : 6.0, vertexPaint);
      canvas.drawCircle(p1, isSelected ? 9.0 : 6.0, vertexBorder);

      // Vertex label
      _drawLabel(canvas, 'P${BanglaNumerals.toBangla(i + 1)}', Offset(p1.dx, p1.dy - 16), isSatellite, isPointLabel: true);
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset offset, bool isSat, {bool isPointLabel = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: isSat ? (isPointLabel ? Colors.cyanAccent : Colors.white) : (isPointLabel ? AppColors.accentCrimson : AppColors.textPrimary),
          fontSize: isPointLabel ? 11 : 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'Hind Siliguri',
          backgroundColor: isSat ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(offset.dx - tp.width / 2, offset.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) => true;
}
