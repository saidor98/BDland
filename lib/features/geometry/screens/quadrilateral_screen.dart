import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/services/history_service.dart';
import '../../history/models/calculation_history_item.dart';
import '../models/geometry_models.dart';
import '../painters/geometry_painters.dart';
import '../services/geometry_calculator.dart';

class QuadrilateralScreen extends StatefulWidget {
  const QuadrilateralScreen({super.key});

  @override
  State<QuadrilateralScreen> createState() => _QuadrilateralScreenState();
}

class _QuadrilateralScreenState extends State<QuadrilateralScreen> {
  final _formKey = GlobalKey<FormState>();

  final _northController = TextEditingController(text: '120');
  final _eastController = TextEditingController(text: '80');
  final _southController = TextEditingController(text: '110');
  final _westController = TextEditingController(text: '85');
  final _diagonalController = TextEditingController(text: '145');

  QuadrilateralResult? _result;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _northController.dispose();
    _eastController.dispose();
    _southController.dispose();
    _westController.dispose();
    _diagonalController.dispose();
    super.dispose();
  }

  void _calculate() {
    final north = double.tryParse(_northController.text) ?? 0.0;
    final east = double.tryParse(_eastController.text) ?? 0.0;
    final south = double.tryParse(_southController.text) ?? 0.0;
    final west = double.tryParse(_westController.text) ?? 0.0;
    final diagonal = double.tryParse(_diagonalController.text) ?? 0.0;

    if (north > 0 && east > 0 && south > 0 && west > 0 && diagonal > 0) {
      setState(() {
        _result = GeometryCalculator.calculateQuadrilateral(
          north: north,
          east: east,
          south: south,
          west: west,
          diagonal: diagonal,
        );
      });
    }
  }

  String _generateReport() {
    if (_result == null) return '';
    final r = _result!;
    return '''
=== জমি পরিমাপ রিপোর্ট (অনিয়মিত চতুর্ভুজ) ===
তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}

[বাহুর মাপ]
উত্তর (North): ${BanglaFormatter.formatNumber(r.sideNorth)} ফুট
পূর্ব (East): ${BanglaFormatter.formatNumber(r.sideEast)} ফুট
দক্ষিণ (South): ${BanglaFormatter.formatNumber(r.sideSouth)} ফুট
পশ্চিম (West): ${BanglaFormatter.formatNumber(r.sideWest)} ফুট
কর্ণ (Diagonal): ${BanglaFormatter.formatNumber(r.diagonal)} ফুট

[হেরন্স ফর্মুলায় নিখুঁত পরিমাপ]
মোট ক্ষেত্রফল: ${BanglaFormatter.formatNumber(r.exactAreaSqFt)} বর্গফুট
মোট শতাংশ: ${BanglaFormatter.formatNumber(r.exactAreaDecimal, fractionDigits: 3)} শতক
মোট কাঠা: ${BanglaFormatter.formatNumber(r.exactAreaKatha, fractionDigits: 3)} কাঠা
বিস্তারিত হিসাব: ${BanglaFormatter.formatLandBreakdown(r.exactAreaSqFt)}

[ঐতিহ্যবাহী আমিনের গড় পদ্ধতি তুলনা]
গড় পদ্ধতিতে ক্ষেত্রফল: ${BanglaFormatter.formatNumber(r.averageAreaSqFt)} বর্গফুট (${BanglaFormatter.formatNumber(r.averageAreaDecimal, fractionDigits: 3)} শতক)
পার্থক্য/ত্রুটি: ${BanglaFormatter.formatNumber(r.diffSqFt.abs())} বর্গফুট (${BanglaFormatter.formatNumber(r.diffDecimal.abs(), fractionDigits: 3)} শতক)
শতকরা ব্যবধান: ${BanglaFormatter.formatPercentage(r.percentageError)}
মন্তব্য: ${r.messageBangla}

অ্যাপ: BDLandPro (বাংলাদেশ ভূমি জরিপ ও পরিমাপ)
''';
  }

  void _copyReport() {
    final report = _generateReport();
    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('সম্পূর্ণ বাংলা রিপোর্ট ক্লিপবোর্ডে কপি করা হয়েছে!'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  Future<void> _saveToHistory() async {
    if (_result == null || !_result!.isValid) return;
    final r = _result!;
    final item = CalculationHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'চতুর্ভুজ পরিমাপ (${BanglaFormatter.formatNumber(r.exactAreaDecimal, fractionDigits: 2)} শতক)',
      category: 'জ্যামিতি',
      timestamp: DateTime.now(),
      inputSummary: 'উ: ${r.sideNorth}\', পূ: ${r.sideEast}\', দ: ${r.sideSouth}\', প: ${r.sideWest}\', কর্ণ: ${r.diagonal}\'',
      resultSummary: '${BanglaFormatter.formatNumber(r.exactAreaDecimal, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(r.exactAreaSqFt)} বর্গফুট)',
      fullReportBangla: _generateReport(),
    );
    await HistoryService.instance.saveItem(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('হিস্ট্রিতে সফলভাবে সংরক্ষিত হয়েছে!'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('অনিয়মিত চতুর্ভুজ পরিমাপ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'রিপোর্ট কপি',
            onPressed: _result != null ? _copyReport : null,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'হিস্ট্রিতে সেভ',
            onPressed: _result != null ? _saveToHistory : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Visual Painter Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      const Text(
                        'জ্যামিতিক নকশা ও কর্ণ বিভাজন',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: QuadrilateralPainter(
                            north: double.tryParse(_northController.text) ?? 0,
                            east: double.tryParse(_eastController.text) ?? 0,
                            south: double.tryParse(_southController.text) ?? 0,
                            west: double.tryParse(_westController.text) ?? 0,
                            diagonal: double.tryParse(_diagonalController.text) ?? 0,
                            isValid: _result?.isValid ?? true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Input Form Fields
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'জমির ৪ বাহু ও কর্ণের মাপ (ফুটে)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              controller: _northController,
                              label: 'উত্তর বাহু (ফুট)',
                              icon: Icons.north,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInputField(
                              controller: _southController,
                              label: 'দক্ষিণ বাহু (ফুট)',
                              icon: Icons.south,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              controller: _eastController,
                              label: 'পূর্ব বাহু (ফুট)',
                              icon: Icons.east,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInputField(
                              controller: _westController,
                              label: 'পশ্চিম বাহু (ফুট)',
                              icon: Icons.west,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(
                        controller: _diagonalController,
                        label: 'কর্ণের দৈর্ঘ্য (ফুট)',
                        icon: Icons.architecture,
                        helperText: 'যেকোনো এক কোণা থেকে বিপরীত কোণার সরাসরি মাপ',
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

              // Results Section
              if (_result != null) ...[
                if (!_result!.isValid)
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.accentCrimson),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _result!.messageBangla,
                              style: const TextStyle(color: AppColors.accentCrimson),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // Primary Exact Result Card
                  Card(
                    color: AppColors.primaryGreenLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.verified, color: AppColors.primaryGreen),
                              SizedBox(width: 8),
                              Text(
                                'হেরন্স ফর্মুলায় প্রকৃত ক্ষেত্রফল',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreenDark,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _buildResultRow('মোট শতাংশ (শতক)',
                              '${BanglaFormatter.formatNumber(_result!.exactAreaDecimal, fractionDigits: 3)} শতক',
                              isHighlight: true),
                          _buildResultRow('মোট কাঠা',
                              '${BanglaFormatter.formatNumber(_result!.exactAreaKatha, fractionDigits: 3)} কাঠা'),
                          _buildResultRow('বর্গফুট',
                              '${BanglaFormatter.formatNumber(_result!.exactAreaSqFt)} বর্গফুট'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'বিস্তারিত: ${BanglaFormatter.formatLandBreakdown(_result!.exactAreaSqFt)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amin Average Method Comparison Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.compare_arrows, color: AppColors.secondaryGoldDark),
                              SizedBox(width: 8),
                              Text(
                                'ঐতিহ্যবাহী আমিনের গড় পদ্ধতি তুলনা',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondaryGoldDark,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _buildResultRow('গড় পদ্ধতিতে শতক',
                              '${BanglaFormatter.formatNumber(_result!.averageAreaDecimal, fractionDigits: 3)} শতক'),
                          _buildResultRow('গড় পদ্ধতিতে বর্গফুট',
                              '${BanglaFormatter.formatNumber(_result!.averageAreaSqFt)} বর্গফুট'),
                          _buildResultRow('পার্থক্য / ব্যবধান',
                              '${BanglaFormatter.formatNumber(_result!.diffSqFt.abs())} বর্গফুট (${BanglaFormatter.formatNumber(_result!.diffDecimal.abs(), fractionDigits: 3)} শতক)',
                              textColor: AppColors.accentCrimson),
                          _buildResultRow('শতকরা ত্রুটি',
                              BanglaFormatter.formatPercentage(_result!.percentageError),
                              textColor: AppColors.accentOrange),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryGoldLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.secondaryGold),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, size: 20, color: AppColors.secondaryGoldDark),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _result!.messageBangla,
                                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.primaryGreen),
        helperText: helperText,
      ),
      onChanged: (_) => _calculate(),
    );
  }

  Widget _buildResultRow(String label, String value,
      {bool isHighlight = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHighlight ? 16 : 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
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
