import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/services/device_file_service.dart';
import '../../../core/services/history_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/utils/pdf_report_helper.dart';
import '../../../core/utils/polygon_geometry.dart';
import '../../history/models/calculation_history_item.dart';
import '../01_google_map_survey/google_map_survey_screen.dart';
import '../06_all_mouza_maps/all_mouza_maps_screen.dart';
import '../widgets/digital_gunia_scale.dart';
import '../widgets/mouza_sheet_image.dart';
import '../widgets/touch_magnifier_loupe.dart';

enum MouzaViewMode { portal, cad }

class MouzaMapSimpleScreen extends StatefulWidget {
  final String? initialMouzaName;
  final String? initialSheetNo;
  final String? initialJlNo;
  final List<Offset>? initialPoints;
  final String? initialImageUrl;

  const MouzaMapSimpleScreen({
    super.key,
    this.initialMouzaName,
    this.initialSheetNo,
    this.initialJlNo,
    this.initialPoints,
    this.initialImageUrl,
  });

  @override
  State<MouzaMapSimpleScreen> createState() => _MouzaMapSimpleScreenState();
}

class _MouzaMapSimpleScreenState extends State<MouzaMapSimpleScreen> {
  // Current active mode: Portal (Image 5) or CAD Canvas (Image 3)
  MouzaViewMode _viewMode = MouzaViewMode.portal;

  // Active Project & Sheet Info
  String _activeMouza = 'মৌজা: আমিনপুর (জে.এল. ৩৪)';
  String _activeSheet = 'শিট ১';
  String _selectedScale = '১৬" = ১ মাইল';
  double _feetPerPixel = 1.0; // 1.0 gives 200.0', 161.2', 240.8', 141.4', 33,000 sq ft
  bool _isHighQuality = true;
  bool _highContrast = false;
  bool _showScannedSheet = true;
  double _sheetOpacity = 0.85;
  String? _customSheetImageUrl;

  // Interactive Zoom & Pan for inspecting and measuring tiny Mouza plots
  final TransformationController _transformationController = TransformationController();
  bool _isZoomPanMode = false;
  bool _dragSnapshotSaved = false;
  double _canvasZoom = 1.0;

  // Real device GPS reading for Mouza reference dialog
  DeviceLocationResult? _lastGpsResult;
  bool _isFetchingGps = false;

