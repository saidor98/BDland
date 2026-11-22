import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';

class MouzaMapOverlayScreen extends StatefulWidget {
  const MouzaMapOverlayScreen({super.key});

  @override
  State<MouzaMapOverlayScreen> createState() => _MouzaMapOverlayScreenState();
}

class _MouzaMapOverlayScreenState extends State<MouzaMapOverlayScreen> {
  double _opacity = 0.65;
  double _rotation = 0.0; // degrees
  double _scale = 1.0;
  Offset _panOffset = Offset.zero;

  void _exportKmz() {
    final kml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Folder>
    <name>BDLandPro_Georeferenced_Mouza_Map</name>
    <GroundOverlay>
      <name>Mouza Overlay Sheet</name>
      <color>${((_opacity * 255).toInt()).toRadixString(16).padLeft(2, '0')}ffffff</color>
      <Icon><href>mouza_sheet_georeferenced.png</href></Icon>
      <LatLonBox>
        <north>23.8150</north>
        <south>23.8050</south>
        <east>90.4180</east>
        <west>90.4080</west>
        <rotation>$_rotation</rotation>
      </LatLonBox>
    </GroundOverlay>
  </Folder>
</kml>
''';
    Clipboard.setData(ClipboardData(text: kml));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('জিওরেফারেন্সড KML/KMZ কোড ক্লিপবোর্ডে কপি করা হয়েছে! (Google Earth-এ সরাসরি ওপেন করা যাবে)'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('গুগল ম্যাপে মৌজা ম্যাপ (KMZ)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'KMZ এক্সপোর্ট',
            onPressed: _exportKmz,
          ),
        ],
      ),
      body: Column(
        children: [
          // Overlay Map Display
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() => _panOffset += details.delta);
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Base Satellite layer
                  Container(
                    color: const Color(0xFF1E2F23),
                    child: CustomPaint(
                      painter: _SatelliteTerrainPainter(),
                    ),
                  ),

                  // Overlay Mouza Cadastral Sheet (Translucent)
                  Transform.translate(
                    offset: _panOffset,
                    child: Transform.rotate(
                      angle: (_rotation * 3.14159) / 180.0,
                      child: Transform.scale(
                        scale: _scale,
                        child: Opacity(
                          opacity: _opacity,
                          child: CustomPaint(
                            painter: _CadastralOverlaySheetPainter(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Compass & Alignment HUD
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.navigation, color: Colors.redAccent, size: 28),
                          const SizedBox(height: 2),
                          Text('${BanglaNumerals.toBangla(_rotation.toInt())}°', style: const TextStyle(color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Control Sliders Panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.opacity, size: 20, color: AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    Text('স্বচ্ছতা (Opacity): ${BanglaNumerals.toBangla((_opacity * 100).toInt())}%'),
                    Expanded(
                      child: Slider(
                        value: _opacity,
                        min: 0.1,
                        max: 1.0,
                        activeColor: AppColors.primaryGreen,
                        onChanged: (val) => setState(() => _opacity = val),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.rotate_right, size: 20, color: AppColors.secondaryGoldDark),
                    const SizedBox(width: 8),
                    Text('ঘূর্ণন (Rotation): ${BanglaNumerals.toBangla(_rotation.toInt())}°'),
                    Expanded(
                      child: Slider(
                        value: _rotation,
                        min: -45,
                        max: 45,
                        activeColor: AppColors.secondaryGoldDark,
                        onChanged: (val) => setState(() => _rotation = val),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _panOffset = Offset.zero;
                          _rotation = 0.0;
                          _scale = 1.0;
                        });
                      },
                      icon: const Icon(Icons.restart_alt, size: 18),
                      label: const Text('রিসেট'),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _exportKmz,
                      icon: const Icon(Icons.download),
                      label: const Text('KMZ তৈরি করুন'),
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

class _SatelliteTerrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Simulated Satellite Landscape: roads, canal, green fields
    final canalPaint = Paint()
      ..color = const Color(0xFF1E3A5F)
      ..strokeWidth = 24.0
      ..style = PaintingStyle.stroke;
    final canalPath = Path()
      ..moveTo(0, size.height * 0.3)
      ..cubicTo(size.width * 0.4, size.height * 0.4, size.width * 0.6, size.height * 0.2, size.width, size.height * 0.35);
    canvas.drawPath(canalPath, canalPaint);

    final roadPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 10.0;
    canvas.drawLine(Offset(size.width * 0.2, 0), Offset(size.width * 0.5, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CadastralOverlaySheetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Semi-transparent parchment sheet with black plot lines
    final bgPaint = Paint()..color = const Color(0xFFFFF9E6).withOpacity(0.4);
    canvas.drawRect(const Rect.fromLTWH(40, 40, 320, 360), bgPaint);

    final plotPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // Plots
    canvas.drawRect(const Rect.fromLTWH(60, 60, 120, 100), plotPaint);
    canvas.drawRect(const Rect.fromLTWH(180, 60, 140, 100), plotPaint);
    canvas.drawRect(const Rect.fromLTWH(60, 160, 120, 120), plotPaint);
    canvas.drawRect(const Rect.fromLTWH(180, 160, 140, 120), plotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
