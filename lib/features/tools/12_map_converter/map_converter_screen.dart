import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/services/history_service.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/utils/pdf_report_helper.dart';
import '../../history/models/calculation_history_item.dart';
import '../widgets/mouza_sheet_image.dart';

class MapConverterScreen extends StatefulWidget {
  const MapConverterScreen({super.key});

  @override
  State<MapConverterScreen> createState() => _MapConverterScreenState();
}

class _MapConverterScreenState extends State<MapConverterScreen> {
  final GlobalKey _captureKey = GlobalKey();
  double _contrast = 1.2;
  double _deskewAngle = 0.0;
  bool _isBlackAndWhite = true;
  String _targetFormat = 'PDF';
  String? _selectedSheetAsset;
  bool _isExporting = false;

  static const List<Map<String, String?>> _sheetOptions = [
    {'label': 'ভেক্টর শিট', 'asset': null},
    {'label': 'নমুনা শিট ১', 'asset': 'assets/mouza_maps/sample_mouza_sheet_1.jpg'},
    {'label': 'নমুনা শিট ২', 'asset': 'assets/mouza_maps/sample_mouza_sheet_2.jpg'},
    {'label': 'কাওরান বাজার', 'asset': 'assets/mouza_maps/SA_Tejgaon_Kawran_Sheet1.pdf'},
  ];

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

  List<double> _buildColorMatrix() {
    final c = _contrast;
    final t = (1.0 - c) * 128.0;
    if (_isBlackAndWhite) {
      // Luminance grayscale + contrast
      const r = 0.2126;
      const g = 0.7152;
      const b = 0.0722;
      return [
        r * c, g * c, b * c, 0, t,
        r * c, g * c, b * c, 0, t,
        r * c, g * c, b * c, 0, t,
        0, 0, 0, 1, 0,
      ];
    }
    return [
      c, 0, 0, 0, t,
      0, c, 0, 0, t,
      0, 0, c, 0, t,
      0, 0, 0, 1, 0,
    ];
  }

