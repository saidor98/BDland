import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/services/history_service.dart';
import '../../history/models/calculation_history_item.dart';
import '../models/mouza_scale.dart';
import '../services/mouza_scale_service.dart';

class MouzaScaleScreen extends StatefulWidget {
  const MouzaScaleScreen({super.key});

  @override
  State<MouzaScaleScreen> createState() => _MouzaScaleScreenState();
}

class _MouzaScaleScreenState extends State<MouzaScaleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  MouzaScaleRatio _selectedRatio = MouzaScaleRatio.scale16;
  String _inputUnit = 'links'; // 'links', 'inches', 'mm'
  final _readingController = TextEditingController(text: '100'); // 100 links

  // Plot Area inputs
  final _mapLengthController = TextEditingController(text: '150');
  final _mapWidthController = TextEditingController(text: '80');

  GroundDistanceResult? _distanceResult;
  GroundAreaResult? _areaResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _calculateDistance();
    _calculateArea();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _readingController.dispose();
    _mapLengthController.dispose();
    _mapWidthController.dispose();
    super.dispose();
  }

  void _calculateDistance() {
    final reading = double.tryParse(_readingController.text) ?? 0.0;
    if (reading > 0) {
      setState(() {
        _distanceResult = MouzaScaleService.calculateDistance(
          mapReading: reading,
          ratio: _selectedRatio,
          inputUnit: _inputUnit,
        );
      });
    }
  }

  void _calculateArea() {
    final len = double.tryParse(_mapLengthController.text) ?? 0.0;
    final wid = double.tryParse(_mapWidthController.text) ?? 0.0;
    if (len > 0 && wid > 0) {
      setState(() {
        _areaResult = MouzaScaleService.calculatePlotArea(
          mapLengthLinks: len,
          mapWidthLinks: wid,
          ratio: _selectedRatio,
        );
      });
    }
  }

  String _generateReport() {
    final info = MouzaScaleInfo.getByRatio(_selectedRatio);
    final buffer = StringBuffer();
    buffer.writeln('=== মৌজা ম্যাপ স্কেল পরিমাপ রিপোর্ট ===');
    buffer.writeln('তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}');
    buffer.writeln('ব্যবহৃত স্কেল: ${info.titleBangla}');
    buffer.writeln('${info.descriptionBangla}\n');

    if (_tabController.index == 0 && _distanceResult != null) {
      final d = _distanceResult!;
      buffer.writeln('[ভূমির বাস্তব দূরত্ব]');
      buffer.writeln('নকশার পাঠ: ${_readingController.text} ${_inputUnit == "links" ? "লিংক (গুনিয়া)" : _inputUnit == "inches" ? "ইঞ্চি" : "মিমি"}');
      buffer.writeln('বাস্তব দূরত্ব (ফুট): ${BanglaFormatter.formatNumber(d.groundFeet)} ফুট');
      buffer.writeln('বাস্তব দূরত্ব (মিটার): ${BanglaFormatter.formatNumber(d.groundMeters)} মিটার');
      buffer.writeln('গান্টার্স লিংক: ${BanglaFormatter.formatNumber(d.groundLinks)} লিংক');
      buffer.writeln('চেইন: ${BanglaFormatter.formatNumber(d.groundChains, fractionDigits: 3)} চেইন');
      buffer.writeln('হাত: ${BanglaFormatter.formatNumber(d.groundHath)} হাত');
    } else if (_areaResult != null) {
      final a = _areaResult!;
      buffer.writeln('[নকশা থেকে বাস্তব প্লটের ক্ষেত্রফল]');
      buffer.writeln('নকশায় দৈর্ঘ্য: ${_mapLengthController.text} লিংক (বাস্তবে ${BanglaFormatter.formatNumber(a.lengthFeet)} ফুট)');
      buffer.writeln('নকশায় প্রস্থ: ${_mapWidthController.text} লিংক (বাস্তবে ${BanglaFormatter.formatNumber(a.widthFeet)} ফুট)');
      buffer.writeln('মোট শতাংশ: ${BanglaFormatter.formatNumber(a.groundAreaDecimal, fractionDigits: 3)} শতক');
      buffer.writeln('মোট কাঠা: ${BanglaFormatter.formatNumber(a.groundAreaKatha, fractionDigits: 3)} কাঠা');
      buffer.writeln('মোট বর্গফুট: ${BanglaFormatter.formatNumber(a.groundAreaSqFt)} বর্গফুট');
      buffer.writeln('বিস্তারিত: ${BanglaFormatter.formatLandBreakdown(a.groundAreaSqFt)}');
    }

    buffer.writeln('\nঅ্যাপ: BDLandPro (বাংলাদেশ ভূমি জরিপ ও পরিমাপ)');
    return buffer.toString();
  }

  void _copyReport() {
    final report = _generateReport();
    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('মৌজা স্কেল রিপোর্ট কপি করা হয়েছে!'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  Future<void> _saveToHistory() async {
    final info = MouzaScaleInfo.getByRatio(_selectedRatio);
    final isDistance = _tabController.index == 0;

    final item = CalculationHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: isDistance
          ? 'মৌজা দূরত্ব: ${_readingController.text} $_inputUnit = ${BanglaFormatter.formatNumber(_distanceResult?.groundFeet ?? 0)} ফুট'
          : 'মৌজা প্লট: ${BanglaFormatter.formatNumber(_areaResult?.groundAreaDecimal ?? 0, fractionDigits: 2)} শতক',
      category: 'মৌজা স্কেল',
      timestamp: DateTime.now(),
      inputSummary: 'স্কেল: ${info.titleBangla}',
      resultSummary: isDistance
          ? '${BanglaFormatter.formatNumber(_distanceResult?.groundFeet ?? 0)} ফুট (${BanglaFormatter.formatNumber(_distanceResult?.groundMeters ?? 0)} মিটার)'
          : '${BanglaFormatter.formatNumber(_areaResult?.groundAreaDecimal ?? 0, fractionDigits: 3)} শতক',
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
        title: const Text('মৌজা ম্যাপ স্কেল ক্যালকুলেটর'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondaryGold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'নকশা থেকে ভূমির দূরত্ব'),
            Tab(text: 'নকশা থেকে প্লট ক্ষেত্রফল'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'কপি',
            onPressed: _copyReport,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'সেভ',
            onPressed: _saveToHistory,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDistanceTab(),
          _buildAreaTab(),
        ],
      ),
    );
  }

  Widget _buildScaleSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'মৌজা নকশার স্কেল নির্বাচন করুন (Scale)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<MouzaScaleRatio>(
              value: _selectedRatio,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.map, color: AppColors.primaryGreen),
              ),
              items: MouzaScaleInfo.scales.map((s) {
                return DropdownMenuItem(
                  value: s.ratio,
                  child: Text(s.titleBangla, style: const TextStyle(fontWeight: FontWeight.w600)),
                );
              }).toList(),
              onChanged: (ratio) {
                if (ratio != null) {
                  setState(() {
                    _selectedRatio = ratio;
                    _calculateDistance();
                    _calculateArea();
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              MouzaScaleInfo.getByRatio(_selectedRatio).descriptionBangla,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScaleSelector(),
          const SizedBox(height: 14),

          // Map Reading Input Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'নকশায় পরিমাপকৃত পাঠ ইনপুট দিন',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('গুনিয়া লিংক (Links)'),
                        selected: _inputUnit == 'links',
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _inputUnit = 'links';
                              _calculateDistance();
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('ইঞ্চি (Inches)'),
                        selected: _inputUnit == 'inches',
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _inputUnit = 'inches';
                              _calculateDistance();
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('মিমি (MM)'),
                        selected: _inputUnit == 'mm',
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _inputUnit = 'mm';
                              _calculateDistance();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _readingController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _inputUnit == 'links'
                          ? 'গুনিয়া স্কেলের দাগ/লিংক সংখ্যা'
                          : _inputUnit == 'inches'
                              ? 'স্কেলের ইঞ্চি মাপ'
                              : 'মিলিমিটার মাপ',
                      prefixIcon: const Icon(Icons.straighten, color: AppColors.secondaryGoldDark),
                    ),
                    onChanged: (_) => _calculateDistance(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Ground Distance Results
          if (_distanceResult != null)
            Card(
              color: AppColors.primaryGreenLight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'জমিতে বা ভূমিতে বাস্তব দূরত্ব',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreenDark,
                      ),
                    ),
                    const Divider(height: 18),
                    _buildResultRow('বাস্তব দৈর্ঘ্য (ফুট)',
                        '${BanglaFormatter.formatNumber(_distanceResult!.groundFeet)} ফুট',
                        isHighlight: true),
                    _buildResultRow('বাস্তব দৈর্ঘ্য (মিটার)',
                        '${BanglaFormatter.formatNumber(_distanceResult!.groundMeters)} মিটার'),
                    _buildResultRow('গান্টার্স লিংক (Links)',
                        '${BanglaFormatter.formatNumber(_distanceResult!.groundLinks)} লিংক'),
                    _buildResultRow('চেইন (Chains)',
                        '${BanglaFormatter.formatNumber(_distanceResult!.groundChains, fractionDigits: 3)} চেইন'),
                    _buildResultRow('হাত (Hath - ১৮ ইঞ্চি)',
                        '${BanglaFormatter.formatNumber(_distanceResult!.groundHath)} হাত'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),

          // Survey Reference Card
          Card(
            color: AppColors.secondaryGoldLight,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'গুনিয়া স্কেল পরিচিতি ও ব্যবহার বিধি:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondaryGoldDark),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• গুনিয়া স্কেলের মোট দৈর্ঘ্য ২ ইঞ্চি এবং এতে ১০টি বড় দাগ থাকে।\n'
                    '• ১৬" = ১ মাইল স্কেলে গুনিয়ার প্রতিটি বড় দাগ = ১০০ লিংক (১ চেইন = ৬৬ ফুট)।\n'
                    '• ছোট দাগগুলোর এক পিঠে প্রতি দাগ = ১০ লিংক (৬.৬ ফুট) এবং অপর পিঠে ২০ লিংক (১৩.২ ফুট)।',
                    style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScaleSelector(),
          const SizedBox(height: 14),

          // Plot Dimensions Input Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'নকশা থেকে নেওয়া দাগের দৈর্ঘ্য ও প্রস্থ (লিংক এককে)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _mapLengthController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'নকশায় দৈর্ঘ্য (লিংক)'),
                          onChanged: (_) => _calculateArea(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _mapWidthController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'নকশায় প্রস্থ (লিংক)'),
                          onChanged: (_) => _calculateArea(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Ground Area Results
          if (_areaResult != null)
            Card(
              color: AppColors.primaryGreenLight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'ভূমির বাস্তব ক্ষেত্রফল ও জমির পরিমাণ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreenDark,
                      ),
                    ),
                    const Divider(height: 18),
                    _buildResultRow('মোট শতাংশ (শতক)',
                        '${BanglaFormatter.formatNumber(_areaResult!.groundAreaDecimal, fractionDigits: 3)} শতক',
                        isHighlight: true),
                    _buildResultRow('মোট কাঠা',
                        '${BanglaFormatter.formatNumber(_areaResult!.groundAreaKatha, fractionDigits: 3)} কাঠা'),
                    _buildResultRow('মোট বর্গফুট',
                        '${BanglaFormatter.formatNumber(_areaResult!.groundAreaSqFt)} বর্গফুট'),
                    _buildResultRow('বাস্তব দৈর্ঘ্য ও প্রস্থ',
                        '${BanglaFormatter.formatNumber(_areaResult!.lengthFeet)}\' × ${BanglaFormatter.formatNumber(_areaResult!.widthFeet)}\' ফুট'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'বিস্তারিত: ${BanglaFormatter.formatLandBreakdown(_areaResult!.groundAreaSqFt)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