  Widget _buildSheetErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade400),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined, color: Colors.redAccent, size: 40),
            const SizedBox(height: 10),
            Text(
              'নকশা শিট লোড ব্যর্থ হয়েছে ($_activeSheet)',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'সার্ভার সংযোগ বিচ্ছিন্ন বা নির্দিষ্ট শিটটি পাওয়া যায়নি।',
              style: TextStyle(color: Colors.grey, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('পুনরায় চেষ্টা করুন (Retry)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapBackgroundLayer() {
    if (!_showScannedSheet) {
      return Container(
        color: _highContrast ? Colors.white : const Color(0xFF0F172A),
      );
    }

    final src = _customSheetImageUrl ?? 'assets/mouza_maps/sample_mouza_sheet_1.jpg';

    return Container(
      color: _highContrast ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
      child: Opacity(
        opacity: _sheetOpacity.clamp(0.1, 1.0),
        child: Center(
          child: MouzaSheetImage(
            source: src,
            fit: BoxFit.contain,
            errorFallback: _buildSheetErrorState(),
          ),
        ),
      ),
    );
  }

  void _setCanvasZoom(double nextScale, Size viewportSize) {
    final clamped = nextScale.clamp(0.8, 8.0);
    final current = _transformationController.value;
    final currentScale = current.getMaxScaleOnAxis();
    if (currentScale <= 0) return;
    final center = Offset(viewportSize.width / 2.0, viewportSize.height / 2.0);
    final sceneCenter = _transformationController.toScene(center);
    final updated = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..scale(clamped)
      ..translate(-sceneCenter.dx, -sceneCenter.dy);
    _transformationController.value = updated;
    setState(() => _canvasZoom = clamped);
  }

  void _resetCanvasZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() => _canvasZoom = 1.0);
  }

  Future<void> _pickCustomDeviceSheet() async {
    final picked = await DeviceFileService.instance.pickMouzaSheet();
    if (!mounted) return;
    if (picked == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কোনো ফাইল নির্বাচন করা হয়নি')),
      );
      return;
    }
    setState(() {
      _activeMouza = 'ডিভাইস: ${picked.name}';
      _activeSheet = picked.isPdf ? 'কাস্টম PDF' : 'কাস্টম ইমেজ';
      _customSheetImageUrl = picked.path;
      _showScannedSheet = true;
      _viewMode = MouzaViewMode.cad;
      _transformationController.value = Matrix4.identity();
      _canvasZoom = 1.0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${picked.name} CAD ক্যানভাসে লোড হয়েছে!'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  static String _toDmsString(double val, bool isLat) {
    final dir = isLat ? (val >= 0 ? 'N' : 'S') : (val >= 0 ? 'E' : 'W');
    final absVal = val.abs();
    final deg = absVal.floor();
    final minDec = (absVal - deg) * 60;
    final min = minDec.floor();
    final sec = (minDec - min) * 60;
    return "$deg° $min' ${sec.toStringAsFixed(1)}\" $dir";
  }

  Future<void> _showGpsLocationDialog() async {
    setState(() => _isFetchingGps = true);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          if (_isFetchingGps) {
            LocationService.instance.getCurrentLocation().then((res) {
              if (!mounted) return;
              setState(() {
                _lastGpsResult = res;
                _isFetchingGps = false;
              });
              try {
                setDlgState(() {});
              } catch (_) {}
            });
          }

          final res = _lastGpsResult;
          final hasLoc = res != null && res.success && res.latitude != null && res.longitude != null;

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.gps_fixed, color: AppColors.primaryGreen),
                SizedBox(width: 8),
                Flexible(
                  child: Text('ডিভাইস GPS ও ভৌগোলিক অবস্থান', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isFetchingGps)
                  const Row(
                    children: [
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 10),
                      Expanded(child: Text('ফোনের GPS স্যাটেলাইট থেকে অবস্থান নেওয়া হচ্ছে...', style: TextStyle(fontSize: 12))),
                    ],
                  )
                else if (hasLoc) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Text(
                      'লাইভ ডিভাইস GPS সংযুক্ত (±${res.accuracyMeters?.toStringAsFixed(1) ?? "?"} মিটার)',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '• অক্ষাংশ (Lat): ${res.latitude!.toStringAsFixed(6)}°\n'
                    '• দ্রাঘিমাংশ (Lng): ${res.longitude!.toStringAsFixed(6)}°\n'
                    '• DMS: ${_toDmsString(res.latitude!, true)}, ${_toDmsString(res.longitude!, false)}',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B), height: 1.5),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(
                      res?.errorMessageBangla ?? 'GPS অবস্থান পাওয়া যায়নি। ফোনের লোকেশন চালু করে আবার চেষ্টা করুন।',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF991B1B)),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                const Text(
                  'টিপস: স্যাটেলাইট ম্যাপে সরাসরি আপনার জায়গায় পিন বসাতে নিচের "গুগল ম্যাপে খুলুন" চাপুন।',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setDlgState(() => _isFetchingGps = true);
                },
                child: const Text('রিফ্রেশ'),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বন্ধ করুন')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const GoogleMapSurveyScreen()),
                  );
                },
                icon: const Icon(Icons.map, size: 16),
                label: const Text('গুগল ম্যাপে খুলুন'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSheetSelectorModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.photo_library, color: AppColors.primaryGreen),
                SizedBox(width: 8),
                Text('আসল মৌজা নকশা নির্বাচন করুন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              dense: true,
              leading: const Icon(Icons.map_outlined, color: Color(0xFF0284C7)),
              title: const Text('১০১ - টঙ্গিবাড়ী, মুন্সীগঞ্জ (CS / RS জরিপ)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('www.mouzamap.tech ফুল এইচডি স্ক্যান শিট'),
              trailing: const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 18),
              onTap: () {
                setState(() {
                  _activeMouza = 'মৌজা: ১০১ - টঙ্গিবাড়ী (জে.এল. ৩৪)';
                  _activeSheet = 'শীট ১';
                  _customSheetImageUrl =
                      'https://free.mouzamap.tech/0:/Munshiganj/%E0%A6%9F%E0%A6%99%E0%A7%8D%E0%A6%97%E0%A6%BF%E0%A6%AC%E0%A6%BE%E0%A6%A1%E0%A6%BC%E0%A7%80/101%20-%20(www.mouzamap.tech).jpg';
                  _showScannedSheet = true;
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.map_outlined, color: Color(0xFF0284C7)),
              title: const Text('১০২ - টঙ্গিবাড়ী, মুন্সীগঞ্জ (CS / RS জরিপ)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('www.mouzamap.tech ফুল এইচডি স্ক্যান শিট'),
              onTap: () {
                setState(() {
                  _activeMouza = 'মৌজা: ১০২ - টঙ্গিবাড়ী (জে.এল. ৩৫)';
                  _activeSheet = 'শীট ২';
                  _customSheetImageUrl =
                      'https://free.mouzamap.tech/0:/Munshiganj/%E0%A6%9F%E0%A6%99%E0%A7%8D%E0%A6%97%E0%A6%BF%E0%A6%AC%E0%A6%BE%E0%A6%A1%E0%A6%BC%E0%A7%80/102%20-%20(www.mouzamap.tech).jpg';
                  _showScannedSheet = true;
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.map_outlined, color: Color(0xFF0284C7)),
              title: const Text('নমুনা শিট ১: তেজকুনিপাড়া, ঢাকা (SA জরিপ)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('অফলাইন বান্ডেল্ড ক্যাডাস্ট্রাল নমুনা ১'),
              onTap: () {
                setState(() {
                  _activeMouza = 'নমুনা শিট ১: তেজকুনিপাড়া (SA জরিপ)';
                  _activeSheet = 'নমুনা শিট ১';
                  _customSheetImageUrl = 'assets/mouza_maps/sample_mouza_sheet_1.jpg';
                  _showScannedSheet = true;
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.map_outlined, color: Color(0xFF0284C7)),
              title: const Text('নমুনা শিট ২: কাওরান বাজার, ঢাকা (SA জরিপ)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('অফলাইন বান্ডেল্ড ক্যাডাস্ট্রাল নমুনা ২'),
              onTap: () {
                setState(() {
                  _activeMouza = 'নমুনা শিট ২: কাওরান বাজার (SA জরিপ)';
                  _activeSheet = 'নমুনা শিট ২';
                  _customSheetImageUrl = 'assets/mouza_maps/sample_mouza_sheet_2.jpg';
                  _showScannedSheet = true;
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.photo_camera, color: Color(0xFF16A34A)),
              title: const Text('গ্যালারি / ক্যামেরা থেকে নকশা ছবি আনুন', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('স্মার্টফোনে তোলা মৌজা নকশার যেকোনো ছবি'),
              onTap: () {
                Navigator.pop(ctx);
                _openDeviceFilePicker();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Saved Projects List (Image 5 / Page 5)
  final List<Map<String, dynamic>> _savedProjects = [
    {
      'name': 'আমিনপুর দাগ ১০৫ পরিমাপ',
      'location': 'সোনারগাঁও, নারায়ণগঞ্জ | CS',
      'areaDec': 75.758,
      'katha': 45.83,
      'sqFt': 33000.0,
      'date': '২৩ নভে ২০২৬',
      'points': [
        const Offset(60, 60),
        const Offset(260, 60),
        const Offset(280, 220),
        const Offset(40, 200),
      ],
    },
    {
      'name': 'রূপগঞ্জ দাগ ৮৮ সীমানা নির্ধারণ',
      'location': 'রূপগঞ্জ, নারায়ণগঞ্জ | RS',
      'areaDec': 24.350,
      'katha': 14.73,
      'sqFt': 10606.86,
      'date': '২২ নভে ২০২৬',
      'points': [
        const Offset(70, 70),
        const Offset(220, 75),
        const Offset(230, 190),
        const Offset(65, 180),
      ],
    },
    {
      'name': 'জাফরাবাদ দাগ ১২ বাউন্ডারি',
      'location': 'ধানমন্ডি, ঢাকা | সিটি জরিপ',
      'areaDec': 18.400,
      'katha': 11.13,
      'sqFt': 8015.04,
      'date': '২১ নভে ২০২৬',
      'points': [
        const Offset(80, 80),
        const Offset(210, 80),
        const Offset(205, 175),
        const Offset(75, 170),
      ],
    },
    {
      'name': 'মাওনা দাগ ৪৩ খাস জমি বণ্টন',
      'location': 'শ্রীপুর, গাজীপুর | BS',
      'areaDec': 50.000,
      'katha': 30.25,
      'sqFt': 21780.0,
      'date': '২০ নভে ২০২৬',
      'points': [
        const Offset(50, 50),
        const Offset(250, 50),
        const Offset(260, 200),
        const Offset(45, 195),
      ],
    },
  ];

  // CAD Measurement Points (Image 3 polygon)
  List<Offset> _measuredPoints = [
    const Offset(60, 60),
    const Offset(260, 60),
    const Offset(280, 220),
    const Offset(40, 200),
  ];

  // History / Undo Stack
  final List<List<Offset>> _undoStack = [];

  // Measurements
  double _totalAreaSqFt = 0.0;
  double _totalPerimeterFt = 0.0;

  // CAD Interactive State
  int? _selectedVertexIndex;
  bool _showGuniaScale = false;
  bool _showAngles = true;
  bool _showDimensions = true;
  Offset? _touchPosition;
  bool _isTouchActive = false;

  // Auto-Division State
  bool _showDivisionCutLine = false;
  double _targetCutDecimals = 5.0;
  bool _cutFromNorth = true;
  Offset? _cutLineP1;
  Offset? _cutLineP2;
  String _cutOffsetSummary = 'উত্তর বাহু হতে কর্তন রেখা';

  static const String _savedCadProjectsKey = 'saved_mouza_cad_projects_v1';

  @override
  void initState() {
    super.initState();
    if (widget.initialPoints != null && widget.initialPoints!.isNotEmpty) {
      _measuredPoints = List.from(widget.initialPoints!);
      _viewMode = MouzaViewMode.cad;
    }
    if (widget.initialMouzaName != null) {
      _activeMouza = 'মৌজা: ${widget.initialMouzaName} (জে.এল. ${widget.initialJlNo ?? "৩৪"})';
      _activeSheet = widget.initialSheetNo ?? 'শিট ১';
    }
    if (widget.initialImageUrl != null) {
      _customSheetImageUrl = widget.initialImageUrl;
      _showScannedSheet = true;
    }
    _loadSavedProjects();
    _recompute();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_savedCadProjectsKey) ?? const [];
      if (list.isEmpty || !mounted) return;
      final loaded = list.map((raw) {
        final map = json.decode(raw) as Map<String, dynamic>;
        final ptsRaw = (map['points'] as List<dynamic>? ?? []);
        final pts = ptsRaw.map((p) {
          final pair = p as Map<String, dynamic>;
          return Offset((pair['dx'] as num).toDouble(), (pair['dy'] as num).toDouble());
        }).toList();
        return <String, dynamic>{
          'name': map['name'] ?? 'সেভড প্রজেক্ট',
          'location': map['location'] ?? '',
          'areaDec': (map['areaDec'] as num?)?.toDouble() ?? 0.0,
          'katha': (map['katha'] as num?)?.toDouble() ?? 0.0,
          'sqFt': (map['sqFt'] as num?)?.toDouble() ?? 0.0,
          'date': map['date'] ?? '',
          'imageUrl': map['imageUrl'],
          'points': pts,
        };
      }).toList();
      setState(() {
        _savedProjects.insertAll(0, loaded);
      });
    } catch (_) {}
  }

  Future<void> _saveCurrentProject() async {
    final dec = _totalAreaSqFt / 435.60;
    final katha = _totalAreaSqFt / 720.00;
    final entry = <String, dynamic>{
      'name': _activeMouza,
      'location': '$_activeSheet | $_selectedScale',
      'areaDec': double.parse(dec.toStringAsFixed(3)),
      'katha': double.parse(katha.toStringAsFixed(2)),
      'sqFt': double.parse(_totalAreaSqFt.toStringAsFixed(1)),
      'date': BanglaFormatter.formatDateTime(DateTime.now()).split(',')[0],
      'imageUrl': _customSheetImageUrl,
      'points': List<Offset>.from(_measuredPoints),
    };

    setState(() {
      _savedProjects.insert(0, entry);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_savedCadProjectsKey) ?? const [];
      final serialized = json.encode({
        'name': entry['name'],
        'location': entry['location'],
        'areaDec': entry['areaDec'],
        'katha': entry['katha'],
        'sqFt': entry['sqFt'],
        'date': entry['date'],
        'imageUrl': entry['imageUrl'],
        'points': _measuredPoints.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      });
      await prefs.setStringList(_savedCadProjectsKey, [serialized, ...existing]);

      await HistoryService.instance.saveItem(
        CalculationHistoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: '$_activeMouza (${BanglaFormatter.formatNumber(dec, fractionDigits: 2)} শতক)',
          category: 'মৌজা ম্যাপ',
          timestamp: DateTime.now(),
          inputSummary: '${BanglaNumerals.toBangla(_measuredPoints.length)} বিন্দু CAD | $_selectedScale',
          resultSummary: '${BanglaFormatter.formatNumber(dec, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(_totalAreaSqFt)} বর্গফুট)',
          fullReportBangla: '=== মৌজা CAD পরিমাপ ===\nমৌজা: $_activeMouza\nশিট: $_activeSheet\nক্ষেত্রফল: ${BanglaFormatter.formatNumber(dec, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(katha, fractionDigits: 2)} কাঠা)\nবর্গফুট: ${BanglaFormatter.formatNumber(_totalAreaSqFt)} sq ft\nপরিসীমা: ${BanglaFormatter.formatNumber(_totalPerimeterFt, fractionDigits: 1)} ফুট',
        ),
      );
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('প্রজেক্ট ও পরিমাপের তথ্য সংরক্ষণ করা হয়েছে!'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    }
  }

  void _recompute() {
    if (_measuredPoints.length < 3) {
      _totalAreaSqFt = 0;
      _totalPerimeterFt = 0;
      return;
    }

    final pixelArea = PolygonGeometry.calculateArea(_measuredPoints);
    final perimPx = PolygonGeometry.calculatePerimeter(_measuredPoints);
    _totalAreaSqFt = pixelArea * (_feetPerPixel * _feetPerPixel);
    _totalPerimeterFt = perimPx * _feetPerPixel;

    if (_showDivisionCutLine) {
      _calculateCutLine();
    }
  }

  void _calculateCutLine() {
    if (_measuredPoints.length < 3 || _totalAreaSqFt <= 0) return;

    final targetSqFt = _targetCutDecimals * 435.60;
    final targetPixelArea = targetSqFt / (_feetPerPixel * _feetPerPixel);
    final res = PolygonGeometry.findAreaBisectionCutLine(
      polygon: _measuredPoints,
      targetArea: targetPixelArea,
      horizontalCut: true,
      fromStart: _cutFromNorth,
    );

    if (res == null) return;

    final cutLenFt = res.cutLength * _feetPerPixel;
    final offsetFt = res.offsetFromEdge * _feetPerPixel;
    final dirLabel = _cutFromNorth ? 'উত্তর হতে' : 'দক্ষিণ হতে';

    setState(() {
      _cutLineP1 = res.cutStart;
      _cutLineP2 = res.cutEnd;
      _cutOffsetSummary = '$dirLabel ${BanglaFormatter.formatNumber(offsetFt, fractionDigits: 1)} ফুট দূরত্বে কর্তন (দৈর্ঘ্য: ${BanglaFormatter.formatNumber(cutLenFt, fractionDigits: 1)} ft)';
    });
  }

  void _pushUndo() {
    _undoStack.add(List.from(_measuredPoints));
    if (_undoStack.length > 20) _undoStack.removeAt(0);
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      setState(() {
        _measuredPoints = _undoStack.removeLast();
        _recompute();
      });
      HapticFeedback.lightImpact();
    }
  }

  void _deleteLastPoint() {
    if (_measuredPoints.length > 3) {
      _pushUndo();
      setState(() {
        _measuredPoints.removeLast();
        _recompute();
      });
      HapticFeedback.mediumImpact();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কমপক্ষে ৩টি শীর্ষবিন্দু থাকতে হবে')),
      );
    }
  }

  void _addNewPointAtCenter() {
    _pushUndo();
    final center = _measuredPoints.reduce((a, b) => a + b) / _measuredPoints.length.toDouble();
    final newPt = center + const Offset(30, 30);
    setState(() {
      _measuredPoints.add(newPt);
      _recompute();
    });
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('নতুন CAD শীর্ষবিন্দু যোগ করা হয়েছে। ড্র্যাগ করে অবস্থান পরিবর্তন করুন।')),
    );
  }

  // Saved Projects Modal (Image 5: ফোল্ডার বেছে নিন)
  void _showSavedProjectsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.folder_shared, color: AppColors.primaryGreen, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'ডিভাইসের সংরক্ষিত প্রজেক্ট সমূহ',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'ফোনের স্টোরেজ থেকে পূর্বে সেভ করা ক্যাডাস্ট্রাল প্রজেক্ট বেছে নিন:',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: _savedProjects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final proj = _savedProjects[idx];
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFDCFCE7),
                          child: const Icon(Icons.architecture, color: AppColors.primaryGreen),
                        ),
                        title: Text(
                          proj['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                        ),
                        subtitle: Text(
                          '${proj['location']}\n${proj['areaDec']} শতক (${proj['katha']} কাঠা) • ${proj['date']}',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primaryGreen),
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _activeMouza = proj['name'] as String;
                            _measuredPoints = List.from(proj['points'] as List<Offset>);
                            if (proj['imageUrl'] != null) {
                              _customSheetImageUrl = proj['imageUrl'] as String;
                              _showScannedSheet = true;
                            }
                            _viewMode = MouzaViewMode.cad;
                            _recompute();
                          });
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('${proj['name']} CAD ক্যানভাসে সফলভাবে লোড হয়েছে!'),
                              backgroundColor: AppColors.primaryGreen,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _activeMouza = 'নতুন প্রজেক্ট (${BanglaFormatter.formatDateTime(DateTime.now())})';
                      _measuredPoints = [
                        const Offset(60, 60),
                        const Offset(260, 60),
                        const Offset(280, 220),
                        const Offset(40, 200),
                      ];
                      _viewMode = MouzaViewMode.cad;
                      _recompute();
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('নতুন প্রজেক্ট তৈরি করুন'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Auto-division dialog with live exact bisection calculation
  void _showAutoDivisionDialog() {
    final targetDecController = TextEditingController(text: _targetCutDecimals.toStringAsFixed(1));
    String cutDirection = _cutFromNorth ? 'উত্তর হতে' : 'দক্ষিণ হতে';
    final totalDec = _totalAreaSqFt / 435.60;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final isExcess = _targetCutDecimals <= 0 || _targetCutDecimals >= totalDec;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.call_split, color: AppColors.primaryGreen),
                SizedBox(width: 8),
                Flexible(child: Text('অটো-ডিভিশন / জমি বণ্টন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'মোট জমি: ${BanglaFormatter.formatNumber(totalDec, fractionDigits: 3)} শতক। পৃথক করার শতক ইনপুট দিন:',
                  style: const TextStyle(fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: targetDecController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'কাটতে চাওয়া শতক',
                          border: OutlineInputBorder(),
                          suffixText: 'শতক',
                          isDense: true,
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val) ?? 0.0;
                          setDlgState(() => _targetCutDecimals = parsed);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: cutDirection,
                      items: const [
                        DropdownMenuItem(value: 'উত্তর হতে', child: Text('উত্তর হতে')),
                        DropdownMenuItem(value: 'দক্ষিণ হতে', child: Text('দক্ষিণ হতে')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDlgState(() => cutDirection = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isExcess ? Colors.red.shade50 : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isExcess ? Colors.red.shade300 : Colors.green.shade200),
                  ),
                  child: Text(
                    isExcess
                        ? 'সতর্কতা: কাটার পরিমাণ মোট জমির (${BanglaFormatter.formatNumber(totalDec, fractionDigits: 2)} শতক) চেয়ে কম ও শূন্যের বেশি হতে হবে।'
                        : '• মোট পৃথক শতক: ${BanglaFormatter.formatNumber(_targetCutDecimals, fractionDigits: 2)} শতক ($cutDirection)\n• সমপরিমাণ বর্গফুট: ${BanglaFormatter.formatNumber(_targetCutDecimals * 435.60, fractionDigits: 1)} sq ft\n• অবশিষ্ট অংশ: ${BanglaFormatter.formatNumber(totalDec - _targetCutDecimals, fractionDigits: 2)} শতক',
                    style: TextStyle(fontSize: 11.5, color: isExcess ? Colors.red.shade900 : Colors.green.shade900),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() => _showDivisionCutLine = false);
                  Navigator.pop(ctx);
                },
                child: const Text('কাটলাইন মুছুন'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                onPressed: isExcess
                    ? null
                    : () {
                        setState(() {
                          _cutFromNorth = cutDirection == 'উত্তর হতে';
                          _showDivisionCutLine = true;
                          _calculateCutLine();
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('অটো-ডিভিশন কাটলাইন CAD ক্যানভাসে সক্রিয় করা হয়েছে! ($_cutOffsetSummary)'),
                            backgroundColor: AppColors.primaryGreen,
                          ),
                        );
                      },
                child: const Text('কাটলাইন প্রয়োগ করুন', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Two-Point Reference Line Calibration using actual edge 1->2 pixel length
  void _showCalibrationDialog() {
    final distController = TextEditingController(text: '100');
    String unit = 'লিংক';
    final refPixelDist = _measuredPoints.length >= 2
        ? (_measuredPoints[1] - _measuredPoints[0]).distance
        : 200.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.straighten, color: AppColors.primaryGreen),
              SizedBox(width: 8),
              Flexible(child: Text('২-পয়েন্ট স্কেল ক্যালিব্রেশন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'বিন্দু ১ → ২ রেখার (দৈর্ঘ্য: ${refPixelDist.toStringAsFixed(0)} px) বাস্তব দূরত্ব ইনপুট দিন:',
                style: const TextStyle(fontSize: 12.5),
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
              const SizedBox(height: 8),
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
                final dist = double.tryParse(distController.text.trim()) ?? 0.0;
                if (dist <= 0 || refPixelDist <= 0) return;
                final distInFeet = unit == 'লিংক' ? dist * 0.66 : dist;
                setState(() {
                  _feetPerPixel = (distInFeet / refPixelDist).clamp(0.05, 50.0);
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

  // Total Station / RTK Coordinate Input Dialog (supports single or multi-line CSV N,E plotting)
  void _showTotalStationDialog() {
    final csvCtrl = TextEditingController(
      text: '2645120.45, 542100.32\n2645120.45, 542160.32\n2645070.45, 542165.32\n2645075.45, 542095.32',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.gps_fixed, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Flexible(child: Text('টোটাল স্টেশন / RTK (N, E) প্লটিং', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'প্রতি লাইনে Northing, Easting (মিটারে) কমা দিয়ে লিখুন (কমপক্ষে ৩টি বিন্দু দিলে সম্পূর্ণ প্লট প্লট হবে):',
              style: TextStyle(fontSize: 11.5),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: csvCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Northing (N), Easting (E)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () {
              final rawLines = csvCtrl.text.trim().split('\n');
              final nePts = <Offset>[];
              for (final line in rawLines) {
                final parts = line.split(',').map((s) => double.tryParse(s.trim())).toList();
                if (parts.length >= 2 && parts[0] != null && parts[1] != null) {
                  nePts.add(Offset(parts[1]!, parts[0]!)); // x = Easting, y = Northing
                }
              }
              if (nePts.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('সঠিক Northing, Easting সংখ্যা লিখুন!'), backgroundColor: Colors.red),
                );
                return;
              }

              // Convert meters to feet (1m = 3.28084 ft) relative to centroid and scale cleanly onto CAD canvas
              final avgE = nePts.map((p) => p.dx).reduce((a, b) => a + b) / nePts.length;
              final avgN = nePts.map((p) => p.dy).reduce((a, b) => a + b) / nePts.length;
              const mToFt = 3.28084;
              const feetPerPxScale = 1.0;

              final projected = nePts.map((p) {
                final dxFt = (p.dx - avgE) * mToFt;
                final dyFt = -(p.dy - avgN) * mToFt; // screen Y is southwards
                return Offset(180.0 + dxFt / feetPerPxScale, 180.0 + dyFt / feetPerPxScale);
              }).toList();

              _pushUndo();
              Navigator.pop(ctx);
              setState(() {
                if (projected.length >= 3) {
                  _measuredPoints = projected;
                  _feetPerPixel = feetPerPxScale;
                  _selectedScale = 'টোটাল স্টেশন (১ px = ১ ft)';
                } else {
                  _measuredPoints.addAll(projected);
                }
                _viewMode = MouzaViewMode.cad;
                _recompute();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('টোটাল স্টেশন হতে ${BanglaNumerals.toBangla(projected.length)} টি পয়েন্ট CAD ক্যানভাসে প্লট হয়েছে!'),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
            },
            child: const Text('প্লট করুন', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _acquireDeviceImageSource(String sourceName) {
    _pickCustomDeviceSheet();
  }

  // Device Sheet Picker
  void _openDeviceFilePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ডিভাইস বা অফলাইন মেমোরি থেকে নকশা নির্বাচন করুন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('সরাসরি ফোনের স্টোরেজ/গ্যালারি থেকে JPG, PNG বা PDF মৌজা শিট বেছে নিন:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 14),

            // Real phone file/image/PDF picker
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _pickCustomDeviceSheet();
                },
                icon: const Icon(Icons.folder_open),
                label: const Text('ফোন থেকে ফাইল / ছবি / PDF বাছাই করুন', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 14),

            // Bundled real high-res sheets
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified, size: 16, color: Color(0xFF16A34A)),
                      SizedBox(width: 6),
                      Text('আসল ক্যাডাস্ট্রাল মৌজা শিট (Free.mouzamap.tech)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF15803D))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(radius: 16, backgroundColor: Color(0xFFDC2626), child: Icon(Icons.picture_as_pdf, color: Colors.white, size: 16)),
                    title: const Text('নমুনা শিট ১: তেজগাঁও - তেজকুনিপাড়া', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text('ঢাকা • SA জরিপ • অফলাইন ফুল HD স্ক্যান'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _activeMouza = 'নমুনা শিট ১: তেজকুনিপাড়া (SA জরিপ)';
                        _activeSheet = 'নমুনা শিট ১';
                        _customSheetImageUrl = 'assets/mouza_maps/sample_mouza_sheet_1.jpg';
                        _showScannedSheet = true;
                        _viewMode = MouzaViewMode.cad;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('তেজকুনিপাড়া নমুনা শিট CAD ক্যানভাসে লোড হয়েছে')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(radius: 16, backgroundColor: Color(0xFFDC2626), child: Icon(Icons.picture_as_pdf, color: Colors.white, size: 16)),
                    title: const Text('নমুনা শিট ২: তেজগাঁও - কাওরান বাজার', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text('ঢাকা • SA জরিপ • অফলাইন ফুল HD স্ক্যান'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _activeMouza = 'নমুনা শিট ২: কাওরান বাজার (SA জরিপ)';
                        _activeSheet = 'নমুনা শিট ২';
                        _customSheetImageUrl = 'assets/mouza_maps/sample_mouza_sheet_2.jpg';
                        _showScannedSheet = true;
                        _viewMode = MouzaViewMode.cad;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('কাওরান বাজার নমুনা শিট CAD ক্যানভাসে লোড হয়েছে')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFDCFCE7), child: Icon(Icons.photo, color: AppColors.primaryGreen)),
              title: const Text('গ্যালারি / ছবি (JPG, PNG)'),
              subtitle: const Text('ফোনে সেভ থাকা যেকোনো স্ক্যান করা মৌজা ম্যাপের ছবি'),
              onTap: () {
                Navigator.pop(ctx);
                _acquireDeviceImageSource('গ্যালারি');
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.camera_alt, color: Colors.blue)),
              title: const Text('ক্যামেরা দিয়ে নকশা স্ক্যান'),
              subtitle: const Text('ক্যামেরা দিয়ে তোলা মৌজা ম্যাপের ছবি'),
              onTap: () {
                Navigator.pop(ctx);
                _acquireDeviceImageSource('ক্যামেরা');
              },
            ),
          ],
        ),
      ),
    );
  }

  // Generate AutoCAD DXF R12 / R2000 content
  String _generateDxfContent() {
    final sb = StringBuffer();
    sb.writeln('0\nSECTION\n2\nHEADER\n0\nENDSEC');
    sb.writeln('0\nSECTION\n2\nTABLES\n0\nTABLE\n2\nLAYER\n70\n1');
    sb.writeln('0\nLAYER\n2\nCADASTRAL_BOUNDARY\n70\n0\n62\n4\n6\nCONTINUOUS\n0\nENDTAB\n0\nENDSEC');
    sb.writeln('0\nSECTION\n2\nENTITIES');
    sb.writeln('0\nPOLYLINE\n8\nCADASTRAL_BOUNDARY\n66\n1\n70\n1');
    for (final pt in _measuredPoints) {
      sb.writeln('0\nVERTEX\n8\nCADASTRAL_BOUNDARY\n10\n${(pt.dx * _feetPerPixel).toStringAsFixed(2)}\n20\n${((500 - pt.dy) * _feetPerPixel).toStringAsFixed(2)}\n30\n0.0');
    }
    sb.writeln('0\nSEQEND');
    sb.writeln('0\nTEXT\n8\nCADASTRAL_BOUNDARY\n10\n100.0\n20\n100.0\n40\n14.0\n1\n$_activeMouza Area: ${_totalAreaSqFt.toStringAsFixed(2)} sq ft (${(_totalAreaSqFt / 435.6).toStringAsFixed(3)} Dec)');
    sb.writeln('0\nENDSEC\n0\nEOF');
    return sb.toString();
  }

  void _exportDxf() {
    final dxf = _generateDxfContent();
    Clipboard.setData(ClipboardData(text: dxf));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.code, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('AutoCAD DXF প্রস্তুত', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('স্ট্যান্ডার্ড AutoCAD DXF ভেক্টর কোড ক্লিপবোর্ডে কপি করা হয়েছে।'),
            const SizedBox(height: 10),
            Text('মোট শীর্ষবিন্দু: ${BanglaNumerals.toBangla(_measuredPoints.length)} টি\nমোট ক্ষেত্রফল: ${BanglaFormatter.formatNumber(_totalAreaSqFt)} sq ft\nমোট শতক: ${BanglaFormatter.formatNumber(_totalAreaSqFt / 435.6, fractionDigits: 3)} শতক', style: const TextStyle(fontSize: 12, color: Colors.black87)),
            const SizedBox(height: 10),
            const Text('কম্পিউটার বা মোবাইলে AutoCAD / LibreCAD-এ .dxf এক্সটেনশনে ফাইলটি সরাসরি খুলুন।', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বুঝেছি', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Generate Google Earth KML XML
  String _generateKmlContent() {
    const baseLat = 23.650000;
    const baseLon = 90.500000;
    const ftToDegLat = 1.0 / 364000.0;
    const ftToDegLon = 1.0 / 334000.0;

    final coords = StringBuffer();
    for (final pt in _measuredPoints) {
      final lon = baseLon + (pt.dx * _feetPerPixel * ftToDegLon);
      final lat = baseLat - (pt.dy * _feetPerPixel * ftToDegLat);
      coords.writeln('$lon,$lat,0');
    }
    if (_measuredPoints.isNotEmpty) {
      final p0 = _measuredPoints.first;
      final lon0 = baseLon + (p0.dx * _feetPerPixel * ftToDegLon);
      final lat0 = baseLat - (p0.dy * _feetPerPixel * ftToDegLat);
      coords.writeln('$lon0,$lat0,0');
    }

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>$_activeMouza</name>
    <description>BDLand Pro Survey CAD Polygon - Area: ${_totalAreaSqFt.toStringAsFixed(2)} sq ft</description>
    <Placemark>
      <name>দাগ বাউন্ডারি</name>
      <Polygon>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
$coords
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
  </Document>
</kml>''';
  }

  void _exportKml() {
    final kml = _generateKmlContent();
    Clipboard.setData(ClipboardData(text: kml));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.public, color: Colors.blue),
            SizedBox(width: 8),
            Text('Google Earth KML প্রস্তুত', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Google Earth KML কোঅর্ডিনেট কোড ক্লিপবোর্ডে কপি করা হয়েছে।'),
            const SizedBox(height: 10),
            const Text('এটি .kml ফাইল হিসেবে সেভ করে সরাসরি Google Earth Pro-তে স্যাটেলাইট ভিউতে দাগ দেখতে পারবেন।', style: TextStyle(fontSize: 12, color: Colors.black87)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বুঝেছি', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Export PDF Certificate
  void _exportPdf() async {
    final bengaliTheme = await PdfReportHelper.loadBengaliTheme();
    final pdf = pw.Document(theme: bengaliTheme);
    final dec = _totalAreaSqFt / 435.60;
    final katha = _totalAreaSqFt / 720.00;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text('মৌজা ম্যাপ ক্যাডাস্ট্রাল পরিমাপ ও জরিপ প্রত্যয়নপত্র', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text('$_activeMouza | $_activeSheet | স্কেল: $_selectedScale', style: const pw.TextStyle(fontSize: 11)),
                ),
                pw.Divider(thickness: 1.5),
                pw.SizedBox(height: 12),
                pw.Text('মোট ক্ষেত্রফল: ${BanglaFormatter.formatNumber(_totalAreaSqFt)} বর্গফুট', style: const pw.TextStyle(fontSize: 13)),
                pw.Text('মোট পরিমাণ: ${BanglaFormatter.formatNumber(dec, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(katha, fractionDigits: 2)} কাঠা)', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.Text('মোট পরিসীমা: ${BanglaFormatter.formatNumber(_totalPerimeterFt)} ফুট', style: const pw.TextStyle(fontSize: 13)),
                if (_showDivisionCutLine) ...[
                  pw.SizedBox(height: 8),
                  pw.Text('অটো-ডিভিশন কর্তন: ${BanglaFormatter.formatNumber(_targetCutDecimals, fractionDigits: 2)} শতক ($_cutOffsetSummary)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
                ],
                pw.SizedBox(height: 16),
                pw.Container(
                  height: 180,
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                  child: pw.Center(child: pw.Text('দাগের ক্যাডাস্ট্রাল ভেক্টর সীমানা নকশা', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700))),
                ),
                pw.Spacer(),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}'),
                    pw.Text('সার্ভেয়ারের স্বাক্ষর ও সিল: ____________________'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Mouza_Survey_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_viewMode == MouzaViewMode.cad) {
      return _buildCadView();
    }
    return _buildPortalView();
  }

  // ==========================================
  // VIEW 1: PORTAL & MAP LOADER (Image 5)
  // ==========================================
  Widget _buildPortalView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: PopupMenuButton<String>(
          onSelected: (val) {
            setState(() {
              _activeMouza = val;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _activeMouza,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 20),
            ],
          ),
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'মৌজা: আমিনপুর (জে.এল. ৩৪)', child: Text('আমিনপুর (জে.এল. ৩৪)')),
            const PopupMenuItem(value: 'মৌজা: রূপগঞ্জ (জে.এল. ১২)', child: Text('রূপগঞ্জ (জে.এল. ১২)')),
            const PopupMenuItem(value: 'মৌজা: তেজগাঁও (জে.এল. ০৮)', child: Text('তেজগাঁও (জে.এল. ০৮)')),
          ],
        ),
        actions: [
          // Blue active map button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _viewMode = MouzaViewMode.cad),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.map, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Color(0xFF334155), size: 22),
            tooltip: 'নতুন প্রজেক্ট',
            onPressed: () {
              setState(() {
                _measuredPoints = [
                  const Offset(60, 60),
                  const Offset(260, 60),
                  const Offset(280, 220),
                  const Offset(40, 200),
                ];
                _viewMode = MouzaViewMode.cad;
              });
            },
          ),
          IconButton(
            icon: Icon(
              _highContrast ? Icons.lightbulb : Icons.lightbulb_outline,
              color: _highContrast ? Colors.amber : const Color(0xFF334155),
              size: 22,
            ),
            tooltip: 'কন্ট্রাস্ট / ব্রাইটনেস',
            onPressed: () => setState(() => _highContrast = !_highContrast),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF334155), size: 22),
            tooltip: 'নির্দেশিকা',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('মৌজা ম্যাপ ব্যবহারের নিয়ম'),
                  content: const Text('১. "Cloud থেকে" অথবা "Device থেকে" ম্যাপ নির্বাচন করুন।\n২. ক্যানভাসে দাগের চারকোণা ড্র্যাগ করে মাপুন।\n৩. গুনিয়া স্কেল চালু করে দাগের বাহু সরাসরি যাচাই করুন।'),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ঠিক আছে'))],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_outlined, color: Color(0xFFDC2626), size: 22),
            tooltip: 'ব্যবহারবিধি গাইড',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('মৌজা CAD ব্যবহারবিধি'),
                  content: const Text(
                    '১. "Cloud থেকে" বা "Device থেকে" আসল মৌজা নকশা শিট লোড করুন।\n'
                    '২. ক্যালিব্রেশন আইকন (📐) দিয়ে বিন্দু ১→২ রেখার বাস্তব লিংক/ফুট দূরত্ব সেট করুন।\n'
                    '৩. শীর্ষবিন্দুগুলো ড্র্যাগ করলে ম্যাগনিফায়ার লুপ ও অর্থো-স্ন্যাপিং সহ নিখুঁত পরিমাপ পাবেন।\n'
                    '৪. সেভ ও PDF/DXF/KML এক্সপোর্ট সরাসরি ব্যবহার করুন।',
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বুঝেছি'))],
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF334155)),
            onSelected: (val) {
              if (val == 'cloud') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AllMouzaMapsScreen()));
              }
              if (val == 'device') _openDeviceFilePicker();
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'cloud', child: Text('সকল মৌজা ডিরেক্টরি')),
              PopupMenuItem(value: 'device', child: Text('ফাইল খুলুন')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background engineering grid
          CustomPaint(
            painter: _EngineeringGridPainter(),
            size: Size.infinite,
          ),

          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              // SECTION 1: সংরক্ষিত প্রজেক্ট (Image 5)
              _buildSectionHeader('সংরক্ষিত প্রজেক্ট', null),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.folder_open_outlined, size: 54, color: Color(0xFF64748B)),
                    const SizedBox(height: 12),
                    const Text(
                      'সংরক্ষিত প্রজেক্ট দেখতে ফোনের BDLandPro ফোল্ডারটি একবার বেছে দিন।',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        side: const BorderSide(color: Color(0xFF166534)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      ),
                      onPressed: _showSavedProjectsModal,
                      child: const Text(
                        'ফোল্ডার বেছে নিন',
                        style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // SECTION 2: মৌজা নকশা লোড (Image 5)
              _buildSectionHeader('মৌজা নকশা লোড', 'নতুন কাজ শুরু করুন'),
              const SizedBox(height: 8),

              // Item A: Device থেকে
              InkWell(
                onTap: _openDeviceFilePicker,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF14532D), // Dark emerald green
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.upload_file, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Device থেকে',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'ফোনের JPG · PDF · TIFF নকশা খুলুন',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Item B: Cloud থেকে (Navigates to AllMouzaMapsScreen - Image 5)
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AllMouzaMapsScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7), // Mint green
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.cloud_outlined, color: Color(0xFF166534), size: 26),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cloud থেকে',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'সারাদেশের মৌজা ম্যাপ থেকে বাছুন (free.mouzamap.tech)',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // SECTION 3: ম্যাপের মান (Image 5)
              Row(
                children: [
                  const Text('ম্যাপের মান', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(width: 14),
                  // Option 1: HD Full Quality
                  InkWell(
                    onTap: () => setState(() => _isHighQuality = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _isHighQuality ? const Color(0xFF14532D) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _isHighQuality ? const Color(0xFF14532D) : const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.hd, size: 16, color: _isHighQuality ? Colors.white : const Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            'ফুল কোয়ালিটি',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _isHighQuality ? FontWeight.bold : FontWeight.normal,
                              color: _isHighQuality ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Option 2: Fast
                  InkWell(
                    onTap: () => setState(() => _isHighQuality = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: !_isHighQuality ? const Color(0xFF14532D) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: !_isHighQuality ? const Color(0xFF14532D) : const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.bolt, size: 16, color: !_isHighQuality ? Colors.white : const Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            'দ্রুত',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: !_isHighQuality ? FontWeight.bold : FontWeight.normal,
                              color: !_isHighQuality ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'সবচেয়ে পরিষ্কার · একটু ধীর, বেশি মেমরি',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),

              const SizedBox(height: 20),

              // SECTION 4: টোটাল স্টেশন / RTK (Image 5)
              _buildSectionHeader('টোটাল স্টেশন / RTK', 'পয়েন্ট দিয়ে কাজ'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showTotalStationDialog,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.pin_drop, color: Color(0xFFB45309), size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'টোটাল স্টেশন সার্ভে ডাটা লোড',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Northing & Easting দিয়ে সরাসরি CAD বাউন্ডারি আঁকুন',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? rightSubtitle) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 15,
          decoration: BoxDecoration(
            color: const Color(0xFFC29015), // Amber/gold vertical accent
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF14532D)),
        ),
        if (rightSubtitle != null) ...[
          const Spacer(),
          Text(rightSubtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      ],
    );
  }

  // ==========================================
  // VIEW 2: CAD MEASUREMENT WORKSPACE (Image 3)
  // ==========================================
  Widget _buildCadView() {
    final dec = _totalAreaSqFt / 435.60;
    final katha = _totalAreaSqFt / 720.00;

    final cadCanvas = CustomPaint(
      painter: _CadInteractivePainter(
        points: _measuredPoints,
        feetPerPixel: _feetPerPixel,
        showAngles: _showAngles,
        showDimensions: _showDimensions,
        highContrast: _highContrast,
        showDivisionCutLine: _showDivisionCutLine,
        cutLineP1: _cutLineP1,
        cutLineP2: _cutLineP2,
        targetCutDecimals: _targetCutDecimals,
      ),
      size: Size.infinite,
    );

    return Scaffold(
      backgroundColor: _highContrast ? Colors.white : const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14532D), // Rich dark green header
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => setState(() => _viewMode = MouzaViewMode.portal),
        ),
        title: Text(
          _activeMouza,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined, color: Colors.white),
            tooltip: 'প্রজেক্ট ও হিস্ট্রি সেভ',
            onPressed: _saveCurrentProject,
          ),
          IconButton(
            icon: const Icon(Icons.gps_fixed, color: Colors.white),
            tooltip: 'জিপিএস রেফারেন্স',
            onPressed: _showGpsLocationDialog,
          ),
          IconButton(
            icon: Icon(
              _showGuniaScale ? Icons.square_foot : Icons.straighten_outlined,
              color: _showGuniaScale ? Colors.amberAccent : Colors.white,
            ),
            tooltip: 'গুনিয়া স্কেল',
            onPressed: () => setState(() => _showGuniaScale = !_showGuniaScale),
          ),
          IconButton(
            icon: const Icon(Icons.architecture, color: Colors.white),
            tooltip: 'স্কেল ক্যালিব্রেশন',
            onPressed: _showCalibrationDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download, color: Colors.white),
            tooltip: 'এক্সপোর্ট',
            onSelected: (val) {
              if (val == 'pdf') _exportPdf();
              if (val == 'dxf') _exportDxf();
              if (val == 'kml') _exportKml();
              if (val == 'add_pt') _addNewPointAtCenter();
              if (val == 'sheet_sel') _showSheetSelectorModal();
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'pdf', child: Text('অফিশিয়াল A4 PDF প্রত্যয়ন')),
              PopupMenuItem(value: 'dxf', child: Text('AutoCAD DXF (.dxf)')),
              PopupMenuItem(value: 'kml', child: Text('Google Earth KML (.kml)')),
              PopupMenuItem(value: 'add_pt', child: Text('নতুন শীর্ষবিন্দু যোগ করুন (+)')),
              PopupMenuItem(value: 'sheet_sel', child: Text('আসল নকশা শিট নির্বাচন করুন')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // CAD Banner (Matching Image 3 banner)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFF1E293B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified, color: Color(0xFFFBBF24), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'CAD ক্ষেত্রফল: ${BanglaFormatter.formatNumber(dec, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(katha, fractionDigits: 2)} কাঠা)',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${BanglaFormatter.formatNumber(_totalAreaSqFt, fractionDigits: 2)} sq ft',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),

          // Sheet Controls Sub-Bar (Toggle sheet visibility, opacity, sheet switch, and add vertex)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: const Color(0xFF0F172A),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                    // Interactive Mode Toggle (Zoom/Pan vs Measure/Drag Pin)
                  InkWell(
                    onTap: () => setState(() => _isZoomPanMode = !_isZoomPanMode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isZoomPanMode ? const Color(0xFFD97706) : const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isZoomPanMode ? Icons.pan_tool : Icons.touch_app,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isZoomPanMode ? 'জুম/প্যান মোড' : 'মাপ/পিন মোড',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => _showScannedSheet = !_showScannedSheet),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _showScannedSheet ? const Color(0xFF166534) : const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _showScannedSheet ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showScannedSheet ? 'নকশা চালু' : 'নকশা বন্ধ',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showSheetSelectorModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0369A1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.photo_library, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('নকশা পরিবর্তন', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<double>(
                    tooltip: 'নকশা অপাসিটি',
                    onSelected: (val) => setState(() => _sheetOpacity = val),
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 0.35, child: Text('অপাসিটি ৩৫%')),
                      PopupMenuItem(value: 0.50, child: Text('অপাসিটি ৫০%')),
                      PopupMenuItem(value: 0.75, child: Text('অপাসিটি ৭৫%')),
                      PopupMenuItem(value: 0.90, child: Text('অপাসিটি ৯০% (স্ট্যান্ডার্ড)')),
                      PopupMenuItem(value: 1.00, child: Text('অপাসিটি ১০০% (গাঢ়)')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.opacity, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'স্বচ্ছতা: ${(_sheetOpacity * 100).round()}%',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _addNewPointAtCenter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF854D0E),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_circle_outline, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('+ নতুন বিন্দু', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showGpsLocationDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        border: Border.all(color: const Color(0xFF475569)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.gps_fixed, color: Color(0xFF4ADE80), size: 14),
                          SizedBox(width: 4),
                          Text('GPS অবস্থান', style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Optional Cut-Line Status Alert
          if (_showDivisionCutLine)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: const Color(0xFF78350F),
              child: Row(
                children: [
                  const Icon(Icons.call_split, color: Colors.amberAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'কাটলাইন সক্রিয়: $_cutOffsetSummary',
                      style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _showDivisionCutLine = false),
                    child: const Icon(Icons.close, color: Colors.white70, size: 16),
                  ),
                ],
              ),
            ),

          // Main CAD Interactive Canvas with Synchronized Pinch-to-Zoom & Pan
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                final transformedSceneTouch = _touchPosition != null
                    ? MatrixUtils.transformPoint(_transformationController.value, _touchPosition!)
                    : null;

                return Stack(
                  children: [
                    InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 0.8,
                      maxScale: 8.0,
                      boundaryMargin: const EdgeInsets.all(400),
                      panEnabled: _isZoomPanMode,
                      scaleEnabled: _isZoomPanMode,
                      onInteractionEnd: (_) {
                        setState(() {
                          _canvasZoom = _transformationController.value.getMaxScaleOnAxis();
                        });
                      },
                      child: SizedBox(
                        width: canvasSize.width,
                        height: canvasSize.height,
                        child: Stack(
                          children: [
                            // Authentic Scanned Cadastral Sheet Layer (zooms with pins!)
                            Positioned.fill(
                              child: _buildMapBackgroundLayer(),
                            ),

                            // Interactive Listener for Moving Vertices in exact scene coordinates
                            IgnorePointer(
                              ignoring: _isZoomPanMode,
                              child: Listener(
                                onPointerDown: (event) {
                                  final pos = event.localPosition;
                                  int? tappedIdx;
                                  final hitRadius = (28.0 / _canvasZoom).clamp(8.0, 32.0);
                                  for (int i = 0; i < _measuredPoints.length; i++) {
                                    if ((_measuredPoints[i] - pos).distance <= hitRadius) {
                                      tappedIdx = i;
                                      break;
                                    }
                                  }
                                  _dragSnapshotSaved = false;
                                  setState(() {
                                    _touchPosition = pos;
                                    _isTouchActive = true;
                                    _selectedVertexIndex = tappedIdx;
                                  });
                                  if (tappedIdx != null) {
                                    HapticFeedback.selectionClick();
                                  }
                                },
                                onPointerMove: (event) {
                                  final pos = event.localPosition;
                                  if (_selectedVertexIndex != null) {
                                    if (!_dragSnapshotSaved) {
                                      _pushUndo();
                                      _dragSnapshotSaved = true;
                                    }

                                    // Magnetic Ortho-Snapping when aligning horizontally/vertically
                                    Offset adjustedPos = pos;
                                    final currIdx = _selectedVertexIndex!;
                                    final prevPt = _measuredPoints[(currIdx - 1 + _measuredPoints.length) % _measuredPoints.length];
                                    final nextPt = _measuredPoints[(currIdx + 1) % _measuredPoints.length];
                                    final snapThreshold = (8.0 / _canvasZoom).clamp(2.0, 10.0);

                                    if ((pos.dx - prevPt.dx).abs() < snapThreshold) {
                                      adjustedPos = Offset(prevPt.dx, adjustedPos.dy);
                                    } else if ((pos.dx - nextPt.dx).abs() < snapThreshold) {
                                      adjustedPos = Offset(nextPt.dx, adjustedPos.dy);
                                    }

                                    if ((pos.dy - prevPt.dy).abs() < snapThreshold) {
                                      adjustedPos = Offset(adjustedPos.dx, prevPt.dy);
                                    } else if ((pos.dy - nextPt.dy).abs() < snapThreshold) {
                                      adjustedPos = Offset(adjustedPos.dx, nextPt.dy);
                                    }

                                    setState(() {
                                      _measuredPoints[currIdx] = adjustedPos;
                                      _touchPosition = adjustedPos;
                                      _recompute();
                                    });
                                  } else {
                                    setState(() => _touchPosition = pos);
                                  }
                                },
                                onPointerUp: (_) {
                                  setState(() {
                                    _isTouchActive = false;
                                    _touchPosition = null;
                                    _selectedVertexIndex = null;
                                    _dragSnapshotSaved = false;
                                  });
                                },
                                onPointerCancel: (_) {
                                  setState(() {
                                    _isTouchActive = false;
                                    _touchPosition = null;
                                    _selectedVertexIndex = null;
                                    _dragSnapshotSaved = false;
                                  });
                                },
                                child: cadCanvas,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Floating Zoom Controls (+ / - / 1x / Lock Mode)
                    Positioned(
                      bottom: 14,
                      right: 12,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xCC0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF475569)),
                            ),
                            child: Text(
                              '${_canvasZoom.toStringAsFixed(1)}x',
                              style: const TextStyle(color: Colors.amberAccent, fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 6),
                          FloatingActionButton.small(
                            heroTag: 'mouza_zoom_in',
                            backgroundColor: const Color(0xE60F172A),
                            foregroundColor: Colors.white,
                            onPressed: () => _setCanvasZoom(_canvasZoom * 1.4, canvasSize),
                            tooltip: 'মৌজা জুম ইন (+)',
                            child: const Icon(Icons.zoom_in, size: 20),
                          ),
                          const SizedBox(height: 6),
                          FloatingActionButton.small(
                            heroTag: 'mouza_zoom_out',
                            backgroundColor: const Color(0xE60F172A),
                            foregroundColor: Colors.white,
                            onPressed: () => _setCanvasZoom(_canvasZoom / 1.4, canvasSize),
                            tooltip: 'মৌজা জুম আউট (-)',
                            child: const Icon(Icons.zoom_out, size: 20),
                          ),
                          if (_canvasZoom != 1.0) ...[
                            const SizedBox(height: 6),
                            FloatingActionButton.small(
                              heroTag: 'mouza_zoom_reset',
                              backgroundColor: const Color(0xE60F5A38),
                              foregroundColor: Colors.white,
                              onPressed: _resetCanvasZoom,
                              tooltip: 'স্বাভাবিক সাইজ (১x)',
                              child: const Icon(Icons.center_focus_strong, size: 18),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Floating 1000-Link Digital Gunia Scale
                    if (_showGuniaScale)
                      DigitalGuniaScale(
                        pixelsPer100Links: (66.0 / _feetPerPixel),
                        onClose: () => setState(() => _showGuniaScale = false),
                      ),

                    // Precision Touch Loupe (works accurately even while sheet is zoomed)
                    if (_isTouchActive && transformedSceneTouch != null && !_isZoomPanMode)
                      TouchMagnifierLoupe(
                        touchPosition: transformedSceneTouch,
                        scaleFactor: 2.2,
                        sourceSize: canvasSize,
                        child: Transform(
                          transform: _transformationController.value,
                          child: SizedBox(
                            width: canvasSize.width,
                            height: canvasSize.height,
                            child: Stack(
                              children: [
                                Positioned.fill(child: _buildMapBackgroundLayer()),
                                cadCanvas,
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Bottom CAD Controls (Matching Image 3 bottom bar)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF0F172A),
            child: Row(
              children: [
                // Auto Division button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showAutoDivisionDialog,
                    icon: const Icon(Icons.call_split, size: 16, color: Colors.white),
                    label: const Text('অটো-ডিভিশন / বণ্টন', style: TextStyle(color: Colors.white, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF334155)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Undo button
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.undo, color: Color(0xFF166534), size: 20),
                    tooltip: 'পূর্বাবস্থায় ফিরুন',
                    onPressed: _undo,
                  ),
                ),
                const SizedBox(width: 8),

                // Delete vertex button
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 20),
                    tooltip: 'বিন্দু ডিলিট',
                    onPressed: _deleteLastPoint,
                  ),
                ),
                const SizedBox(width: 8),

                // Export / Share button (Image 3: green circle button)
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF14532D),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.file_upload_outlined, color: Colors.white, size: 20),
                    tooltip: 'এক্সপোর্ট / রিপোর্ট',
                    onPressed: _exportPdf,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// PAINTER 1: Subtle Graph Paper Background
// ==========================================
class _EngineeringGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0).withOpacity(0.4)
      ..strokeWidth = 0.8;

    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================
// PAINTER 2: CAD Canvas with Angles & Dimensions (Image 3)
// ==========================================
class _CadInteractivePainter extends CustomPainter {
  final List<Offset> points;
  final double feetPerPixel;
  final bool showAngles;
  final bool showDimensions;
  final bool highContrast;
  final bool showDivisionCutLine;
  final Offset? cutLineP1;
  final Offset? cutLineP2;
  final double targetCutDecimals;

  _CadInteractivePainter({
    required this.points,
    required this.feetPerPixel,
    required this.showAngles,
    required this.showDimensions,
    required this.highContrast,
    this.showDivisionCutLine = false,
    this.cutLineP1,
    this.cutLineP2,
    this.targetCutDecimals = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Dot Matrix Grid
    final dotPaint = Paint()
      ..color = (highContrast ? Colors.grey.shade400 : const Color(0xFF334155)).withOpacity(0.35)
      ..style = PaintingStyle.fill;

    const gridGap = 24.0;
    for (double x = 0; x < size.width; x += gridGap) {
      for (double y = 0; y < size.height; y += gridGap) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }

    if (points.length < 2) return;

    // 2. Draw Polygon Fill
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();

    final fillPaint = Paint()
      ..color = const Color(0xFF06B6D4).withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 3. Draw Polygon Stroke (Cyan #22D3EE as in Image 3)
    final strokePaint = Paint()
      ..color = const Color(0xFF22D3EE)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);

    // 4. Draw Side Dimension Badges (feet tags along sides, yellow on black)
    if (showDimensions && points.length >= 2) {
      for (int i = 0; i < points.length; i++) {
        final p1 = points[i];
        final p2 = points[(i + 1) % points.length];
        final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        final distPx = (p2 - p1).distance;
        final distFt = distPx * feetPerPixel;

        final textSpan = TextSpan(
          text: '${BanglaFormatter.formatNumber(distFt, fractionDigits: 1)}\'',
          style: const TextStyle(
            color: Color(0xFFFDE047), // Yellow text on dark badge (Image 3)
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
          ),
        );
        final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();

        // Draw dark badge background for clarity
        final badgeRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: mid, width: tp.width + 10, height: tp.height + 4),
          const Radius.circular(4),
        );
        canvas.drawRRect(badgeRect, Paint()..color = const Color(0xFF000000).withOpacity(0.85));
        tp.paint(canvas, mid - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // 5. Draw Auto-Division Cut Line if active
    if (showDivisionCutLine && cutLineP1 != null && cutLineP2 != null) {
      final cutPaint = Paint()
        ..color = const Color(0xFFF59E0B) // Amber/orange cutline
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      // Draw dashed line
      final pA = cutLineP1!;
      final pB = cutLineP2!;
      final totalDist = (pB - pA).distance;
      const dashWidth = 6.0;
      const dashSpace = 4.0;
      double currentDist = 0.0;

      while (currentDist < totalDist) {
        final start = Offset.lerp(pA, pB, currentDist / totalDist)!;
        final end = Offset.lerp(pA, pB, math.min(1.0, (currentDist + dashWidth) / totalDist))!;
        canvas.drawLine(start, end, cutPaint);
        currentDist += dashWidth + dashSpace;
      }

      // Draw Cut-Line Badge
      final midCut = Offset((pA.dx + pB.dx) / 2, (pA.dy + pB.dy) / 2);
      final cutSpan = TextSpan(
        text: 'কাটলাইন: ${BanglaFormatter.formatNumber(targetCutDecimals, fractionDigits: 1)} শতক',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      final tpCut = TextPainter(text: cutSpan, textDirection: TextDirection.ltr)..layout();
      final cutRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: midCut, width: tpCut.width + 12, height: tpCut.height + 4),
        const Radius.circular(4),
      );
      canvas.drawRRect(cutRect, Paint()..color = const Color(0xFFD97706));
      tpCut.paint(canvas, midCut - Offset(tpCut.width / 2, tpCut.height / 2));
    }

    // 6. Draw Vertices and Angles (Degrees e.g. ৯৮°, ৯৭°, ৮৭°, ৭৮°)
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];

      // Draw vertex handle circle (Cyan outer ring + pure white center)
      canvas.drawCircle(pt, 7.0, Paint()..color = const Color(0xFF22D3EE));
      canvas.drawCircle(pt, 4.0, Paint()..color = Colors.white);

      // Angle readout
      if (showAngles && points.length >= 3) {
        final prev = points[(i - 1 + points.length) % points.length];
        final next = points[(i + 1) % points.length];
        final v1 = prev - pt;
        final v2 = next - pt;
        final angleRad = (math.atan2(v2.dy, v2.dx) - math.atan2(v1.dy, v1.dx)).abs();
        double angleDeg = angleRad * (180.0 / math.pi);
        if (angleDeg > 180) angleDeg = 360 - angleDeg;

        final angleSpan = TextSpan(
          text: '${BanglaNumerals.toBangla(angleDeg.round())}°',
          style: const TextStyle(
            color: Color(0xFF86EFAC), // Mint green angle degree text (Image 3)
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        );
        final tpAngle = TextPainter(text: angleSpan, textDirection: TextDirection.ltr)..layout();
        tpAngle.paint(canvas, pt + const Offset(-10, -22));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CadInteractivePainter oldDelegate) => true;
}

class _CadastralSheetFallbackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFFBF7EE);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Cadastral border
    final borderPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(12, 12, size.width - 24, size.height - 24), borderPaint);

    // Fine grid
    final gridPaint = Paint()
      ..color = const Color(0xFFE2D9C8)
      ..strokeWidth = 0.8;
    for (double x = 20; x < size.width - 20; x += 40) {
      canvas.drawLine(Offset(x, 20), Offset(x, size.height - 20), gridPaint);
    }
    for (double y = 20; y < size.height - 20; y += 40) {
      canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), gridPaint);
    }

    // Parcel boundaries
    final parcelPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(40, 60);
    path.lineTo(size.width * 0.45, 55);
    path.lineTo(size.width * 0.42, size.height * 0.45);
    path.lineTo(35, size.height * 0.42);
    path.close();

    path.moveTo(size.width * 0.45, 55);
    path.lineTo(size.width - 40, 65);
    path.lineTo(size.width - 45, size.height * 0.45);
    path.lineTo(size.width * 0.42, size.height * 0.45);
    path.close();

    path.moveTo(35, size.height * 0.48);
    path.lineTo(size.width * 0.5, size.height * 0.48);
    path.lineTo(size.width * 0.48, size.height - 50);
    path.lineTo(40, size.height - 45);
    path.close();

    path.moveTo(size.width * 0.5, size.height * 0.48);
    path.lineTo(size.width - 40, size.height * 0.5);
    path.lineTo(size.width - 45, size.height - 50);
    path.lineTo(size.width * 0.48, size.height - 50);
    path.close();

    canvas.drawPath(path, parcelPaint);

    // Text labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    void drawText(String text, Offset pos, {double fontSize = 11, Color color = const Color(0xFF64748B)}) {
      tp.text = TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold),
      );
      tp.layout();
      tp.paint(canvas, pos);
    }

    drawText('মৌজা ক্যাডাস্ট্রাল জরিপ নকশা (CS / RS)', const Offset(20, 20), fontSize: 12, color: const Color(0xFF78350F));
    drawText('দাগ ১০১', Offset(size.width * 0.2, size.height * 0.22));
    drawText('দাগ ১০২', Offset(size.width * 0.65, size.height * 0.22));
    drawText('দাগ ১০৫', Offset(size.width * 0.2, size.height * 0.68), color: const Color(0xFF0369A1));
    drawText('দাগ ১০৬', Offset(size.width * 0.65, size.height * 0.68));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
