import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/services/history_service.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/utils/polygon_geometry.dart';
import '../../geometry/models/geometry_models.dart';
import '../../geometry/screens/polygon_screen.dart';
import '../../geometry/services/geometry_calculator.dart';
import '../../history/models/calculation_history_item.dart';

class QuadMasterScreen extends StatefulWidget {
  const QuadMasterScreen({super.key});

  @override
  State<QuadMasterScreen> createState() => _QuadMasterScreenState();
}

class _QuadMasterScreenState extends State<QuadMasterScreen> {
  // Tabs: 0: ১ বাহু, 1: ২ পদ্ধতি, 2: ৩ ক্ষেত্রফল, 3: ৪ বণ্টন (Page 2)
  int _activeTab = 0;

  final _northCtrl = TextEditingController(text: '120.0');
  final _southCtrl = TextEditingController(text: '110.0');
  final _eastCtrl = TextEditingController(text: '80.0');
  final _westCtrl = TextEditingController(text: '85.0');
  final _diagXCtrl = TextEditingController(text: '145.0');
  final _diagYCtrl = TextEditingController(text: '140.0');

  bool _showDiagX = true;
  bool _showDiagY = false;
  bool _showAngles = false;
  bool _showSideNames = true;

  int _divisionParts = 2; // Split into 2 shares
  QuadrilateralResult? _result;

  final List<Map<String, String>> _undoStack = [];
  final List<Map<String, String>> _redoStack = [];
  Map<String, String>? _lastMeasurementState;

  Map<String, String> _getCurrentState() {
    return {
      'n': _northCtrl.text,
      's': _southCtrl.text,
      'e': _eastCtrl.text,
      'w': _westCtrl.text,
      'dx': _diagXCtrl.text,
      'dy': _diagYCtrl.text,
    };
  }

