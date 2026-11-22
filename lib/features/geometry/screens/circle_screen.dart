import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/services/history_service.dart';
import '../../history/models/calculation_history_item.dart';
import '../models/geometry_models.dart';
import '../painters/geometry_painters.dart';
import '../services/geometry_calculator.dart';

class CircleScreen extends StatefulWidget {
  const CircleScreen({super.key});

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  final _radiusController = TextEditingController(text: '40');
  final _angleController = TextEditingController(text: '');

  bool _isSector = false;
  CircleResult? _result;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _radiusController.dispose();
    _angleController.dispose();
    super.dispose();
  }

  void _calculate() {
    final r = double.tryParse(_radiusController.text) ?? 0.0;
    final angle = _isSector ? double.tryParse(_angleController.text) : null;

    if (r > 0) {
      setState(() {
        _result = GeometryCalculator.calculateCircle(
          radius: r,
          angleDegrees: angle,
        );
      });
    }
  }

  String _generateReport() {
    if (_result == null) return '';
    final res = _result!;
    return '''
=== বৃত্তাকার / বৃত্তাংশ জমি পরিমাপ রিপোর্ট ===
তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}
ধরন: ${res.isSector ? "বৃত্তাংশ (Sector)" : "পূর্ণ বৃত্ত (Full Circle)"}
ব্যাসার্ধ (Radius): ${BanglaFormatter.formatNumber(res.radius)} ফুট
ব্যাস (Diameter): ${BanglaFormatter.formatNumber(res.diameter)} ফুট
${res.isSector ? "কোণ (Angle): ${BanglaFormatter.formatNumber(res.angleDegrees ?? 0)}°" : ""}

[ফলাফল]
মোট ক্ষেত্রফল: ${BanglaFormatter.formatNumber(res.areaSqFt)} বর্গফুট
মোট শতাংশ: ${BanglaFormatter.formatNumber(res.areaDecimal, fractionDigits: 3)} শতক
মোট কাঠা: ${BanglaFormatter.formatNumber(res.areaKatha, fractionDigits: 3)} কাঠা
${res.isSector ? "চাপ ও ব্যাসার্ধের দৈর্ঘ্য: ${BanglaFormatter.formatNumber(res.perimeterOrArcLength)} ফুট" : "পরিধি: ${BanglaFormatter.formatNumber(res.perimeterOrArcLength)} ফুট"}
বিস্তারিত: ${BanglaFormatter.formatLandBreakdown(res.areaSqFt)}

অ্যাপ: BDLandPro (বাংলাদেশ ভূমি জরিপ ও পরিমাপ)
''';
  }

  void _copyReport() {
    final report = _generateReport();
    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('বৃত্তাকার জমির রিপোর্ট কপি করা হয়েছে!'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  Future<void> _saveToHistory() async {
    if (_result == null) return;
    final res = _result!;
    final item = CalculationHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'বৃত্তাকার জমি (${BanglaFormatter.formatNumber(res.areaDecimal, fractionDigits: 2)} শতক)',
      category: 'জ্যামিতি',
      timestamp: DateTime.now(),
      inputSummary: 'ব্যাসার্ধ: ${res.radius}\'${res.isSector ? ', কোণ: ${res.angleDegrees}°' : ''}',
      resultSummary: '${BanglaFormatter.formatNumber(res.areaDecimal, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(res.areaSqFt)} বর্গফুট)',
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
        title: const Text('বৃত্তাকার জমি পরিমাপ'),
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
                  height: 190,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: CirclePainter(
                      radius: double.tryParse(_radiusController.text) ?? 0,
                      angleDegrees: _isSector ? double.tryParse(_angleController.text) : null,
                      isSector: _isSector,
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
                      controller: _radiusController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'কেন্দ্র থেকে সীমানার ব্যাসার্ধ (Radius - ফুট)',
                        prefixIcon: Icon(Icons.radio_button_checked, color: AppColors.primaryGreen),
                      ),
                      onChanged: (_) => _calculate(),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('বৃত্তাংশ / খণ্ড জমি (Sector)'),
                      subtitle: const Text('জমি পূর্ণ বৃত্ত না হয়ে পিঠার মতো খণ্ড হলে'),
                      value: _isSector,
                      activeColor: AppColors.primaryGreen,
                      onChanged: (val) {
                        setState(() {
                          _isSector = val;
                          _calculate();
                        });
                      },
                    ),
                    if (_isSector) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _angleController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'কেন্দ্রস্থ কোণ (ডিগ্রী, যেমন: ৯০, ১২০ ইত্যাদি)',
                          prefixIcon: Icon(Icons.pie_chart, color: AppColors.secondaryGold),
                        ),
                        onChanged: (_) => _calculate(),
                      ),
                    ],
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
                      _buildResultRow(
                        _result!.isSector ? 'চাপের দৈর্ঘ্য' : 'পরিধি (Perimeter)',
                        '${BanglaFormatter.formatNumber(_result!.perimeterOrArcLength)} ফুট',
                      ),
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
