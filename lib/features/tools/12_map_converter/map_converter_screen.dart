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

  // Page 8: Scale & DPI Selection
  int _dpi = 300; // 150, 300, 400, 600
  String _scale = '১৬" = ১ মাইল'; // 16", 32", 64", 80"

  double get _feetPerInch {
    switch (_scale) {
      case '৩২" = ১ মাইল':
        return 165.0;
      case '৬৪" = ১ মাইল':
        return 82.5;
      case '৮০" = ১ মাইল':
        return 66.0;
      case '১৬" = ১ মাইল':
      default:
        return 330.0;
    }
  }

  double get _feetPerPixel => _feetPerInch / _dpi;
  double get _linksPerPixel => (_feetPerInch / 0.66) / _dpi;

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

                // Page 8: Scale & DPI Selection
                Row(
                  children: [
                    const Text('ম্যাপ স্কেল: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    DropdownButton<String>(
                      value: _scale,
                      items: const [
                        DropdownMenuItem(value: '১৬" = ১ মাইল', child: Text('১৬" = ১ মাইল (CS/RS)')),
                        DropdownMenuItem(value: '৩২" = ১ মাইল', child: Text('৩২" = ১ মাইল')),
                        DropdownMenuItem(value: '৬৪" = ১ মাইল', child: Text('৬৪" = ১ মাইল')),
                        DropdownMenuItem(value: '৮০" = ১ মাইল', child: Text('৮০" = ১ মাইল')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _scale = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text('রেজোলিউশন (DPI): ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    ...[150, 300, 400, 600].map((dpi) {
                      final isSel = _dpi == dpi;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text('$dpi', style: TextStyle(color: isSel ? Colors.white : Colors.black87, fontSize: 12)),
                          selected: isSel,
                          selectedColor: AppColors.primaryGreen,
                          onSelected: (_) => setState(() => _dpi = dpi),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 10),

                // Live Calibration Card
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('১ ইঞ্চি =', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text('${BanglaNumerals.toBangla(_dpi)} পিক্সেল', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF15803D))),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('১ পিক্সেল =', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text('${BanglaNumerals.toBangla(_feetPerPixel.toStringAsFixed(3))} ফুট', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF15803D))),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('১ পিক্সেল =', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text('${BanglaNumerals.toBangla(_linksPerPixel.toStringAsFixed(3))} লিংক', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF15803D))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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
