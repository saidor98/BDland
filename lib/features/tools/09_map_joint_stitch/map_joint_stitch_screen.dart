import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';

class MapJointStitchScreen extends StatefulWidget {
  const MapJointStitchScreen({super.key});

  @override
  State<MapJointStitchScreen> createState() => _MapJointStitchScreenState();
}

class _MapJointStitchScreenState extends State<MapJointStitchScreen> {
  double _horizontalOverlap = 0.0;
  double _verticalAlignment = 0.0;
  String _sheetA = 'মৌজা শিট নং ১ (পশ্চিম অংশ)';
  String _sheetB = 'মৌজা শিট নং ২ (পূর্ব অংশ)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ম্যাপ জয়েন্ট (একাধিক সিট জয়েন)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'জয়েন্ট সম্পন্ন করুন',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('উভয় শিট সফলভাবে জোড়া লাগানো হয়েছে!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Sheet titles header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.primaryGreenLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_sheetA, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Icon(Icons.link, color: AppColors.primaryGreen),
                Text(_sheetB, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),

          // Interactive Stitched Map Canvas
          Expanded(
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(30),
              minScale: 0.5,
              maxScale: 3.0,
              child: CustomPaint(
                painter: _StitchedMapPainter(
                  overlap: _horizontalOverlap,
                  verticalShift: _verticalAlignment,
                ),
                size: Size.infinite,
              ),
            ),
          ),

          // Alignment Nudge Sliders
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('অনুভূমিক মিলকরণ (Overlap): '),
                    Text('${BanglaNumerals.toBangla(_horizontalOverlap.toInt())} px', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Slider(
                        value: _horizontalOverlap,
                        min: -50,
                        max: 50,
                        activeColor: AppColors.primaryGreen,
                        onChanged: (val) => setState(() => _horizontalOverlap = val),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('উল্লম্ব মিলকরণ (Vertical): '),
                    Text('${BanglaNumerals.toBangla(_verticalAlignment.toInt())} px', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Slider(
                        value: _verticalAlignment,
                        min: -30,
                        max: 30,
                        activeColor: AppColors.secondaryGoldDark,
                        onChanged: (val) => setState(() => _verticalAlignment = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => setState(() {
                        _horizontalOverlap = 0;
                        _verticalAlignment = 0;
                      }),
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('রিসেট'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('সংযুক্ত মৌজা ম্যাপ সফলভাবে সেভ করা হয়েছে!'),
                            backgroundColor: AppColors.primaryGreen,
                          ),
                        );
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('জয়েন্ট ম্যাপ সেভ করুন'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StitchedMapPainter extends CustomPainter {
  final double overlap;
  final double verticalShift;

  _StitchedMapPainter({required this.overlap, required this.verticalShift});

  @override
  void paint(Canvas canvas, Size size) {
    final midX = size.width / 2;

    // Sheet 1 (Left)
    final sheet1Rect = Rect.fromLTWH(20, 40, midX - 20 + overlap, size.height - 80);
    canvas.drawRect(sheet1Rect, Paint()..color = const Color(0xFFFAF6EE));
    canvas.drawRect(sheet1Rect, Paint()..color = const Color(0xFFC7BCA1)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Sheet 2 (Right with vertical shift)
    final sheet2Rect = Rect.fromLTWH(midX + overlap, 40 + verticalShift, midX - 30, size.height - 80);
    canvas.drawRect(sheet2Rect, Paint()..color = const Color(0xFFFDFBF7));
    canvas.drawRect(sheet2Rect, Paint()..color = const Color(0xFFC7BCA1)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Continuous road / canal running across both sheets
    final continuousRoadPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 14.0
      ..style = PaintingStyle.stroke;

    final roadPath = Path()
      ..moveTo(20, size.height * 0.45)
      ..lineTo(midX + overlap, size.height * 0.45 + verticalShift * 0.5)
      ..lineTo(size.width - 30, size.height * 0.48 + verticalShift);
    canvas.drawPath(roadPath, continuousRoadPaint);

    // Seam line
    final seamPaint = Paint()
      ..color = AppColors.accentCrimson
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(midX + overlap, 20), Offset(midX + overlap, size.height - 20), seamPaint);
  }

  @override
  bool shouldRepaint(covariant _StitchedMapPainter oldDelegate) =>
      oldDelegate.overlap != overlap || oldDelegate.verticalShift != verticalShift;
}
