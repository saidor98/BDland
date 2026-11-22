import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/services/history_service.dart';
import '../../history/models/calculation_history_item.dart';
import '../models/faraiz_models.dart';
import '../services/faraiz_engine.dart';

class FaraizCalculatorScreen extends StatefulWidget {
  const FaraizCalculatorScreen({super.key});

  @override
  State<FaraizCalculatorScreen> createState() => _FaraizCalculatorScreenState();
}

class _FaraizCalculatorScreenState extends State<FaraizCalculatorScreen> {
  DeceasedGender _deceasedGender = DeceasedGender.male;
  bool _applyMflo1961 = false;

  final _estateDecimalController = TextEditingController(text: '100');
  final _estateTakaController = TextEditingController(text: '1000000');

  // Heir Counts
  final Map<HeirType, int> _heirCounts = {
    HeirType.wife: 1,
    HeirType.son: 2,
    HeirType.daughter: 1,
    HeirType.father: 0,
    HeirType.mother: 1,
    HeirType.paternalGrandfather: 0,
    HeirType.paternalGrandmother: 0,
    HeirType.maternalGrandmother: 0,
    HeirType.fullBrother: 0,
    HeirType.fullSister: 0,
    HeirType.consanguineBrother: 0,
    HeirType.consanguineSister: 0,
    HeirType.uterineBrother: 0,
    HeirType.uterineSister: 0,
    HeirType.sonSon: 0,
    HeirType.sonDaughter: 0,
    HeirType.husband: 0,
  };

