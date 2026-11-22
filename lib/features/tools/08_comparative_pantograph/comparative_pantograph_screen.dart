import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/utils/bangla_formatter.dart';

class ComparativePantographScreen extends StatefulWidget {
  const ComparativePantographScreen({super.key});

  @override
  State<ComparativePantographScreen> createState() => _ComparativePantographScreenState();
}

class _ComparativePantographScreenState extends State<ComparativePantographScreen> {
  double _splitWipe = 0.50; // 0.0 to 1.0 wipe split
  String _oldSurvey = 'CS / SA সাবেক জরিপ';
  String _newSurvey = 'RS / BS হাল জরিপ';

  double _encroachmentDiffDec = 1.25; // Shift difference in Decimal

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('তুলনামূলক প্যান্টোগ্রাফ (সাবেক ও হাল ম্যাপ)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'কপি রিপোর্ট',
            onPressed: () {
              final report = '''
=== তুলনামূলক প্যান্টোগ্রাফ রিপোর্ট ===
তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}
সাবেক রেকর্ড: $_oldSurvey
হাল রেকর্ড: $_newSurvey
সীমানা পরিবর্তন / ব্যবধান: ${BanglaFormatter.formatNumber(_encroachmentDiffDec, fractionDigits: 3)} শতক
মন্তব্য: সাবেক ও হাল নকশার তুলনামূলক বিশ্লেষণে সীমানা রেখায় সামান্য বিচ্যুতি পরিলক্ষিত হয়েছে।
অ্যাপ: BDLandPro - পেশাদার বাংলাদেশ ভূমি জরিপ
''';
              Clipboard.setData(ClipboardData(text: report));
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.primaryGreenLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(_oldSurvey, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  backgroundColor: Colors.amber.shade100,
                ),
                const Icon(Icons.compare_arrows, color: AppColors.primaryGreen),
                Chip(
                  label: Text(_newSurvey, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  backgroundColor: Colors.teal.shade100,
                ),
              ],
            ),
          ),

          // Interactive Pantograph Split Canvas
          Expanded(
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                final w = MediaQuery.of(context).size.width;
                setState(() {
                  _splitWipe = (_splitWipe + (details.primaryDelta ?? 0) / w).clamp(0.05, 0.95);
                });
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Layer 1: New RS/BS Map
                  CustomPaint(
                    painter: _MapSheetPainter(isOld: false),
                  ),

                  // Layer 2: Clipped Old CS/SA Map
                  ClipRect(
                    clipper: _WipeClipper(_splitWipe),
                    child: CustomPaint(
                      painter: _MapSheetPainter(isOld: true),
                    ),
                  ),

                  // Wipe Divider Line
                  Positioned(
                    left: MediaQuery.of(context).size.width * _splitWipe - 2,
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
            ),
          ),

          // Wipe Slider and Analysis Summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('সাবেক (CS/SA)'),
                    Text('তুলনা স্লাইডার: ${BanglaNumerals.toBangla((_splitWipe * 100).toInt())}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text('হাল (RS/BS)'),
                  ],
                ),
                Slider(
                  value: _splitWipe,
                  min: 0.05,
                  max: 0.95,
                  activeColor: AppColors.accentCrimson,
                  onChanged: (val) => setState(() => _splitWipe = val),
                ),
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
                          'সীমানার তারতম্য: ${BanglaFormatter.formatNumber(_encroachmentDiffDec, fractionDigits: 2)} শতক। লাল দাগটি ডানে-বামে টেনে সাবেক ও হাল দাগের সীমানা বিচ্যুতি প্রত্যক্ষ করুন।',
                          style: const TextStyle(fontSize: 12),
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
  _MapSheetPainter({required this.isOld});

  @override
  void paint(Canvas canvas, Size size) {
    // Background tint
    final bgPaint = Paint()..color = isOld ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final linePaint = Paint()
      ..color = isOld ? const Color(0xFFB45309) : const Color(0xFF047857)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Plots with slight boundary deviation
    final offsetShift = isOld ? 0.0 : 18.0;

    canvas.drawRect(Rect.fromLTWH(50, 60, 140, 120), linePaint);
    _drawLabel(canvas, isOld ? 'সাবেক দাগ ৫০১' : 'হাল দাগ ৭২০', Offset(120, 120), linePaint.color);

    canvas.drawRect(Rect.fromLTWH(190 + offsetShift, 60, 150 - offsetShift, 120), linePaint);
    _drawLabel(canvas, isOld ? 'সাবেক দাগ ৫০২' : 'হাল দাগ ৭২১', Offset(260, 120), linePaint.color);
  }

  void _drawLabel(Canvas canvas, String text, Offset offset, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Hind Siliguri')),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(offset.dx - tp.width / 2, offset.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
