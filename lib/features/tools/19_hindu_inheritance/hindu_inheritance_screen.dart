import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/services/history_service.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../history/models/calculation_history_item.dart';

class HinduHeirResult {
  final String title;
  final int count;
  final double fraction;
  final double allocatedDecimal;
  final double allocatedTaka;
  final String legalReason;

  const HinduHeirResult({
    required this.title,
    required this.count,
    required this.fraction,
    required this.allocatedDecimal,
    required this.allocatedTaka,
    required this.legalReason,
  });
}

class HinduInheritanceScreen extends StatefulWidget {
  const HinduInheritanceScreen({super.key});

  @override
  State<HinduInheritanceScreen> createState() => _HinduInheritanceScreenState();
}

class _HinduInheritanceScreenState extends State<HinduInheritanceScreen> {
  final _estateDecCtrl = TextEditingController(text: '100.0');
  final _estateTakaCtrl = TextEditingController(text: '1000000');

  int _sonsCount = 2;
  int _widowCount = 1;
  int _unmarriedDaughterCount = 1;
  int _marriedDaughterWithSonCount = 0;
  int _fatherCount = 0;
  int _motherCount = 0;
  int _brotherCount = 0;

  List<HinduHeirResult> _results = [];

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final land = double.tryParse(_estateDecCtrl.text) ?? 0.0;
    final taka = double.tryParse(_estateTakaCtrl.text) ?? 0.0;

    final list = <HinduHeirResult>[];

    // Dayabhaga Hindu Law rules + Hindu Women's Rights to Property Act, 1937 (applicable in Bangladesh)
    if (_sonsCount > 0) {
      if (_widowCount > 0) {
        // Under 1937 Act, widow shares equally with each son (as life estate)
        final totalParts = _sonsCount + 1;
        final sonsFraction = _sonsCount / totalParts;
        final widowFraction = 1.0 / totalParts;
        list.add(HinduHeirResult(
          title: 'পুত্র / ছেলে',
          count: _sonsCount,
          fraction: sonsFraction,
          allocatedDecimal: land * sonsFraction,
          allocatedTaka: taka * sonsFraction,
          legalReason:
              '১৯৩৭ সালের হিন্দু নারীর সম্পত্তি অধিকার আইন ও দায়ভাগ অনুযায়ী পুত্রগণ এবং জীবিত বিধবা মাতা/স্ত্রী সমান হারে অংশ পান।',
        ));
        list.add(HinduHeirResult(
          title: 'বিধবা স্ত্রী',
          count: _widowCount,
          fraction: widowFraction,
          allocatedDecimal: land * widowFraction,
          allocatedTaka: taka * widowFraction,
          legalReason:
              '১৯৩৭ সালের আইন অনুযায়ী বিধবা স্ত্রী প্রতিটি পুত্রের সমান ১টি অংশ (জীবনস্বত্ব / Life Estate হিসেবে) লাভ করেন।',
        ));
      } else {
        // Sons inherit exclusively in equal shares when no widow survives
        list.add(HinduHeirResult(
          title: 'পুত্র / ছেলে',
          count: _sonsCount,
          fraction: 1.0,
          allocatedDecimal: land,
          allocatedTaka: taka,
          legalReason: 'দায়ভাগ আইন অনুযায়ী পুত্রের উপস্থিতিতে কন্যা ও দূরবর্তী ওয়ারিশ বঞ্চিত হন এবং পুত্রগণ সমান ভাগে পান।',
        ));
      }
    } else if (_widowCount > 0) {
      // 2. Widow inherits life estate if no sons
      list.add(HinduHeirResult(
        title: 'বিধবা স্ত্রী',
        count: _widowCount,
        fraction: 1.0,
        allocatedDecimal: land,
        allocatedTaka: taka,
        legalReason: 'পুত্র না থাকলে বিধবা স্ত্রী স্বামীর সমগ্র সম্পত্তিতে জীবনস্বত্ব (Life Estate) লাভ করেন। তিনি ভোগদখল করতে পারবেন কিন্তু দান/বিক্রয় করতে আইনি বাধ্যবাধকতা রয়েছে।',
      ));
    } else if (_unmarriedDaughterCount > 0) {
      // 3. Maiden daughters
      list.add(HinduHeirResult(
        title: 'অবিবাহিতা কন্যা',
        count: _unmarriedDaughterCount,
        fraction: 1.0,
        allocatedDecimal: land,
        allocatedTaka: taka,
        legalReason: 'পুত্র বা বিধবা স্ত্রী না থাকলে অবিবাহিত কন্যাগণ দায়ভাগ আইনে অগ্রাধিকার ভিত্তিতে উত্তরাধিকারী হন।',
      ));
    } else if (_marriedDaughterWithSonCount > 0) {
      // 4. Married daughters having sons
      list.add(HinduHeirResult(
        title: 'পুত্রবতী বিবাহিতা কন্যা',
        count: _marriedDaughterWithSonCount,
        fraction: 1.0,
        allocatedDecimal: land,
        allocatedTaka: taka,
        legalReason: 'অবিবাহিতা কন্যা না থাকলে পুত্রবতী কন্যা উত্তরাধিকারী হন (নিঃসন্তান কন্যা দায়ভাগে উত্তরাধিকার পান না)।',
      ));
    } else if (_fatherCount > 0) {
      // 5. Father
      list.add(HinduHeirResult(
        title: 'পিতা',
        count: _fatherCount,
        fraction: 1.0,
        allocatedDecimal: land,
        allocatedTaka: taka,
        legalReason: 'সন্তান ও স্ত্রী না থাকলে পিতা উত্তরাধিকারী হন।',
      ));
    } else if (_motherCount > 0) {
      // 6. Mother
      list.add(HinduHeirResult(
        title: 'মাতা',
        count: _motherCount,
        fraction: 1.0,
        allocatedDecimal: land,
        allocatedTaka: taka,
        legalReason: 'পিতার অবর্তমানে মাতা সপিণ্ড হিসেবে উত্তরাধিকারী হন।',
      ));
    } else if (_brotherCount > 0) {
      // 7. Brother
      list.add(HinduHeirResult(
        title: 'সহোদর ভাই',
        count: _brotherCount,
        fraction: 1.0,
        allocatedDecimal: land,
        allocatedTaka: taka,
        legalReason: 'পিতা-মাতার অবর্তমানে সহোদর ভাই উত্তরাধিকারী হন।',
      ));
    }

