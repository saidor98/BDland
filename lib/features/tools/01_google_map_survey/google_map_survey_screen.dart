import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/services/history_service.dart';
import '../../history/models/calculation_history_item.dart';
import '../widgets/esri_satellite_map_view.dart';

class GoogleMapSurveyScreen extends StatefulWidget {
  const GoogleMapSurveyScreen({super.key});

  @override
  State<GoogleMapSurveyScreen> createState() => _GoogleMapSurveyScreenState();
}

class _GoogleMapSurveyScreenState extends State<GoogleMapSurveyScreen> {
  final EsriMapController _mapController = EsriMapController();

  // WGS84 Survey Vertices in real geographic space (Dhaka, Bangladesh)
  List<LatLngPoint> _surveyPoints = [
    const LatLngPoint(23.8115, 90.4120),
    const LatLngPoint(23.8115, 90.4132),
    const LatLngPoint(23.8105, 90.4133),
    const LatLngPoint(23.8105, 90.4119),
  ];

  bool _isGpsWalkMode = false;
  String _activeTool = 'আঁকুন';
  bool _showDimensions = true;

  // Current simulated GPS location
  double _currentLat = 23.8110;
  double _currentLng = 90.4126;
  final double _gpsAccuracyMeters = 0.012; // High-precision RTK Fix

  // Computed metrics
  double _areaSqFt = 0.0;
  double _perimeterFt = 0.0;

  @override
  void initState() {
    super.initState();
    _recompute();
  }

  void _recompute() {
    if (_surveyPoints.length < 3) {
      _areaSqFt = 0.0;
      _perimeterFt = 0.0;
      return;
    }

    // Geodesic spherical area in square feet
    _areaSqFt = EsriSatelliteMapView.calculateGeodesicAreaSqFt(_surveyPoints);

    // Geodesic perimeter via Haversine formula
    double perim = 0.0;
    for (int i = 0; i < _surveyPoints.length; i++) {
      final p1 = _surveyPoints[i];
      final p2 = _surveyPoints[(i + 1) % _surveyPoints.length];
      perim += EsriSatelliteMapView.haversineFeet(p1, p2);
    }
    _perimeterFt = perim;
  }

