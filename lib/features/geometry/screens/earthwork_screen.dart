import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/services/history_service.dart';
import '../../history/models/calculation_history_item.dart';
import '../models/geometry_models.dart';
import '../painters/geometry_painters.dart';
import '../services/geometry_calculator.dart';

class EarthworkScreen extends StatefulWidget {
  const EarthworkScreen({super.key});

  @override
  State<EarthworkScreen> createState() => _EarthworkScreenState();
}

class _EarthworkScreenState extends State<EarthworkScreen> {
  final _topLengthController = TextEditingController(text: '120');
  final _topWidthController = TextEditingController(text: '80');
  final _depthController = TextEditingController(text: '8');
  final _slopeController = TextEditingController(text: '1.5');
  final _rateController = TextEditingController(text: '800'); // Rate per 100 cft

  EarthworkResult? _result;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _topLengthController.dispose();
    _topWidthController.dispose();
    _depthController.dispose();
    _slopeController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _calculate() {
    final tLen = double.tryParse(_topLengthController.text) ?? 0.0;
    final tWid = double.tryParse(_topWidthController.text) ?? 0.0;
    final depth = double.tryParse(_depthController.text) ?? 0.0;
    final slope = double.tryParse(_slopeController.text) ?? 1.5;
    final rate = double.tryParse(_rateController.text) ?? 0.0;

    if (tLen > 0 && tWid > 0 && depth > 0) {
      setState(() {
        _result = GeometryCalculator.calculateEarthwork(
          topLength: tLen,
          topWidth: tWid,
          depth: depth,
          sideSlopeRatio: slope,
          ratePer100Cft: rate,
        );
      });
    }
  }

  String _generateReport() {
    if (_result == null) return '';
    final r = _result!;
    return '''
=== পুকুর / খাল / মাটি খনন ও ভরাট হিসাব ===
তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}

[পরিমাপের ইনপুট]
উপরের দৈর্ঘ্য: ${BanglaFormatter.formatNumber(r.topLength)} ফুট
উপরের প্রস্থ: ${BanglaFormatter.formatNumber(r.topWidth)} ফুট
গভীরতা: ${BanglaFormatter.formatNumber(r.depth)} ফুট
পার্শ্ব ঢাল (Side Slope): ১:${BanglaFormatter.formatNumber(r.sideSlopeRatio)}
তলার দৈর্ঘ্য: ${BanglaFormatter.formatNumber(r.bottomLength)} ফুট
তলার প্রস্থ: ${BanglaFormatter.formatNumber(r.bottomWidth)} ফুট

[মাটির পরিমাণ (Volume)]
মোট মাটির আয়তন: ${BanglaFormatter.formatNumber(r.volumeCFT)} সেফটি (CFT / ঘনফুট)
ঘনমিটার: ${BanglaFormatter.formatNumber(r.volumeCubicMeter)} m³
উপরের জমির ক্ষেত্রফল: ${BanglaFormatter.formatNumber(r.topSurfaceAreaSqFt / 435.6, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(r.topSurfaceAreaSqFt)} বর্গফুট)

[খরচের প্রাক্কলন]
প্রতি ১০০ সেফটি দর: ৳ ${BanglaFormatter.formatNumber(double.tryParse(_rateController.text) ?? 0)}
সর্বমোট আনুমানিক খনন খরচ: ${BanglaFormatter.formatCurrency(r.estimatedCostTaka)}

অ্যাপ: BDLandPro (বাংলাদেশ ভূমি জরিপ ও পরিমাপ)
''';
  }

  void _copyReport() {
    final report = _generateReport();
    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('মাটি খননের রিপোর্ট কপি করা হয়েছে!'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  Future<void> _saveToHistory() async {
    if (_result == null) return;
    final r = _result!;
    final item = CalculationHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'মাটি খনন/ভরাট (${BanglaFormatter.formatNumber(r.volumeCFT)} CFT)',
      category: 'জ্যামিতি',
      timestamp: DateTime.now(),
      inputSummary: 'উপরের বিস্তার: ${r.topLength}\' × ${r.topWidth}\', গভীরতা: ${r.depth}\'',
      resultSummary: '${BanglaFormatter.formatNumber(r.volumeCFT)} সেফটি (খরচ: ${BanglaFormatter.formatCurrency(r.estimatedCostTaka)})',
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
        title: const Text('পুকুর/রাস্তা/মাটি খনন পরিমাপ'),
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
                    painter: EarthworkCrossSectionPainter(
                      topLength: double.tryParse(_topLengthController.text) ?? 0,
                      topWidth: double.tryParse(_topWidthController.text) ?? 0,
                      bottomWidth: _result?.bottomWidth ?? 0,
                      depth: double.tryParse(_depthController.text) ?? 0,
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _topLengthController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'উপরের দৈর্ঘ্য (ফুট)'),
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _topWidthController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'উপরের প্রস্থ (ফুট)'),
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _depthController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'গভীরতা (ফুট)'),
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _slopeController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'পার্শ্ব ঢাল (যেমন ১:১.৫)'),
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _rateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'প্রতি ১০০ সেফটি (CFT) মাটি কাটার খরচ (টাকা)',
                        prefixIcon: Icon(Icons.currency_lira, color: AppColors.secondaryGoldDark),
                      ),
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
                      _buildResultRow(
                        'মোট মাটির পরিমাণ (CFT / সেফটি)',
                        '${BanglaFormatter.formatNumber(_result!.volumeCFT)} সেফটি',
                        isHighlight: true,
                      ),
                      _buildResultRow(
                        'ঘনমিটার (Cubic Meter)',
                        '${BanglaFormatter.formatNumber(_result!.volumeCubicMeter)} m³',
                      ),
                      _buildResultRow(
                        'উপরের মোট জমির পরিমাণ',
                        '${BanglaFormatter.formatNumber(_result!.topSurfaceAreaSqFt / 435.6, fractionDigits: 3)} শতক',
                      ),
                      _buildResultRow(
                        'তলার দৈর্ঘ্য × প্রস্থ',
                        '${BanglaFormatter.formatNumber(_result!.bottomLength)}\' × ${BanglaFormatter.formatNumber(_result!.bottomWidth)}\' ফুট',
                      ),
                      const Divider(height: 20),
                      _buildResultRow(
                        'আনুমানিক খনন খরচ',
                        BanglaFormatter.formatCurrency(_result!.estimatedCostTaka),
                        isHighlight: true,
                        textColor: AppColors.primaryGreenDark,
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

  Widget _buildResultRow(String label, String value,
      {bool isHighlight = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isHighlight ? 16 : 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlight ? 17 : 14,
              fontWeight: FontWeight.bold,
              color: textColor ?? (isHighlight ? AppColors.primaryGreenDark : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