    setState(() => _results = list);
  }

  String _buildReportText() {
    final buffer = StringBuffer();
    buffer.writeln('=== হিন্দু উত্তরাধিকার (দায়ভাগ ও ১৯৩৭ আইন) বণ্টন রিপোর্ট ===');
    buffer.writeln('তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}');
    buffer.writeln('বণ্টনযোগ্য মোট জমি: ${_estateDecCtrl.text} শতক | নগদ টাকা: ৳ ${_estateTakaCtrl.text}\n');

    for (final r in _results) {
      buffer.writeln('• ${r.title} (${BanglaNumerals.toBangla(r.count)} জন):');
      buffer.writeln('   প্রাপ্ত জমি: ${BanglaFormatter.formatNumber(r.allocatedDecimal, fractionDigits: 3)} শতক');
      buffer.writeln('   নগদ টাকা: ${BanglaFormatter.formatCurrency(r.allocatedTaka)}');
      if (r.count > 1) {
        buffer.writeln('   জনপ্রতি জমি: ${BanglaFormatter.formatNumber(r.allocatedDecimal / r.count, fractionDigits: 3)} শতক | জনপ্রতি অর্থ: ${BanglaFormatter.formatCurrency(r.allocatedTaka / r.count)}');
      }
      buffer.writeln('   আইনি কারণ: ${r.legalReason}\n');
    }
    buffer.writeln('অ্যাপ: BDLandPro - পেশাদার বাংলাদেশ ভূমি জরিপ');
    return buffer.toString();
  }

  void _copyReport() {
    Clipboard.setData(ClipboardData(text: _buildReportText()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('হিন্দু উত্তরাধিকার রিপোর্ট কপি করা হয়েছে!')));
  }

  Future<void> _saveToHistory() async {
    await HistoryService.instance.saveItem(
      CalculationHistoryItem(
        id: 'hindu_${DateTime.now().millisecondsSinceEpoch}',
        title: 'হিন্দু উত্তরাধিকার বণ্টন (${_estateDecCtrl.text} শতক)',
        category: 'ফারায়েজ',
        timestamp: DateTime.now(),
        inputSummary: 'পুত্র: $_sonsCount, স্ত্রী: $_widowCount, অবিবাহিতা কন্যা: $_unmarriedDaughterCount',
        resultSummary: _results.isEmpty ? 'ওয়ারিশ নেই' : _results.map((r) => '${r.title}: ${BanglaFormatter.formatNumber(r.allocatedDecimal, fractionDigits: 2)} শতক').join(' | '),
        fullReportBangla: _buildReportText(),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('বণ্টন রিপোর্ট ইতিহাসে সেভ করা হয়েছে'), backgroundColor: AppColors.primaryGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('উত্তরাধিকার (হিন্দু দায়ভাগ আইন)'),
        actions: [
          IconButton(icon: const Icon(Icons.bookmark_add_outlined), tooltip: 'ইতিহাসে সেভ', onPressed: _saveToHistory),
          IconButton(icon: const Icon(Icons.copy), tooltip: 'কপি', onPressed: _copyReport),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Estate inputs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _estateDecCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'মোট জমি (শতক)'),
                      onChanged: (_) => _calculate(),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _estateTakaCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'মোট নগদ অর্থ (টাকা)'),
                      onChanged: (_) => _calculate(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Heirs Counters
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('জীবিত ওয়ারিশদের সংখ্যা নির্ধারণ করুন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    _counter('পুত্র / ছেলে (Sons)', _sonsCount, (v) => setState(() { _sonsCount = v; _calculate(); })),
                    _counter('বিধবা স্ত্রী (Widow)', _widowCount, (v) => setState(() { _widowCount = v; _calculate(); }), max: 1),
                    _counter('অবিবাহিতা কন্যা', _unmarriedDaughterCount, (v) => setState(() { _unmarriedDaughterCount = v; _calculate(); })),
                    _counter('পুত্রবতী বিবাহিতা কন্যা', _marriedDaughterWithSonCount, (v) => setState(() { _marriedDaughterWithSonCount = v; _calculate(); })),
                    _counter('পিতা', _fatherCount, (v) => setState(() { _fatherCount = v; _calculate(); }), max: 1),
                    _counter('মাতা', _motherCount, (v) => setState(() { _motherCount = v; _calculate(); }), max: 1),
                    _counter('সহোদর ভাই', _brotherCount, (v) => setState(() { _brotherCount = v; _calculate(); })),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Distribution Results
            if (_results.isEmpty)
              Card(
                color: Colors.amber.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFFB45309)),
                      SizedBox(width: 10),
                      Expanded(child: Text('কমপক্ষে একজন জীবিত ওয়ারিশের সংখ্যা ১ বা তার বেশি নির্ধারণ করুন।')),
                    ],
                  ),
                ),
              ),
            ..._results.map((r) {
              return Card(
                color: AppColors.primaryGreenLight,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${r.title} (${BanglaNumerals.toBangla(r.count)} জন)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreenDark)),
                          Text('${BanglaFormatter.formatNumber(r.allocatedDecimal, fractionDigits: 3)} শতক',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryGreenDark)),
                        ],
                      ),
                      const Divider(height: 14),
                      if (r.count > 1)
                        Text(
                          'জনপ্রতি জমি: ${BanglaFormatter.formatNumber(r.allocatedDecimal / r.count, fractionDigits: 3)} শতক | জনপ্রতি অর্থ: ${BanglaFormatter.formatCurrency(r.allocatedTaka / r.count)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      Text('মোট নগদ অর্থ: ${BanglaFormatter.formatCurrency(r.allocatedTaka)}'),
                      const SizedBox(height: 6),
                      Text('আইনি দলীল: ${r.legalReason}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _counter(String label, int count, Function(int) onChanged, {int max = 10}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20), onPressed: count > 0 ? () => onChanged(count - 1) : null),
              Text(BanglaNumerals.toBangla(count), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), onPressed: count < max ? () => onChanged(count + 1) : null),
            ],
          ),
        ],
      ),
    );
  }
}
