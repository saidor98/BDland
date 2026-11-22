import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/services/history_service.dart';
import '../../history/models/calculation_history_item.dart';
import '../models/geometry_models.dart';
import '../painters/geometry_painters.dart';
import '../services/geometry_calculator.dart';

class TriangleScreen extends StatefulWidget {
  const TriangleScreen({super.key});

  @override
  State<TriangleScreen> createState() => _TriangleScreenState();
}

class _TriangleScreenState extends State<TriangleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Heron 3 sides
  final _sideAController = TextEditingController(text: '60');
  final _sideBController = TextEditingController(text: '80');
  final _sideCController = TextEditingController(text: '100');

  // Base & Height
  final _baseController = TextEditingController(text: '80');
  final _heightController = TextEditingController(text: '60');

  TriangleResult? _heronResult;
  TriangleResult? _baseHeightResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _calculateHeron();
    _calculateBaseHeight();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sideAController.dispose();
    _sideBController.dispose();
    _sideCController.dispose();
    _baseController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _calculateHeron() {
    final a = double.tryParse(_sideAController.text) ?? 0.0;
    final b = double.tryParse(_sideBController.text) ?? 0.0;
    final c = double.tryParse(_sideCController.text) ?? 0.0;

    if (a > 0 && b > 0 && c > 0) {
      setState(() {
        _heronResult = GeometryCalculator.calculateTriangleHeron(a: a, b: b, c: c);
      });
    }
  }

  void _calculateBaseHeight() {
    final base = double.tryParse(_baseController.text) ?? 0.0;
    final height = double.tryParse(_heightController.text) ?? 0.0;

    if (base > 0 && height > 0) {
      setState(() {
        _baseHeightResult = GeometryCalculator.calculateTriangleBaseHeight(
          base: base,
          height: height,
        );
      });
    }
  }

  TriangleResult? get _currentResult =>
      _tabController.index == 0 ? _heronResult : _baseHeightResult;

  String _generateReport() {
    final r = _currentResult;
    if (r == null || !r.isValid) return '';

    return '''
=== ত্রিভুজাকার জমি পরিমাপ রিপোর্ট ===
তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}
পদ্ধতি: ${r.isHeron ? "হেরন্স ফর্মুলা (৩ বাহু)" : "ভূমি ও উচ্চতা"}

${r.isHeron ? """[বাহুসমূহের মাপ]
বাহু ১: ${BanglaFormatter.formatNumber(r.sideA)} ফুট
বাহু ২: ${BanglaFormatter.formatNumber(r.sideB)} ফুট
বাহু ৩: ${BanglaFormatter.formatNumber(r.sideC)} ফুট
পরিসীমা: ${BanglaFormatter.formatNumber(r.perimeter)} ফুট""" : """[ভূমি ও উচ্চতা]
ভূমি: ${BanglaFormatter.formatNumber(r.base ?? 0)} ফুট
উচ্চতা: ${BanglaFormatter.formatNumber(r.height ?? 0)} ফুট"""}

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
        content: Text('ত্রিভুজের বাংলা রিপোর্ট কপি করা হয়েছে!'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  Future<void> _saveToHistory() async {
    final r = _currentResult;
    if (r == null || !r.isValid) return;

    final item = CalculationHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'ত্রিভুজ জমি (${BanglaFormatter.formatNumber(r.areaDecimal, fractionDigits: 2)} শতক)',
      category: 'জ্যামিতি',
      timestamp: DateTime.now(),
      inputSummary: r.isHeron
          ? 'বাহু: ${r.sideA}\', ${r.sideB}\', ${r.sideC}\''
          : 'ভূমি: ${r.base}\', উচ্চতা: ${r.height}\'',
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
        title: const Text('ত্রিভুজাকার জমি পরিমাপ'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondaryGold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '৩ বাহু (হেরন্স ফর্মুলা)'),
            Tab(text: 'ভূমি ও লম্ব উচ্চতা'),
          ],
          onTap: (_) => setState(() {}),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'কপি রিপোর্ট',
            onPressed: _currentResult != null ? _copyReport : null,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'সেভ',
            onPressed: _currentResult != null ? _saveToHistory : null,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHeronTab(),
          _buildBaseHeightTab(),
        ],
      ),
    );
  }

  Widget _buildHeronTab() {
    return SingleChildScrollView(
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
                  painter: TrianglePainter(
                    sideA: double.tryParse(_sideAController.text) ?? 0,
                    sideB: double.tryParse(_sideBController.text) ?? 0,
                    sideC: double.tryParse(_sideCController.text) ?? 0,
                    isHeron: true,
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
                    controller: _sideAController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: '১ম বাহু (ফুট)'),
                    onChanged: (_) => _calculateHeron(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _sideBController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: '২য় বাহু (ফুট)'),
                    onChanged: (_) => _calculateHeron(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _sideCController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: '৩য় বাহু (ফুট)'),
                    onChanged: (_) => _calculateHeron(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _calculateHeron,
                    icon: const Icon(Icons.calculate),
                    label: const Text('হিসাব করুন'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_heronResult != null) _buildResultDisplay(_heronResult!),
        ],
      ),
    );
  }

  Widget _buildBaseHeightTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _baseController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'ভূমি (Base - ফুট)'),
                    onChanged: (_) => _calculateBaseHeight(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'উচ্চতা (Height - ফুট)'),
                    onChanged: (_) => _calculateBaseHeight(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _calculateBaseHeight,
                    icon: const Icon(Icons.calculate),
                    label: const Text('হিসাব করুন'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_baseHeightResult != null) _buildResultDisplay(_baseHeightResult!),
        ],
      ),
    );
  }

  Widget _buildResultDisplay(TriangleResult r) {
    if (!r.isValid) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            r.messageBangla,
            style: const TextStyle(color: AppColors.accentCrimson),
          ),
        ),
      );
    }

    return Card(
      color: AppColors.primaryGreenLight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildResultRow('মোট শতাংশ (শতক)',
                '${BanglaFormatter.formatNumber(r.areaDecimal, fractionDigits: 3)} শতক',
                isHighlight: true),
            _buildResultRow('মোট কাঠা',
                '${BanglaFormatter.formatNumber(r.areaKatha, fractionDigits: 3)} কাঠা'),
            _buildResultRow('মোট বর্গফুট',
                '${BanglaFormatter.formatNumber(r.areaSqFt)} বর্গফুট'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'বিস্তারিত: ${BanglaFormatter.formatLandBreakdown(r.areaSqFt)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
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
