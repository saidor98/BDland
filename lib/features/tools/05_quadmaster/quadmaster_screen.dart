import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/services/history_service.dart';
import '../../history/models/calculation_history_item.dart';
import '../../geometry/models/geometry_models.dart';
import '../../geometry/services/geometry_calculator.dart';
import '../../geometry/painters/geometry_painters.dart';

class QuadMasterScreen extends StatefulWidget {
  const QuadMasterScreen({super.key});

  @override
  State<QuadMasterScreen> createState() => _QuadMasterScreenState();
}

class _QuadMasterScreenState extends State<QuadMasterScreen> {
  final _northCtrl = TextEditingController(text: '120');
  final _southCtrl = TextEditingController(text: '110');
  final _eastCtrl = TextEditingController(text: '80');
  final _westCtrl = TextEditingController(text: '85');
  final _diagCtrl = TextEditingController(text: '145');

  int _divisionParts = 2; // Split into 2 shares
  QuadrilateralResult? _result;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _northCtrl.dispose();
    _southCtrl.dispose();
    _eastCtrl.dispose();
    _westCtrl.dispose();
    _diagCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final n = double.tryParse(_northCtrl.text) ?? 0;
    final s = double.tryParse(_southCtrl.text) ?? 0;
    final e = double.tryParse(_eastCtrl.text) ?? 0;
    final w = double.tryParse(_westCtrl.text) ?? 0;
    final d = double.tryParse(_diagCtrl.text) ?? 0;

    if (n > 0 && s > 0 && e > 0 && w > 0 && d > 0) {
      setState(() {
        _result = GeometryCalculator.calculateQuadrilateral(
          north: n,
          east: e,
          south: s,
          west: w,
          diagonal: d,
        );
      });
    }
  }

  String _generateReport() {
    if (_result == null) return '';
    final r = _result!;
    final perPersonDec = r.exactAreaDecimal / _divisionParts;
    final perPersonSqFt = r.exactAreaSqFt / _divisionParts;

    final buffer = StringBuffer();
    buffer.writeln('=== QuadMaster চতুর্ভুজ পরিমাপ ও বণ্টন রিপোর্ট ===');
    buffer.writeln('তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}');
    buffer.writeln('বাহুসমূহ: উত্তর: ${r.sideNorth}\', দক্ষিণ: ${r.sideSouth}\', পূর্ব: ${r.sideEast}\', পশ্চিম: ${r.sideWest}\', কর্ণ: ${r.diagonal}\'');
    buffer.writeln('[হেরন্স ফর্মুলায় প্রকৃত ক্ষেত্রফল]');
    buffer.writeln('মোট শতাংশ: ${BanglaFormatter.formatNumber(r.exactAreaDecimal, fractionDigits: 3)} শতক');
    buffer.writeln('মোট কাঠা: ${BanglaFormatter.formatNumber(r.exactAreaKatha, fractionDigits: 3)} কাঠা');
    buffer.writeln('মোট বর্গফুট: ${BanglaFormatter.formatNumber(r.exactAreaSqFt)} ft²');
    buffer.writeln('\n[আমিনের গড় পদ্ধতির সাথে তুলনা]');
    buffer.writeln('গড় পদ্ধতিতে ক্ষেত্রফল: ${BanglaFormatter.formatNumber(r.averageAreaDecimal, fractionDigits: 3)} শতক');
    buffer.writeln('পার্থক্য / ত্রুটি: ${BanglaFormatter.formatNumber(r.diffDecimal.abs(), fractionDigits: 3)} শতক (${BanglaFormatter.formatPercentage(r.percentageError)})');
    buffer.writeln('\n[সমান ${_divisionParts} ভাগে বণ্টন]');
    buffer.writeln('জনপ্রতি জমির পরিমাণ: ${BanglaFormatter.formatNumber(perPersonDec, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(perPersonSqFt)} ft²)');
    buffer.writeln('জনপ্রতি কাঠা: ${BanglaFormatter.formatNumber(perPersonSqFt / 720.0, fractionDigits: 3)} কাঠা');
    buffer.writeln('\nঅ্যাপ: BDLandPro - পেশাদার বাংলাদেশ ভূমি জরিপ');
    return buffer.toString();
  }

  void _copyReport() {
    Clipboard.setData(ClipboardData(text: _generateReport()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QuadMaster রিপোর্ট কপি করা হয়েছে!'), backgroundColor: AppColors.primaryGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('চতুর্ভুজ পরিমাপ ও বণ্টন (QuadMaster)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'কপি রিপোর্ট',
            onPressed: r != null && r.isValid ? _copyReport : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Visual Diagram
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: QuadrilateralPainter(
                      north: double.tryParse(_northCtrl.text) ?? 0,
                      east: double.tryParse(_eastCtrl.text) ?? 0,
                      south: double.tryParse(_southCtrl.text) ?? 0,
                      west: double.tryParse(_westCtrl.text) ?? 0,
                      diagonal: double.tryParse(_diagCtrl.text) ?? 0,
                      isValid: r?.isValid ?? true,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Input Fields
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildInput(_northCtrl, 'উত্তর বাহু (ফুট)')),
                        const SizedBox(width: 10),
                        Expanded(child: _buildInput(_southCtrl, 'দক্ষিণ বাহু (ফুট)')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildInput(_eastCtrl, 'পূর্ব বাহু (ফুট)')),
                        const SizedBox(width: 10),
                        Expanded(child: _buildInput(_westCtrl, 'পশ্চিম বাহু (ফুট)')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildInput(_diagCtrl, 'কর্ণের দৈর্ঘ্য (ফুট)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Results & Partition
            if (r != null && r.isValid) ...[
              Card(
                color: AppColors.primaryGreenLight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('মোট প্রকৃত জমি:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('${BanglaFormatter.formatNumber(r.exactAreaDecimal, fractionDigits: 3)} শতক',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primaryGreenDark)),
                        ],
                      ),
                      const Divider(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('কাঠা: ${BanglaFormatter.formatNumber(r.exactAreaKatha, fractionDigits: 3)} কাঠা'),
                          Text('বর্গফুট: ${BanglaFormatter.formatNumber(r.exactAreaSqFt)} ft²'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Division Share Selector Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('অংশীদারদের মাঝে সমান বণ্টন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('অংশীদার সংখ্যা:'),
                          DropdownButton<int>(
                            value: _divisionParts,
                            items: [2, 3, 4, 5, 6].map((count) {
                              return DropdownMenuItem(value: count, child: Text('${BanglaNumerals.toBangla(count)} জন সমান ভাগ'));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _divisionParts = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryGoldLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.secondaryGold),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('জনপ্রতি প্রাপ্ত জমি:'),
                            Text(
                              '${BanglaFormatter.formatNumber(r.exactAreaDecimal / _divisionParts, fractionDigits: 3)} শতক',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.secondaryGoldDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, isDense: true),
      onChanged: (_) => _calculate(),
    );
  }
}
