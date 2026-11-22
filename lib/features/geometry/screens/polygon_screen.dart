import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/services/history_service.dart';
import '../../history/models/calculation_history_item.dart';
import '../models/geometry_models.dart';
import '../services/geometry_calculator.dart';

class PolygonScreen extends StatefulWidget {
  const PolygonScreen({super.key});

  @override
  State<PolygonScreen> createState() => _PolygonScreenState();
}

class _TriangleInputHolder {
  final TextEditingController sideA;
  final TextEditingController sideB;
  final TextEditingController sideC;

  _TriangleInputHolder({
    required String a,
    required String b,
    required String c,
  })  : sideA = TextEditingController(text: a),
        sideB = TextEditingController(text: b),
        sideC = TextEditingController(text: c);

  void dispose() {
    sideA.dispose();
    sideB.dispose();
    sideC.dispose();
  }
}

class _PolygonScreenState extends State<PolygonScreen> {
  final List<_TriangleInputHolder> _triangles = [
    _TriangleInputHolder(a: '70', b: '90', c: '110'),
    _TriangleInputHolder(a: '110', b: '85', c: '120'),
    _TriangleInputHolder(a: '120', b: '65', c: '95'),
  ];

  PolygonResult? _result;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    for (final t in _triangles) {
      t.dispose();
    }
    super.dispose();
  }

  void _addTriangle() {
    setState(() {
      _triangles.add(_TriangleInputHolder(a: '', b: '', c: ''));
    });
  }

  void _removeTriangle(int index) {
    if (_triangles.length <= 1) return;
    setState(() {
      final removed = _triangles.removeAt(index);
      removed.dispose();
      _calculate();
    });
  }

  void _calculate() {
    final list = <List<double>>[];
    for (final t in _triangles) {
      final a = double.tryParse(t.sideA.text) ?? 0.0;
      final b = double.tryParse(t.sideB.text) ?? 0.0;
      final c = double.tryParse(t.sideC.text) ?? 0.0;
      if (a > 0 && b > 0 && c > 0) {
        list.add([a, b, c]);
      }
    }

    if (list.isNotEmpty) {
      setState(() {
        _result = GeometryCalculator.calculatePolygonTriangulation(list);
      });
    }
  }

  String _generateReport() {
    if (_result == null) return '';
    final r = _result!;

    final buffer = StringBuffer();
    buffer.writeln('=== বহুভুজ জমি পরিমাপ (ত্রিভুজায়ন পদ্ধতি) ===');
    buffer.writeln('তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}');
    buffer.writeln('মোট খণ্ড/ত্রিভুজ সংখ্যা: ${BanglaNumerals.toBangla(r.parts.length)} টি\n');

    for (final p in r.parts) {
      buffer.writeln('ত্রিভুজ #${BanglaNumerals.toBangla(p.index)}:');
      buffer.writeln('বাহুসমূহ: ${BanglaFormatter.formatNumber(p.sideA)}\', ${BanglaFormatter.formatNumber(p.sideB)}\', ${BanglaFormatter.formatNumber(p.sideC)}\' ফুট');
      buffer.writeln('ক্ষেত্রফল: ${BanglaFormatter.formatNumber(p.areaSqFt)} বর্গফুট (${BanglaFormatter.formatNumber(p.areaDecimal, fractionDigits: 3)} শতক)\n');
    }

    buffer.writeln('[সর্বমোট জমির পরিমাণ]');
    buffer.writeln('মোট ক্ষেত্রফল: ${BanglaFormatter.formatNumber(r.totalAreaSqFt)} বর্গফুট');
    buffer.writeln('মোট শতাংশ: ${BanglaFormatter.formatNumber(r.totalAreaDecimal, fractionDigits: 3)} শতক');
    buffer.writeln('মোট কাঠা: ${BanglaFormatter.formatNumber(r.totalAreaKatha, fractionDigits: 3)} কাঠা');
    buffer.writeln('বিস্তারিত: ${BanglaFormatter.formatLandBreakdown(r.totalAreaSqFt)}');
    buffer.writeln('\nঅ্যাপ: BDLandPro (বাংলাদেশ ভূমি জরিপ ও পরিমাপ)');

    return buffer.toString();
  }

  void _copyReport() {
    final report = _generateReport();
    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('বহুভুজের সম্পূর্ণ রিপোর্ট কপি করা হয়েছে!'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  Future<void> _saveToHistory() async {
    if (_result == null) return;
    final r = _result!;
    final item = CalculationHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'বহুভুজ জমি (${BanglaFormatter.formatNumber(r.totalAreaDecimal, fractionDigits: 2)} শতক)',
      category: 'জ্যামিতি',
      timestamp: DateTime.now(),
      inputSummary: '${r.parts.length} টি ত্রিভুজ খণ্ডে বিভক্ত জমি',
      resultSummary: '${BanglaFormatter.formatNumber(r.totalAreaDecimal, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(r.totalAreaSqFt)} বর্গফুট)',
      fullReportBangla: _generateReport(),
    );
    await HistoryService.instance.saveItem(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('হিস্ট্রিতে সংরক্ষিত হয়েছে!'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('বহুভুজ জমি পরিমাপ (ত্রিভুজায়ন)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'কপি',
            onPressed: _result != null ? _copyReport : null,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'সেভ',
            onPressed: _result != null ? _saveToHistory : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Educational Notice Card
            Card(
              color: AppColors.secondaryGoldLight,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: AppColors.secondaryGoldDark),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '৫, ৬ বা ততোধিক বাহুর অনিয়মিত জমি পরিমাপের জন্য জমিটিকে অভ্যন্তরীণ কর্ণ টেনে কয়েকটি ত্রিভুজে ভাগ করে প্রত্যেক ত্রিভুজের ৩ বাহুর মাপ ইনপুট দিন।',
                        style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Triangles List
            ...List.generate(_triangles.length, (index) {
              final holder = _triangles[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ত্রিভুজ খণ্ড #${BanglaNumerals.toBangla(index + 1)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          if (_triangles.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.accentCrimson, size: 20),
                              onPressed: () => _removeTriangle(index),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: holder.sideA,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: '১ম বাহু (ফুট)'),
                              onChanged: (_) => _calculate(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: holder.sideB,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: '২য় বাহু (ফুট)'),
                              onChanged: (_) => _calculate(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: holder.sideC,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: '৩য় বাহু (ফুট)'),
                              onChanged: (_) => _calculate(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            OutlinedButton.icon(
              onPressed: _addTriangle,
              icon: const Icon(Icons.add),
              label: const Text('আরও একটি ত্রিভুজ খণ্ড যোগ করুন'),
            ),
            const SizedBox(height: 16),

            // Total Results
            if (_result != null)
              Card(
                color: AppColors.primaryGreenLight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'সর্বমোট জমির পরিমাণ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreenDark,
                        ),
                      ),
                      const Divider(height: 20),
                      _buildResultRow('সর্বমোট শতাংশ (শতক)',
                          '${BanglaFormatter.formatNumber(_result!.totalAreaDecimal, fractionDigits: 3)} শতক',
                          isHighlight: true),
                      _buildResultRow('সর্বমোট কাঠা',
                          '${BanglaFormatter.formatNumber(_result!.totalAreaKatha, fractionDigits: 3)} কাঠা'),
                      _buildResultRow('সর্বমোট বর্গফুট',
                          '${BanglaFormatter.formatNumber(_result!.totalAreaSqFt)} বর্গফুট'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'বিস্তারিত: ${BanglaFormatter.formatLandBreakdown(_result!.totalAreaSqFt)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isHighlight ? 16 : 14)),
          Text(value,
              style: TextStyle(
                fontSize: isHighlight ? 17 : 14,
                fontWeight: FontWeight.bold,
                color: isHighlight ? AppColors.primaryGreenDark : AppColors.textPrimary,
              )),
        ],
      ),
    );
  }
}