  void _pushUndoState() {
    final stateToSave = _lastMeasurementState ?? _getCurrentState();
    _undoStack.add(Map<String, String>.from(stateToSave));
    if (_undoStack.length > 20) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void _onInputChanged() {
    _pushUndoState();
    _lastMeasurementState = _getCurrentState();
    _calculate();
  }

  void _undo() {
    if (_undoStack.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('আর পূর্বাবস্থায় ফেরার তথ্য নেই'), duration: Duration(seconds: 1)),
      );
      return;
    }
    _redoStack.add(_getCurrentState());
    final prev = _undoStack.removeLast();
    _northCtrl.text = prev['n']!;
    _southCtrl.text = prev['s']!;
    _eastCtrl.text = prev['e']!;
    _westCtrl.text = prev['w']!;
    _diagXCtrl.text = prev['dx']!;
    _diagYCtrl.text = prev['dy']!;
    _lastMeasurementState = _getCurrentState();
    _calculate();
    setState(() {});
  }

  void _redo() {
    if (_redoStack.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সামনে যাওয়ার তথ্য নেই'), duration: Duration(seconds: 1)),
      );
      return;
    }
    _undoStack.add(_getCurrentState());
    final next = _redoStack.removeLast();
    _northCtrl.text = next['n']!;
    _southCtrl.text = next['s']!;
    _eastCtrl.text = next['e']!;
    _westCtrl.text = next['w']!;
    _diagXCtrl.text = next['dx']!;
    _diagYCtrl.text = next['dy']!;
    _lastMeasurementState = _getCurrentState();
    _calculate();
    setState(() {});
  }

  void _showTutorialGuideDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.school, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('চতুর্ভুজ পরিমাপ প্রশিক্ষণ গাইড', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '১. বিষমবাহু চতুর্ভুজ ও কর্ণ পদ্ধতি:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              SizedBox(height: 4),
              Text(
                'যেকোনো চারকোনা জমির প্রকৃত ক্ষেত্রফল বের করতে কর্ণ (Diagonal) মেপে জমিকে দুটি ত্রিভুজে বিভক্ত করে হেরন সূত্রে ক্ষেত্রফল বের করতে হয়।',
                style: TextStyle(fontSize: 12, color: Color(0xFF334155)),
              ),
              SizedBox(height: 10),
              Text(
                '২. আমিনের গড় পদ্ধতির মারাত্মক ভুল:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFDC2626)),
              ),
              SizedBox(height: 4),
              Text(
                'উত্তর+দক্ষিণ/২ × পূর্ব+পশ্চিম/২ করলে প্রকৃত ক্ষেত্রফলের চেয়ে জমি বেশি বা কম দেখায়। এটি আদালত বা সরকার কর্তৃক স্বীকৃত নয়।',
                style: TextStyle(fontSize: 12, color: Color(0xFF334155)),
              ),
              SizedBox(height: 10),
              Text(
                '৩. ত্রিভুজীয় অসমতা নিয়ম:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0369A1)),
              ),
              SizedBox(height: 4),
              Text(
                'কর্ণের মান সবসময় অপর দুই বাহুর যোগফলের চেয়ে ছোট এবং বিয়োগফলের চেয়ে বড় হতে হবে।',
                style: TextStyle(fontSize: 12, color: Color(0xFF334155)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বুঝেছি')),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('হিসাব ও ডিসপ্লে সেটিংস', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              dense: true,
              leading: Icon(Icons.calculate, color: Color(0xFF0284C7)),
              title: Text('পদ্ধতি: হেরন সূত্র (আইনসম্মত ও নিখুঁত)'),
              subtitle: Text('কর্ণসহ দুটি স্বতন্ত্র ত্রিভুজ সমাধান'),
            ),
            ListTile(
              dense: true,
              leading: Icon(Icons.straighten, color: Color(0xFF16A34A)),
              title: Text('একক রূপান্তর: ফুট ↔ লিংক ↔ শতাংশ'),
              subtitle: Text('১ শতক = ৪৩৫.৬০ বর্গফুট = ১০০০ বর্গলিংক'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ঠিক আছে')),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _lastMeasurementState = _getCurrentState();
    _calculate();
  }

  @override
  void dispose() {
    _northCtrl.dispose();
    _southCtrl.dispose();
    _eastCtrl.dispose();
    _westCtrl.dispose();
    _diagXCtrl.dispose();
    _diagYCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final n = double.tryParse(_northCtrl.text) ?? 0;
    final s = double.tryParse(_southCtrl.text) ?? 0;
    final e = double.tryParse(_eastCtrl.text) ?? 0;
    final w = double.tryParse(_westCtrl.text) ?? 0;
    final d = double.tryParse(_diagXCtrl.text) ?? 0;

    if (n > 0 && s > 0 && e > 0 && w > 0 && d > 0) {
      setState(() {
        _result = GeometryCalculator.calculateQuadrilateral(
          north: n,
          east: e,
          south: s,
          west: w,
          diagonal: d,
        );
      });
    }
  }

  String _generateReport() {
    if (_result == null) return '';
    final r = _result!;
    final perPersonDec = r.exactAreaDecimal / _divisionParts;
    final perPersonSqFt = r.exactAreaSqFt / _divisionParts;

    final buffer = StringBuffer();
    buffer.writeln('=== QuadMaster চতুর্ভুজ পরিমাপ ও বণ্টন রিপোর্ট ===');
    buffer.writeln('তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}');
    buffer.writeln('বাহুসমূহ: উত্তর: ${r.sideNorth}\', দক্ষিণ: ${r.sideSouth}\', পূর্ব: ${r.sideEast}\', পশ্চিম: ${r.sideWest}\', কর্ণ: ${r.diagonal}\'');
    buffer.writeln('[হেরন্স ফর্মুলায় প্রকৃত ক্ষেত্রফল]');
    buffer.writeln('মোট শতাংশ: ${BanglaFormatter.formatNumber(r.exactAreaDecimal, fractionDigits: 3)} শতক');
    buffer.writeln('মোট কাঠা: ${BanglaFormatter.formatNumber(r.exactAreaKatha, fractionDigits: 3)} কাঠা');
    buffer.writeln('মোট বর্গফুট: ${BanglaFormatter.formatNumber(r.exactAreaSqFt)} ft²');
    buffer.writeln('\n[আমিনের গড় পদ্ধতির সাথে তুলনা]');
    buffer.writeln('গড় পদ্ধতিতে ক্ষেত্রফল: ${BanglaFormatter.formatNumber(r.averageAreaDecimal, fractionDigits: 3)} শতক');
    buffer.writeln('পার্থক্য / ত্রুটি: ${BanglaFormatter.formatNumber(r.diffDecimal.abs(), fractionDigits: 3)} শতক (${BanglaFormatter.formatPercentage(r.percentageError)})');
    buffer.writeln('\n[সমান $_divisionParts ভাগে বণ্টন]');
    buffer.writeln('জনপ্রতি জমির পরিমাণ: ${BanglaFormatter.formatNumber(perPersonDec, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(perPersonSqFt)} ft²)');
    buffer.writeln('জনপ্রতি কাঠা: ${BanglaFormatter.formatNumber(perPersonSqFt / 720.0, fractionDigits: 3)} কাঠা');
    buffer.writeln('\nঅ্যাপ: BDLandPro - পেশাদার বাংলাদেশ ভূমি জরিপ');
    return buffer.toString();
  }

  void _copyReport() {
    Clipboard.setData(ClipboardData(text: _generateReport()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QuadMaster রিপোর্ট কপি করা হয়েছে!'), backgroundColor: AppColors.primaryGreen),
    );
  }

  Future<void> _saveToHistory() async {
    final r = _result;
    if (r == null || !r.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সঠিক চতুর্ভুজ মান দিয়ে হিসাব করুন'), backgroundColor: AppColors.accentCrimson),
      );
      return;
    }
    final item = CalculationHistoryItem(
      id: 'quad_${DateTime.now().millisecondsSinceEpoch}',
      title: 'QuadMaster চতুর্ভুজ (${BanglaFormatter.formatNumber(r.exactAreaDecimal, fractionDigits: 2)} শতক)',
      category: 'জ্যামিতি',
      timestamp: DateTime.now(),
      inputSummary: 'উ: ${r.sideNorth}\', দ: ${r.sideSouth}\', পূ: ${r.sideEast}\', প: ${r.sideWest}\', কর্ণ: ${r.diagonal}\'',
      resultSummary: '${BanglaFormatter.formatNumber(r.exactAreaDecimal, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(r.exactAreaSqFt)} sq ft)',
      fullReportBangla: _generateReport(),
    );
    await HistoryService.instance.saveItem(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('হিসাব ইতিহাসে সংরক্ষণ করা হয়েছে'), backgroundColor: AppColors.primaryGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    final areaDec = r?.exactAreaDecimal ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'চতুর্ভুজ পরিমাপ ও বণ্টন',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'QuadMaster Pro • হিরন ও গড় পদ্ধতি',
              style: TextStyle(fontSize: 10.5, color: Color(0xFFFFDEA3)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.white, size: 20),
            tooltip: 'পূর্বাবস্থা (Undo)',
            onPressed: _undo,
          ),
          IconButton(
            icon: const Icon(Icons.redo, color: Colors.white, size: 20),
            tooltip: 'পুনরাবৃত্তি (Redo)',
            onPressed: _redo,
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_fill, color: Color(0xFFFFC64D), size: 22),
            tooltip: 'প্রশিক্ষণ ও নিয়মাবলি',
            onPressed: _showTutorialGuideDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (val) {
              if (val == 'copy') _copyReport();
              if (val == 'save') _saveToHistory();
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'save', child: Text('ইতিহাসে সেভ করুন')),
              PopupMenuItem(value: 'copy', child: Text('রিপোর্ট কপি করুন')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. FOUR TABS: ১ বাহু | ২ পদ্ধতি | ৩ ক্ষেত্রফল | ৪ বণ্টন (Page 2)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                _buildTabItem(0, '১  বাহু'),
                _buildTabItem(1, '২  পদ্ধতি'),
                _buildTabItem(2, '৩  ক্ষেত্রফল'),
                _buildTabItem(3, '৪  বণ্টন'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2. Extra sides button -> PolygonScreen
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PolygonScreen()),
              );
            },
            icon: const Icon(Icons.straighten, size: 16, color: AppColors.primaryGreen),
            label: const Text('আরও ৪+ বাহু / বহুভুজ মাপুন', style: TextStyle(color: AppColors.primaryGreen, fontSize: 13, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryGreen),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),

          const SizedBox(height: 14),

          // 3. INTERACTIVE CANVAS HEADER (Page 2)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.crop_square, color: Color(0xFF2563EB), size: 18),
                  SizedBox(width: 6),
                  Text('ইন্টারেক্টিভ ক্যানভাস', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  'মোট: ${BanglaFormatter.formatNumber(areaDec, fractionDigits: 3)} শতক',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1D4ED8)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 4. CANVAS TOOLBAR: [X-কর্ণ] [Y-কর্ণ] [কোণ] [নাম/ক্ষেত্রফল] [সেটিং] (Page 2)
          Row(
            children: [
              _buildCanvasToolButton('X-কর্ণ', _showDiagX, () => setState(() => _showDiagX = !_showDiagX)),
              const SizedBox(width: 6),
              _buildCanvasToolButton('Y-কর্ণ', _showDiagY, () => setState(() => _showDiagY = !_showDiagY)),
              const SizedBox(width: 6),
              _buildCanvasToolButton('কোণ', _showAngles, () => setState(() => _showAngles = !_showAngles)),
              const SizedBox(width: 6),
              _buildCanvasToolButton('নাম/ক্ষেত্রফল', _showSideNames, () => setState(() => _showSideNames = !_showSideNames)),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Color(0xFF64748B), size: 18),
                  tooltip: 'সেটিংস',
                  onPressed: _showSettingsDialog,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 5. INTERACTIVE QUADRILATERAL CANVAS (Page 2)
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: CustomPaint(
              size: Size.infinite,
              painter: _QuadInteractivePainter(
                north: double.tryParse(_northCtrl.text) ?? 120,
                south: double.tryParse(_southCtrl.text) ?? 110,
                east: double.tryParse(_eastCtrl.text) ?? 80,
                west: double.tryParse(_westCtrl.text) ?? 85,
                diagX: double.tryParse(_diagXCtrl.text) ?? 145,
                showDiagX: _showDiagX,
                showDiagY: _showDiagY,
                showAngles: _showAngles,
                showSideNames: _showSideNames,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 6. BOTTOM CANVAS ACTION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.edit_note, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 6),
                  Text('প্রকৃত কোণ ও বাহু অনুযায়ী স্কেল করা', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _calculate();
                  setState(() {});
                },
                icon: const Icon(Icons.fullscreen, size: 14),
                label: const Text('ফিট', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (r != null && !r.isValid)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.accentCrimson),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r.messageBangla.isNotEmpty
                          ? r.messageBangla
                          : 'অবাস্তব পরিমাপ! কর্ণের দৈর্ঘ্য ত্রিভুজীয় অসমতা নিয়ম মেনে চলেনি।',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          if (_activeTab == 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: Color(0xFF2563EB)),
                    SizedBox(width: 6),
                    Text('চার বাহুর পরিমাপ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                  ],
                ),
                Text('ধাপ ১', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ফুট দশমিক ফরম্যাটে মান দিন। যেমন: ১২০.৫ মানে ১২০.৫ ফুট। কর্ণ AC সঠিকভাবে দিলে প্রকৃত আকার আঁকা হবে।',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildInput(_northCtrl, 'উত্তর বাহু (ফুট)')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInput(_southCtrl, 'দক্ষিণ বাহু (ফুট)')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildInput(_eastCtrl, 'পূর্ব বাহু (ফুট)')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInput(_westCtrl, 'পশ্চিম বাহু (ফুট)')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInput(_diagXCtrl, 'কর্ণের দৈর্ঘ্য (AC কর্ণ ফুট)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (r != null && r.isValid)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF14532D),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('হেরন্স ফর্মুলায় প্রকৃত জমি:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Row(
                          children: [
                            Text(
                              '${BanglaFormatter.formatNumber(r.exactAreaDecimal, fractionDigits: 3)} শতক',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _saveToHistory,
                              child: const Icon(Icons.bookmark_add_outlined, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('কাঠা: ${BanglaFormatter.formatNumber(r.exactAreaKatha, fractionDigits: 2)} কাঠা', style: const TextStyle(color: Colors.white)),
                        Text('বর্গফুট: ${BanglaFormatter.formatNumber(r.exactAreaSqFt)} sq ft', style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
          ] else if (_activeTab == 1 && r != null && r.isValid) ...[
            _buildMethodComparisonTab(r),
          ] else if (_activeTab == 2 && r != null && r.isValid) ...[
            _buildAreaUnitsTab(r),
          ] else if (_activeTab == 3 && r != null && r.isValid) ...[
            _buildDivisionTab(r),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildMethodComparisonTab(QuadrilateralResult r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('হেরন সূত্র (আইনসম্মত ২ ত্রিভুজ পদ্ধতি)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF14532D))),
                const SizedBox(height: 10),
                _buildCompRow('১ম ত্রিভুজ (উত্তর + পূর্ব + কর্ণ AC)', '${BanglaFormatter.formatNumber(r.triangle1AreaSqFt)} sq ft'),
                _buildCompRow('২য় ত্রিভুজ (দক্ষিণ + পশ্চিম + কর্ণ AC)', '${BanglaFormatter.formatNumber(r.triangle2AreaSqFt)} sq ft'),
                const Divider(),
                _buildCompRow('প্রকৃত মোট ক্ষেত্রফল', '${BanglaFormatter.formatNumber(r.exactAreaDecimal, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(r.exactAreaSqFt)} sq ft)', isBold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFFFFFBEB),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFFDE68A))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('আমিনের গড় পদ্ধতি বনাম প্রকৃত ফলাফল', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFB45309))),
                const SizedBox(height: 10),
                _buildCompRow('গড় পদ্ধতিতে ক্ষেত্রফল', '${BanglaFormatter.formatNumber(r.averageAreaDecimal, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(r.averageAreaSqFt)} sq ft)'),
                _buildCompRow('ত্রুটির পরিমাণ', '${BanglaFormatter.formatNumber(r.diffDecimal.abs(), fractionDigits: 3)} শতক (${BanglaFormatter.formatPercentage(r.percentageError)})'),
                const SizedBox(height: 6),
                Text(
                  r.percentageError > 0.5
                      ? 'সতর্কতা: গড় পদ্ধতিতে জমি প্রকৃতের চেয়ে বেশি বা কম দেখাচ্ছে — দলিল ও বণ্টনে হেরন সূত্র ব্যবহার করুন।'
                      : 'জমি প্রায় আয়তাকার হওয়ায় দুই পদ্ধতির পার্থক্য খুব সামান্য।',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF78350F)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAreaUnitsTab(QuadrilateralResult r) {
    final sqFt = r.exactAreaSqFt;
    final dec = r.exactAreaDecimal;
    final katha = r.exactAreaKatha;
    final bigha = dec / 33.0;
    final acre = dec / 100.0;
    final sqMeter = sqFt * 0.092903;
    final sqLink = sqFt * (1000.0 / 435.6);

    return Column(
      children: [
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('সকল ভূমি এককে প্রকৃত ক্ষেত্রফল', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                const SizedBox(height: 10),
                _buildCompRow('শতাংশ / শতক', '${BanglaFormatter.formatNumber(dec, fractionDigits: 4)} শতক', isBold: true),
                _buildCompRow('কাঠা (৭২০ বর্গফুট)', '${BanglaFormatter.formatNumber(katha, fractionDigits: 4)} কাঠা'),
                _buildCompRow('বিঘা (৩৩ শতক)', '${BanglaFormatter.formatNumber(bigha, fractionDigits: 4)} বিঘা'),
                _buildCompRow('একর (১০০ শতক)', '${BanglaFormatter.formatNumber(acre, fractionDigits: 4)} একর'),
                _buildCompRow('বর্গফুট (sq ft)', '${BanglaFormatter.formatNumber(sqFt)} বর্গফুট'),
                _buildCompRow('বর্গমিটার (m²)', '${BanglaFormatter.formatNumber(sqMeter)} বর্গমিটার'),
                _buildCompRow('বর্গলিংক (sq link)', '${BanglaFormatter.formatNumber(sqLink)} বর্গলিংক'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saveToHistory,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('ইতিহাসে সেভ'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyReport,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('রিপোর্ট কপি'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDivisionTab(QuadrilateralResult r) {
    final perPersonDec = r.exactAreaDecimal / _divisionParts;
    final perPersonSqFt = r.exactAreaSqFt / _divisionParts;
    final perPersonKatha = perPersonSqFt / 720.0;

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('অংশীদার / ওয়ারিশদের মাঝে সমান বণ্টন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('ভাগ সংখ্যা: ${BanglaNumerals.toBangla(_divisionParts)} জন', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                Expanded(
                  child: Slider(
                    value: _divisionParts.toDouble(),
                    min: 2,
                    max: 12,
                    divisions: 10,
                    onChanged: (v) => setState(() => _divisionParts = v.round()),
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildCompRow('প্রতি অংশের জমি (শতক)', '${BanglaFormatter.formatNumber(perPersonDec, fractionDigits: 3)} শতক', isBold: true),
            _buildCompRow('প্রতি অংশের জমি (কাঠা)', '${BanglaFormatter.formatNumber(perPersonKatha, fractionDigits: 3)} কাঠা'),
            _buildCompRow('প্রতি অংশের ক্ষেত্রফল', '${BanglaFormatter.formatNumber(perPersonSqFt)} বর্গফুট'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _copyReport,
                icon: const Icon(Icons.share, size: 18),
                label: const Text('বণ্টন রিপোর্ট কপি করুন'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: TextStyle(fontSize: 12.5, color: isBold ? const Color(0xFF0F172A) : const Color(0xFF475569), fontWeight: isBold ? FontWeight.bold : FontWeight.normal))),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isBold ? const Color(0xFF14532D) : const Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isSel = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                color: isSel ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasToolButton(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onChanged: (_) => _onInputChanged(),
    );
  }
}

// Interactive Painter for QuadMaster (Page 2)
class _QuadInteractivePainter extends CustomPainter {
  final double north;
  final double south;
  final double east;
  final double west;
  final double diagX;
  final bool showDiagX;
  final bool showDiagY;
  final bool showAngles;
  final bool showSideNames;

  _QuadInteractivePainter({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
    required this.diagX,
    required this.showDiagX,
    required this.showDiagY,
    required this.showAngles,
    required this.showSideNames,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 42.0;
    final solved = PolygonGeometry.solveQuadrilateralVertices(
      north: north,
      east: east,
      south: south,
      west: west,
      diagAC: diagX,
    );

    List<Offset> pts;
    if (solved != null) {
      double minX = solved.map((p) => p.dx).reduce(math.min);
      double maxX = solved.map((p) => p.dx).reduce(math.max);
      double minY = solved.map((p) => p.dy).reduce(math.min);
      double maxY = solved.map((p) => p.dy).reduce(math.max);
      final spanX = math.max(maxX - minX, 1e-6);
      final spanY = math.max(maxY - minY, 1e-6);
      final availW = math.max(size.width - pad * 2, 10.0);
      final availH = math.max(size.height - pad * 2, 10.0);
      final scale = math.min(availW / spanX, availH / spanY);
      final offsetX = (size.width - spanX * scale) / 2.0 - minX * scale;
      final offsetY = (size.height - spanY * scale) / 2.0 - minY * scale;
      pts = solved.map((p) => Offset(p.dx * scale + offsetX, p.dy * scale + offsetY)).toList();
    } else {
      final w = size.width - (pad * 2);
      final h = size.height - (pad * 2);
      pts = [
        const Offset(pad, pad),
        Offset(pad + w, pad),
        Offset(pad + w, pad + h),
        Offset(pad, pad + h),
      ];
    }

    final pA = pts[0];
    final pB = pts[1];
    final pC = pts[2];
    final pD = pts[3];

    // 1. Polygon Fill
    final path = Path()
      ..moveTo(pA.dx, pA.dy)
      ..lineTo(pB.dx, pB.dy)
      ..lineTo(pC.dx, pC.dy)
      ..lineTo(pD.dx, pD.dy)
      ..close();

    final fillPaint = Paint()
      ..color = solved != null ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 2. Stroke
    final strokePaint = Paint()
      ..color = solved != null ? const Color(0xFF1E293B) : const Color(0xFFDC2626)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);

    // 3. Diagonal X (A -> C)
    if (showDiagX) {
      final diagPaint = Paint()
        ..color = const Color(0xFF6366F1)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      canvas.drawLine(pA, pC, diagPaint);
    }

    // 4. Diagonal Y (B -> D)
    if (showDiagY) {
      final diagPaint2 = Paint()
        ..color = const Color(0xFFEC4899)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      canvas.drawLine(pB, pD, diagPaint2);
      final diagBDLen = (pB - pD).distance;
      final diagScale = solved != null ? (diagBDLen / ((pA - pC).distance > 0 ? (pA - pC).distance : 1.0)) * diagX : 0.0;
      if (diagScale > 0) {
        _drawCenteredText(
          canvas,
          'BD=${diagScale.toStringAsFixed(1)}\'',
          Offset((pB.dx + pD.dx) / 2, (pB.dy + pD.dy) / 2 + 10),
          color: const Color(0xFFDB2777),
        );
      }
    }

    // 5. Corner letters & Interior Angles
    final centroid = Offset(
      (pA.dx + pB.dx + pC.dx + pD.dx) / 4.0,
      (pA.dy + pB.dy + pC.dy + pD.dy) / 4.0,
    );
    const cornerNames = ['A', 'B', 'C', 'D'];
    for (int i = 0; i < 4; i++) {
      final prev = pts[(i + 3) % 4];
      final curr = pts[i];
      final next = pts[(i + 1) % 4];
      canvas.drawCircle(curr, 3.5, Paint()..color = const Color(0xFF2563EB));
      final outVec = curr - centroid;
      final outLen = outVec.distance > 1e-6 ? outVec.distance : 1.0;
      final outDir = Offset(outVec.dx / outLen, outVec.dy / outLen);
      _drawCenteredText(
        canvas,
        cornerNames[i],
        curr + outDir * 14,
        color: const Color(0xFF0F172A),
      );
      if (showAngles && solved != null) {
        final angle = PolygonGeometry.calculateInteriorAngleDegrees(prev, curr, next);
        _drawCenteredText(
          canvas,
          '${angle.toStringAsFixed(0)}°',
          curr - outDir * 18,
          color: const Color(0xFF0369A1),
        );
      }
    }

    // 6. Side Name Labels
    if (showSideNames) {
      final edges = [
        (pA, pB, 'উত্তর (${north.toStringAsFixed(1)}\')'),
        (pB, pC, 'পূর্ব (${east.toStringAsFixed(1)}\')'),
        (pC, pD, 'দক্ষিণ (${south.toStringAsFixed(1)}\')'),
        (pD, pA, 'পশ্চিম (${west.toStringAsFixed(1)}\')'),
      ];
      for (final edge in edges) {
        final mid = Offset((edge.$1.dx + edge.$2.dx) / 2, (edge.$1.dy + edge.$2.dy) / 2);
        final outVec = mid - centroid;
        final outLen = outVec.distance > 1e-6 ? outVec.distance : 1.0;
        final pos = mid + Offset(outVec.dx / outLen, outVec.dy / outLen) * 14;
        _drawCenteredText(canvas, edge.$3, pos, color: Colors.red);
      }
    }
  }

  void _drawCenteredText(Canvas canvas, String text, Offset center, {Color color = Colors.black, bool isVertical = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();

    if (isVertical) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    } else {
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _QuadInteractivePainter oldDelegate) => true;
}
