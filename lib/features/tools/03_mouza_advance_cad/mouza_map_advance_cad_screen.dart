import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/services/history_service.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/utils/polygon_geometry.dart';
import '../../history/models/calculation_history_item.dart';
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
  final double _gridSpacing = 20.0;
  double _feetPerPixel = 1.0;

  List<Offset> _vertices = [
    const Offset(60, 60),
    const Offset(260, 60),
    const Offset(280, 220),
    const Offset(40, 200),
  ];

  final List<List<Offset>> _undoStack = [];
  bool _dragSnapshotSaved = false;

  // Optional dividing line (start & end)
  Offset? _splitStart;
  Offset? _splitEnd;
  bool _isSplitMode = false;
  String _splitResultText = '';

  int? _selectedVertexIndex;
  Offset? _touchPosition;
  bool _isTouchActive = false;

  void _pushUndo() {
    _undoStack.add(List<Offset>.from(_vertices));
    if (_undoStack.length > 30) _undoStack.removeAt(0);
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      setState(() {
        _vertices = _undoStack.removeLast();
        _splitStart = null;
        _splitEnd = null;
        _splitResultText = '';
      });
    } else if (_vertices.isNotEmpty) {
      setState(() {
        _vertices.removeLast();
        _splitStart = null;
        _splitEnd = null;
      });
    }
  }

  Future<void> _saveToHistory(double areaSqFt) async {
    final dec = areaSqFt / 435.60;
    final katha = areaSqFt / 720.00;
    await HistoryService.instance.saveItem(
      CalculationHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'অ্যাডভান্স CAD জরিপ (${BanglaFormatter.formatNumber(dec, fractionDigits: 2)} শতক)',
        category: 'মৌজা ম্যাপ',
        timestamp: DateTime.now(),
        inputSummary: '${BanglaNumerals.toBangla(_vertices.length)} টি CAD শীর্ষবিন্দু',
        resultSummary: '${BanglaFormatter.formatNumber(dec, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(katha, fractionDigits: 2)} কাঠা)',
        fullReportBangla:
            '=== অ্যাডভান্স CAD পরিমাপ রিপোর্ট ===\nতারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}\nক্ষেত্রফল: ${BanglaFormatter.formatNumber(dec, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(areaSqFt)} sq ft)\n${_splitResultText.isNotEmpty ? 'বিভাজন: $_splitResultText' : ''}',
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CAD জরিপ হিস্ট্রিতে সংরক্ষিত হয়েছে!'), backgroundColor: AppColors.primaryGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final areaSqFt = PolygonGeometry.calculateArea(_vertices) * (_feetPerPixel * _feetPerPixel);
    final dec = areaSqFt / 435.60;
    final katha = areaSqFt / 720.00;

    final cadContent = CustomPaint(
      painter: _CadCanvasPainter(
        vertices: _vertices,
        gridSpacing: _gridSpacing,
        feetPerPixel: _feetPerPixel,
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
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'হিস্ট্রি সেভ',
            onPressed: _vertices.length >= 3 ? () => _saveToHistory(areaSqFt) : null,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download),
            tooltip: 'CAD/GIS ফাইল এক্সপোর্ট',
            onSelected: (val) {
              if (val == 'dxf') _exportDxf();
              if (val == 'kml') _exportKml();
              if (val == 'scale') _showScaleDialog();
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'scale', child: Text('স্কেল সেট করুন (ft/px)')),
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
                Flexible(
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: AppColors.secondaryGold, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'CAD ক্ষেত্রফল: ${BanglaFormatter.formatNumber(dec, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(katha, fractionDigits: 2)} কাঠা)',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
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

          // Interactive CAD View with LayoutBuilder & 1:1 Touch Loupe
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                return Stack(
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

                        int? found;
                        for (int i = 0; i < _vertices.length; i++) {
                          if ((_vertices[i] - details.localPosition).distance < 24) {
                            found = i;
                            break;
                          }
                        }
                        if (found != null) {
                          setState(() => _selectedVertexIndex = found);
                        } else {
                          _pushUndo();
                          setState(() {
                            _vertices.add(pos);
                            _splitStart = null;
                            _splitEnd = null;
                          });
                        }
                      },
                      onPanDown: (details) {
                        int? found;
                        for (int i = 0; i < _vertices.length; i++) {
                          if ((_vertices[i] - details.localPosition).distance < 24) {
                            found = i;
                            break;
                          }
                        }
                        _dragSnapshotSaved = false;
                        setState(() {
                          _selectedVertexIndex = found;
                          _touchPosition = details.localPosition;
                          _isTouchActive = true;
                        });
                      },
                      onPanUpdate: (details) {
                        final snapped = _snapPos(details.localPosition);
                        if (_selectedVertexIndex != null && !_dragSnapshotSaved) {
                          _pushUndo();
                          _dragSnapshotSaved = true;
                        }
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
                        _dragSnapshotSaved = false;
                      }),
                      child: cadContent,
                    ),

                    // Touch Loupe during CAD editing with exact canvasSize alignment
                    if (_isTouchActive && _touchPosition != null)
                      TouchMagnifierLoupe(
                        touchPosition: _touchPosition!,
                        scaleFactor: 2.2,
                        sourceSize: canvasSize,
                        child: cadContent,
                      ),
                  ],
                );
              },
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
                      } else {
                        _splitResultText = '';
                      }
                    });
                  },
                  icon: const Icon(Icons.call_split, size: 18),
                  label: Text(_isSplitMode ? 'বাতিল' : 'রেখা দিয়ে ভাগ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _isSplitMode ? AppColors.accentCrimson : AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: (_undoStack.isNotEmpty || _vertices.isNotEmpty) ? _undo : null,
                  icon: const Icon(Icons.undo),
                  tooltip: 'পূর্বাবস্থা',
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () {
                    _pushUndo();
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
                  onPressed: _vertices.length >= 3 ? _showSubdivisionDialog : null,
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

  void _showScaleDialog() {
    final ctrl = TextEditingController(text: _feetPerPixel.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CAD স্কেল নির্ধারণ'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'প্রতি ১ পিক্সেল = কত ফুট', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim()) ?? 1.0;
              if (v > 0) setState(() => _feetPerPixel = v.clamp(0.05, 50.0));
              Navigator.pop(ctx);
            },
            child: const Text('সেট করুন'),
          ),
        ],
      ),
    );
  }

  void _calculateSplitDimension() {
    if (_splitStart == null || _splitEnd == null || _vertices.length < 3) return;
    final splitDist = (_splitEnd! - _splitStart!).distance * _feetPerPixel;
    final splitAreas = PolygonGeometry.computeSplitLineAreas(_vertices, _splitStart!, _splitEnd!);
    final scaleSq = _feetPerPixel * _feetPerPixel;
    final decA = (splitAreas.areaLeft * scaleSq) / 435.60;
    final decB = (splitAreas.areaRight * scaleSq) / 435.60;

    setState(() {
      _splitResultText =
          'কাট-লাইন: ${BanglaFormatter.formatNumber(splitDist, fractionDigits: 1)}\' | ১ম অংশ: ${BanglaFormatter.formatNumber(decA, fractionDigits: 3)} শতক, ২য় অংশ: ${BanglaFormatter.formatNumber(decB, fractionDigits: 3)} শতক';
    });
  }

  void _showSubdivisionDialog() {
    final totalSqFt = PolygonGeometry.calculateArea(_vertices) * (_feetPerPixel * _feetPerPixel);
    final totalDec = totalSqFt / 435.60;
    final decController = TextEditingController(text: (totalDec / 2.0).toStringAsFixed(2));
    bool fromNorth = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.pie_chart, color: AppColors.primaryGreen),
              SizedBox(width: 8),
              Flexible(child: Text('নির্দিষ্ট শতকে অটো-কাট')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('মোট জমি: ${BanglaFormatter.formatNumber(totalDec, fractionDigits: 3)} শতক'),
              const SizedBox(height: 10),
              TextField(
                controller: decController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'পৃথক করার পরিমাণ (শতক)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              DropdownButton<bool>(
                isExpanded: true,
                value: fromNorth,
                items: const [
                  DropdownMenuItem(value: true, child: Text('উত্তর দিক হতে কেটে আলাদা করুন')),
                  DropdownMenuItem(value: false, child: Text('দক্ষিণ দিক হতে কেটে আলাদা করুন')),
                ],
                onChanged: (v) {
                  if (v != null) setDlgState(() => fromNorth = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              onPressed: () {
                final targetDec = double.tryParse(decController.text.trim()) ?? 0.0;
                if (targetDec <= 0 || targetDec >= totalDec) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('সঠিক শতক দিন (শূন্যের বেশি এবং মোট জমির কম হতে হবে)।'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                final targetPixelArea = (targetDec * 435.60) / (_feetPerPixel * _feetPerPixel);
                final res = PolygonGeometry.findAreaBisectionCutLine(
                  polygon: _vertices,
                  targetArea: targetPixelArea,
                  horizontalCut: true,
                  fromStart: fromNorth,
                );
                if (res != null) {
                  setState(() {
                    _splitStart = res.cutStart;
                    _splitEnd = res.cutEnd;
                    final cutFt = res.cutLength * _feetPerPixel;
                    final offFt = res.offsetFromEdge * _feetPerPixel;
                    _splitResultText =
                        '${fromNorth ? "উত্তর" : "দক্ষিণ"} প্রান্ত হতে ${BanglaFormatter.formatNumber(offFt, fractionDigits: 1)} ফুট দূরত্বে কাটলে ঠিক ${BanglaFormatter.formatNumber(targetDec, fractionDigits: 3)} শতক (কাট-লাইন: ${BanglaFormatter.formatNumber(cutFt, fractionDigits: 1)}\') আলাদা হবে।';
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('হিসাব ও প্রয়োগ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Offset _snapPos(Offset pos) {
    if (_snapToVertex) {
      for (int i = 0; i < _vertices.length; i++) {
        if (i == _selectedVertexIndex) continue;
        if ((_vertices[i] - pos).distance < 16.0) {
          return _vertices[i];
        }
      }
    }

    if (_snapToGrid) {
      final sx = (pos.dx / _gridSpacing).round() * _gridSpacing;
      final sy = (pos.dy / _gridSpacing).round() * _gridSpacing;
      return Offset(sx, sy);
    }

    return pos;
  }

  void _exportDxf() {
    final buffer = StringBuffer();
    buffer.writeln('0\nSECTION\n2\nHEADER\n0\nENDSEC');
    buffer.writeln('0\nSECTION\n2\nENTITIES');
    for (int i = 0; i < _vertices.length; i++) {
      final p1 = _vertices[i] * _feetPerPixel;
      final p2 = _vertices[(i + 1) % _vertices.length] * _feetPerPixel;
      buffer.writeln('0\nLINE\n8\nBOUNDARY');
      buffer.writeln('10\n${p1.dx.toStringAsFixed(2)}\n20\n${p1.dy.toStringAsFixed(2)}\n30\n0.0');
      buffer.writeln('11\n${p2.dx.toStringAsFixed(2)}\n21\n${p2.dy.toStringAsFixed(2)}\n31\n0.0');
    }
    if (_splitStart != null && _splitEnd != null) {
      final s1 = _splitStart! * _feetPerPixel;
      final s2 = _splitEnd! * _feetPerPixel;
      buffer.writeln('0\nLINE\n8\nSPLIT_LINE');
      buffer.writeln('10\n${s1.dx.toStringAsFixed(2)}\n20\n${s1.dy.toStringAsFixed(2)}\n30\n0.0');
      buffer.writeln('11\n${s2.dx.toStringAsFixed(2)}\n21\n${s2.dy.toStringAsFixed(2)}\n31\n0.0');
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
      final lon = 90.35 + (v.dx * _feetPerPixel / 334000.0);
      final lat = 23.81 - (v.dy * _feetPerPixel / 364000.0);
      buffer.writeln('$lon,$lat,0');
    }
    if (_vertices.isNotEmpty) {
      final lon = 90.35 + (_vertices[0].dx * _feetPerPixel / 334000.0);
      final lat = 23.81 - (_vertices[0].dy * _feetPerPixel / 364000.0);
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
  final double gridSpacing;
  final double feetPerPixel;
  final bool showAngles;
  final Offset? splitStart;
  final Offset? splitEnd;

  _CadCanvasPainter({
    required this.vertices,
    required this.gridSpacing,
    required this.feetPerPixel,
    required this.showAngles,
    this.splitStart,
    this.splitEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0F172A));

    final dotPaint = Paint()..color = const Color(0xFF334155)..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += gridSpacing) {
      for (double y = 0; y < size.height; y += gridSpacing) {
        canvas.drawCircle(Offset(x, y), 0.8, dotPaint);
      }
    }

    if (vertices.isEmpty) return;

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

    for (int i = 0; i < vertices.length; i++) {
      final p1 = vertices[i];
      canvas.drawCircle(p1, 5, Paint()..color = Colors.white);
      canvas.drawCircle(p1, 5, Paint()..color = Colors.cyanAccent..strokeWidth = 1.5..style = PaintingStyle.stroke);

      if (vertices.length > 1) {
        final p2 = vertices[(i + 1) % vertices.length];
        if (i < vertices.length - 1 || vertices.length >= 3) {
          final dist = (p2 - p1).distance * feetPerPixel;
          final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
          _drawText(canvas, '${BanglaNumerals.toBangla(dist.toStringAsFixed(1))}\'', mid, Colors.yellowAccent);
        }
      }

      if (showAngles && vertices.length >= 3) {
        final prev = vertices[(i - 1 + vertices.length) % vertices.length];
        final next = vertices[(i + 1) % vertices.length];
        final angle = PolygonGeometry.calculateInteriorAngleDegrees(prev, p1, next);
        _drawText(canvas, '${BanglaNumerals.toBangla(angle.toStringAsFixed(0))}°', Offset(p1.dx + 12, p1.dy - 12), Colors.greenAccent);
      }
    }

    if (splitStart != null && splitEnd != null) {
      final splitPaint = Paint()
        ..color = AppColors.accentCrimson
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(splitStart!, splitEnd!, splitPaint);
      _drawText(canvas, 'বিভাজন রেখা', Offset((splitStart!.dx + splitEnd!.dx) / 2, (splitStart!.dy + splitEnd!.dy) / 2 - 12), Colors.redAccent);
    }
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
