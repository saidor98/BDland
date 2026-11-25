import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

class MapJointStitchScreen extends StatefulWidget {
  const MapJointStitchScreen({super.key});

  @override
  State<MapJointStitchScreen> createState() => _MapJointStitchScreenState();
}

class _MapJointStitchScreenState extends State<MapJointStitchScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  double _horizontalOverlap = 0.0;
  double _verticalAlignment = 0.0;
  double _sheetBRotation = 0.0; // degrees

  String? _sheetAAsset;
  String? _sheetBAsset;
  bool _isExporting = false;

  static const List<Map<String, String?>> _sheetChoices = [
    {'label': 'ভেক্টর শিট', 'asset': null},
    {'label': 'নমুনা শিট ১', 'asset': 'assets/mouza_maps/sample_mouza_sheet_1.jpg'},
    {'label': 'নমুনা শিট ২', 'asset': 'assets/mouza_maps/sample_mouza_sheet_2.jpg'},
    {'label': 'তেজকুনিপাড়া শিট', 'asset': 'assets/mouza_maps/SA_Tejgaon_Tejkunipara_Sheet1.pdf'},
  ];

  String _labelFor(String? asset, String fallback) {
    final match = _sheetChoices.where((e) => e['asset'] == asset).toList();
    return match.isNotEmpty ? match.first['label']! : fallback;
  }

  Future<void> _exportAndSaveJointPdf() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      Uint8List? pngBytes;
      final boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 2.5);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        pngBytes = byteData?.buffer.asUint8List();
      }

      final theme = await PdfReportHelper.loadBengaliTheme();
      final pdf = pw.Document(theme: theme);
      final sheetALabel = _labelFor(_sheetAAsset, 'শিট ১');
      final sheetBLabel = _labelFor(_sheetBAsset, 'শিট ২');

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('BDLandPro সংযুক্ত মৌজা ম্যাপ (Map Joint Sheet)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text(
                  'বাম শিট: $sheetALabel | ডান শিট: $sheetBLabel | অনুভূমিক মিল: ${_horizontalOverlap.toStringAsFixed(0)} px | উল্লম্ব: ${_verticalAlignment.toStringAsFixed(0)} px | ঘূর্ণন: ${_sheetBRotation.toStringAsFixed(1)} deg',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 10),
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

      await HistoryService.instance.saveItem(
        CalculationHistoryItem(
          id: 'joint_${DateTime.now().millisecondsSinceEpoch}',
          title: 'ম্যাপ জয়েন্ট: $sheetALabel + $sheetBLabel',
          category: 'মৌজা ম্যাপ',
          timestamp: DateTime.now(),
          inputSummary: 'ওভারল্যাপ: ${_horizontalOverlap.toInt()}px | উল্লম্ব: ${_verticalAlignment.toInt()}px | ঘূর্ণন: ${_sheetBRotation.toStringAsFixed(1)}°',
          resultSummary: 'সংযুক্ত ২ শিট A4 ল্যান্ডস্কেপ PDF প্রস্তুত',
          fullReportBangla: 'ম্যাপ জয়েন্ট প্রকল্প\nতারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}\n$sheetALabel + $sheetBLabel',
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'BDLandPro_Joint_Mouza_Map.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ম্যাপ এক্সপোর্ট ত্রুটি: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ম্যাপ জয়েন্ট (একাধিক সিট জয়েন)'),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'PDF ও সেভ করুন',
            onPressed: _exportAndSaveJointPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          // Sheet selectors header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppColors.primaryGreenLight,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String?>(
                    value: _sheetAAsset,
                    isExpanded: true,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    items: _sheetChoices
                        .map((c) => DropdownMenuItem<String?>(
                              value: c['asset'],
                              child: Text('বাম: ${c['label']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _sheetAAsset = v),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.link, color: AppColors.primaryGreen, size: 18),
                ),
                Expanded(
                  child: DropdownButton<String?>(
                    value: _sheetBAsset,
                    isExpanded: true,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    items: _sheetChoices
                        .map((c) => DropdownMenuItem<String?>(
                              value: c['asset'],
                              child: Text('ডান: ${c['label']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _sheetBAsset = v),
                  ),
                ),
              ],
            ),
          ),

          // Interactive Stitched Map Canvas
          Expanded(
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(40),
              minScale: 0.5,
              maxScale: 4.0,
              child: RepaintBoundary(
                key: _canvasKey,
                child: (_sheetAAsset == null && _sheetBAsset == null)
                    ? CustomPaint(
                        painter: _StitchedMapPainter(
                          overlap: _horizontalOverlap,
                          verticalShift: _verticalAlignment,
                          rotationDeg: _sheetBRotation,
                        ),
                        size: Size.infinite,
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final halfW = constraints.maxWidth / 2;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: 8,
                                top: 20,
                                width: halfW + _horizontalOverlap,
                                height: constraints.maxHeight - 40,
                                child: _sheetAAsset != null
                                    ? MouzaSheetImage(assetPath: _sheetAAsset, fit: BoxFit.contain)
                                    : Container(color: const Color(0xFFFAF6EE), child: const Center(child: Text('ভেক্টর শিট ১'))),
                              ),
                              Positioned(
                                left: halfW + _horizontalOverlap,
                                top: 20 + _verticalAlignment,
                                width: halfW - 8,
                                height: constraints.maxHeight - 40,
                                child: Transform.rotate(
                                  angle: _sheetBRotation * math.pi / 180.0,
                                  child: _sheetBAsset != null
                                      ? MouzaSheetImage(assetPath: _sheetBAsset, fit: BoxFit.contain)
                                      : Container(color: const Color(0xFFFDFBF7), child: const Center(child: Text('ভেক্টর শিট ২'))),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),
          ),

          // Alignment Nudge Sliders
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('অনুভূমিক মিল:', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text('${BanglaNumerals.toBangla(_horizontalOverlap.toInt())} px', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                    const Text('উল্লম্ব মিল:', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text('${BanglaNumerals.toBangla(_verticalAlignment.toInt())} px', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                Row(
                  children: [
                    const Text('ডান শিট ঘূর্ণন:', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text('${BanglaNumerals.toBangla(_sheetBRotation.toStringAsFixed(1))}°', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: _sheetBRotation,
                        min: -15,
                        max: 15,
                        activeColor: const Color(0xFF0284C7),
                        onChanged: (val) => setState(() => _sheetBRotation = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => setState(() {
                        _horizontalOverlap = 0;
                        _verticalAlignment = 0;
                        _sheetBRotation = 0;
                      }),
                      icon: const Icon(Icons.restart_alt, size: 18),
                      label: const Text('রিসেট'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isExporting ? null : _exportAndSaveJointPdf,
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('জয়েন্ট PDF তৈরি ও সেভ'),
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
  final double rotationDeg;

  _StitchedMapPainter({
    required this.overlap,
    required this.verticalShift,
    required this.rotationDeg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midX = size.width / 2;

    // Sheet 1 (Left)
    final sheet1Rect = Rect.fromLTWH(20, 40, midX - 20 + overlap, size.height - 80);
    canvas.drawRect(sheet1Rect, Paint()..color = const Color(0xFFFAF6EE));
    canvas.drawRect(sheet1Rect, Paint()..color = const Color(0xFFC7BCA1)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Sheet 2 (Right with vertical shift & rotation)
    canvas.save();
    final sheet2Rect = Rect.fromLTWH(midX + overlap, 40 + verticalShift, midX - 30, size.height - 80);
    canvas.translate(sheet2Rect.center.dx, sheet2Rect.center.dy);
    canvas.rotate(rotationDeg * math.pi / 180.0);
    canvas.translate(-sheet2Rect.center.dx, -sheet2Rect.center.dy);
    canvas.drawRect(sheet2Rect, Paint()..color = const Color(0xFFFDFBF7));
    canvas.drawRect(sheet2Rect, Paint()..color = const Color(0xFFC7BCA1)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.restore();

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
      oldDelegate.overlap != overlap ||
      oldDelegate.verticalShift != verticalShift ||
      oldDelegate.rotationDeg != rotationDeg;
}
