import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/services/history_service.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../history/models/calculation_history_item.dart';
import '../widgets/esri_satellite_map_view.dart';
import '../widgets/mouza_sheet_image.dart';

class MouzaMapOverlayScreen extends StatefulWidget {
  const MouzaMapOverlayScreen({super.key});

  @override
  State<MouzaMapOverlayScreen> createState() => _MouzaMapOverlayScreenState();
}

class _MouzaMapOverlayScreenState extends State<MouzaMapOverlayScreen> {
  final EsriMapController _mapController = EsriMapController();

  double _opacity = 0.70;
  double _rotation = 0.0; // degrees
  double _scale = 1.0;
  Offset _panOffset = Offset.zero;

  // Selected overlay source: null = vector demo grid, or asset path
  String? _selectedSheetAsset;

  static const List<Map<String, String?>> _sheetOptions = [
    {'label': 'ভেক্টর শিট', 'asset': null},
    {'label': 'নমুনা শিট ১', 'asset': 'assets/mouza_maps/sample_mouza_sheet_1.jpg'},
    {'label': 'নমুনা শিট ২', 'asset': 'assets/mouza_maps/sample_mouza_sheet_2.jpg'},
    {'label': 'কাওরান বাজার', 'asset': 'assets/mouza_maps/SA_Tejgaon_Kawran_Sheet1.pdf'},
  ];

  Map<String, double> _computeGeoBounds() {
    final center = _mapController.currentCenter;
    final zoom = _mapController.currentZoom;
    final centerPx = EsriSatelliteMapView.latLngToWorldPixels(center.lat, center.lng, zoom);
    final halfSheetW = (320.0 * _scale) / 2.0;
    final halfSheetH = (360.0 * _scale) / 2.0;

    // Account for rotation around sheet center by computing axis-aligned bounding box
    final rad = (_rotation * math.pi) / 180.0;
    final cosA = math.cos(rad).abs();
    final sinA = math.sin(rad).abs();
    final rotHalfW = halfSheetW * cosA + halfSheetH * sinA;
    final rotHalfH = halfSheetW * sinA + halfSheetH * cosA;

    final sheetCenterWorldX = centerPx.dx + _panOffset.dx;
    final sheetCenterWorldY = centerPx.dy + _panOffset.dy;

    final nw = EsriSatelliteMapView.worldPixelsToLatLng(
      sheetCenterWorldX - rotHalfW,
      sheetCenterWorldY - rotHalfH,
      zoom,
    );
    final se = EsriSatelliteMapView.worldPixelsToLatLng(
      sheetCenterWorldX + rotHalfW,
      sheetCenterWorldY + rotHalfH,
      zoom,
    );

    return {
      'north': math.max(nw.lat, se.lat),
      'south': math.min(nw.lat, se.lat),
      'east': math.max(nw.lng, se.lng),
      'west': math.min(nw.lng, se.lng),
    };
  }

