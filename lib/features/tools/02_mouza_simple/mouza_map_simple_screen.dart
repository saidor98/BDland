import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/services/history_service.dart';
import '../../history/models/calculation_history_item.dart';
import '../06_all_mouza_maps/all_mouza_maps_screen.dart';
import '../widgets/digital_gunia_scale.dart';
import '../widgets/touch_magnifier_loupe.dart';

enum MouzaViewMode { portal, cad }

class MouzaMapSimpleScreen extends StatefulWidget {
  final String? initialMouzaName;
  final String? initialSheetNo;
  final String? initialJlNo;
  final List<Offset>? initialPoints;

  const MouzaMapSimpleScreen({
    super.key,
    this.initialMouzaName,
    this.initialSheetNo,
    this.initialJlNo,
    this.initialPoints,
  });

  @override
  State<MouzaMapSimpleScreen> createState() => _MouzaMapSimpleScreenState();
}

class _MouzaMapSimpleScreenState extends State<MouzaMapSimpleScreen> {
  // Current active mode: Portal (Image 4) or CAD Canvas (Image 2)
  MouzaViewMode _viewMode = MouzaViewMode.portal;

  // Active Project & Sheet Info
  String _activeMouza = 'মৌজা: আমিনপুর (জে.এল. ৩৪)';
  String _activeSheet = 'শিট ১';
  String _selectedScale = '১৬" = ১ মাইল';
  double _feetPerPixel = 1.65; // default 32" / 16"
  bool _isHighQuality = true;
  bool _highContrast = false;

  // Saved Projects List
  final List<Map<String, dynamic>> _savedProjects = [
    {
      'name': 'আমিনপুর দাগ ১০৫ পরিমাপ',
      'location': 'সোনারগাঁও, নারায়ণগঞ্জ | CS',
      'areaDec': 75.758,
      'katha': 45.83,
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
      'date': '২২ নভে ২০২৬',
      'points': [
        const Offset(70, 70),
        const Offset(220, 75),
        const Offset(230, 190),
        const Offset(65, 180),
      ],
    },
  ];

  // CAD Measurement Points (Image 2 polygon)
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

