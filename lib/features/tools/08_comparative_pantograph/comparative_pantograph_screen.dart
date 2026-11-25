import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/services/device_file_service.dart';
import '../../../core/services/history_service.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../history/models/calculation_history_item.dart';
import '../widgets/mouza_sheet_image.dart';

class ComparativePantographScreen extends StatefulWidget {
  const ComparativePantographScreen({super.key});

  @override
  State<ComparativePantographScreen> createState() => _ComparativePantographScreenState();
}

class _ComparativePantographScreenState extends State<ComparativePantographScreen> {
  double _splitWipe = 0.50; // 0.0 to 1.0 wipe split
  String _oldSurvey = 'CS জরিপ (১৬"=১ মাইল)';
  String _newSurvey = 'RS / BS জরিপ (১৬"=১ মাইল)';

  // Relative pantograph adjustments between Old (base) and New (adjusted) sheets
  double _rsShiftX = 14.0; // pixels (-40 to +40)
  double _rsShiftY = 6.0;  // pixels (-30 to +30)
  double _rsScale = 1.02;  // 0.85 to 1.15
  String? _oldSheetSource;
  String? _newSheetSource;

  Future<void> _pickSurveySheet({required bool isOld}) async {
    final picked = await DeviceFileService.instance.pickMouzaSheet();
    if (!mounted || picked == null) return;
    setState(() {
      if (isOld) {
        _oldSheetSource = picked.path;
      } else {
        _newSheetSource = picked.path;
      }
    });
  }

  static const double _baseWidthFt = 220.0;
  static const double _baseHeightFt = 150.0;
  static const double _pxToFeet = 1.0;

  double get _oldAreaSqFt => _baseWidthFt * _baseHeightFt;
  double get _newAreaSqFt => (_baseWidthFt * _rsScale) * (_baseHeightFt * _rsScale);

  // Compute non-overlapping (encroached / shifted) area in sq ft dynamically
  double get _encroachmentDiffSqFt {
    const oldLeft = 50.0;
    const oldTop = 60.0;
    const oldW = 140.0;
    const oldH = 120.0;
    const oldRight = oldLeft + oldW;
    const oldBottom = oldTop + oldH;

    final newLeft = 50.0 + _rsShiftX;
    final newTop = 60.0 + _rsShiftY;
    final newW = oldW * _rsScale;
    final newH = oldH * _rsScale;
    final newRight = newLeft + newW;
    final newBottom = newTop + newH;

    final interW = (newRight < oldRight ? newRight : oldRight) - (newLeft > oldLeft ? newLeft : oldLeft);
    final interH = (newBottom < oldBottom ? newBottom : oldBottom) - (newTop > oldTop ? newTop : oldTop);
    final overlapPxArea = (interW > 0 && interH > 0) ? interW * interH : 0.0;
    final unionPxArea = (oldW * oldH) + (newW * newH) - overlapPxArea;
    final diffPxArea = (unionPxArea - overlapPxArea).abs();
    return diffPxArea * (_pxToFeet * _pxToFeet);
  }

  double get _encroachmentDiffDec => _encroachmentDiffSqFt / 435.6;

  Future<void> _saveReportToHistory(String report) async {
    await HistoryService.instance.saveItem(
      CalculationHistoryItem(
        id: 'panto_${DateTime.now().millisecondsSinceEpoch}',
        title: 'প্যান্টোগ্রাফ সীমানা বিশ্লেষণ',
        category: 'মৌজা ম্যাপ',
        timestamp: DateTime.now(),
        inputSummary: 'X:${_rsShiftX.toStringAsFixed(0)}px, Y:${_rsShiftY.toStringAsFixed(0)}px, স্কেল:${_rsScale.toStringAsFixed(2)}x',
        resultSummary: 'সীমানা তারতম্য: ${BanglaFormatter.formatNumber(_encroachmentDiffDec, fractionDigits: 3)} শতক',
        fullReportBangla: report,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('প্যান্টোগ্রাফ রিপোর্ট ইতিহাসে সংরক্ষণ করা হয়েছে'), backgroundColor: AppColors.primaryGreen),
    );
  }