  FaraizDistributionResult? _result;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _estateDecimalController.dispose();
    _estateTakaController.dispose();
    super.dispose();
  }

  void _calculate() {
    final landDec = double.tryParse(_estateDecimalController.text) ?? 0.0;
    final cashTaka = double.tryParse(_estateTakaController.text) ?? 0.0;

    setState(() {
      _result = FaraizEngine.calculate(
        deceasedGender: _deceasedGender,
        heirCounts: _heirCounts,
        totalEstateDecimal: landDec,
        totalEstateTaka: cashTaka,
        applyMflo1961: _applyMflo1961,
      );
    });
  }

  void _setCount(HeirType type, int count) {
    setState(() {
      _heirCounts[type] = count < 0 ? 0 : count;
      _calculate();
    });
  }

  String _generateReport() {
    if (_result == null) return '';
    final r = _result!;

    final buffer = StringBuffer();
    buffer.writeln('=== মুসলিম উত্তরাধিকার (ফারায়েজ) বণ্টন রিপোর্ট ===');
    buffer.writeln('তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}');
    buffer.writeln('মৃত ব্যক্তি: ${r.deceasedGender == DeceasedGender.male ? "পুরুষ (স্বামী/পিতা)" : "নারী (স্ত্রী/মাতা)"}');
    buffer.writeln('বণ্টনযোগ্য মোট জমি: ${BanglaFormatter.formatNumber(r.totalEstateDecimal)} শতক');
    buffer.writeln('বণ্টনযোগ্য নগদ অর্থ: ${BanglaFormatter.formatCurrency(r.totalEstateTaka)}');
    buffer.writeln('মাসআলার ধরন: ${r.summaryExplanationBangla}\n');

    buffer.writeln('--------------------------------------------------');
    for (final h in r.heirs) {
      if (h.isExcluded) {
        buffer.writeln('• ${h.titleBangla} (${BanglaNumerals.toBangla(h.count)} জন):');
        buffer.writeln('   অবস্থা: বঞ্চিত (হিজাব) | কারণ: ${h.legalBasisBangla}\n');
      } else {
        buffer.writeln('• ${h.titleBangla} (${BanglaNumerals.toBangla(h.count)} জন):');
        buffer.writeln('   অংশ: ${h.fractionText} (${BanglaFormatter.formatPercentage(h.percentage)})');
        buffer.writeln('   প্রাপ্ত জমি: ${BanglaFormatter.formatNumber(h.allocatedDecimal, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(h.allocatedKatha, fractionDigits: 3)} কাঠা)');
        buffer.writeln('   নগদ টাকা: ${BanglaFormatter.formatCurrency(h.allocatedTaka)}');
        if (h.count > 1) {
          buffer.writeln('   জনপ্রতি জমি: ${BanglaFormatter.formatNumber(h.perPersonDecimal, fractionDigits: 3)} শতক');
          buffer.writeln('   জনপ্রতি টাকা: ${BanglaFormatter.formatCurrency(h.perPersonTaka)}');
        }
        buffer.writeln('   শরীয়াহ দলীল: ${h.legalBasisBangla}\n');
      }
    }
    buffer.writeln('--------------------------------------------------');
    buffer.writeln('অ্যাপ: BDLandPro (বাংলাদেশ ভূমি জরিপ ও ফারায়েজ ক্যালকুলেটর)');
    return buffer.toString();
  }

  void _copyReport() {
    final report = _generateReport();
    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ফারায়েজের সম্পূর্ণ বাংলা রিপোর্ট কপি করা হয়েছে!'),
        backgroundColor: AppColors.accentPurple,
      ),
    );
  }

  Future<void> _saveToHistory() async {
    if (_result == null) return;
    final r = _result!;

    final item = CalculationHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'ফারায়েজ বণ্টন (${BanglaFormatter.formatNumber(r.totalEstateDecimal)} শতক)',
      category: 'ফারায়েজ',
      timestamp: DateTime.now(),
      inputSummary: 'মৃত: ${r.deceasedGender == DeceasedGender.male ? "পুরুষ" : "নারী"}, জমি: ${r.totalEstateDecimal} শতক',
      resultSummary: '${r.heirs.where((h) => !h.isExcluded).length} শ্রেণির ওয়ারিশের মাঝে বণ্টিত (${r.isAwl ? "আওল" : r.isRadd ? "রদ" : "স্বাভাবিক"})',
      fullReportBangla: _generateReport(),
    );

    await HistoryService.instance.saveItem(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('হিস্ট্রিতে সংরক্ষিত হয়েছে!'),
        backgroundColor: AppColors.accentPurple,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('মুসলিম ফারায়েজ ক্যালকুলেটর'),
        backgroundColor: AppColors.accentPurple,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Deceased Gender Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'মৃত ব্যক্তির তথ্য ও লিঙ্গ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('মৃত ব্যক্তি পুরুষ')),
                            selected: _deceasedGender == DeceasedGender.male,
                            selectedColor: AppColors.accentPurple.withOpacity(0.2),
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _deceasedGender = DeceasedGender.male;
                                  _heirCounts[HeirType.husband] = 0;
                                  if ((_heirCounts[HeirType.wife] ?? 0) == 0) {
                                    _heirCounts[HeirType.wife] = 1;
                                  }
                                  _calculate();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('মৃত ব্যক্তি নারী')),
                            selected: _deceasedGender == DeceasedGender.female,
                            selectedColor: AppColors.accentPurple.withOpacity(0.2),
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _deceasedGender = DeceasedGender.female;
                                  _heirCounts[HeirType.wife] = 0;
                                  if ((_heirCounts[HeirType.husband] ?? 0) == 0) {
                                    _heirCounts[HeirType.husband] = 1;
                                  }
                                  _calculate();
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Estate Values
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'বণ্টনযোগ্য মোট সম্পত্তি (জমি ও নগদ অর্থ)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _estateDecimalController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'মোট জমি (শতক)',
                              prefixIcon: Icon(Icons.landscape, color: AppColors.accentPurple),
                            ),
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _estateTakaController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'মোট নগদ অর্থ (টাকা)',
                              prefixIcon: Icon(Icons.payments_outlined, color: AppColors.secondaryGoldDark),
                            ),
                            onChanged: (_) => _calculate(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('মুসলিম পারিবারিক আইন ১৯৬১ (ধারা ৪)'),
                      subtitle: const Text('মৃত সন্তানের জীবিত এতিম পৌত্র/পৌত্রীর হিস্যা কার্যকর'),
                      value: _applyMflo1961,
                      activeColor: AppColors.accentPurple,
                      onChanged: (val) {
                        setState(() {
                          _applyMflo1961 = val;
                          _calculate();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Heirs Input Counters
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'জীবিত ওয়ারিশদের সংখ্যা নির্বাচন করুন',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Spouse
                    if (_deceasedGender == DeceasedGender.male)
                      _buildCounterRow(HeirType.wife, 'স্ত্রী (Wives - ১ থেকে ৪)', max: 4)
                    else
                      _buildCounterRow(HeirType.husband, 'স্বামী (Husband)', max: 1),

                    // Children
                    _buildCounterRow(HeirType.son, 'ছেলে / পুত্র (Sons)'),
                    _buildCounterRow(HeirType.daughter, 'মেয়ে / কন্যা (Daughters)'),

                    // Parents
                    _buildCounterRow(HeirType.father, 'পিতা / বাবা (Father)', max: 1),
                    _buildCounterRow(HeirType.mother, 'মাতা / মা (Mother)', max: 1),

                    // Grandparents
                    _buildCounterRow(HeirType.paternalGrandfather, 'দাদা (Paternal Grandfather)', max: 1),
                    _buildCounterRow(HeirType.paternalGrandmother, 'দাদী (Paternal Grandmother)', max: 1),
                    _buildCounterRow(HeirType.maternalGrandmother, 'নানী (Maternal Grandmother)', max: 1),

                    // Siblings
                    _buildCounterRow(HeirType.fullBrother, 'সহোদর ভাই (Full Brothers)'),
                    _buildCounterRow(HeirType.fullSister, 'সহোদর বোন (Full Sisters)'),
                    _buildCounterRow(HeirType.consanguineBrother, 'বৈমাত্রেয় ভাই'),
                    _buildCounterRow(HeirType.consanguineSister, 'বৈমাত্রেয় বোন'),
                    _buildCounterRow(HeirType.uterineBrother, 'বৈপিত্রেয় ভাই'),
                    _buildCounterRow(HeirType.uterineSister, 'বৈপিত্রেয় বোন'),

                    // Grandchildren
                    _buildCounterRow(HeirType.sonSon, 'পৌত্র (মৃত ছেলের ছেলে)'),
                    _buildCounterRow(HeirType.sonDaughter, 'পৌত্রী (মৃত ছেলের মেয়ে)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Distribution Results
            if (_result != null) ...[
              // Summary Banner
              Card(
                color: _result!.isAwl
                    ? Colors.amber.shade50
                    : _result!.isRadd
                        ? Colors.blue.shade50
                        : AppColors.primaryGreenLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _result!.isAwl
                        ? Colors.amber.shade700
                        : _result!.isRadd
                            ? Colors.blue.shade600
                            : AppColors.primaryGreen,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      Icon(
                        _result!.isAwl
                            ? Icons.trending_down
                            : _result!.isRadd
                                ? Icons.trending_up
                                : Icons.verified,
                        color: _result!.isAwl
                            ? Colors.amber.shade800
                            : _result!.isRadd
                                ? Colors.blue.shade700
                                : AppColors.primaryGreenDark,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _result!.summaryExplanationBangla,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _result!.isAwl
                                ? Colors.amber.shade900
                                : _result!.isRadd
                                    ? Colors.blue.shade900
                                    : AppColors.primaryGreenDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Individual Heir Share Cards
              const Text(
                'ওয়ারিশদের মাঝে বণ্টন বিবরণী',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              ..._result!.heirs.map((h) {
                if (h.isExcluded) {
                  return Card(
                    color: Colors.grey.shade100,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.block, color: AppColors.accentCrimson, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${h.titleBangla} (${BanglaNumerals.toBangla(h.count)} জন) - বঞ্চিত',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  h.legalBasisBangla,
                                  style: const TextStyle(fontSize: 12, color: AppColors.accentCrimson),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${h.titleBangla} (${BanglaNumerals.toBangla(h.count)} জন)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentPurple,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accentPurple.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${h.fractionText} (${BanglaFormatter.formatPercentage(h.percentage)})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentPurple,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'প্রাপ্ত মোট জমি: ${BanglaFormatter.formatNumber(h.allocatedDecimal, fractionDigits: 3)} শতক',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '(${BanglaFormatter.formatNumber(h.allocatedKatha, fractionDigits: 3)} কাঠা)',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'নগদ অর্থ: ${BanglaFormatter.formatCurrency(h.allocatedTaka)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondaryGoldDark,
                              ),
                            ),
                            Text(
                              'বর্গফুট: ${BanglaFormatter.formatNumber(h.allocatedSqFt)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        if (h.count > 1) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'জনপ্রতি জমি: ${BanglaFormatter.formatNumber(h.perPersonDecimal, fractionDigits: 3)} শতক',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'জনপ্রতি টাকা: ${BanglaFormatter.formatCurrency(h.perPersonTaka)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          'দলীল: ${h.legalBasisBangla}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCounterRow(HeirType type, String label, {int max = 20}) {
    final count = _heirCounts[type] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
                color: count > 0 ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 22),
                color: count > 0 ? AppColors.accentCrimson : Colors.grey,
                onPressed: count > 0 ? () => _setCount(type, count - 1) : null,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 32),
                child: Text(
                  BanglaNumerals.toBangla(count),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 22),
                color: count < max ? AppColors.primaryGreen : Colors.grey,
                onPressed: count < max ? () => _setCount(type, count + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