  Future<void> _exportKmz() async {
    final bounds = _computeGeoBounds();
    final north = bounds['north']!.toStringAsFixed(6);
    final south = bounds['south']!.toStringAsFixed(6);
    final east = bounds['east']!.toStringAsFixed(6);
    final west = bounds['west']!.toStringAsFixed(6);
    final sheetHref = _selectedSheetAsset?.split('/').last ?? 'mouza_sheet_georeferenced.png';

    final kml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Folder>
    <name>BDLandPro_Georeferenced_Mouza_Map_ESRI</name>
    <GroundOverlay>
      <name>Mouza Overlay Sheet ($sheetHref)</name>
      <color>${((_opacity * 255).toInt()).toRadixString(16).padLeft(2, '0')}ffffff</color>
      <Icon><href>$sheetHref</href></Icon>
      <LatLonBox>
        <north>$north</north>
        <south>$south</south>
        <east>$east</east>
        <west>$west</west>
        <rotation>${_rotation.toStringAsFixed(2)}</rotation>
      </LatLonBox>
    </GroundOverlay>
  </Folder>
</kml>
''';
    await Clipboard.setData(ClipboardData(text: kml));
    await HistoryService.instance.saveItem(
      CalculationHistoryItem(
        id: 'overlay_${DateTime.now().millisecondsSinceEpoch}',
        title: 'ম্যাপ ওভারলে KML ($sheetHref)',
        category: 'মৌজা ম্যাপ',
        timestamp: DateTime.now(),
        inputSummary: 'স্কেল: ${_scale.toStringAsFixed(2)}x | ঘূর্ণন: ${_rotation.toStringAsFixed(1)}°',
        resultSummary: 'N:$north, S:$south, E:$east, W:$west',
        fullReportBangla: kml,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('সঠিক LatLonBox ($north, $east) সহ KML/KMZ ক্লিপবোর্ড ও ইতিহাসে সেভ হয়েছে!'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('গুগল ও ESRI ম্যাপে মৌজা ওভারলে (KMZ)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            tooltip: 'লেয়ার পরিবর্তন',
            onPressed: () => _mapController.showLayerDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.location_city_outlined),
            tooltip: 'বিভাগে যান',
            onPressed: () => _mapController.showJumpDialog(context),
          ),
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
            child: Stack(
              children: [
                // Live ESRI World Imagery Base Satellite Layer
                EsriSatelliteMapView(
                  controller: _mapController,
                  surveyPoints: const [],
                  isDrawingMode: false,
                  showDimensions: false,
                  showAngles: false,
                  initialLayer: SatelliteLayerType.esriSatellite,
                  initialCenter: const LatLngPoint(23.6472, 90.6015), // Sonargaon Aminpur Mouza
                  initialZoom: 16.5,
                  showControls: true,
                  showLayerTag: true,
                  showZoomButtons: true,
                  overlayChild: LayoutBuilder(
                    builder: (context, constraints) {
                      final sheetContent = _selectedSheetAsset == null
                          ? CustomPaint(
                              size: Size.infinite,
                              painter: _CadastralOverlaySheetPainter(),
                            )
                          : Center(
                              child: SizedBox(
                                width: 320,
                                height: 360,
                                child: MouzaSheetImage(
                                  assetPath: _selectedSheetAsset,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                      return GestureDetector(
                        onPanUpdate: (details) {
                          setState(() => _panOffset += details.delta);
                        },
                        child: Transform.translate(
                          offset: _panOffset,
                          child: Transform.rotate(
                            angle: (_rotation * 3.1415926535) / 180.0,
                            child: Transform.scale(
                              scale: _scale,
                              child: Opacity(
                                opacity: _opacity,
                                child: sheetContent,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Top Notification Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xE00F172A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF0284C7), width: 1.2),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.layers, color: Color(0xFF38BDF8), size: 14),
                        SizedBox(width: 6),
                        Text(
                          'মৌজা: আমিনপুর (জে.এল. ৩৪) | Mapbox ও ESRI স্যাটেলাইট',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

                // Compass & Alignment HUD
                Positioned(
                  top: 50,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xB3000000),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.navigation, color: Colors.redAccent, size: 24),
                        const SizedBox(height: 2),
                        Text('${BanglaNumerals.toBangla(_rotation.toInt())}°', style: const TextStyle(color: Colors.white, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Control Sliders Panel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _sheetOptions.map((opt) {
                      final isSel = _selectedSheetAsset == opt['asset'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 6, bottom: 6),
                        child: ChoiceChip(
                          label: Text(opt['label']!, style: TextStyle(fontSize: 11.5, color: isSel ? Colors.white : Colors.black87)),
                          selected: isSel,
                          selectedColor: AppColors.primaryGreen,
                          onSelected: (_) => setState(() => _selectedSheetAsset = opt['asset']),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.opacity, size: 20, color: AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 130,
                      child: Text('স্বচ্ছতা: ${BanglaNumerals.toBangla((_opacity * 100).toInt())}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
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
                    SizedBox(
                      width: 130,
                      child: Text('ঘূর্ণন: ${BanglaNumerals.toBangla(_rotation.toInt())}°', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
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
                    const Icon(Icons.zoom_in, size: 20, color: Color(0xFF0284C7)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 130,
                      child: Text('ম্যাপ স্কেল: ${BanglaNumerals.toBangla(_scale.toStringAsFixed(2))}x', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    Expanded(
                      child: Slider(
                        value: _scale,
                        min: 0.5,
                        max: 2.0,
                        activeColor: const Color(0xFF0284C7),
                        onChanged: (val) => setState(() => _scale = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
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

class _CadastralOverlaySheetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Center point of canvas
    final cx = size.width / 2.0;
    final cy = size.height / 2.0;
    const sheetW = 320.0;
    const sheetH = 360.0;
    final left = cx - sheetW / 2.0;
    final top = cy - sheetH / 2.0;
    final sheetRect = Rect.fromLTWH(left, top, sheetW, sheetH);

    // 1. Semi-transparent parchment mouza paper
    final bgPaint = Paint()..color = const Color(0xD9FFF9E6);
    canvas.drawRRect(RRect.fromRectAndRadius(sheetRect, const Radius.circular(4)), bgPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(sheetRect, const Radius.circular(4)), borderPaint);

    // 2. Light cadastral grid lines
    final gridPaint = Paint()
      ..color = const Color(0x40D97706)
      ..strokeWidth = 0.8;
    for (double x = left + 20; x < left + sheetW; x += 30) {
      canvas.drawLine(Offset(x, top), Offset(x, top + sheetH), gridPaint);
    }
    for (double y = top + 20; y < top + sheetH; y += 30) {
      canvas.drawLine(Offset(left, y), Offset(left + sheetW, y), gridPaint);
    }

    // 3. Cadastral Header
    final headerTp = TextPainter(
      text: const TextSpan(
        text: 'মৌজা: আমিনপুর | জে.এল. ৩৪ | শিট নং: ১ (১৬" = ১ মাইল)',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF78350F),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    headerTp.paint(canvas, Offset(cx - headerTp.width / 2.0, top + 8));

    // 4. Cadastral Plots (Dag Lines)
    final plotPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    // Row 1: Plots 101, 102, 103
    final r1Top = top + 26;
    const r1H = 65.0;
    final c1W = (sheetW - 20) / 3.0;

    canvas.drawRect(Rect.fromLTWH(left + 10, r1Top, c1W, r1H), plotPaint);
    canvas.drawRect(Rect.fromLTWH(left + 10 + c1W, r1Top, c1W, r1H), plotPaint);
    canvas.drawRect(Rect.fromLTWH(left + 10 + c1W * 2, r1Top, c1W, r1H), plotPaint);
    _drawDagLabel(canvas, 'দাগ ১০১', Offset(left + 10 + c1W / 2, r1Top + r1H / 2));
    _drawDagLabel(canvas, 'দাগ ১০২', Offset(left + 10 + c1W * 1.5, r1Top + r1H / 2));
    _drawDagLabel(canvas, 'দাগ ১০৩', Offset(left + 10 + c1W * 2.5, r1Top + r1H / 2));

    // Row 2: Plots 104, 105, 106
    final r2Top = r1Top + r1H;
    const r2H = 65.0;
    canvas.drawRect(Rect.fromLTWH(left + 10, r2Top, c1W, r2H), plotPaint);
    canvas.drawRect(Rect.fromLTWH(left + 10 + c1W, r2Top, c1W, r2H), plotPaint);
    canvas.drawRect(Rect.fromLTWH(left + 10 + c1W * 2, r2Top, c1W, r2H), plotPaint);
    _drawDagLabel(canvas, 'দাগ ১০৪', Offset(left + 10 + c1W / 2, r2Top + r2H / 2));
    _drawDagLabel(canvas, 'দাগ ১০৫', Offset(left + 10 + c1W * 1.5, r2Top + r2H / 2));
    _drawDagLabel(canvas, 'দাগ ১০৬', Offset(left + 10 + c1W * 2.5, r2Top + r2H / 2));

    // River / Canal strip across the middle
    final canalPaint = Paint()
      ..color = const Color(0x6660A5FA)
      ..style = PaintingStyle.fill;
    final canalPath = Path()
      ..moveTo(left + 8, r2Top + r2H + 4)
      ..cubicTo(left + 80, r2Top + r2H + 16, left + 200, r2Top + r2H - 4, left + sheetW - 8, r2Top + r2H + 12)
      ..lineTo(left + sheetW - 8, r2Top + r2H + 32)
      ..cubicTo(left + 200, r2Top + r2H + 16, left + 80, r2Top + r2H + 36, left + 8, r2Top + r2H + 24)
      ..close();
    canvas.drawPath(canalPath, canalPaint);
    canvas.drawPath(canalPath, Paint()..color = const Color(0xFF2563EB)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // Row 3: Plots 107, 108, 109
    final r3Top = r2Top + r2H + 36;
    const r3H = 65.0;
    canvas.drawRect(Rect.fromLTWH(left + 10, r3Top, c1W, r3H), plotPaint);
    canvas.drawRect(Rect.fromLTWH(left + 10 + c1W, r3Top, c1W, r3H), plotPaint);
    canvas.drawRect(Rect.fromLTWH(left + 10 + c1W * 2, r3Top, c1W, r3H), plotPaint);
    _drawDagLabel(canvas, 'দাগ ১০৭', Offset(left + 10 + c1W / 2, r3Top + r3H / 2));
    _drawDagLabel(canvas, 'দাগ ১০৮', Offset(left + 10 + c1W * 1.5, r3Top + r3H / 2));
    _drawDagLabel(canvas, 'দাগ ১০৯', Offset(left + 10 + c1W * 2.5, r3Top + r3H / 2));

    // Row 4: Plots 110, 111, 112
    final r4Top = r3Top + r3H;
    const r4H = 65.0;
    canvas.drawRect(Rect.fromLTWH(left + 10, r4Top, c1W, r4H), plotPaint);
    canvas.drawRect(Rect.fromLTWH(left + 10 + c1W, r4Top, c1W, r4H), plotPaint);
    canvas.drawRect(Rect.fromLTWH(left + 10 + c1W * 2, r4Top, c1W, r4H), plotPaint);
    _drawDagLabel(canvas, 'দাগ ১১০', Offset(left + 10 + c1W / 2, r4Top + r4H / 2));
    _drawDagLabel(canvas, 'দাগ ১১১', Offset(left + 10 + c1W * 1.5, r4Top + r4H / 2));
    _drawDagLabel(canvas, 'দাগ ১১২', Offset(left + 10 + c1W * 2.5, r4Top + r4H / 2));
  }

  void _drawDagLabel(Canvas canvas, String label, Offset center) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2.0, center.dy - tp.height / 2.0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
