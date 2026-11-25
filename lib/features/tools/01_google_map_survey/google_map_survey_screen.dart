import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/utils/pdf_report_helper.dart';
import '../../../core/services/history_service.dart';
import '../../../core/utils/polygon_geometry.dart';
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

  // Selected vertex and partition split line
  int? _selectedVertexIndex;
  List<LatLngPoint>? _partitionSplitLine;
  final List<List<LatLngPoint>> _undoStack = [];
  final List<List<LatLngPoint>> _redoStack = [];
  bool _hasEditedPolygon = false;

  // Real Device Live GPS State
  LatLngPoint? _userGpsLocation;
  double? _gpsAccuracyMeters;
  bool _isLocatingGps = false;
  StreamSubscription<Position>? _gpsSubscription;

  // Computed metrics
  double _areaSqFt = 0.0;
  double _perimeterFt = 0.0;

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    super.dispose();
  }

  void _recordUndoSnapshot() {
    _undoStack.add(List<LatLngPoint>.from(_surveyPoints));
    if (_undoStack.length > 30) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void _undoPoints() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(List<LatLngPoint>.from(_surveyPoints));
    setState(() {
      _surveyPoints = _undoStack.removeLast();
      _partitionSplitLine = null;
      _recompute();
    });
  }

  void _redoPoints() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(List<LatLngPoint>.from(_surveyPoints));
    setState(() {
      _surveyPoints = _redoStack.removeLast();
      _partitionSplitLine = null;
      _recompute();
    });
  }

  @override
  void initState() {
    super.initState();
    _recompute();
    _fetchLiveLocation(jumpToUser: true, silent: true);
  }

  Future<void> _fetchLiveLocation({bool jumpToUser = true, bool silent = false}) async {
    if (_isLocatingGps) return;
    setState(() => _isLocatingGps = true);

    final res = await LocationService.instance.getCurrentLocation();
    if (!mounted) return;
    setState(() => _isLocatingGps = false);

    if (res.success && res.latitude != null && res.longitude != null) {
      final pt = LatLngPoint(res.latitude!, res.longitude!);
      setState(() {
        _userGpsLocation = pt;
        _gpsAccuracyMeters = res.accuracyMeters;
      });
      if (jumpToUser) {
        _mapController.jumpTo(pt.latitude, pt.longitude, zoom: 18.0);
        // If user hasn't started custom plotting yet, center starter plot or let user plot here
        if (!_hasEditedPolygon && !silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'আপনার বর্তমান GPS অবস্থানে ম্যাপ সেট হয়েছে (±${res.accuracyMeters?.toStringAsFixed(1) ?? "?"} মিটার)',
              ),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
        }
      }
    } else if (!silent && res.errorMessageBangla != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.errorMessageBangla!),
          backgroundColor: AppColors.accentCrimson,
        ),
      );
    }
  }

  void _toggleGpsWalkMode(bool enabled) {
    setState(() => _isGpsWalkMode = enabled);
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    if (enabled) {
      _fetchLiveLocation(jumpToUser: true, silent: false);
      try {
        _gpsSubscription = LocationService.instance.watchPosition().listen((pos) {
          if (!mounted) return;
          final pt = LatLngPoint(pos.latitude, pos.longitude);
          setState(() {
            _userGpsLocation = pt;
            _gpsAccuracyMeters = pos.accuracy;
          });
        }, onError: (_) {});
      } catch (_) {}
    }
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

  static String _toDms(double val, bool isLat) {
    final dir = isLat ? (val >= 0 ? 'N' : 'S') : (val >= 0 ? 'E' : 'W');
    final absVal = val.abs();
    final deg = absVal.floor();
    final minDec = (absVal - deg) * 60;
    final min = minDec.floor();
    final sec = (minDec - min) * 60;
    return "$deg°$min'${sec.toStringAsFixed(1)}\"$dir";
  }

  static double _calculateBearing(LatLngPoint p1, LatLngPoint p2) {
    final lat1 = p1.latitude * math.pi / 180.0;
    final lat2 = p2.latitude * math.pi / 180.0;
    final dLng = (p2.longitude - p1.longitude) * math.pi / 180.0;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    final brng = math.atan2(y, x) * 180.0 / math.pi;
    return (brng + 360.0) % 360.0;
  }

  void _addPointAtCenterReticle() {
    final center = _mapController.currentCenter;
    _recordUndoSnapshot();
    setState(() {
      _surveyPoints.add(center);
      _selectedVertexIndex = _surveyPoints.length - 1;
      _recompute();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'পয়েন্ট ${BanglaNumerals.toBangla(_surveyPoints.length)} যুক্ত হয়েছে! (Lat: ${center.latitude.toStringAsFixed(6)}°, Lng: ${center.longitude.toStringAsFixed(6)}°)',
        ),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addCurrentGpsPoint() {
    final targetPt = _userGpsLocation ?? _mapController.currentCenter;
    final usedRealGps = _userGpsLocation != null;
    _hasEditedPolygon = true;
    _recordUndoSnapshot();
    setState(() {
      _surveyPoints.add(targetPt);
      _selectedVertexIndex = _surveyPoints.length - 1;
      _recompute();
    });
    _mapController.jumpTo(targetPt.latitude, targetPt.longitude, zoom: math.max(_mapController.currentZoom, 18.0));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          usedRealGps
              ? 'লাইভ GPS পিন ${BanglaNumerals.toBangla(_surveyPoints.length)} যুক্ত হয়েছে! (${targetPt.latitude.toStringAsFixed(6)}° N, ±${_gpsAccuracyMeters?.toStringAsFixed(1) ?? "?"}m)'
              : 'ম্যাপ সেন্টার পিন ${BanglaNumerals.toBangla(_surveyPoints.length)} যুক্ত হয়েছে! (${targetPt.latitude.toStringAsFixed(6)}° N)',
        ),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddCustomCoordinateDialog(BuildContext context, {required VoidCallback onAdded}) {
    final latCtrl = TextEditingController(text: _mapController.currentCenter.latitude.toStringAsFixed(6));
    final lngCtrl = TextEditingController(text: _mapController.currentCenter.longitude.toStringAsFixed(6));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_location_alt, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('সরাসরি GPS কোঅর্ডিনেট যোগ করুন', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'WGS84 ডেসিমাল ডিগ্রি ফরম্যাটে অক্ষাংশ (Lat) ও দ্রাঘিমাংশ (Lng) লিখুন:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: latCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'অক্ষাংশ (Latitude - উত্তর N)',
                hintText: 'e.g. 23.8103',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: lngCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'দ্রাঘিমাংশ (Longitude - পূর্ব E)',
                hintText: 'e.g. 90.4125',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
            onPressed: () {
              final lat = double.tryParse(latCtrl.text.trim());
              final lng = double.tryParse(lngCtrl.text.trim());
              if (lat == null || lng == null || !lat.isFinite || !lng.isFinite || lat < 20.0 || lat > 27.0 || lng < 88.0 || lng > 93.0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('সঠিক বাংলাদেশি জিপিএস কোঅর্ডিনেট দিন (Lat: 20°-27°, Lng: 88°-93°)'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final newPt = LatLngPoint(lat, lng);
              _recordUndoSnapshot();
              setState(() {
                _surveyPoints.add(newPt);
                _selectedVertexIndex = _surveyPoints.length - 1;
                _recompute();
              });
              _mapController.jumpTo(lat, lng, zoom: 18.0);
              Navigator.pop(ctx);
              onAdded();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('নতুন জিপিএস পয়েন্ট ${_surveyPoints.length} যুক্ত করা হয়েছে!'),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
            },
            child: const Text('যুক্ত করুন'),
          ),
        ],
      ),
    );
  }

  void _showEditCoordinateDialog(BuildContext context, int index, {required VoidCallback onEdited}) {
    final pt = _surveyPoints[index];
    final latCtrl = TextEditingController(text: pt.latitude.toStringAsFixed(6));
    final lngCtrl = TextEditingController(text: pt.longitude.toStringAsFixed(6));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit_location_alt, color: Color(0xFFD97706)),
            const SizedBox(width: 8),
            Text('পয়েন্ট ${BanglaNumerals.toBangla(index + 1)} কোঅর্ডিনেট এডিট', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'অক্ষাংশ (Latitude)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: lngCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'দ্রাঘিমাংশ (Longitude)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
            onPressed: () {
              final lat = double.tryParse(latCtrl.text.trim());
              final lng = double.tryParse(lngCtrl.text.trim());
              if (lat == null || lng == null || !lat.isFinite || !lng.isFinite || lat < -90.0 || lat > 90.0 || lng < -180.0 || lng > 180.0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('সঠিক WGS84 কোঅর্ডিনেট দিন (Lat: -90° হতে 90°, Lng: -180° হতে 180°)'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              _recordUndoSnapshot();
              setState(() {
                _surveyPoints[index] = LatLngPoint(lat, lng);
                _recompute();
              });
              _mapController.jumpTo(lat, lng, zoom: 18.0);
              Navigator.pop(ctx);
              onEdited();
            },
            child: const Text('সংরক্ষণ'),
          ),
        ],
      ),
    );
  }

  void _showGpsWaypointsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.gps_fixed, color: AppColors.primaryGreen),
                  SizedBox(width: 8),
                  Text('সার্ভে পয়েন্ট ও জিপিএস কোঅর্ডিনেট', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              Text(
                '${BanglaNumerals.toBangla(_surveyPoints.length)} টি পিন',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            height: 380,
            child: _surveyPoints.isEmpty
                ? const Center(child: Text('কোনো সার্ভে পয়েন্ট ড্রপ করা হয়নি।'))
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _surveyPoints.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final p = _surveyPoints[idx];
                      final nextPt = _surveyPoints[(idx + 1) % _surveyPoints.length];
                      final distFeet = EsriSatelliteMapView.haversineFeet(p, nextPt);
                      final bearing = _calculateBearing(p, nextPt);

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primaryGreen,
                          child: Text(
                            BanglaNumerals.toBangla(idx + 1),
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              'পয়েন্ট ${BanglaNumerals.toBangla(idx + 1)}: ',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Flexible(
                              child: Text(
                                '${p.latitude.toStringAsFixed(6)}°, ${p.longitude.toStringAsFixed(6)}°',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF0369A1)),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DMS: ${_toDms(p.latitude, true)}, ${_toDms(p.longitude, false)}',
                              style: const TextStyle(fontSize: 10.5, color: Colors.black87),
                            ),
                            if (_surveyPoints.length >= 2)
                              Text(
                                'বাহুর দৈর্ঘ্য: ${BanglaFormatter.formatNumber(distFeet, fractionDigits: 1)} ft (${BanglaFormatter.formatNumber(distFeet / 0.66, fractionDigits: 0)} link) | বিয়ারিং: ${bearing.toStringAsFixed(0)}°',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.my_location, size: 18, color: Color(0xFF0284C7)),
                              tooltip: 'ম্যাপে জুম করুন',
                              onPressed: () {
                                Navigator.pop(ctx);
                                _mapController.jumpTo(p.latitude, p.longitude, zoom: 18.5);
                                setState(() => _selectedVertexIndex = idx);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: Color(0xFFD97706)),
                              tooltip: 'কোঅর্ডিনেট এডিট',
                              onPressed: () {
                                _showEditCoordinateDialog(context, idx, onEdited: () {
                                  setDialogState(() {});
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              tooltip: 'পয়েন্ট মুছুন',
                              onPressed: () {
                                _recordUndoSnapshot();
                                setState(() {
                                  _surveyPoints.removeAt(idx);
                                  _recompute();
                                });
                                setDialogState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                _showAddCustomCoordinateDialog(context, onAdded: () {
                  setDialogState(() {});
                });
              },
              icon: const Icon(Icons.add_location_alt, size: 16),
              label: const Text('+ নতুন কোঅর্ডিনেট লিখুন'),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বন্ধ করুন')),
          ],
        ),
      ),
    );
  }

  void _showBearingCompassDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.explore, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('কম্পাস ও বাউন্ডারি বিয়ারিং', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: _surveyPoints.length < 2
              ? const Text('বিয়ারিং হিসাবের জন্য কমপক্ষে ২টি সার্ভে পয়েন্ট যুক্ত করুন।')
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Text(
                          'ট্রু নর্থ রেফারেন্স: ০° (EPSG:3857 Web Mercator)\nবর্তমান ম্যাপ সেন্টার: ${_mapController.currentCenter.latitude.toStringAsFixed(6)}° N, ${_mapController.currentCenter.longitude.toStringAsFixed(6)}° E',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(_surveyPoints.length, (i) {
                        final p1 = _surveyPoints[i];
                        final p2 = _surveyPoints[(i + 1) % _surveyPoints.length];
                        final distFt = EsriSatelliteMapView.haversineFeet(p1, p2);
                        final bearing = _calculateBearing(p1, p2);
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFF0F172A),
                            child: Text(
                              '${BanglaNumerals.toBangla(i + 1)}→${BanglaNumerals.toBangla(((i + 1) % _surveyPoints.length) + 1)}',
                              style: const TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            'দৈর্ঘ্য: ${BanglaFormatter.formatNumber(distFt, fractionDigits: 1)} ft (${BanglaFormatter.formatNumber(distFt / 0.66, fractionDigits: 0)} link)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          subtitle: Text(
                            'ট্রু নর্থ আজিমুথ বিয়ারিং: ${BanglaNumerals.toBangla(bearing.toStringAsFixed(1))}°',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF0369A1)),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (_surveyPoints.isNotEmpty) {
                double avgLat = 0, avgLng = 0;
                for (final p in _surveyPoints) {
                  avgLat += p.latitude;
                  avgLng += p.longitude;
                }
                _mapController.jumpTo(
                  avgLat / _surveyPoints.length,
                  avgLng / _surveyPoints.length,
                  zoom: _mapController.currentZoom,
                );
              }
            },
            child: const Text('প্লট সেন্টারে যান'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বন্ধ করুন')),
        ],
      ),
    );
  }

  void _showPlotDivisionDialog() {
    if (_surveyPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('বণ্টন করার জন্য কমপক্ষে ৩টি সার্ভে পয়েন্ট দিয়ে প্লট তৈরি করুন।')),
      );
      return;
    }

    final decimal = _areaSqFt / 435.60;
    final katha = _areaSqFt / 720.00;

    double splitRatio = 0.50; // 50:50 default
    bool horizontalCut = true; // true = North-South boundary split (horizontal line), false = East-West

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final share1Dec = decimal * splitRatio;
          final share1SqFt = _areaSqFt * splitRatio;
          final share1Katha = katha * splitRatio;

          final share2Dec = decimal * (1.0 - splitRatio);
          final share2SqFt = _areaSqFt * (1.0 - splitRatio);
          final share2Katha = katha * (1.0 - splitRatio);

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.pie_chart, color: AppColors.primaryGreen),
                SizedBox(width: 8),
                Flexible(
                  child: Text('জমি বণ্টন ও প্লট বিভাজন (অংশীদার)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('মোট পরিমাপকৃত জমি:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Flexible(
                          child: Text(
                            '${BanglaFormatter.formatNumber(decimal, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(_areaSqFt, fractionDigits: 0)} sq ft)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.primaryGreenDark),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('বণ্টনের অনুপাত নির্বাচন করুন:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ChoiceChip(
                        label: const Text('৫০ : ৫০'),
                        selected: (splitRatio - 0.50).abs() < 0.01,
                        onSelected: (_) => setModalState(() => splitRatio = 0.50),
                      ),
                      ChoiceChip(
                        label: const Text('৬০ : ৪০'),
                        selected: (splitRatio - 0.60).abs() < 0.01,
                        onSelected: (_) => setModalState(() => splitRatio = 0.60),
                      ),
                      ChoiceChip(
                        label: const Text('৭০ : ৩০'),
                        selected: (splitRatio - 0.70).abs() < 0.01,
                        onSelected: (_) => setModalState(() => splitRatio = 0.70),
                      ),
                    ],
                  ),
                  Slider(
                    value: splitRatio,
                    min: 0.10,
                    max: 0.90,
                    divisions: 80,
                    activeColor: AppColors.primaryGreen,
                    label: '${(splitRatio * 100).round()}% : ${(100 - splitRatio * 100).round()}%',
                    onChanged: (v) => setModalState(() => splitRatio = v),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('কাটলাইনের দিক: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Expanded(
                        child: DropdownButton<bool>(
                          isExpanded: true,
                          value: horizontalCut,
                          items: const [
                            DropdownMenuItem(value: true, child: Text('উত্তর-দক্ষিণ বিভাজন (পূর্ব-পশ্চিম রেখা)', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: false, child: Text('পূর্ব-পশ্চিম বিভাজন (উত্তর-দক্ষিণ রেখা)', style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (v) {
                            if (v != null) setModalState(() => horizontalCut = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Shares Breakdown Card
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(width: 10, height: 10, color: const Color(0xFF0284C7)),
                                const SizedBox(width: 6),
                                Text(
                                  'অংশীদার ১ (${BanglaNumerals.toBangla((splitRatio * 100).round())}%):',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                            Text(
                              '${BanglaFormatter.formatNumber(share1Dec, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(share1Katha, fractionDigits: 2)} কাঠা)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0284C7)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${BanglaFormatter.formatNumber(share1SqFt, fractionDigits: 0)} বর্গফুট',
                            style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                          ),
                        ),
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(width: 10, height: 10, color: const Color(0xFFF59E0B)),
                                const SizedBox(width: 6),
                                Text(
                                  'অংশীদার ২ (${BanglaNumerals.toBangla((100 - splitRatio * 100).round())}%):',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                            Text(
                              '${BanglaFormatter.formatNumber(share2Dec, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(share2Katha, fractionDigits: 2)} কাঠা)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFD97706)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${BanglaFormatter.formatNumber(share2SqFt, fractionDigits: 0)} বর্গফুট',
                            style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (_partitionSplitLine != null)
                TextButton(
                  onPressed: () {
                    setState(() => _partitionSplitLine = null);
                    Navigator.pop(ctx);
                  },
                  child: const Text('বণ্টন রেখা মুছুন', style: TextStyle(color: Colors.red)),
                ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // Project LatLngPoints to Mercator pixels at z=20 for exact area bisection
                  const double projZoom = 20.0;
                  final worldPts = _surveyPoints
                      .map((p) => EsriSatelliteMapView.latLngToWorldPixels(p.latitude, p.longitude, projZoom))
                      .toList();
                  final totalWorldArea = PolygonGeometry.calculateArea(worldPts);
                  final bisection = PolygonGeometry.findAreaBisectionCutLine(
                    polygon: worldPts,
                    targetArea: totalWorldArea * splitRatio,
                    horizontalCut: horizontalCut,
                    fromStart: true,
                  );

                  if (bisection != null) {
                    final llStart = EsriSatelliteMapView.worldPixelsToLatLng(
                      bisection.cutStart.dx,
                      bisection.cutStart.dy,
                      projZoom,
                    );
                    final llEnd = EsriSatelliteMapView.worldPixelsToLatLng(
                      bisection.cutEnd.dx,
                      bisection.cutEnd.dy,
                      projZoom,
                    );
                    setState(() {
                      _partitionSplitLine = [llStart, llEnd];
                    });
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'ম্যাপে সঠিক ক্ষেত্রফল-ভিত্তিক বণ্টন রেখা অঙ্কন হয়েছে! অংশ ১: ${BanglaFormatter.formatNumber(share1Dec, fractionDigits: 2)} শতক, অংশ ২: ${BanglaFormatter.formatNumber(share2Dec, fractionDigits: 2)} শতক',
                      ),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('ম্যাপে বণ্টন দেখান'),
              ),
            ],
          );
        },
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

  Future<void> _exportPdf() async {
    final decimal = _areaSqFt / 435.60;
    final katha = _areaSqFt / 720.00;
    final bigha = decimal / 33.0;
    final esc = PdfReportHelper.escapeHtml;

    final rows = _surveyPoints.asMap().entries.map((e) {
      return '<tr><td>পিন ${esc(BanglaNumerals.toBangla(e.key + 1))}</td><td>${e.value.latitude.toStringAsFixed(6)}°</td><td>${e.value.longitude.toStringAsFixed(6)}°</td></tr>';
    }).join();

    final bodyHtml = '''
      <div class="kpi-grid">
        <div class="kpi-box"><div class="kpi-label">শতক (Decimal)</div><div class="kpi-val">${esc(BanglaFormatter.formatNumber(decimal, fractionDigits: 3))} শতক</div></div>
        <div class="kpi-box"><div class="kpi-label">কাঠা (Katha)</div><div class="kpi-val">${esc(BanglaFormatter.formatNumber(katha, fractionDigits: 2))} কাঠা</div></div>
        <div class="kpi-box"><div class="kpi-label">বিঘা / বর্গফুট</div><div class="kpi-val">${esc(BanglaFormatter.formatNumber(bigha, fractionDigits: 3))} বিঘা</div></div>
      </div>
      <div class="info-panel">
        <strong>মোট ক্ষেত্রফল:</strong> ${esc(BanglaFormatter.formatNumber(_areaSqFt, fractionDigits: 2))} বর্গফুট •
        <strong>মোট পরিসীমা:</strong> ${esc(BanglaFormatter.formatNumber(_perimeterFt, fractionDigits: 1))} ফুট •
        <strong>পয়েন্ট সংখ্যা:</strong> ${esc(BanglaNumerals.toBangla(_surveyPoints.length))} টি (WGS84)
      </div>
      <h3 class="section-title">জরিপকৃত সীমানা ওয়েপয়েন্ট তালিকা (WGS84)</h3>
      <table>
        <tr><th>ক্রমিক পিন</th><th>অক্ষাংশ (Latitude)</th><th>দ্রাঘিমাংশ (Longitude)</th></tr>
        $rows
      </table>
    ''';

    final html = PdfReportHelper.buildCadastralHtmlDocument(
      title: 'BDLandPro স্যাটেলাইট ও GPS ভূমি জরিপ প্রত্যয়নপত্র',
      subtitle: 'তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())} • ESRI / Mapbox GeoDesic WGS84',
      badgeText: '${BanglaFormatter.formatNumber(decimal, fractionDigits: 2)} শতক',
      bodyHtml: bodyHtml,
    );

    await PdfReportHelper.printHtmlPdf(
      html: html,
      jobName: 'BDLandPro_GPS_Survey_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
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
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'A4 PDF প্রত্যয়ন',
            onPressed: _surveyPoints.length >= 3 ? _exportPdf : null,
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
          // 1. Measurement summary header (multi-metric scrollable HUD)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppColors.primaryGreenLight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildMetricItem('শতাংশ', '${BanglaFormatter.formatNumber(decimal, fractionDigits: 3)} শতক', isPrimary: true),
                  const SizedBox(width: 14),
                  _buildMetricItem('কাঠা', '${BanglaFormatter.formatNumber(katha, fractionDigits: 3)} কাঠা'),
                  const SizedBox(width: 14),
                  _buildMetricItem('বিঘা', '${BanglaFormatter.formatNumber(bigha, fractionDigits: 3)} বিঘা'),
                  const SizedBox(width: 14),
                  _buildMetricItem('একর', '${BanglaFormatter.formatNumber(decimal / 100.0, fractionDigits: 4)} একর'),
                  const SizedBox(width: 14),
                  _buildMetricItem('বর্গফুট', '${BanglaFormatter.formatNumber(_areaSqFt, fractionDigits: 1)} sq ft'),
                  const SizedBox(width: 14),
                  _buildMetricItem('পরিসীমা', '${BanglaFormatter.formatNumber(_perimeterFt, fractionDigits: 1)} ft (${BanglaFormatter.formatNumber(_perimeterFt / 0.66, fractionDigits: 0)} link)'),
                ],
              ),
            ),
          ),

          // 2. Reticle Pin Drop vs Manual Draw Mode Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: _isGpsWalkMode ? const Color(0xFF1E293B) : Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        _isGpsWalkMode ? Icons.center_focus_strong : Icons.touch_app,
                        size: 18,
                        color: _isGpsWalkMode ? Colors.greenAccent : AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _isGpsWalkMode
                              ? 'সেন্টার টার্গেট মোড চালু (ক্রসহেয়ার অনুযায়ী পিন দিন)'
                              : 'ম্যানুয়াল পিন ড্রপ ও স্যাটেলাইট মেজারমেন্ট',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isGpsWalkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isGpsWalkMode,
                  activeColor: Colors.greenAccent,
                  onChanged: _toggleGpsWalkMode,
                ),
              ],
            ),
          ),

          // 3. Live ESRI/Mapbox Satellite Slippy Tile Canvas with Floating HUD & Tool Palette
          Expanded(
            child: Stack(
              children: [
                // Live Satellite Tile Engine
                EsriSatelliteMapView(
                  controller: _mapController,
                  surveyPoints: _surveyPoints,
                  onDragBegin: () {
                    _hasEditedPolygon = true;
                    _recordUndoSnapshot();
                  },
                  onPointsChanged: (pts) {
                    _hasEditedPolygon = true;
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
                  showControls: false,
                  showCenterReticle: _isGpsWalkMode || _activeTool == 'Point',
                  showNudgeDpad: true,
                  partitionSplitLine: _partitionSplitLine,
                  userLocation: _userGpsLocation,
                  userAccuracyMeters: _gpsAccuracyMeters,
                  onVertexSelected: (idx) => setState(() => _selectedVertexIndex = idx),
                ),

                // Top Floating Map & Survey Telemetry HUD
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xE00F172A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _userGpsLocation != null ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Color(0x4D000000), blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _userGpsLocation != null ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _userGpsLocation != null
                              ? 'GPS সক্রিয় (±${_gpsAccuracyMeters?.toStringAsFixed(0) ?? "?"}m) • ${_surveyPoints.length} পিন'
                              : 'ম্যানুয়াল মোড • ${_surveyPoints.length} পিন • ESRI/Mapbox',
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right Vertical Floating Palette
                Positioned(
                  top: 12,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xEB0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155), width: 1.0),
                      boxShadow: const [
                        BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 4)),
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
                          _addPointAtCenterReticle();
                        }, isActive: _activeTool == 'Point'),
                        _buildPaletteTool('সার্ভে পয়েন্ট', Icons.list_alt, _showGpsWaypointsDialog),
                        _buildPaletteTool('প্যান', Icons.pan_tool, () {
                          setState(() => _activeTool = 'প্যান');
                        }, isActive: _activeTool == 'প্যান'),
                        _buildPaletteTool('ডাইমেনশন', Icons.straighten, () {
                          setState(() => _showDimensions = !_showDimensions);
                        }, isActive: _showDimensions),
                        _buildPaletteTool('বিভাগ', Icons.pie_chart, _showPlotDivisionDialog),
                        _buildPaletteTool('কম্পাস', Icons.explore, _showBearingCompassDialog),
                      ],
                    ),
                  ),
                ),

                // My Location GPS + Zoom Buttons on bottom-right of map
                Positioned(
                  bottom: 16,
                  right: 12,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'survey_my_gps',
                        backgroundColor: _userGpsLocation != null ? const Color(0xFF0F5A38) : const Color(0xE60F172A),
                        foregroundColor: Colors.white,
                        onPressed: () => _fetchLiveLocation(jumpToUser: true, silent: false),
                        tooltip: 'আমার বর্তমান GPS অবস্থান',
                        child: _isLocatingGps
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.my_location, size: 20),
                      ),
                      const SizedBox(height: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      label: const Text('ক্রসহেয়ার পয়েন্ট যুক্ত করুন (+Point)'),
                    ),
                  )
                else ...[
                  IconButton.filledTonal(
                    onPressed: _undoStack.isNotEmpty
                        ? _undoPoints
                        : (_surveyPoints.isNotEmpty
                            ? () {
                                _recordUndoSnapshot();
                                setState(() {
                                  _surveyPoints.removeLast();
                                  _recompute();
                                });
                              }
                            : null),
                    icon: const Icon(Icons.undo),
                    tooltip: 'পূর্বাবস্থা (Undo)',
                  ),
                  const SizedBox(width: 4),
                  if (_redoStack.isNotEmpty) ...[
                    IconButton.filledTonal(
                      onPressed: _redoPoints,
                      icon: const Icon(Icons.redo),
                      tooltip: 'পুনরাবৃত্তি (Redo)',
                    ),
                    const SizedBox(width: 4),
                  ],
                  IconButton.filledTonal(
                    onPressed: _surveyPoints.isNotEmpty
                        ? () {
                            _recordUndoSnapshot();
                            setState(() {
                              _surveyPoints.clear();
                              _partitionSplitLine = null;
                              _selectedVertexIndex = null;
                              _recompute();
                            });
                          }
                        : null,
                    icon: const Icon(Icons.delete_sweep, color: AppColors.accentCrimson),
                    tooltip: 'সব পিন মুছুন',
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    onPressed: () {
                      _recordUndoSnapshot();
                      setState(() {
                        _surveyPoints = [
                          const LatLngPoint(23.8115, 90.4120),
                          const LatLngPoint(23.8115, 90.4132),
                          const LatLngPoint(23.8105, 90.4133),
                          const LatLngPoint(23.8105, 90.4119),
                        ];
                        _partitionSplitLine = null;
                        _selectedVertexIndex = null;
                        _recompute();
                        _mapController.jumpTo(23.8110, 90.4126, zoom: 17.0);
                      });
                    },
                    icon: const Icon(Icons.crop_square, size: 16),
                    label: const Text('নমুনা প্লট', style: TextStyle(fontSize: 12)),
                  ),
                  const Spacer(),
                  Text(
                    _selectedVertexIndex != null
                        ? 'পিন ${BanglaNumerals.toBangla(_selectedVertexIndex! + 1)} নির্বাচিত'
                        : 'পিন: ${BanglaNumerals.toBangla(_surveyPoints.length)} টি',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
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
