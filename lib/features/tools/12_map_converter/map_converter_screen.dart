import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';

class MapConverterScreen extends StatefulWidget {
  const MapConverterScreen({super.key});

  @override
  State<MapConverterScreen> createState() => _MapConverterScreenState();
}

class _MapConverterScreenState extends State<MapConverterScreen> {
  double _contrast = 1.2;
  double _threshold = 0.5;
  double _deskewAngle = 0.0;
  bool _isBlackAndWhite = true;
  String _targetFormat = 'PDF';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Converter (ফরম্যাট ও ক্লিন)'),
      ),
      body: Column(
        children: [
          // Filtered Map Preview Canvas
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isBlackAndWhite ? Colors.white : const Color(0xFFFBF7EE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorderLight),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Transform.rotate(
                  angle: (_deskewAngle * 3.14159) / 180.0,
                  child: Center(
                    child: CustomPaint(
                      painter: _MouzaFilterPainter(
                        isBw: _isBlackAndWhite,
                        contrast: _contrast,
                        threshold: _threshold,
                      ),
                      size: const Size(300, 300),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Controls & Conversion Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.cardBorderLight)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.contrast, color: AppColors.primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    const Text('কন্ট্রাস্ট / থ্রেশহোল্ড:'),
                    Expanded(
                      child: Slider(
                        value: _contrast,
                        min: 0.5,
                        max: 2.5,
                        activeColor: AppColors.primaryGreen,
                        onChanged: (val) => setState(() => _contrast = val),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.rotate_90_degrees_ccw, color: AppColors.secondaryGoldDark, size: 20),
                    const SizedBox(width: 8),
                    Text('সোজা করুন (Deskew): ${BanglaNumerals.toBangla(_deskewAngle.toStringAsFixed(1))}°'),
                    Expanded(
                      child: Slider(
                        value: _deskewAngle,
                        min: -10,
                        max: 10,
                        activeColor: AppColors.secondaryGoldDark,
                        onChanged: (val) => setState(() => _deskewAngle = val),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FilterChip(
                      label: const Text('সাদা-কালো ক্লিন মোড'),
                      selected: _isBlackAndWhite,
                      onSelected: (val) => setState(() => _isBlackAndWhite = val),
                    ),
                    DropdownButton<String>(
                      value: _targetFormat,
                      items: const [
                        DropdownMenuItem(value: 'PDF', child: Text('PDF ডকুমেন্ট')),
                        DropdownMenuItem(value: 'PNG', child: Text('উচ্চ রেজোলিউশন PNG')),
                        DropdownMenuItem(value: 'DXF', child: Text('AutoCAD DXF')),
                        DropdownMenuItem(value: 'KMZ', child: Text('Google Earth KMZ')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _targetFormat = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('মৌজা ম্যাপ সফলভাবে $_targetFormat ফরম্যাটে কনভার্ট ও এক্সপোর্ট হয়েছে!'),
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: Text('কনভার্ট ও ডাউনলোড করুন ($_targetFormat)'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MouzaFilterPainter extends CustomPainter {
  final bool isBw;
  final double contrast;
  final double threshold;

  _MouzaFilterPainter({required this.isBw, required this.contrast, required this.threshold});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeColor = isBw ? Colors.black : const Color(0xFF5D4037);
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.0 * contrast
      ..style = PaintingStyle.stroke;

    // Survey plot lines
    canvas.drawRect(const Rect.fromLTWH(30, 30, 110, 100), paint);
    canvas.drawRect(const Rect.fromLTWH(140, 30, 130, 100), paint);
    canvas.drawRect(const Rect.fromLTWH(30, 130, 110, 130), paint);
    canvas.drawRect(const Rect.fromLTWH(140, 130, 130, 130), paint);

    final tp = TextPainter(
      text: TextSpan(
        text: 'ক্লিনকৃত দাগ নম্বর: ১২০, ১২১, ১২২',
        style: TextStyle(color: strokeColor, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Hind Siliguri'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(50, 180));
  }

  @override
  bool shouldRepaint(covariant _MouzaFilterPainter oldDelegate) => true;
}