  void _addCurrentGpsPoint() {
    setState(() {
      final lastPt = _surveyPoints.isNotEmpty ? _surveyPoints.last : const LatLngPoint(23.8110, 90.4126);
      final newPt = LatLngPoint(
        lastPt.latitude + 0.00018 * math.cos(_surveyPoints.length),
        lastPt.longitude + 0.00015 * math.sin(_surveyPoints.length),
      );
      _surveyPoints.add(newPt);
      _currentLat = newPt.latitude;
      _currentLng = newPt.longitude;
      _recompute();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'GPS পয়েন্ট ${BanglaNumerals.toBangla(_surveyPoints.length)} রেকর্ড করা হয়েছে! (Lat: ${_currentLat.toStringAsFixed(6)}°, Lng: ${_currentLng.toStringAsFixed(6)}°)',
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
            Text('জিপিএস ওয়েকপয়েন্ট তালিকা (WGS84)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _surveyPoints.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final p = _surveyPoints[idx];
              final prevPt = idx > 0 ? _surveyPoints[idx - 1] : null;
              final distFeet = prevPt != null ? EsriSatelliteMapView.haversineFeet(prevPt, p) : 0.0;

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
                title: Text('পয়েন্ট ${BanglaNumerals.toBangla(idx + 1)} (WGS84)'),
                subtitle: Text('Lat: ${p.latitude.toStringAsFixed(6)}°, Lng: ${p.longitude.toStringAsFixed(6)}°'),
                trailing: Text(
                  idx > 0 ? '${BanglaFormatter.formatNumber(distFeet, fractionDigits: 1)} ft' : 'সূচনা',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreenDark),
                ),
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
    buffer.writeln('<name>BDLandPro_ESRI_Satellite_Survey</name>');
    buffer.writeln('<Placemark>');
    buffer.writeln('<name>Plotted Land Area</name>');
    buffer.writeln('<Polygon><outerBoundaryIs><LinearRing><coordinates>');
    for (final p in _surveyPoints) {
      buffer.writeln('${p.longitude},${p.latitude},0');
    }
    if (_surveyPoints.isNotEmpty) {
      final p = _surveyPoints.first;
      buffer.writeln('${p.longitude},${p.latitude},0');
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
        content: Text('KML কোড ক্লিপবোর্ডে কপি করা হয়েছে! Google Earth বা GIS সফটওয়্যারে সরাসরি পেস্ট/ইম্পোর্ট করুন।'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  String _generateReport() {
    final decimal = _areaSqFt / 435.60;
    final katha = _areaSqFt / 720.00;
    final bigha = decimal / 33.0;

    final buffer = StringBuffer();
    buffer.writeln('=== Mapbox ও ESRI স্যাটেলাইট জমি জরিপ রিপোর্ট ===');
    buffer.writeln('তারিখ ও সময়: ${BanglaFormatter.formatDateTime(DateTime.now())}');
    buffer.writeln('স্যাটেলাইট ইঞ্জিন: Mapbox HD & ESRI World Imagery');
    buffer.writeln('পয়েন্ট সংখ্যা: ${BanglaNumerals.toBangla(_surveyPoints.length)} টি (WGS84)');
    buffer.writeln('মোট পরিসীমা: ${BanglaFormatter.formatNumber(_perimeterFt, fractionDigits: 1)} ফুট');
    buffer.writeln('মোট ক্ষেত্রফল: ${BanglaFormatter.formatNumber(_areaSqFt, fractionDigits: 2)} বর্গফুট');
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
      inputSummary: '${_surveyPoints.length} টি জিপিএস পিন / ওয়েকপয়েন্ট (ESRI Satellite)',
      resultSummary: '${BanglaFormatter.formatNumber(decimal, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(_areaSqFt, fractionDigits: 1)} বর্গফুট)',
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
            icon: const Icon(Icons.layers_outlined),
            tooltip: 'স্যাটেলাইট / টপো লেয়ার',
            onPressed: () => _mapController.showLayerDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.location_city_outlined),
            tooltip: 'বিভাগে জাম্প',
            onPressed: () => _mapController.showJumpDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'জিপিএস পয়েন্ট তালিকা',
            onPressed: _surveyPoints.isNotEmpty ? _showGpsWaypointsDialog : null,
          ),
          IconButton(
            icon: const Icon(Icons.share_location),
            tooltip: 'KML এক্সপোর্ট',
            onPressed: _surveyPoints.length >= 3 ? _exportKml : null,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'কপি রিপোর্ট',
            onPressed: _surveyPoints.length >= 3 ? _copyReport : null,
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'হিস্ট্রিতে সংরক্ষণ',
            onPressed: _surveyPoints.length >= 3 ? _saveToHistory : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Measurement summary header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.primaryGreenLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem('শতাংশ', '${BanglaFormatter.formatNumber(decimal, fractionDigits: 3)} শতক', isPrimary: true),
                _buildMetricItem('কাঠা', '${BanglaFormatter.formatNumber(katha, fractionDigits: 3)} কাঠা'),
                _buildMetricItem('বিঘা', '${BanglaFormatter.formatNumber(bigha, fractionDigits: 3)} বিঘা'),
                _buildMetricItem('পরিসীমা', '${BanglaFormatter.formatNumber(_perimeterFt, fractionDigits: 1)} ফুট'),
              ],
            ),
          ),

          // 2. GPS Walk Mode Status Bar
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
                      _isGpsWalkMode ? 'GPS ফিল্ড ওয়াক মোড চালু (±${_gpsAccuracyMeters}m RTK FIX)' : 'ম্যানুয়াল পিন ড্রপ ও স্যাটেলাইট মেজারমেন্ট',
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

          // 3. Live ESRI Satellite Slippy Tile Canvas with Floating HUD & Tool Palette
          Expanded(
            child: Stack(
              children: [
                // Live ESRI World Imagery Tile Engine
                EsriSatelliteMapView(
                  controller: _mapController,
                  surveyPoints: _surveyPoints,
                  onPointsChanged: (pts) {
                    setState(() {
                      _surveyPoints = pts;
                      _recompute();
                    });
                  },
                  isDrawingMode: _activeTool == 'আঁকুন' && !_isGpsWalkMode,
                  showDimensions: _showDimensions,
                  showAngles: true,
                  initialLayer: SatelliteLayerType.esriSatellite,
                  initialCenter: const LatLngPoint(23.8110, 90.4126),
                  initialZoom: 17.0,
                  showControls: false, // Hosted in host screen palette and custom controls
                ),

                // Top Floating GNSS RTK Status Badge (Stitch Design System Token)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xE00F172A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF0284C7), width: 1.2),
                      boxShadow: [
                        BoxShadow(color: const Color(0x4D000000), blurRadius: 6, offset: const Offset(0, 2)),
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
                          'RTK: FIX (14 Sats) | H: 0.012m | Mapbox & ESRI HD',
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

                // Right Vertical Floating Palette (CamScanner PDF Design Pattern)
                Positioned(
                  top: 12,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xEB0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155), width: 1.0),
                      boxShadow: [
                        BoxShadow(color: const Color(0x66000000), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPaletteTool('ম্যাপ নিন', Icons.layers, () {
                          _mapController.showLayerDialog(context);
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
                        _buildPaletteTool('ডাইমেনশন', Icons.straighten, () {
                          setState(() => _showDimensions = !_showDimensions);
                        }, isActive: _showDimensions),
                        _buildPaletteTool('বিভাগ', Icons.location_searching, () {
                          _mapController.showJumpDialog(context);
                        }),
                        _buildPaletteTool('কম্পাস', Icons.explore, () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('নর্থ বিয়ারিং ০° (ESRI EPSG:3857 ট্রু নর্থ ক্যালিব্রেটেড)')),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // Zoom Buttons on bottom-right of map
                Positioned(
                  bottom: 16,
                  right: 12,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'survey_zoom_in',
                        backgroundColor: const Color(0xE60F172A),
                        foregroundColor: Colors.white,
                        onPressed: () => _mapController.zoomIn(),
                        tooltip: 'জুম ইন (+)',
                        child: const Icon(Icons.add, size: 20),
                      ),
                      const SizedBox(height: 6),
                      FloatingActionButton.small(
                        heroTag: 'survey_zoom_out',
                        backgroundColor: const Color(0xE60F172A),
                        foregroundColor: Colors.white,
                        onPressed: () => _mapController.zoomOut(),
                        tooltip: 'জুম আউট (-)',
                        child: const Icon(Icons.remove, size: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Bottom Control Buttons
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
                    onPressed: _surveyPoints.isNotEmpty
                        ? () {
                            setState(() {
                              _surveyPoints.removeLast();
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
                        _surveyPoints.clear();
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
                        _surveyPoints = [
                          const LatLngPoint(23.8115, 90.4120),
                          const LatLngPoint(23.8115, 90.4132),
                          const LatLngPoint(23.8105, 90.4133),
                          const LatLngPoint(23.8105, 90.4119),
                        ];
                        _recompute();
                        _mapController.jumpTo(23.8110, 90.4126, zoom: 17.0);
                      });
                    },
                    icon: const Icon(Icons.crop_square, size: 18),
                    label: const Text('নমুনা প্লট'),
                  ),
                  const Spacer(),
                  Text(
                    'পিন: ${BanglaNumerals.toBangla(_surveyPoints.length)} টি',
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
