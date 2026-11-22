import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/services/history_service.dart';
import '../../history/models/calculation_history_item.dart';

class MouzaMapAdvanceCadScreen extends StatefulWidget {
  const MouzaMapAdvanceCadScreen({super.key});

  @override
  State<MouzaMapAdvanceCadScreen> createState() => _MouzaMapAdvanceCadScreenState();
}

class _MouzaMapAdvanceCadScreenState extends State<MouzaMapAdvanceCadScreen> {
  bool _snapToGrid = true;
  bool _showAngles = true;
  double _gridSpacing = 20.0;

  final List<Offset> _vertices = [
    const Offset(60, 60),
    const Offset(260, 60),
    const Offset(280, 220),
    const Offset(40, 200),
  ];

  // Optional dividing line (start & end)
  Offset? _splitStart;
  Offset? _splitEnd;
  bool _isSplitMode = false;

  int? _selectedVertexIndex;

  @override
  Widget build(BuildContext context) {
    final areaSqFt = _calculatePolygonArea(_vertices);
    final dec = areaSqFt / 435.60;
    final katha = areaSqFt / 720.00;

    return Scaffold(
      appBar: AppBar(
        title: const Text('মৌজা ম্যাপ পরিমাপ (অ্যাডভান্সড CAD)'),
        actions: [
          IconButton(
            icon: Icon(_snapToGrid ? Icons.grid_on : Icons.grid_off),
            tooltip: _snapToGrid ? 'স্ন্যাপ গ্রিড চালু' : 'স্ন্যাপ গ্রিড বন্ধ',
            onPressed: () => setState(() => _snapToGrid = !_snapToGrid),
          ),
          IconButton(
            icon: Icon(_showAngles ? Icons.architecture : Icons.crop_square),
            tooltip: _showAngles ? 'কোণ প্রদর্শন চালু' : 'কোণ প্রদর্শন বন্ধ',
            onPressed: () => setState(() => _showAngles = !_showAngles),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'DXF এক্সপোর্ট',
            onPressed: _exportDxf,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'কপি রিপোর্ট',
            onPressed: _copyReport,
          ),
        ],
      ),
      body: Column(
        children: [
          // CAD Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF1E293B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified, color: AppColors.secondaryGold, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'CAD ক্ষেত্রফল: ${BanglaFormatter.formatNumber(dec, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(katha, fractionDigits: 2)} কাঠা)',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Text(
                  '${BanglaFormatter.formatNumber(areaSqFt)} sq ft',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // Interactive CAD View
          Expanded(
            child: GestureDetector(
              onTapDown: (details) {
                final pos = _snapPos(details.localPosition);
                if (_isSplitMode) {
                  setState(() {
                    if (_splitStart == null) {
                      _splitStart = pos;
                    } else if (_splitEnd == null) {
                      _splitEnd = pos;
                      _isSplitMode = false;
                    }
                  });
                  return;
                }

                // Check vertex click
                int? found;
                for (int i = 0; i < _vertices.length; i++) {
                  if ((_vertices[i] - pos).distance < 20) {
                    found = i;
                    break;
                  }
                }
                setState(() {
                  if (found != null) {
                    _selectedVertexIndex = found;
                  } else {
                    _vertices.add(pos);
                  }
                });
              },
              onPanUpdate: (details) {
                if (_selectedVertexIndex != null && _selectedVertexIndex! < _vertices.length) {
                  setState(() {
                    _vertices[_selectedVertexIndex!] = _snapPos(details.localPosition);
                  });
                }
              },
              onPanEnd: (_) => setState(() => _selectedVertexIndex = null),
              child: CustomPaint(
                painter: _CadCanvasPainter(
                  vertices: _vertices,
                  snapToGrid: _snapToGrid,
                  gridSpacing: _gridSpacing,
                  showAngles: _showAngles,
                  splitStart: _splitStart,
                  splitEnd: _splitEnd,
                ),
                size: Size.infinite,
              ),
            ),
          ),

          // CAD Tools Command Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isSplitMode = !_isSplitMode;
                      if (_isSplitMode) {
                        _splitStart = null;
                        _splitEnd = null;
                      }
                    });
                  },
                  icon: const Icon(Icons.call_split, size: 18),
                  label: Text(_isSplitMode ? 'বিভাজন সম্পন্ন করুন' : 'প্লট দ্বিখণ্ডিত করুন'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _isSplitMode ? AppColors.accentCrimson : AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () {
                    if (_vertices.isNotEmpty) {
                      setState(() => _vertices.removeLast());
                    }
                  },
                  icon: const Icon(Icons.undo),
                  tooltip: 'পূর্বাবস্থা',
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () {
                    setState(() {
                      _vertices.clear();
                      _splitStart = null;
                      _splitEnd = null;
                    });
                  },
                  icon: const Icon(Icons.delete_sweep, color: AppColors.accentCrimson),
                  tooltip: 'ক্লিয়ার',
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _exportDxf,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('DXF ফাইল'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Offset _snapPos(Offset pos) {
    if (!_snapToGrid) return pos;
    final sx = (pos.dx / _gridSpacing).round() * _gridSpacing;
    final sy = (pos.dy / _gridSpacing).round() * _gridSpacing;
    return Offset(sx, sy);
  }

  double _calculatePolygonArea(List<Offset> pts) {
    if (pts.length < 3) return 0.0;
    double sum = 0.0;
    for (int i = 0; i < pts.length; i++) {
      final p1 = pts[i];
      final p2 = pts[(i + 1) % pts.length];
      sum += (p1.dx * p2.dy) - (p2.dx * p1.dy);
    }
    return sum.abs() / 2.0;
  }

  String _generateDxfText() {
    // Generate valid standard AutoCAD DXF file content
    final buffer = StringBuffer();
    buffer.writeln('0\nSECTION\n2\nHEADER\n0\nENDSEC');
    buffer.writeln('0\nSECTION\n2\nENTITIES');
    for (int i = 0; i < _vertices.length; i++) {
      final p1 = _vertices[i];
      final p2 = _vertices[(i + 1) % _vertices.length];
      buffer.writeln('0\nLINE\n8\nBOUNDARY');
      buffer.writeln('10\n${p1.dx}\n20\n${p1.dy}\n30\n0.0');
      buffer.writeln('11\n${p2.dx}\n21\n${p2.dy}\n31\n0.0');
    }
    if (_splitStart != null && _splitEnd != null) {
      buffer.writeln('0\nLINE\n8\nSPLIT_LINE');
      buffer.writeln('10\n${_splitStart!.dx}\n20\n${_splitStart!.dy}\n30\n0.0');
      buffer.writeln('11\n${_splitEnd!.dx}\n21\n${_splitEnd!.dy}\n31\n0.0');
    }
    buffer.writeln('0\nENDSEC\n0\nEOF');
    return buffer.toString();
  }

  void _exportDxf() {
    final dxf = _generateDxfText();
    Clipboard.setData(ClipboardData(text: dxf));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AutoCAD DXF কোড ক্লিপবোর্ডে কপি করা হয়েছে! (.dxf ফাইলে সেভ করে ক্যাড সফটওয়্যারে খুলুন)'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _copyReport() {
    final areaSqFt = _calculatePolygonArea(_vertices);
    final dec = areaSqFt / 435.60;
    final katha = areaSqFt / 720.00;

    final text = '''
=== মৌজা ম্যাপ CAD রিপোর্ট ===
তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}
মোট শীর্ষবিন্দু: ${BanglaNumerals.toBangla(_vertices.length)} টি
মোট ক্ষেত্রফল: ${BanglaFormatter.formatNumber(areaSqFt)} বর্গফুট
মোট শতাংশ: ${BanglaFormatter.formatNumber(dec, fractionDigits: 3)} শতক
মোট কাঠা: ${BanglaFormatter.formatNumber(katha, fractionDigits: 3)} কাঠা
বিভাজন রেখা: ${_splitStart != null && _splitEnd != null ? "যুক্ত করা হয়েছে" : "নেই"}
অ্যাপ: BDLandPro - পেশাদার বাংলাদেশ ভূমি জরিপ
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CAD রিপোর্ট ক্লিপবোর্ডে কপি করা হয়েছে!')),
    );
  }
}

class _CadCanvasPainter extends CustomPainter {
  final List<Offset> vertices;
  final bool snapToGrid;
  final double gridSpacing;
  final bool showAngles;
  final Offset? splitStart;
  final Offset? splitEnd;

  _CadCanvasPainter({
    required this.vertices,
    required this.snapToGrid,
    required this.gridSpacing,
    required this.showAngles,
    this.splitStart,
    this.splitEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dark CAD background (AutoCAD aesthetic)
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0F172A));

    // 2. CAD Dot Grid
    final dotPaint = Paint()..color = const Color(0xFF334155)..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += gridSpacing) {
      for (double y = 0; y < size.height; y += gridSpacing) {
        canvas.drawCircle(Offset(x, y), 0.8, dotPaint);
      }
    }

    if (vertices.isEmpty) return;

    // 3. Polygon Lines
    final polyPath = Path();
    polyPath.moveTo(vertices[0].dx, vertices[0].dy);
    for (int i = 1; i < vertices.length; i++) {
      polyPath.lineTo(vertices[i].dx, vertices[i].dy);
    }
    if (vertices.length >= 3) {
      polyPath.close();
      canvas.drawPath(polyPath, Paint()..color = Colors.cyan.withOpacity(0.15)..style = PaintingStyle.fill);
    }

    final linePaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(polyPath, linePaint);

    // 4. Dimensions & Angle labels
    for (int i = 0; i < vertices.length; i++) {
      final p1 = vertices[i];
      // Vertex node
      canvas.drawCircle(p1, 5, Paint()..color = Colors.white);
      canvas.drawCircle(p1, 5, Paint()..color = Colors.cyanAccent..strokeWidth = 1.5..style = PaintingStyle.stroke);

      if (vertices.length > 1) {
        final p2 = vertices[(i + 1) % vertices.length];
        if (i < vertices.length - 1 || vertices.length >= 3) {
          final dist = (p2 - p1).distance;
          final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
          _drawText(canvas, '${BanglaNumerals.toBangla(dist.toStringAsFixed(1))}\'', mid, Colors.yellowAccent);
        }
      }

      // Vertex angle calculation
      if (showAngles && vertices.length >= 3) {
        final prev = vertices[(i - 1 + vertices.length) % vertices.length];
        final next = vertices[(i + 1) % vertices.length];
        final angle = _computeAngle(prev, p1, next);
        _drawText(canvas, '${BanglaNumerals.toBangla(angle.toStringAsFixed(0))}°', Offset(p1.dx + 12, p1.dy - 12), Colors.greenAccent);
      }
    }

    // 5. Dividing Split Line
    if (splitStart != null && splitEnd != null) {
      final splitPaint = Paint()
        ..color = AppColors.accentCrimson
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(splitStart!, splitEnd!, splitPaint);
      _drawText(canvas, 'বিভাজন রেখা (Cut Line)', Offset((splitStart!.dx + splitEnd!.dx) / 2, (splitStart!.dy + splitEnd!.dy) / 2 - 10), Colors.redAccent);
    }
  }

  double _computeAngle(Offset p1, Offset p2, Offset p3) {
    final v1 = Offset(p1.dx - p2.dx, p1.dy - p2.dy);
    final v2 = Offset(p3.dx - p2.dx, p3.dy - p2.dy);
    final dot = (v1.dx * v2.dx) + (v1.dy * v2.dy);
    final mag1 = math.sqrt(v1.dx * v1.dx + v1.dy * v1.dy);
    final mag2 = math.sqrt(v2.dx * v2.dx + v2.dy * v2.dy);
    if (mag1 == 0 || mag2 == 0) return 0;
    final cosAngle = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    return math.acos(cosAngle) * (180.0 / math.pi);
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black.withOpacity(0.6),
          fontFamily: 'Hind Siliguri',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(offset.dx - tp.width / 2, offset.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _CadCanvasPainter oldDelegate) => true;
}
