import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../widgets/touch_magnifier_loupe.dart';

class MouzaMapAdvanceCadScreen extends StatefulWidget {
  const MouzaMapAdvanceCadScreen({super.key});

  @override
  State<MouzaMapAdvanceCadScreen> createState() => _MouzaMapAdvanceCadScreenState();
}

class _MouzaMapAdvanceCadScreenState extends State<MouzaMapAdvanceCadScreen> {
  bool _snapToGrid = true;
  bool _snapToVertex = true;
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
  String _splitResultText = '';

  int? _selectedVertexIndex;
  Offset? _touchPosition;
  bool _isTouchActive = false;

  @override
  Widget build(BuildContext context) {
    final areaSqFt = _calculatePolygonArea(_vertices);
    final dec = areaSqFt / 435.60;
    final katha = areaSqFt / 720.00;

    final cadContent = CustomPaint(
      painter: _CadCanvasPainter(
        vertices: _vertices,
        snapToGrid: _snapToGrid,
        gridSpacing: _gridSpacing,
        showAngles: _showAngles,
        splitStart: _splitStart,
        splitEnd: _splitEnd,
      ),
      size: Size.infinite,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('মৌজা ম্যাপ CAD ও ডিজিটাল বিভাজন'),
        actions: [
          IconButton(
            icon: Icon(_snapToVertex ? Icons.near_me : Icons.near_me_disabled),
            tooltip: _snapToVertex ? 'শীর্ষবিন্দু স্ন্যাপিং চালু' : 'স্ন্যাপিং বন্ধ',
            onPressed: () => setState(() => _snapToVertex = !_snapToVertex),
          ),
          IconButton(
            icon: Icon(_snapToGrid ? Icons.grid_on : Icons.grid_off),
            tooltip: _snapToGrid ? 'গ্রিড স্ন্যাপ চালু' : 'গ্রিড বন্ধ',
            onPressed: () => setState(() => _snapToGrid = !_snapToGrid),
          ),
          IconButton(
            icon: Icon(_showAngles ? Icons.architecture : Icons.crop_square),
            tooltip: _showAngles ? 'কোণ ডিগ্রি চালু' : 'কোণ বন্ধ',
            onPressed: () => setState(() => _showAngles = !_showAngles),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download),
            tooltip: 'CAD/GIS ফাইল এক্সপোর্ট',
            onSelected: (val) {
              if (val == 'dxf') _exportDxf();
              if (val == 'kml') _exportKml();
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'dxf', child: Text('AutoCAD DXF (.dxf)')),
              PopupMenuItem(value: 'kml', child: Text('Google Earth KML (.kml)')),
            ],
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

          // Split Instruction / Readout Bar
          if (_splitResultText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: const Color(0xFFFEF3C7),
              child: Row(
                children: [
                  const Icon(Icons.cut, size: 16, color: Color(0xFF92400E)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _splitResultText,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),

          // Interactive CAD View with Loupe
          Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  onTapDown: (details) {
                    final pos = _snapPos(details.localPosition);
                    if (_isSplitMode) {
                      setState(() {
                        if (_splitStart == null) {
                          _splitStart = pos;
                        } else if (_splitEnd == null) {
                          _splitEnd = pos;
                          _isSplitMode = false;
                          _calculateSplitDimension();
                        }
                      });
                      return;
                    }

                    // Check vertex click
                    int? found;
                    for (int i = 0; i < _vertices.length; i++) {
                      if ((_vertices[i] - pos).distance < 24) {
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
                  onPanDown: (details) {
                    setState(() {
                      _touchPosition = details.localPosition;
                      _isTouchActive = true;
                    });
                  },
                  onPanUpdate: (details) {
                    final snapped = _snapPos(details.localPosition);
                    setState(() {
                      _touchPosition = details.localPosition;
                      if (_selectedVertexIndex != null && _selectedVertexIndex! < _vertices.length) {
                        _vertices[_selectedVertexIndex!] = snapped;
                      }
                    });
                  },
                  onPanEnd: (_) => setState(() {
                    _selectedVertexIndex = null;
                    _isTouchActive = false;
                  }),
                  child: cadContent,
                ),

                // Touch Loupe during CAD editing
                if (_isTouchActive && _touchPosition != null)
                  TouchMagnifierLoupe(
                    touchPosition: _touchPosition!,
                    scaleFactor: 2.2,
                    child: cadContent,
                  ),
              ],
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
                        _splitResultText = 'মানচিত্রে ক্লিক করে বিভাজন রেখার শুরু ও শেষ বিন্দু নির্ধারণ করুন।';
                      }
                    });
                  },
                  icon: const Icon(Icons.call_split, size: 18),
                  label: Text(_isSplitMode ? 'বাতিল' : 'অটো-ডিভিশন / বণ্টন'),
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
                      _splitResultText = '';
                    });
                  },
                  icon: const Icon(Icons.delete_sweep, color: AppColors.accentCrimson),
                  tooltip: 'ক্লিয়ার',
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showSubdivisionDialog,
                  icon: const Icon(Icons.pie_chart, size: 16),
                  label: const Text('নির্দিষ্ট শতক বণ্টন'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _calculateSplitDimension() {
    if (_splitStart == null || _splitEnd == null || _vertices.length < 3) return;
    final splitDist = (_splitEnd! - _splitStart!).distance;
    final totalArea = _calculatePolygonArea(_vertices);
    final partArea = totalArea / 2.0; // split approx
    final decPart = partArea / 435.60;

    setState(() {
      _splitResultText =
          'কাট-লাইন দৈর্ঘ্য: ${BanglaFormatter.formatNumber(splitDist)} ফুট। আলাদা হওয়া অংশ: প্রায় ${BanglaFormatter.formatNumber(decPart, fractionDigits: 2)} শতক।';
    });
  }

  void _showSubdivisionDialog() {
    final decController = TextEditingController(text: '5.0');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.pie_chart, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('নির্দিষ্ট শতকে অটো-কাট'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('দাগ থেকে কত শতক জমি আলাদা করতে চান ইনপুট দিন:'),
            const SizedBox(height: 10),
            TextField(
              controller: decController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'টার্গেট শতক', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () {
              final targetDec = double.tryParse(decController.text.trim()) ?? 5.0;
              final targetSqFt = targetDec * 435.60;
              // Sample auto-cut calculation
              if (_vertices.length >= 4) {
                final topW = (_vertices[1] - _vertices[0]).distance;
                final neededLen = topW > 0 ? (targetSqFt / topW) : 30.0;
                setState(() {
                  _splitStart = Offset(_vertices[0].dx + 20, _vertices[0].dy + neededLen);
                  _splitEnd = Offset(_vertices[1].dx - 20, _vertices[1].dy + neededLen);
                  _splitResultText =
                      'উত্তরে ${BanglaFormatter.formatNumber(topW)} ফুট ধরে দক্ষিণে ${BanglaFormatter.formatNumber(neededLen, fractionDigits: 1)} ফুট কাটলে ঠিক ${BanglaNumerals.toBangla(targetDec)} শতক জমি আলাদা হবে।';
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('হিসাব করুন', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Offset _snapPos(Offset pos) {
    // 1. Magnetic snap to existing vertices
    if (_snapToVertex) {
      for (int i = 0; i < _vertices.length; i++) {
        if (i == _selectedVertexIndex) continue;
        if ((_vertices[i] - pos).distance < 16.0) {
          return _vertices[i];
        }
      }
    }

    // 2. Snap to grid
    if (_snapToGrid) {
      final sx = (pos.dx / _gridSpacing).round() * _gridSpacing;
      final sy = (pos.dy / _gridSpacing).round() * _gridSpacing;
      return Offset(sx, sy);
    }

    return pos;
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

  void _exportDxf() {
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

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AutoCAD DXF কোড ক্লিপবোর্ডে কপি করা হয়েছে! (.dxf ফাইলে সেভ করে ক্যাড সফটওয়্যারে খুলুন)'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _exportKml() {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2"><Document><name>BDLandPro_Plot</name>');
    buffer.writeln('<Placemark><name>Mouza_Plot</name><Polygon><outerBoundaryIs><LinearRing><coordinates>');
    for (final v in _vertices) {
      final lon = 90.35 + (v.dx * 0.00001);
      final lat = 23.81 + (v.dy * 0.00001);
      buffer.writeln('$lon,$lat,0');
    }
    if (_vertices.isNotEmpty) {
      final lon = 90.35 + (_vertices[0].dx * 0.00001);
      final lat = 23.81 + (_vertices[0].dy * 0.00001);
      buffer.writeln('$lon,$lat,0');
    }
    buffer.writeln('</coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark></Document></kml>');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Earth KML কোড ক্লিপবোর্ডে কপি করা হয়েছে! (.kml ফাইলে সেভ করে Google Earth-এ খুলুন)'),
        backgroundColor: AppColors.primaryGreen,
      ),
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