  String _buildReport() {
    return '''
=== তুলনামূলক প্যান্টোগ্রাফ রিপোর্ট ===
তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}
সাবেক রেকর্ড: $_oldSurvey (মূল ক্ষেত্রফল: ${BanglaFormatter.formatNumber(_oldAreaSqFt / 435.6, fractionDigits: 3)} শতক)
হাল রেকর্ড: $_newSurvey (স্কেল ${_rsScale.toStringAsFixed(2)}x, ক্ষেত্রফল: ${BanglaFormatter.formatNumber(_newAreaSqFt / 435.6, fractionDigits: 3)} শতক)
বিচ্যুতি: অনুভূমিক ${_rsShiftX.toStringAsFixed(1)} ft, উল্লম্ব ${_rsShiftY.toStringAsFixed(1)} ft
সীমানা পরিবর্তন / অমিল ক্ষেত্রফল: ${BanglaFormatter.formatNumber(_encroachmentDiffDec, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(_encroachmentDiffSqFt, fractionDigits: 1)} sq ft)
অ্যাপ: BDLandPro - পেশাদার বাংলাদেশ ভূমি জরিপ
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('তুলনামূলক প্যান্টোগ্রাফ (সাবেক ও হাল ম্যাপ)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'ইতিহাসে সেভ',
            onPressed: () => _saveReportToHistory(_buildReport()),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'কপি রিপোর্ট',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _buildReport()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('প্যান্টোগ্রাফ রিপোর্ট কপি করা হয়েছে!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Survey selection banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppColors.primaryGreenLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _oldSurvey,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF92400E)),
                  items: const [
                    DropdownMenuItem(value: 'CS জরিপ (১৬"=১ মাইল)', child: Text('CS জরিপ (১৬")')),
                    DropdownMenuItem(value: 'SA জরিপ (১৬"=১ মাইল)', child: Text('SA জরিপ (১৬")')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _oldSurvey = v);
                  },
                ),
                const Icon(Icons.compare_arrows, color: AppColors.primaryGreen),
                DropdownButton<String>(
                  value: _newSurvey,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF065F46)),
                  items: const [
                    DropdownMenuItem(value: 'RS / BS জরিপ (১৬"=১ মাইল)', child: Text('RS/BS জরিপ (১৬")')),
                    DropdownMenuItem(value: 'দিয়ারা জরিপ (১৬"=১ মাইল)', child: Text('দিয়ারা জরিপ (১৬")')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _newSurvey = v);
                  },
                ),
              ],
            ),
          ),

          // Interactive Pantograph Split Canvas with LayoutBuilder
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canvasW = constraints.maxWidth > 0 ? constraints.maxWidth : 360.0;
                return GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _splitWipe = (_splitWipe + (details.primaryDelta ?? 0) / canvasW).clamp(0.05, 0.95);
                    });
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Optional Background RS/BS Mouza Sheet Image
                      if (_newSheetSource != null)
                        Transform.translate(
                          offset: Offset(_rsShiftX, _rsShiftY),
                          child: Transform.scale(
                            scale: _rsScale,
                            child: Opacity(
                              opacity: 0.45,
                              child: MouzaSheetImage(source: _newSheetSource!, fit: BoxFit.contain),
                            ),
                          ),
                        ),
                      // Layer 1: New RS/BS Map (adjusted by X, Y, Scale)
                      CustomPaint(
                        painter: _MapSheetPainter(
                          isOld: false,
                          shiftX: _rsShiftX,
                          shiftY: _rsShiftY,
                          scale: _rsScale,
                        ),
                      ),

                      // Layer 2: Clipped Old CS/SA Map (base reference)
                      ClipRect(
                        clipper: _WipeClipper(_splitWipe),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_oldSheetSource != null)
                              Opacity(
                                opacity: 0.45,
                                child: MouzaSheetImage(source: _oldSheetSource!, fit: BoxFit.contain),
                              ),
                            CustomPaint(
                              painter: _MapSheetPainter(
                                isOld: true,
                                shiftX: 0.0,
                                shiftY: 0.0,
                                scale: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Wipe Divider Line
                      Positioned(
                        left: canvasW * _splitWipe - 2,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 4,
                          color: AppColors.accentCrimson,
                          child: Center(
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.accentCrimson,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.code, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Wipe Slider, Shift/Scale Pantograph Controls and Analysis Summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('সাবেক (CS/SA)', style: TextStyle(fontSize: 12)),
                    Text('তুলনা স্লাইডার: ${BanglaNumerals.toBangla((_splitWipe * 100).toInt())}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const Text('হাল (RS/BS)', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Slider(
                  value: _splitWipe,
                  min: 0.05,
                  max: 0.95,
                  activeColor: AppColors.accentCrimson,
                  onChanged: (val) => setState(() => _splitWipe = val),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text('X: ${_rsShiftX.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11)),
                          Expanded(
                            child: Slider(
                              value: _rsShiftX,
                              min: -40,
                              max: 40,
                              onChanged: (v) => setState(() => _rsShiftX = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Text('Y: ${_rsShiftY.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11)),
                          Expanded(
                            child: Slider(
                              value: _rsShiftY,
                              min: -30,
                              max: 30,
                              onChanged: (v) => setState(() => _rsShiftY = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Text('স্কেল: ${_rsScale.toStringAsFixed(2)}x', style: const TextStyle(fontSize: 11)),
                          Expanded(
                            child: Slider(
                              value: _rsScale,
                              min: 0.85,
                              max: 1.15,
                              onChanged: (v) => setState(() => _rsScale = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickSurveySheet(isOld: true),
                        icon: const Icon(Icons.folder_open, size: 15),
                        label: Text(_oldSheetSource == null ? 'সাবেক শিট নিন' : 'সাবেক বদলান', style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickSurveySheet(isOld: false),
                        icon: const Icon(Icons.folder_open, size: 15),
                        label: Text(_newSheetSource == null ? 'হাল শিট নিন' : 'হাল বদলান', style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryGoldLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.secondaryGoldDark),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'গণনাকৃত সীমানার অমিল: ${BanglaFormatter.formatNumber(_encroachmentDiffDec, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(_encroachmentDiffSqFt, fractionDigits: 0)} sq ft)। স্লাইডার ও স্কেল সরিয়ে অমিল যাচাই করুন।',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                      ),
                    ],
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

class _WipeClipper extends CustomClipper<Rect> {
  final double splitRatio;
  _WipeClipper(this.splitRatio);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * splitRatio, size.height);
  }

  @override
  bool shouldReclip(covariant _WipeClipper oldClipper) => oldClipper.splitRatio != splitRatio;
}

class _MapSheetPainter extends CustomPainter {
  final bool isOld;
  final double shiftX;
  final double shiftY;
  final double scale;

  _MapSheetPainter({
    required this.isOld,
    required this.shiftX,
    required this.shiftY,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = isOld ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final linePaint = Paint()
      ..color = isOld ? const Color(0xFFB45309) : const Color(0xFF047857)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final sx = isOld ? 0.0 : shiftX;
    final sy = isOld ? 0.0 : shiftY;
    final sc = isOld ? 1.0 : scale;

    final rect1 = Rect.fromLTWH(50 + sx, 60 + sy, 140 * sc, 120 * sc);
    canvas.drawRect(rect1, linePaint);
    _drawLabel(canvas, isOld ? 'সাবেক দাগ ৫০১' : 'হাল দাগ ৭২০', rect1.center, linePaint.color);

    final rect2 = Rect.fromLTWH(50 + sx + 140 * sc, 60 + sy, 150 * sc, 120 * sc);
    canvas.drawRect(rect2, linePaint);
    _drawLabel(canvas, isOld ? 'সাবেক দাগ ৫০২' : 'হাল দাগ ৭২১', rect2.center, linePaint.color);
  }

  void _drawLabel(Canvas canvas, String text, Offset offset, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(offset.dx - tp.width / 2, offset.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MapSheetPainter oldDelegate) =>
      oldDelegate.isOld != isOld ||
      oldDelegate.shiftX != shiftX ||
      oldDelegate.shiftY != shiftY ||
      oldDelegate.scale != scale;
}