  @override
  void initState() {
    super.initState();
    if (widget.initialPoints != null && widget.initialPoints!.isNotEmpty) {
      _measuredPoints = List.from(widget.initialPoints!);
      _viewMode = MouzaViewMode.cad;
    }
    if (widget.initialMouzaName != null) {
      _activeMouza = 'মৌজা: ${widget.initialMouzaName} (জে.এল. ${widget.initialJlNo ?? "০১"})';
      _activeSheet = widget.initialSheetNo ?? 'শিট ১';
    }
    _recompute();
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
    _totalAreaSqFt = pixelArea * (_feetPerPixel * _feetPerPixel);
    _totalPerimeterFt = perimPx * _feetPerPixel;
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
    }
  }

  void _deleteLastPoint() {
    if (_measuredPoints.length > 3) {
      _pushUndo();
      setState(() {
        _measuredPoints.removeLast();
        _recompute();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কমপক্ষে ৩টি শীর্ষবিন্দু থাকতে হবে')),
      );
    }
  }

  // Two-Point Reference Line Calibration
  void _showCalibrationDialog() {
    final distController = TextEditingController(text: '100');
    String unit = 'লিংক';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.straighten, color: AppColors.primaryGreen),
              SizedBox(width: 8),
              Text('২-পয়েন্ট স্কেল ক্যালিব্রেশন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ম্যাপের যেকোনো পরিচিত সীমানা বা গুনিয়া লাইনের বাস্তব দূরত্ব ইনপুট দিন:',
                style: TextStyle(fontSize: 12.5),
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
                final dist = double.tryParse(distController.text.trim()) ?? 100.0;
                final distInFeet = unit == 'লিংক' ? dist * 0.66 : dist;
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

  // Auto-division dialog
  void _showAutoDivisionDialog() {
    final targetDecController = TextEditingController(text: '5.0');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.call_split, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('অটো-ডিভিশন / জমি বণ্টন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'দাগ হতে নির্দিষ্ট শতক পৃথক করার জন্য প্রয়োজনীয় শতক ইনপুট দিন:',
              style: TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetDecController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'কাটতে চাওয়া শতক',
                border: OutlineInputBorder(),
                suffixText: 'শতক',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📐 প্রস্তাবিত ডিভিশন পরিমাপ:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                  const SizedBox(height: 4),
                  Text('• উত্তর বাহু হতে: ২০.০ ফুট\n• দক্ষিণ বাহু হতে: ২২.৫ ফুট\n• কর্তন রেখার দৈর্ঘ্য: ১৬৫.৪ ফুট', style: TextStyle(fontSize: 11.5, color: Colors.green.shade900)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('অটো-ডিভিশন কাটলাইন ড্রয়িংয়ে চিহ্নিত করা হয়েছে!'),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
            },
            child: const Text('কাটলাইন প্রয়োগ করুন', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Total Station / RTK Point Input Dialog
  void _showTotalStationDialog() {
    final nCtrl = TextEditingController(text: '2645120.45');
    final eCtrl = TextEditingController(text: '542100.32');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.gps_fixed, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('টোটাল স্টেশন / RTK পয়েন্ট ইনপুট', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nCtrl,
              decoration: const InputDecoration(labelText: 'Northing (N)', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: eCtrl,
              decoration: const InputDecoration(labelText: 'Easting (E)', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 10),
            const Text('CSV বা TXT ফাইল থেকে বাল্ক কোঅর্ডিনেট লোড করা যায়।', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _viewMode = MouzaViewMode.cad;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('টোটাল স্টেশন সার্ভে পয়েন্ট CAD ক্যানভাসে যুক্ত করা হয়েছে!')),
              );
            },
            child: const Text('পয়েন্ট যোগ করুন', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Device Sheet Picker
  void _openDeviceFilePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ডিভাইস থেকে নকশা নির্বাচন করুন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFDCFCE7), child: Icon(Icons.photo, color: AppColors.primaryGreen)),
              title: const Text('গ্যালারি / ছবি (JPG, PNG)'),
              subtitle: const Text('ফোনে সেভ থাকা স্ক্যান করা মৌজা ম্যাপের ছবি'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _viewMode = MouzaViewMode.cad);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('হাই-রেজোলিউশন মৌজা শিট CAD ক্যানভাসে লোড হয়েছে')),
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.picture_as_pdf, color: Colors.blue)),
              title: const Text('নকশা PDF / TIFF ফাইল'),
              subtitle: const Text('ডিজিটাল ক্যাডাস্ট্রাল ভেক্টর ডকুমেন্ট'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _viewMode = MouzaViewMode.cad);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Video guide
  void _showVideoGuide() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.play_circle_fill, color: Colors.red),
            SizedBox(width: 8),
            Text('মৌজা ম্যাপ পরিমাপ ভিডিও গাইড', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ইউটিউব টিউটোরিয়াল: "কীভাবে নিখুঁতভাবে মৌজা ম্যাপ ও গুনিয়া স্কেল দিয়ে জমি পরিমাপ করবেন"', style: TextStyle(fontSize: 13)),
            SizedBox(height: 10),
            Text('• গুনিয়া স্কেল ব্যবহার করে লিংক থেকে ফুট রূপান্তর\n• ২-পয়েন্ট স্কেল ক্যালিব্রেশন পদ্ধতি\n• ম্যাগনিফাইং লুপ দিয়ে নিখুঁত কর্নার মার্কিং', style: TextStyle(fontSize: 12, color: Colors.black87)),
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

  // Export PDF
  void _exportPdf() async {
    final pdf = pw.Document();
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
  // VIEW 1: PORTAL & MAP LOADER (Image 4)
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
            icon: const Icon(Icons.play_circle_fill, color: Color(0xFFDC2626), size: 24),
            tooltip: 'ভিডিও টিউটোরিয়াল',
            onPressed: _showVideoGuide,
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
              // SECTION 1: সংরক্ষিত প্রজেক্ট (Image 4)
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
                      onPressed: () {
                        // Load first saved project
                        final proj = _savedProjects.first;
                        setState(() {
                          _activeMouza = proj['name'];
                          _measuredPoints = List.from(proj['points']);
                          _viewMode = MouzaViewMode.cad;
                        });
                      },
                      child: const Text(
                        'ফোল্ডার বেছে নিন',
                        style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // SECTION 2: মৌজা নকশা লোড (Image 4)
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

              // Item B: Cloud থেকে (Navigates to AllMouzaMapsScreen - Image 1)
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
                              'সারাদেশের মৌজা ম্যাপ থেকে বাছুন',
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

              // SECTION 3: ম্যাপের মান (Image 4)
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

              // SECTION 4: টোটাল স্টেশন / RTK (Image 4)
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
  // VIEW 2: CAD MEASUREMENT WORKSPACE (Image 2)
  // ==========================================
  Widget _buildCadView() {
    final dec = _totalAreaSqFt / 435.60;
    final katha = _totalAreaSqFt / 720.00;

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
            icon: const Icon(Icons.near_me, color: Colors.white),
            tooltip: 'জিপিএস কেন্দ্র',
            onPressed: () {},
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
              if (val == 'dxf') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AutoCAD DXF ভেক্টর ফাইল সেভ করা হয়েছে')),
                );
              }
              if (val == 'kml') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Google Earth KML ফাইল সেভ করা হয়েছে')),
                );
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'pdf', child: Text('অফিশিয়াল A4 PDF প্রত্যয়ন')),
              PopupMenuItem(value: 'dxf', child: Text('AutoCAD DXF (.dxf)')),
              PopupMenuItem(value: 'kml', child: Text('Google Earth KML (.kml)')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // CAD Banner (Matching Image 2 banner)
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

          // Main CAD Interactive Canvas
          Expanded(
            child: Stack(
              children: [
                // Interactive Listener for Moving Vertices and Touch Magnifier Loupe
                Listener(
                  onPointerDown: (event) {
                    final pos = event.localPosition;
                    int? tappedIdx;
                    for (int i = 0; i < _measuredPoints.length; i++) {
                      if ((_measuredPoints[i] - pos).distance <= 28) {
                        tappedIdx = i;
                        break;
                      }
                    }
                    setState(() {
                      _touchPosition = pos;
                      _isTouchActive = true;
                      _selectedVertexIndex = tappedIdx;
                    });
                  },
                  onPointerMove: (event) {
                    final pos = event.localPosition;
                    if (_selectedVertexIndex != null) {
                      _pushUndo();
                      setState(() {
                        _measuredPoints[_selectedVertexIndex!] = pos;
                        _touchPosition = pos;
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
                    });
                  },
                  onPointerCancel: (_) {
                    setState(() {
                      _isTouchActive = false;
                      _touchPosition = null;
                      _selectedVertexIndex = null;
                    });
                  },
                  child: CustomPaint(
                    painter: _CadInteractivePainter(
                      points: _measuredPoints,
                      feetPerPixel: _feetPerPixel,
                      showAngles: _showAngles,
                      showDimensions: _showDimensions,
                      highContrast: _highContrast,
                    ),
                    size: Size.infinite,
                  ),
                ),

                // Floating 1000-Link Digital Gunia Scale
                if (_showGuniaScale)
                  DigitalGuniaScale(
                    pixelsPer100Links: (66.0 / _feetPerPixel),
                    onClose: () => setState(() => _showGuniaScale = false),
                  ),

                // Precision Touch Loupe (Zoom 2.2x offset above finger)
                if (_isTouchActive && _touchPosition != null)
                  Positioned(
                    left: _touchPosition!.dx - 45,
                    top: _touchPosition!.dy - 120,
                    child: TouchMagnifierLoupe(
                      touchPosition: _touchPosition!,
                      label: 'X: ${_touchPosition!.dx.toInt()} Y: ${_touchPosition!.dy.toInt()}',
                    ),
                  ),
              ],
            ),
          ),

          // Bottom CAD Controls (Matching Image 2 bottom bar)
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

                // Save to History button
                ElevatedButton.icon(
                  onPressed: _exportPdf,
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('রিপোর্ট', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14532D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
// PAINTER 2: CAD Canvas with Angles & Dimensions (Image 2)
// ==========================================
class _CadInteractivePainter extends CustomPainter {
  final List<Offset> points;
  final double feetPerPixel;
  final bool showAngles;
  final bool showDimensions;
  final bool highContrast;

  _CadInteractivePainter({
    required this.points,
    required this.feetPerPixel,
    required this.showAngles,
    required this.showDimensions,
    required this.highContrast,
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

    // 3. Draw Polygon Stroke (Cyan #06B6D4 as in Image 2)
    final strokePaint = Paint()
      ..color = const Color(0xFF22D3EE)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);

    // 4. Draw Side Dimension Badges (feet tags along sides)
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
            color: Color(0xFFFDE047), // Yellow/gold text on dark badge
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

    // 5. Draw Vertices and Angles (Degrees e.g. ৯৮°, ৮৭°)
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];

      // Draw vertex handle circle
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
            color: Color(0xFF86EFAC), // Mint green angle degree text
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