  Future<void> _exportConvertedMap() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      if (_targetFormat == 'DXF') {
        final dxf = _generateScaledDxf();
        await Clipboard.setData(ClipboardData(text: dxf));
        await _saveExportHistory('AutoCAD DXF (${_scale}, $_dpi DPI)', dxf);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('স্কেল-ক্যালিব্রেটেড AutoCAD DXF কোড ক্লিপবোর্ড ও ইতিহাসে সেভ হয়েছে!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        return;
      }

      if (_targetFormat == 'KMZ') {
        final kml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Folder>
    <name>BDLandPro_Calibrated_Mouza_${_dpi}DPI</name>
    <GroundOverlay>
      <name>Converted Mouza Sheet ($_scale)</name>
      <Icon><href>${_selectedSheetAsset?.split('/').last ?? 'converted_mouza_clean.png'}</href></Icon>
      <LatLonBox>
        <north>23.6500</north>
        <south>23.6430</south>
        <east>90.6050</east>
        <west>90.5980</west>
        <rotation>${_deskewAngle.toStringAsFixed(2)}</rotation>
      </LatLonBox>
    </GroundOverlay>
  </Folder>
</kml>
''';
        await Clipboard.setData(ClipboardData(text: kml));
        await _saveExportHistory('KMZ/KML ($_scale, $_dpi DPI)', kml);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ডেসকিউ সহ KMZ/KML কোড ক্লিপবোর্ড ও ইতিহাসে সেভ হয়েছে!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        return;
      }

      // PNG or PDF -> Capture live filtered canvas bytes
      Uint8List? pngBytes;
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final pixelRatio = (_dpi / 150.0).clamp(1.0, 4.0);
        final img = await boundary.toImage(pixelRatio: pixelRatio);
        final bd = await img.toByteData(format: ui.ImageByteFormat.png);
        pngBytes = bd?.buffer.asUint8List();
      }

      if (_targetFormat == 'PNG' && pngBytes != null) {
        await Printing.sharePdf(bytes: pngBytes, filename: 'BDLandPro_Mouza_${_dpi}DPI.png');
        await _saveExportHistory('High-Res PNG ($_scale, $_dpi DPI)', 'PNG ${pngBytes.length} bytes');
        return;
      }

      final theme = await PdfReportHelper.loadBengaliTheme();
      final pdf = pw.Document(theme: theme);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('BDLandPro ক্যালিব্রেটেড ও ক্লিনকৃত মৌজা শিট', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text('স্কেল: $_scale | রেজোলিউশন: $_dpi DPI | ১ পিক্সেল = ${_feetPerPixel.toStringAsFixed(3)} ফুট (${_linksPerPixel.toStringAsFixed(3)} লিংক)', style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 12),
                if (pngBytes != null)
                  pw.Expanded(
                    child: pw.Center(
                      child: pw.Image(pw.MemoryImage(pngBytes), fit: pw.BoxFit.contain),
                    ),
                  ),
              ],
            );
          },
        ),
      );

      await _saveExportHistory('PDF ($_scale, $_dpi DPI)', 'PDF তৈরি (${BanglaFormatter.formatDateTime(DateTime.now())})');
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'BDLandPro_Mouza_Converted.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('এক্সপোর্ট ত্রুটি: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _generateScaledDxf() {
    final s = _feetPerInch;
    return '''
0
SECTION
2
ENTITIES
0
LWPOLYLINE
8
MOUZA_PLOT_120
90
4
70
1
10
0.0
20
0.0
10
${(s * 0.4).toStringAsFixed(2)}
20
0.0
10
${(s * 0.4).toStringAsFixed(2)}
20
${(s * 0.35).toStringAsFixed(2)}
10
0.0
20
${(s * 0.35).toStringAsFixed(2)}
0
ENDSEC
0
EOF
''';
  }

  Future<void> _saveExportHistory(String summary, String body) async {
    await HistoryService.instance.saveItem(
      CalculationHistoryItem(
        id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Map Converter ($_targetFormat)',
        category: 'মৌজা ম্যাপ',
        timestamp: DateTime.now(),
        inputSummary: 'স্কেল: $_scale | $_dpi DPI | কন্ট্রাস্ট: ${_contrast.toStringAsFixed(1)}',
        resultSummary: summary,
        fullReportBangla: body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Converter (ফরম্যাট ও ক্লিন)'),
      ),
      body: Column(
        children: [
          // Sheet selector pills
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: _sheetOptions.map((opt) {
                final isSel = _selectedSheetAsset == opt['asset'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
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

          // Filtered Map Preview Canvas
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              decoration: BoxDecoration(
                color: _isBlackAndWhite ? Colors.white : const Color(0xFFFBF7EE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorderLight),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: RepaintBoundary(
                  key: _captureKey,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.matrix(_buildColorMatrix()),
                    child: Transform.rotate(
                      angle: (_deskewAngle * 3.1415926535) / 180.0,
                      child: _selectedSheetAsset == null
                          ? Center(
                              child: CustomPaint(
                                painter: _MouzaFilterPainter(
                                  isBw: _isBlackAndWhite,
                                  contrast: _contrast,
                                ),
                                size: const Size(300, 300),
                              ),
                            )
                          : MouzaSheetImage(assetPath: _selectedSheetAsset, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Controls & Conversion Panel
          Container(
            padding: const EdgeInsets.all(14),
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
                    Text('কন্ট্রাস্ট: ${BanglaNumerals.toBangla(_contrast.toStringAsFixed(1))}x'),
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
                        DropdownMenuItem(value: 'PNG', child: Text('PNG ছবি (শেয়ার)')),
                        DropdownMenuItem(value: 'DXF', child: Text('AutoCAD DXF')),
                        DropdownMenuItem(value: 'KMZ', child: Text('Google Earth KMZ')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _targetFormat = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),

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
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
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
                ),
                const SizedBox(height: 8),

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
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportConvertedMap,
                  icon: _isExporting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download),
                  label: Text('কনভার্ট ও এক্সপোর্ট করুন ($_targetFormat)'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
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

  _MouzaFilterPainter({required this.isBw, required this.contrast});

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
        style: TextStyle(color: strokeColor, fontWeight: FontWeight.bold, fontSize: 13),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(50, 180));
  }

  @override
  bool shouldRepaint(covariant _MouzaFilterPainter oldDelegate) =>
      oldDelegate.isBw != isBw || oldDelegate.contrast != contrast;
}
