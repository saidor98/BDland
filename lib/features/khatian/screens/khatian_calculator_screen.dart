import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/services/history_service.dart';
import '../../history/models/calculation_history_item.dart';
import '../models/ana_gonda_share.dart';
import '../models/khatian_owner.dart';
import '../services/khatian_service.dart';

class KhatianCalculatorScreen extends StatefulWidget {
  const KhatianCalculatorScreen({super.key});

  @override
  State<KhatianCalculatorScreen> createState() => _KhatianCalculatorScreenState();
}

class _KhatianCalculatorScreenState extends State<KhatianCalculatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1 Controllers
  final _anaController = TextEditingController(text: '4');
  final _gondaController = TextEditingController(text: '10');
  final _koraController = TextEditingController(text: '2');
  final _krantiController = TextEditingController(text: '1');
  final _tilController = TextEditingController(text: '15');
  final _totalLandForShareController = TextEditingController(text: '100');

  // Inverse conversion controller
  final _inverseDecimalController = TextEditingController(text: '28.125');
  AnaGondaShare? _inverseResultShare;

  // Tab 2: Multi-owner distribution
  final _dagTotalLandController = TextEditingController(text: '120');
  final List<KhatianOwner> _owners = [
    const KhatianOwner(
      id: '1',
      name: 'মো: রফিকুল ইসলাম',
      khatianNo: '১০১',
      share: AnaGondaShare(ana: 6, gonda: 8, kora: 0, kranti: 0, til: 0),
      allocatedDecimal: 0,
      allocatedKatha: 0,
      allocatedSqFt: 0,
      percentage: 0,
    ),
    const KhatianOwner(
      id: '2',
      name: 'মোছা: নাছিমা বেগম',
      khatianNo: '১০১',
      share: AnaGondaShare(ana: 5, gonda: 4, kora: 0, kranti: 0, til: 0),
      allocatedDecimal: 0,
      allocatedKatha: 0,
      allocatedSqFt: 0,
      percentage: 0,
    ),
    const KhatianOwner(
      id: '3',
      name: 'মো: তারেক রহমান',
      khatianNo: '১০২',
      share: AnaGondaShare(ana: 4, gonda: 8, kora: 0, kranti: 0, til: 0),
      allocatedDecimal: 0,
      allocatedKatha: 0,
      allocatedSqFt: 0,
      percentage: 0,
    ),
  ];

  KhatianDistributionResult? _distributionResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _calculateTab1();
    _calculateTab2();
    _calculateInverse();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _anaController.dispose();
    _gondaController.dispose();
    _koraController.dispose();
    _krantiController.dispose();
    _tilController.dispose();
    _totalLandForShareController.dispose();
    _inverseDecimalController.dispose();
    _dagTotalLandController.dispose();
    super.dispose();
  }

  AnaGondaShare get _currentTab1Share {
    final ana = int.tryParse(_anaController.text) ?? 0;
    final gonda = int.tryParse(_gondaController.text) ?? 0;
    final kora = int.tryParse(_koraController.text) ?? 0;
    final kranti = int.tryParse(_krantiController.text) ?? 0;
    final til = int.tryParse(_tilController.text) ?? 0;
    return AnaGondaShare(
      ana: ana,
      gonda: gonda,
      kora: kora,
      kranti: kranti,
      til: til,
    );
  }

  void _calculateTab1() {
    setState(() {});
  }

  void _calculateInverse() {
    final dec = double.tryParse(_inverseDecimalController.text) ?? 0.0;
    final total = double.tryParse(_totalLandForShareController.text) ?? 100.0;
    if (total > 0 && dec > 0) {
      final fraction = dec / total;
      setState(() {
        _inverseResultShare = AnaGondaShare.fromFraction(fraction);
      });
    }
  }

  void _calculateTab2() {
    final totalLand = double.tryParse(_dagTotalLandController.text) ?? 0.0;
    setState(() {
      _distributionResult = KhatianService.distributeLand(
        totalPlotDecimal: totalLand,
        rawOwners: _owners,
      );
    });
  }

  void _showAddOwnerDialog() {
    final nameCtrl = TextEditingController();
    final khatianCtrl = TextEditingController(text: '১০১');
    final anaCtrl = TextEditingController(text: '0');
    final gondaCtrl = TextEditingController(text: '0');
    final koraCtrl = TextEditingController(text: '0');
    final krantiCtrl = TextEditingController(text: '0');
    final tilCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('নতুন অংশীদার / মালিক যোগ করুন'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'মালিকের নাম'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: khatianCtrl,
                  decoration: const InputDecoration(labelText: 'খতিয়ান নং'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: anaCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'আনা'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: gondaCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'গণ্ডা'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: koraCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'কড়া'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: krantiCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'ক্রান্তি'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: tilCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'তিল'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim().isEmpty ? 'মালিক #${_owners.length + 1}' : nameCtrl.text.trim();
                final share = AnaGondaShare(
                  ana: int.tryParse(anaCtrl.text) ?? 0,
                  gonda: int.tryParse(gondaCtrl.text) ?? 0,
                  kora: int.tryParse(koraCtrl.text) ?? 0,
                  kranti: int.tryParse(krantiCtrl.text) ?? 0,
                  til: int.tryParse(tilCtrl.text) ?? 0,
                );

                setState(() {
                  _owners.add(KhatianOwner(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    khatianNo: khatianCtrl.text.trim(),
                    share: share,
                    allocatedDecimal: 0,
                    allocatedKatha: 0,
                    allocatedSqFt: 0,
                    percentage: 0,
                  ));
                  _calculateTab2();
                });
                Navigator.pop(ctx);
              },
              child: const Text('যোগ করুন'),
            ),
          ],
        );
      },
    );
  }

  void _removeOwner(int index) {
    setState(() {
      _owners.removeAt(index);
      _calculateTab2();
    });
  }

  String _generateDistributionReport() {
    if (_distributionResult == null) return '';
    final r = _distributionResult!;

    final buffer = StringBuffer();
    buffer.writeln('=== খতিয়ান ও দাগের অংশ বণ্টন রিপোর্ট ===');
    buffer.writeln('তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}');
    buffer.writeln('দাগের মোট জমি: ${BanglaFormatter.formatNumber(r.totalPlotDecimal)} শতক');
    buffer.writeln('অংশীদারের সংখ্যা: ${BanglaNumerals.toBangla(r.owners.length)} জন\n');

    buffer.writeln('--------------------------------------------------');
    for (int i = 0; i < r.owners.length; i++) {
      final o = r.owners[i];
      buffer.writeln('${BanglaNumerals.toBangla(i + 1)}. ${o.name} (খতিয়ান: ${o.khatianNo})');
      buffer.writeln('   হিস্যা: ${o.share.toBanglaText()} [সংকেত: ${o.share.toSymbolRepresentation()}]');
      buffer.writeln('   জমি: ${BanglaFormatter.formatNumber(o.allocatedDecimal, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(o.allocatedKatha, fractionDigits: 3)} কাঠা)');
      buffer.writeln('   বর্গফুট: ${BanglaFormatter.formatNumber(o.allocatedSqFt)} বর্গফুট | অংশ: ${BanglaFormatter.formatPercentage(o.percentage)}\n');
    }
    buffer.writeln('--------------------------------------------------');
    buffer.writeln('মোট বণ্টিত হিস্যা: ${r.totalShare.toBanglaText()} (${BanglaNumerals.toBangla(r.totalTil)} তিল)');

    if (r.isExactly16Ana) {
      buffer.writeln('যাচাই: খতিয়ানের মোট হিস্যা সম্পূর্ণ ষোল আনা (১.০০০০০০) সঠিক আছে।');
    } else if (r.remainingTil > 0) {
      buffer.writeln('সতর্কতা: ষোল আনা থেকে ${r.differenceShare.toBanglaText()} (${BanglaFormatter.formatNumber(r.remainingDecimal, fractionDigits: 3)} শতক) কম রয়েছে।');
    } else {
      buffer.writeln('সতর্কতা: ষোল আনা থেকে ${r.differenceShare.toBanglaText()} (${BanglaFormatter.formatNumber(r.remainingDecimal.abs(), fractionDigits: 3)} শতক) অতিরিক্ত বণ্টন হয়েছে!');
    }

    buffer.writeln('\nঅ্যাপ: BDLandPro (বাংলাদেশ ভূমি জরিপ ও পরিমাপ)');
    return buffer.toString();
  }

  void _copyReport() {
    final report = _generateDistributionReport();
    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('খতিয়ানের বণ্টন রিপোর্ট কপি করা হয়েছে!'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  Future<void> _saveToHistory() async {
    if (_distributionResult == null) return;
    final r = _distributionResult!;

    final item = CalculationHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'খতিয়ান বণ্টন (${BanglaFormatter.formatNumber(r.totalPlotDecimal)} শতক - ${r.owners.length} জন)',
      category: 'খতিয়ান',
      timestamp: DateTime.now(),
      inputSummary: 'দাগের মোট জমি: ${r.totalPlotDecimal} শতক, মালিক: ${r.owners.length} জন',
      resultSummary: r.isExactly16Ana ? '১৬ আনা পূর্ণ সঠিক' : 'হিস্যায় ব্যবধান বিদ্যমান',
      fullReportBangla: _generateDistributionReport(),
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
        title: const Text('খতিয়ান ও আনা-গণ্ডা হিসাবক'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondaryGold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'হিস্যা রূপান্তর ও সংকেত'),
            Tab(text: 'দাগ ও খতিয়ান বণ্টন টেবিল'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'কপি রিপোর্ট',
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
          _buildShareConversionTab(),
          _buildDistributionTableTab(),
        ],
      ),
    );
  }

  Widget _buildShareConversionTab() {
    final share = _currentTab1Share;
    final totalLand = double.tryParse(_totalLandForShareController.text) ?? 100.0;
    final allocatedDec = share.calculateLand(totalLand);
    final allocatedSqFt = allocatedDec * 435.6;
    final allocatedKatha = allocatedSqFt / 720.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Visual Symbol & Share Card
          Card(
            color: AppColors.primaryGreenLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'প্রাচীন বাংলা সংকেত ও হিস্যা',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    share.toSymbolRepresentation(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreenDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    share.toBanglaText(),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat('মোট তিল', '${BanglaNumerals.toBangla(share.toTotalTil())} / ৭৬,৮০০'),
                      _buildMiniStat('দশমিক ভগ্নাংশ', share.toFraction().toStringAsFixed(6)),
                      _buildMiniStat('শতকরা হার', BanglaFormatter.formatPercentage(share.toPercentage())),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Share Input Form Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'হিস্যার এককসমূহ ইনপুট দিন',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _anaController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'আনা (০-১৬)'),
                          onChanged: (_) => _calculateTab1(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _gondaController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'গণ্ডা (০-১৯)'),
                          onChanged: (_) => _calculateTab1(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _koraController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'কড়া (০-৩)'),
                          onChanged: (_) => _calculateTab1(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _krantiController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'ক্রান্তি (০-২)'),
                          onChanged: (_) => _calculateTab1(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _tilController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'তিল (০-১৯)'),
                          onChanged: (_) => _calculateTab1(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _totalLandForShareController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'দাগ বা জোতের মোট জমি (শতাংশ/শতক)',
                      prefixIcon: Icon(Icons.landscape, color: AppColors.primaryGreen),
                    ),
                    onChanged: (_) {
                      _calculateTab1();
                      _calculateInverse();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Allocated Land Result Card
          Card(
            color: AppColors.surfaceLight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'প্রদত্ত হিস্যায় প্রাপ্ত জমির পরিমাণ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                  ),
                  const Divider(height: 16),
                  _buildResultRow('প্রাপ্ত শতাংশ (শতক)',
                      '${BanglaFormatter.formatNumber(allocatedDec, fractionDigits: 3)} শতক',
                      isHighlight: true),
                  _buildResultRow('প্রাপ্ত কাঠা',
                      '${BanglaFormatter.formatNumber(allocatedKatha, fractionDigits: 3)} কাঠা'),
                  _buildResultRow('প্রাপ্ত বর্গফুট',
                      '${BanglaFormatter.formatNumber(allocatedSqFt)} বর্গফুট'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'বিস্তারিত: ${BanglaFormatter.formatLandBreakdown(allocatedSqFt)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Inverse Conversion: Decimal -> Ana Gonda
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'বিপরীত রূপান্তর: জমি (শতক) থেকে আনা-গণ্ডা',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _inverseDecimalController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'নির্দিষ্ট শতক বা জমি লিখুন',
                      prefixIcon: Icon(Icons.compare_arrows, color: AppColors.secondaryGoldDark),
                    ),
                    onChanged: (_) => _calculateInverse(),
                  ),
                  if (_inverseResultShare != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryGoldLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.secondaryGold),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'হিস্যা: ${_inverseResultShare!.toBanglaText()}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondaryGoldDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'প্রতীক: ${_inverseResultShare!.toSymbolRepresentation()}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionTableTab() {
    final r = _distributionResult;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Total Dag Land Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dagTotalLandController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        labelText: 'দাগের মোট জমি (শতাংশ/শতক)',
                        prefixIcon: Icon(Icons.pin_drop, color: AppColors.primaryGreen),
                      ),
                      onChanged: (_) => _calculateTab2(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddOwnerDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('মালিক যোগ'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Share Verification Card
          if (r != null)
            Card(
              color: r.isExactly16Ana ? AppColors.primaryGreenLight : Colors.amber.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: r.isExactly16Ana ? AppColors.primaryGreen : Colors.amber.shade700,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          r.isExactly16Ana ? Icons.check_circle : Icons.warning_amber_rounded,
                          color: r.isExactly16Ana ? AppColors.primaryGreen : Colors.amber.shade800,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            r.isExactly16Ana
                                ? 'খতিয়ানের মোট হিস্যা সম্পূর্ণ ষোল আনা (১.০০০০০০) সঠিক আছে।'
                                : r.remainingTil > 0
                                    ? 'ষোল আনা পূর্ণ হতে ${r.differenceShare.toBanglaText()} (${BanglaFormatter.formatNumber(r.remainingDecimal, fractionDigits: 3)} শতক) বাকি আছে!'
                                    : 'ষোল আনা থেকে ${r.differenceShare.toBanglaText()} (${BanglaFormatter.formatNumber(r.remainingDecimal.abs(), fractionDigits: 3)} শতক) অতিরিক্ত বণ্টন হয়েছে!',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: r.isExactly16Ana ? AppColors.primaryGreenDark : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('মোট বণ্টিত হিস্যা: ${r.totalShare.toBanglaText()}'),
                        Text(
                          '${BanglaNumerals.toBangla(r.totalTil)} / ৭৬,৮০০ তিল',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Distribution Table List
          if (r != null) ...[
            Text(
              'মালিকগণের অংশ বণ্টন তালিকা (${BanglaNumerals.toBangla(r.owners.length)} জন)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: r.owners.length,
              itemBuilder: (context, index) {
                final o = r.owners[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${BanglaNumerals.toBangla(index + 1)}. ${o.name}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.accentCrimson, size: 20),
                              onPressed: () => _removeOwner(index),
                            ),
                          ],
                        ),
                        Text(
                          'খতিয়ান: ${o.khatianNo} | হিস্যা: ${o.share.toBanglaText()} (${o.share.toSymbolRepresentation()})',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'প্রাপ্ত জমি: ${BanglaFormatter.formatNumber(o.allocatedDecimal, fractionDigits: 3)} শতক',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '(${BanglaFormatter.formatNumber(o.allocatedKatha, fractionDigits: 3)} কাঠা)',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                            Text(
                              BanglaFormatter.formatPercentage(o.percentage),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreenDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'বর্গফুট: ${BanglaFormatter.formatNumber(o.allocatedSqFt)} বর্গফুট',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
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
