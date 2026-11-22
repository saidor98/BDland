import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/services/history_service.dart';
import '../../history/models/calculation_history_item.dart';
import '../models/geometry_models.dart';
import '../painters/geometry_painters.dart';
import '../services/geometry_calculator.dart';

class TrapezoidScreen extends StatefulWidget {
  const TrapezoidScreen({super.key});

  @override
  State<TrapezoidScreen> createState() => _TrapezoidScreenState();
}

class _TrapezoidScreenState extends State<TrapezoidScreen> {
  final _parallelAController = TextEditingController(text: '90');
  final _parallelBController = TextEditingController(text: '120');
  final _heightController = TextEditingController(text: '60');

  TrapezoidResult? _result;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _parallelAController.dispose();
    _parallelBController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _calculate() {
    final a = double.tryParse(_parallelAController.text) ?? 0.0;
    final b = double.tryParse(_parallelBController.text) ?? 0.0;
    final h = double.tryParse(_heightController.text) ?? 0.0;

    if (a > 0 && b > 0 && h > 0) {
      setState(() {
        _result = GeometryCalculator.calculateTrapezoid(
          parallelA: a,
          parallelB: b,
          height: h,
        );
      });
    }
  }

  String _generateReport() {
    if (_result == null) return '';
    final r = _result!;
    return '''
=== ট্রাপিজিয়াম জমি পরিমাপ রিপোর্ট ===
তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}
সমান্তরাল বাহু ১ (a): ${BanglaFormatter.formatNumber(r.parallelA)} ফুট
সমান্তরাল বাহু ২ (b): ${BanglaFormatter.formatNumber(r.parallelB)} ফুট
লম্ব দূরত্ব/উচ্চতা (h): ${BanglaFormatter.formatNumber(r.height)} ফুট

[ফলাফল]
মোট ক্ষেত্রফল: ${BanglaFormatter.formatNumber(r.areaSqFt)} বর্গফুট
মোট শতাংশ: ${BanglaFormatter.formatNumber(r.areaDecimal, fractionDigits: 3)} শতক
মোট কাঠা: ${BanglaFormatter.formatNumber(r.areaKatha, fractionDigits: 3)} কাঠা
বিস্তারিত: ${BanglaFormatter.formatLandBreakdown(r.areaSqFt)}

অ্যাপ: BDLandPro (বাংলাদেশ ভূমি জরিপ ও পরিমাপ)
''';
  }

  void _copyReport() {
    final report = _generateReport();
    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ট্রাপিজিয়ামের রিপোর্ট কপি করা হয়েছে!'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  Future<void> _saveToHistory() async {
    if (_result == null) return;
    final r = _result!;
    final item = CalculationHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'ট্রাপিজিয়াম জমি (${BanglaFormatter.formatNumber(r.areaDecimal, fractionDigits: 2)} শতক)',
      category: 'জ্যামিতি',
      timestamp: DateTime.now(),
      inputSummary: 'সমান্তরাল: ${r.parallelA}\', ${r.parallelB}\', উচ্চতা: ${r.height}\'',
      resultSummary: '${BanglaFormatter.formatNumber(r.areaDecimal, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(r.areaSqFt)} বর্গফুট)',
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
        title: const Text('ট্রাপিজিয়াম জমি পরিমাপ'),
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
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: TrapezoidPainter(
                      parallelA: double.tryParse(_parallelAController.text) ?? 0,
                      parallelB: double.tryParse(_parallelBController.text) ?? 0,
                      height: double.tryParse(_heightController.text) ?? 0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _parallelAController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'সমান্তরাল ১ম বাহু - a (ফুট)'),
                      onChanged: (_) => _calculate(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _parallelBController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'সমান্তরাল ২য় বাহু - b (ফুট)'),
                      onChanged: (_) => _calculate(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'লম্ব উচ্চতা - h (ফুট)'),
                      onChanged: (_) => _calculate(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _calculate,
                      icon: const Icon(Icons.calculate),
                      label: const Text('হিসাব করুন'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_result != null)
              Card(
                color: AppColors.primaryGreenLight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildResultRow('মোট শতাংশ (শতক)',
                          '${BanglaFormatter.formatNumber(_result!.areaDecimal, fractionDigits: 3)} শতক',
                          isHighlight: true),
                      _buildResultRow('মোট কাঠা',
                          '${BanglaFormatter.formatNumber(_result!.areaKatha, fractionDigits: 3)} কাঠা'),
                      _buildResultRow('বর্গফুট',
                          '${BanglaFormatter.formatNumber(_result!.areaSqFt)} বর্গফুট'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'বিস্তারিত: ${BanglaFormatter.formatLandBreakdown(_result!.areaSqFt)}',
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
