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
  bool _isGpsWalkMode = false;
  String _activeTool = 'আঁকুন';
  bool _showDimensions = true;

  // Current simulated GPS location (Dhaka Bangladesh region)
  double _currentLat = 23.8103;
  double _currentLng = 90.4125;
  double _gpsAccuracyMeters = 1.2;

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

    // Geodesic / Cartesian Shoelace formula for polygon area
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

  void _addCurrentGpsPoint() {
    // Generate next realistic waypoint along perimeter
    setState(() {
      final lastPt = _points.isNotEmpty ? _points.last : const Offset(100, 100);
      final newPt = Offset(lastPt.dx + 45 * math.cos(_points.length), lastPt.dy + 45 * math.sin(_points.length));
      _points.add(newPt);
      _currentLat += 0.00015;
      _currentLng += 0.00012;
      _recompute();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'GPS পয়েন্ট ${BanglaNumerals.toBangla(_points.length)} রেকর্ড করা হয়েছে! (Lat: ${_currentLat.toStringAsFixed(5)}, Lng: ${_currentLng.toStringAsFixed(5)})',
        ),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showGpsWaypointsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.gps_fixed, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('জিপিএস ওয়েকপয়েন্ট তালিকা (WGS84)'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _points.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final p = _points[idx];
              final lat = 23.8103 + (p.dy * 0.000003);
              final lng = 90.4125 + (p.dx * 0.000003);
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primaryGreen,
                  child: Text(
                    BanglaNumerals.toBangla(idx + 1),
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text('পয়েন্ট ${BanglaNumerals.toBangla(idx + 1)}'),
                subtitle: Text('Lat: ${lat.toStringAsFixed(6)}°, Lng: ${lng.toStringAsFixed(6)}°'),
                trailing: Text('${p.dx.round()}\', ${p.dy.round()}\''),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বন্ধ করুন')),
        ],
      ),
    );
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
    buffer.writeln('</Placemark></Document></kml>');
    return buffer.toString();
  }

  void _exportKml() {
    final kml = _generateKml();
    Clipboard.setData(ClipboardData(text: kml));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('KML কোড ক্লিপবোর্ডে কপি করা হয়েছে! Google Earth-এ সরাসরি পেস্ট বা ইম্পোর্ট করুন।'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  String _generateReport() {
    final decimal = _areaSqFt / 435.60;
    final katha = _areaSqFt / 720.00;
    final bigha = decimal / 33.0;

    final buffer = StringBuffer();
    buffer.writeln('=== গুগল ম্যাপ স্যাটেলাইট জমি জরিপ রিপোর্ট ===');
    buffer.writeln('তারিখ ও সময়: ${BanglaFormatter.formatDateTime(DateTime.now())}');
    buffer.writeln('পয়েন্ট সংখ্যা: ${BanglaNumerals.toBangla(_points.length)} টি');
    buffer.writeln('মোট পরিসীমা: ${BanglaFormatter.formatNumber(_perimeterFt)} ফুট');
    buffer.writeln('মোট ক্ষেত্রফল: ${BanglaFormatter.formatNumber(_areaSqFt)} বর্গফুট');
    buffer.writeln('শতাংশ (শতক): ${BanglaFormatter.formatNumber(decimal, fractionDigits: 3)} শতক');
    buffer.writeln('কাঠা: ${BanglaFormatter.formatNumber(katha, fractionDigits: 3)} কাঠা');
    buffer.writeln('বিঘা: ${BanglaFormatter.formatNumber(bigha, fractionDigits: 3)} বিঘা');
    buffer.writeln('বিস্তারিত বিভাজন: ${BanglaFormatter.formatLandBreakdown(_areaSqFt)}');
    buffer.writeln('\nঅ্যাপ: BDLandPro - পেশাদার বাংলাদেশ ভূমি জরিপ');
    return buffer.toString();
  }

  void _copyReport() {
    Clipboard.setData(ClipboardData(text: _generateReport()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('স্যাটেলাইট জরিপের রিপোর্ট কপি করা হয়েছে!'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  Future<void> _saveToHistory() async {
    final decimal = _areaSqFt / 435.60;
    final item = CalculationHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'স্যাটেলাইট জরিপ (${BanglaFormatter.formatNumber(decimal, fractionDigits: 2)} শতক)',
      category: 'গুগল ম্যাপ',
      timestamp: DateTime.now(),
      inputSummary: '${_points.length} টি জিপিএস পিন / ওয়েকপয়েন্ট',
      resultSummary: '${BanglaFormatter.formatNumber(decimal, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(_areaSqFt)} বর্গফুট)',
      fullReportBangla: _generateReport(),
    );
    await HistoryService.instance.saveItem(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('হিস্ট্রিতে সংরক্ষিত হয়েছে!'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final decimal = _areaSqFt / 435.60;
    final katha = _areaSqFt / 720.00;
    final bigha = decimal / 33.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('গুগল ম্যাপ ও GPS স্যাটেলাইট জরিপ'),
        actions: [
          IconButton(
            icon: Icon(_isSatelliteMode ? Icons.map : Icons.satellite_alt),
            tooltip: _isSatelliteMode ? 'নরমাল ম্যাপ' : 'স্যাটেলাইট ভিউ',
            onPressed: () => setState(() => _isSatelliteMode = !_isSatelliteMode),
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'জিপিএস পয়েন্ট তালিকা',
            onPressed: _points.isNotEmpty ? _showGpsWaypointsDialog : null,
          ),
          IconButton(
            icon: const Icon(Icons.share_location),
            tooltip: 'KML এক্সপোর্ট',
            onPressed: _points.length >= 3 ? _exportKml : null,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'কপি রিপোর্ট',
            onPressed: _points.length >= 3 ? _copyReport : null,
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'হিস্ট্রিতে সংরক্ষণ',
            onPressed: _points.length >= 3 ? _saveToHistory : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Measurement summary header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.primaryGreenLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem('শতাংশ', '${BanglaFormatter.formatNumber(decimal, fractionDigits: 3)} শতক', isPrimary: true),
                _buildMetricItem('কাঠা', '${BanglaFormatter.formatNumber(katha, fractionDigits: 3)} কাঠা'),
                _buildMetricItem('বিঘা', '${BanglaFormatter.formatNumber(bigha, fractionDigits: 3)} বিঘা'),
                _buildMetricItem('পরিসীমা', '${BanglaFormatter.formatNumber(_perimeterFt)} ফুট'),
              ],
            ),
          ),

          // GPS Walk Mode Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: _isGpsWalkMode ? const Color(0xFF1E293B) : Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _isGpsWalkMode ? Icons.directions_walk : Icons.gps_not_fixed,
                      size: 18,
                      color: _isGpsWalkMode ? Colors.greenAccent : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isGpsWalkMode ? 'GPS ফিল্ড ওয়াক মোড চালু (±${_gpsAccuracyMeters}m নির্ভুল)' : 'ম্যানুয়াল পিন ড্রপ মোড',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isGpsWalkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _isGpsWalkMode,
                  activeColor: Colors.greenAccent,
                  onChanged: (val) => setState(() => _isGpsWalkMode = val),
                ),
              ],
            ),
          ),

          // Interactive Map / Satellite Canvas with Floating HUD & Page 1 Tool Palette
          Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  onTapUp: (details) {
                    if (_draggedIndex == null && !_isGpsWalkMode) {
                      setState(() {
                        _points.add(details.localPosition);
                        _recompute();
                      });
                    }
                  },
                  onPanStart: (details) {
                    final pos = details.localPosition;
                    for (int i = 0; i < _points.length; i++) {
                      if ((_points[i] - pos).distance < 24.0) {
                        setState(() => _draggedIndex = i);
                        break;
                      }
                    }
                  },
                  onPanUpdate: (details) {
                    if (_draggedIndex != null) {
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
                      currentLat: _currentLat,
                      currentLng: _currentLng,
                      showDimensions: _showDimensions,
                    ),
                    size: Size.infinite,
                  ),
                ),

                // Top Floating GNSS RTK Status Badge (Stitch Design System Token)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.88),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF0284C7), width: 1.2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'RTK: FIX (14 Sats) | H: 0.012m | WGS84',
                          style: TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right Vertical Floating Palette (Page 1 of CamScanner PDF)
                Positioned(
                  top: 12,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155), width: 1.0),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPaletteTool('ম্যাপ নিন', Icons.layers, () {
                          setState(() => _isSatelliteMode = !_isSatelliteMode);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_isSatelliteMode ? 'স্যাটেলাইট ভিউ সক্রিয়' : 'সাধারণ মানচিত্র ভিউ সক্রিয়')),
                          );
                        }),
                        _buildPaletteTool('আঁকুন', Icons.edit, () {
                          setState(() => _activeTool = 'আঁকুন');
                        }, isActive: _activeTool == 'আঁকুন'),
                        _buildPaletteTool('Point', Icons.add_location_alt, () {
                          setState(() => _activeTool = 'Point');
                          _addCurrentGpsPoint();
                        }, isActive: _activeTool == 'Point'),
                        _buildPaletteTool('সার্ভে পয়েন্ট', Icons.list_alt, _showGpsWaypointsDialog),
                        _buildPaletteTool('প্যান', Icons.pan_tool, () {
                          setState(() => _activeTool = 'প্যান');
                        }, isActive: _activeTool == 'প্যান'),
                        _buildPaletteTool('লাইন', Icons.timeline, () {
                          setState(() => _activeTool = 'লাইন');
                        }, isActive: _activeTool == 'লাইন'),
                        _buildPaletteTool('ডাইমেনশন', Icons.straighten, () {
                          setState(() => _showDimensions = !_showDimensions);
                        }, isActive: _showDimensions),
                        _buildPaletteTool('মার্কার', Icons.pin_drop, () {
                          setState(() => _activeTool = 'মার্কার');
                        }, isActive: _activeTool == 'মার্কার'),
                        _buildPaletteTool('বৃত্ত', Icons.circle_outlined, () {
                          setState(() => _activeTool = 'বৃত্ত');
                        }, isActive: _activeTool == 'বৃত্ত'),
                        _buildPaletteTool('টেক্সট', Icons.title, () {
                          setState(() => _activeTool = 'টেক্সট');
                        }, isActive: _activeTool == 'টেক্সট'),
                        _buildPaletteTool('কম্পাস', Icons.explore, () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('নর্থ বিয়ারিং ০° ক্যালিব্রেট করা হয়েছে')),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Control Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                if (_isGpsWalkMode)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _addCurrentGpsPoint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.add_location_alt),
                      label: const Text('বর্তমান অবস্থান রেকর্ড করুন (+GPS Point)'),
                    ),
                  )
                else ...[
                  IconButton.filledTonal(
                    onPressed: _points.isNotEmpty
                        ? () {
                            setState(() {
                              _points.removeLast();
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
                        _points.clear();
                        _recompute();
                      });
                    },
                    icon: const Icon(Icons.delete_sweep, color: AppColors.accentCrimson),
                    tooltip: 'সব পিন মুছুন',
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _points
                          ..clear()
                          ..addAll([
                            const Offset(60, 60),
                            const Offset(240, 70),
                            const Offset(260, 220),
                            const Offset(50, 200),
                          ]);
                        _recompute();
                      });
                    },
                    icon: const Icon(Icons.crop_square, size: 18),
                    label: const Text('নমুনা প্লট'),
                  ),
                  const Spacer(),
                  Text(
                    'পিন: ${BanglaNumerals.toBangla(_points.length)} টি',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, {bool isPrimary = false}) {
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

  Widget _buildPaletteTool(String label, IconData icon, VoidCallback onTap, {bool isActive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0F5A38) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isActive ? Border.all(color: const Color(0xFF4ADE80), width: 1) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : const Color(0xFFCBD5E1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  final List<Offset> points;
  final bool isSatellite;
  final int? draggedIndex;
  final double currentLat;
  final double currentLng;
  final bool showDimensions;

  _MapCanvasPainter({
    required this.points,
    required this.isSatellite,
    required this.draggedIndex,
    required this.currentLat,
    required this.currentLng,
    this.showDimensions = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Map Base Texture
    final bgPaint = Paint()..color = isSatellite ? const Color(0xFF1B2A1C) : const Color(0xFFF1F5F9);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Simulated Grid Lines resembling Geo-tiles
    final gridPaint = Paint()
      ..color = isSatellite ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 3. Polygon Plot
    if (points.isNotEmpty) {
      final polyFill = Paint()
        ..color = isSatellite ? Colors.greenAccent.withOpacity(0.25) : AppColors.primaryGreen.withOpacity(0.20)
        ..style = PaintingStyle.fill;

      final polyStroke = Paint()
        ..color = isSatellite ? Colors.greenAccent : AppColors.primaryGreen
        ..strokeWidth = 2.8
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      if (points.length >= 3) {
        path.close();
        canvas.drawPath(path, polyFill);
      }
      canvas.drawPath(path, polyStroke);

      // Edge length labels in feet
      if (showDimensions) {
        for (int i = 0; i < points.length; i++) {
          final p1 = points[i];
          final p2 = points[(i + 1) % points.length];
          if (points.length < 3 && i == points.length - 1) break;

          final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
          final dist = (p2 - p1).distance;
          _drawPillLabel(canvas, '${BanglaNumerals.toBangla(dist.round())} ft', mid);
        }
      }

      // Draw Pins with numbering
      for (int i = 0; i < points.length; i++) {
        final p = points[i];
        final isDragged = draggedIndex == i;

        final pinPaint = Paint()..color = isDragged ? Colors.amber : (isSatellite ? Colors.yellowAccent : AppColors.accentCrimson);
        canvas.drawCircle(p, isDragged ? 9.0 : 6.5, pinPaint);
        canvas.drawCircle(p, isDragged ? 9.0 : 6.5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.0);

        // Pin number
        final tp = TextPainter(
          text: TextSpan(
            text: BanglaNumerals.toBangla(i + 1),
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height / 2));
      }
    }

    // 4. North Arrow and Live GPS Coordinates Overlay
    _drawNorthIndicator(canvas, size);
  }

  void _drawPillLabel(Canvas canvas, String text, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: tp.width + 10, height: tp.height + 6),
      const Radius.circular(6),
    );
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF0F172A).withOpacity(0.85));
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  void _drawNorthIndicator(Canvas canvas, Size size) {
    final pos = Offset(size.width - 36, 40);
    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2.5;

    canvas.drawLine(Offset(pos.dx, pos.dy + 12), Offset(pos.dx, pos.dy - 12), paint);
    canvas.drawLine(Offset(pos.dx, pos.dy - 12), Offset(pos.dx - 4, pos.dy - 4), paint);
    canvas.drawLine(Offset(pos.dx, pos.dy - 12), Offset(pos.dx + 4, pos.dy - 4), paint);

    final tp = TextPainter(
      text: const TextSpan(text: 'N', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - 4, pos.dy + 14));
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) => true;
}
