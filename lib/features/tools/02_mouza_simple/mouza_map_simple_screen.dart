import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/services/history_service.dart';
import '../../history/models/calculation_history_item.dart';
import '../widgets/digital_gunia_scale.dart';
import '../widgets/touch_magnifier_loupe.dart';

class MouzaMapSimpleScreen extends StatefulWidget {
  const MouzaMapSimpleScreen({super.key});

  @override
  State<MouzaMapSimpleScreen> createState() => _MouzaMapSimpleScreenState();
}

class _MouzaMapSimpleScreenState extends State<MouzaMapSimpleScreen> {
  // Scale presets: feet per pixel in canvas space
  // On 16"=1 mile: 1 inch = 330 ft = 500 links.
  double _feetPerPixel = 1.65; // default 32"
  String _selectedScale = '16" = 1 মাইল';

  final List<Offset> _measuredPoints = [
    const Offset(100, 120),
    const Offset(280, 120),
    const Offset(290, 240),
    const Offset(90, 230),
  ];

  double _totalAreaSqFt = 0.0;
  double _totalPerimeterFt = 0.0;

  // Advanced features
  bool _showGuniaScale = false;
  Offset? _touchPosition;
  bool _isTouchActive = false;

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

  void _showCalibrationDialog() {
    final distController = TextEditingController(text: '100');
    String unit = 'লিংক'; // লিংক or ফুট

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.straighten, color: AppColors.primaryGreen),
              SizedBox(width: 8),
              Text('২-পয়েন্ট স্কেল ক্যালিব্রেশন', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ম্যাপের যেকোনো পরিচিত সীমানা বা গুনিয়া লাইনের ২টি বিন্দুর দূরত্ব ইনপুট দিন:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: distController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'দূরত্ব',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: unit,
                    items: const [
                      DropdownMenuItem(value: 'লিংক', child: Text('লিংক')),
                      DropdownMenuItem(value: 'ফুট', child: Text('ফুট')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => unit = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '১০০ লিংক = ৬৬ ফুট (১ গান্টার চেইন)\nবর্তমানে প্রতি পিক্সেল = ${BanglaFormatter.formatNumber(_feetPerPixel, fractionDigits: 3)} ফুট',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              onPressed: () {
                final dist = double.tryParse(distController.text.trim()) ?? 100.0;
                final distInFeet = unit == 'লিংক' ? dist * 0.66 : dist;
                // Calibrate: assume current default test span is ~60px
                setState(() {
                  _feetPerPixel = (distInFeet / 60.0).clamp(0.2, 10.0);
                  _selectedScale = 'কাস্টম ক্যালিব্রেটেড';
                  _recompute();
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('স্কেল সফলভাবে ক্যালিব্রেট করা হয়েছে! (১ px = ${BanglaFormatter.formatNumber(_feetPerPixel, fractionDigits: 3)} ft)'),
                    backgroundColor: AppColors.primaryGreen,
                  ),
                );
              },
              child: const Text('ক্যালিব্রেট করুন', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
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

    final sheetContent = CustomPaint(
      painter: _MouzaSheetPainter(
        points: _measuredPoints,
        scaleName: _selectedScale,
        feetPerPixel: _feetPerPixel,
      ),
      size: const Size(600, 600),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('মৌজা ম্যাপ পরিমাপ (সহজ)'),
        actions: [
          IconButton(
            icon: Icon(
              _showGuniaScale ? Icons.square_foot : Icons.straighten_outlined,
              color: _showGuniaScale ? Colors.amberAccent : Colors.white,
            ),
            tooltip: _showGuniaScale ? 'গুনিয়া স্কেল লুকান' : 'গুনিয়া স্কেল অন করুন',
            onPressed: () => setState(() => _showGuniaScale = !_showGuniaScale),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'স্কেল ক্যালিব্রেট',
            onPressed: _showCalibrationDialog,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'কপি রিপোর্ট',
            onPressed: _measuredPoints.length >= 3 ? _copyReport : null,
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'হিস্ট্রিতে সেভ করুন',
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
                      DropdownMenuItem(value: 'কাস্টম ক্যালিব্রেটেড', child: Text('কাস্টম ক্যালিব্রেটেড স্কেল')),
                    ],
                    onChanged: _onScaleChanged,
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.tune, size: 14),
                  label: const Text('ক্যালিব্রেট', style: TextStyle(fontSize: 11)),
                  onPressed: _showCalibrationDialog,
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

          // Mouza Sheet Canvas with Map Texture and Touch Loupe
          Expanded(
            child: Stack(
              children: [
                InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(40),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: GestureDetector(
                    onTapDown: (details) {
                      setState(() {
                        _touchPosition = details.localPosition;
                        _isTouchActive = true;
                      });
                    },
                    onTapUp: (details) {
                      setState(() {
                        _measuredPoints.add(details.localPosition);
                        _isTouchActive = false;
                        _recompute();
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _touchPosition = details.localPosition;
                        _isTouchActive = true;
                      });
                    },
                    onPanEnd: (_) {
                      setState(() {
                        _isTouchActive = false;
                      });
                    },
                    child: sheetContent,
                  ),
                ),

                // Precision Touch Loupe (আতশী কাচ)
                if (_isTouchActive && _touchPosition != null)
                  TouchMagnifierLoupe(
                    touchPosition: _touchPosition!,
                    scaleFactor: 2.2,
                    child: sheetContent,
                  ),

                // Digital Gunia Scale Overlay
                if (_showGuniaScale)
                  DigitalGuniaScale(
                    pixelsPer100Links: (_feetPerPixel > 0 ? (66.0 / _feetPerPixel) : 40.0).clamp(20.0, 70.0),
                    onClose: () => setState(() => _showGuniaScale = false),
                  ),
              ],
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

    // Active measurement polygon
    if (points.isNotEmpty) {
      final polyPaint = Paint()
        ..color = AppColors.primaryGreen.withOpacity(0.25)
        ..style = PaintingStyle.fill;

      final polyStroke = Paint()
        ..color = AppColors.primaryGreen
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      if (points.length >= 3) {
        path.close();
        canvas.drawPath(path, polyPaint);
      }
      canvas.drawPath(path, polyStroke);

      // Draw side lengths along edges
      final textPaint = Paint();
      for (int i = 0; i < points.length; i++) {
        final p1 = points[i];
        final p2 = points[(i + 1) % points.length];
        if (points.length < 3 && i == points.length - 1) break;

        final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        final dx = p2.dx - p1.dx;
        final dy = p2.dy - p1.dy;
        final lenPx = math.sqrt(dx * dx + dy * dy);
        final lenFt = lenPx * feetPerPixel;
        final lenLinks = lenFt / 0.66;

        final label = '${BanglaNumerals.toBangla(lenFt.round())} ft (${BanglaNumerals.toBangla(lenLinks.round())} L)';
        _drawSideLabel(canvas, label, mid, textPaint);
      }

      // Draw Vertex Dots
      final dotPaint = Paint()..color = AppColors.accentCrimson;
      final dotOutline = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      for (int i = 0; i < points.length; i++) {
        canvas.drawCircle(points[i], 5.0, dotPaint);
        canvas.drawCircle(points[i], 5.0, dotOutline);
      }
    }
  }

  void _drawDagLabel(Canvas canvas, String label, Offset position) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6B583E),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(position.dx - (tp.width / 2), position.dy - (tp.height / 2)));
  }

  void _drawSideLabel(Canvas canvas, String text, Offset position, Paint bgPaint) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bgRect = Rect.fromCenter(
      center: position,
      width: tp.width + 6,
      height: tp.height + 4,
    );
    final rrect = RRect.fromRectAndRadius(bgRect, const Radius.circular(4));

    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF1E293B).withOpacity(0.85));
    tp.paint(canvas, Offset(position.dx - (tp.width / 2), position.dy - (tp.height / 2)));
  }

  @override
  bool shouldRepaint(covariant _MouzaSheetPainter oldDelegate) => true;
}
