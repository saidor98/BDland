import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/services/history_service.dart';
import '../../history/models/calculation_history_item.dart';
import '../../geometry/models/geometry_models.dart';
import '../../geometry/services/geometry_calculator.dart';

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

  @override
  void initState() {
    super.initState();
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
    buffer.writeln('\n[সমান ${_divisionParts} ভাগে বণ্টন]');
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

  @override
  Widget build(BuildContext context) {
    final r = _result;
    final areaDec = r?.exactAreaDecimal ?? 0.0;

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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'চতুর্ভুজ পরিম...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            Text(
              'QuadMaster Pro',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo, color: Color(0xFF334155), size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.redo, color: Color(0xFF334155), size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_fill, color: Colors.red, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('চতুর্ভুজ পরিমাপের ভিডিও টিউটোরিয়াল চালু হচ্ছে...')),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF334155)),
            onSelected: (val) {
              if (val == 'copy') _copyReport();
            },
            itemBuilder: (ctx) => const [
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

          // 2. Extra sides button
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('বহুভুজ / অতিরিক্ত বাহু মোড চালু হয়েছে')),
              );
            },
            icon: const Icon(Icons.straighten, size: 16, color: Color(0xFF2563EB)),
            label: const Text('আরও ৪টি বাহুর মাপ দিন', style: TextStyle(color: Color(0xFF2563EB), fontSize: 13)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFBFDBFE)),
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
                  onPressed: () {},
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
            child: Stack(
              children: [
                CustomPaint(
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
                // Corner labels A, B, C, D
                const Positioned(top: 14, left: 24, child: Text('A', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)))),
                const Positioned(top: 14, right: 24, child: Text('B', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)))),
                const Positioned(bottom: 14, right: 24, child: Text('C', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)))),
                const Positioned(bottom: 14, left: 24, child: Text('D', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)))),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 6. BOTTOM CANVAS ACTION: মাপে ক্লিক করে এডিট করুন | [ফিট] (Page 2)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.edit_note, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 6),
                  Text('মাপে ক্লিক করে এডিট করুন', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
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

          // 7. INPUT FIELDS SECTION: চার বাহুর পরিমাপ - ধাপ ১ (Page 2)
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

          // TIP CARD (Page 2)
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
                    'ফুট ও ইঞ্চিতে দশমিক ফরম্যাটে মান দিন। যেমন: ১২০.১১ মানে ১২০ ফুট ১১ ইঞ্চি।',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Input text fields (North, South, East, West, Diag)
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
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

          // 8. Results Card
          if (r != null && r.isValid)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF14532D), // Emerald card
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('হেরন্স ফর্মুলায় প্রকৃত জমি:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text(
                        '${BanglaFormatter.formatNumber(r.exactAreaDecimal, fractionDigits: 3)} শতক',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
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
          const SizedBox(height: 30),
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
      onChanged: (_) => _calculate(),
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
    const pad = 40.0;
    final w = size.width - (pad * 2);
    final h = size.height - (pad * 2);

    final pA = Offset(pad, pad); // A: Top-Left
    final pB = Offset(pad + w, pad); // B: Top-Right
    final pC = Offset(pad + w, pad + h); // C: Bottom-Right
    final pD = Offset(pad, pad + h); // D: Bottom-Left

    // 1. Polygon Fill
    final path = Path()
      ..moveTo(pA.dx, pA.dy)
      ..lineTo(pB.dx, pB.dy)
      ..lineTo(pC.dx, pC.dy)
      ..lineTo(pD.dx, pD.dy)
      ..close();

    final fillPaint = Paint()
      ..color = const Color(0xFFEFF6FF)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 2. Stroke
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);

    // 3. Diagonal X (A -> C)
    if (showDiagX) {
      final diagPaint = Paint()
        ..color = const Color(0xFF6366F1)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(pA, pC, diagPaint);
    }

    // 4. Diagonal Y (B -> D)
    if (showDiagY) {
      final diagPaint2 = Paint()
        ..color = const Color(0xFFEC4899)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(pB, pD, diagPaint2);
    }

    // 5. Red Side Name Labels (Page 2)
    if (showSideNames) {
      _drawCenteredText(canvas, 'উত্তর বাহু (${north.toStringAsFixed(1)}\')', Offset(size.width / 2, pad - 16), color: Colors.red);
      _drawCenteredText(canvas, 'দক্ষিণ বাহু (${south.toStringAsFixed(1)}\')', Offset(size.width / 2, pad + h + 16), color: Colors.red);
      _drawCenteredText(canvas, 'পশ্চিম বাহু', Offset(pad - 22, size.height / 2), color: Colors.red, isVertical: true);
      _drawCenteredText(canvas, 'পূর্ব বাহু', Offset(pad + w + 22, size.height / 2), color: Colors.red, isVertical: true);
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
