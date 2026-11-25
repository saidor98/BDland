import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/history_service.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../history/models/calculation_history_item.dart';

class UnknownSideSolverScreen extends StatefulWidget {
  const UnknownSideSolverScreen({super.key});

  @override
  State<UnknownSideSolverScreen> createState() => _UnknownSideSolverScreenState();
}

class _UnknownSideSolverScreenState extends State<UnknownSideSolverScreen> {
  String _mode = 'আয়তক্ষেত্রাকার জমি';
  final _targetAreaDecCtrl = TextEditingController(text: '5.0'); // 5 decimal target
  final _knownSideCtrl = TextEditingController(text: '80.0'); // Known front/length in feet
  final _secondKnownCtrl = TextEditingController(text: '60.0'); // For trapezoid

  double _requiredLengthFt = 0.0;
  bool _isImpossibleGeometry = false;

  @override
  void initState() {
    super.initState();
    _solve();
  }

  @override
  void dispose() {
    _targetAreaDecCtrl.dispose();
    _knownSideCtrl.dispose();
    _secondKnownCtrl.dispose();
    super.dispose();
  }

  void _solve() {
    final targetDec = double.tryParse(_targetAreaDecCtrl.text) ?? 0;
    final targetSqFt = targetDec * 435.60;
    final side1 = double.tryParse(_knownSideCtrl.text) ?? 0;
    final side2 = double.tryParse(_secondKnownCtrl.text) ?? 0;

    double result = 0;
    if (_mode == 'আয়তক্ষেত্রাকার জমি') {
      if (side1 > 0 && targetSqFt > 0) result = targetSqFt / side1;
    } else if (_mode == 'ট্রাপিজিয়াম (গড় বিস্তার)') {
      // Area = ((a + b) / 2) * h -> b = (2 * Area / h) - a
      if (side2 > 0 && targetSqFt > 0) {
        result = ((2 * targetSqFt) / side2) - side1;
      }
    } else if (_mode == 'ত্রিভুজাকার জমি') {
      // Area = 0.5 * base * height -> height = (2 * Area) / base
      if (side1 > 0 && targetSqFt > 0) result = (2 * targetSqFt) / side1;
    }

    setState(() {
      _isImpossibleGeometry = targetSqFt > 0 && result <= 0;
      _requiredLengthFt = result > 0 ? result : 0;
    });
  }

  String _buildReport(double targetDec, double targetSqFt, double links, double hath) {
    return '''
=== অজানা বাহু পরিমাপ রিপোর্ট ===
তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}
পদ্ধতি: $_mode
কাঙ্ক্ষিত জমি: ${BanglaFormatter.formatNumber(targetDec)} শতক (${BanglaFormatter.formatNumber(targetSqFt)} বর্গফুট)
প্রদত্ত জ্ঞাত বাহু: ${_knownSideCtrl.text} ফুট
প্রয়োজনীয় অজানা বাহুর দৈর্ঘ্য: ${BanglaFormatter.formatNumber(_requiredLengthFt)} ফুট (${BanglaFormatter.formatNumber(links)} লিংক বা ${BanglaFormatter.formatNumber(hath)} হাত)
অ্যাপ: BDLandPro - পেশাদার বাংলাদেশ ভূমি জরিপ
''';
  }

  Future<void> _saveToHistory(double targetDec, double targetSqFt, double links, double hath) async {
    await HistoryService.instance.saveItem(
      CalculationHistoryItem(
        id: 'unknown_${DateTime.now().millisecondsSinceEpoch}',
        title: 'অজানা বাহু নির্ণয় (${BanglaFormatter.formatNumber(targetDec)} শতক)',
        category: 'জ্যামিতি',
        timestamp: DateTime.now(),
        inputSummary: '$_mode | জ্ঞাত: ${_knownSideCtrl.text} ফুট',
        resultSummary: '${BanglaFormatter.formatNumber(_requiredLengthFt)} ফুট (${BanglaFormatter.formatNumber(links)} লিংক)',
        fullReportBangla: _buildReport(targetDec, targetSqFt, links, hath),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('অজানা বাহুর হিসাব হিস্ট্রিতে সংরক্ষিত হয়েছে!'), backgroundColor: AppColors.primaryGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetDec = double.tryParse(_targetAreaDecCtrl.text) ?? 0;
    final targetSqFt = targetDec * 435.60;
    final links = _requiredLengthFt / 0.66;
    final hath = _requiredLengthFt / 1.5;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ক্ষেত্রফল / অজানা বাহু নির্ণয়'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'হিস্ট্রিতে সেভ',
            onPressed: _requiredLengthFt > 0 ? () => _saveToHistory(targetDec, targetSqFt, links, hath) : null,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'কপি',
            onPressed: () {
              final report = _buildReport(targetDec, targetSqFt, links, hath);
              Clipboard.setData(ClipboardData(text: report));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('অজানা বাহুর হিসাব কপি করা হয়েছে!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isImpossibleGeometry)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDAD6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.accentCrimson, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'অসম্ভব জ্যামিতি: প্রদত্ত ১ম বাহু ও উচ্চতা দিয়ে এই ক্ষেত্রফল পাওয়া সম্ভব নয় (২য় বাহু ঋণাত্মক আসছে)।',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF93000A)),
                      ),
                    ),
                  ],
                ),
              ),
            // Target Result Highlight Card (Stitch Emerald Precision Card)
            Card(
              color: AppColors.primaryGreenLight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('প্রয়োজনীয় অজানা বাহুর দৈর্ঘ্য:', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Text(
                      '${BanglaFormatter.formatNumber(_requiredLengthFt)} ফুট',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryGreenDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'গান্টার্স লিংক: ${BanglaFormatter.formatNumber(links)} লিংক | হাত: ${BanglaFormatter.formatNumber(hath)} হাত',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Mode and inputs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _mode,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'জমি বিভাজন বা আকৃতির ধরন'),
                      items: const [
                        DropdownMenuItem(value: 'আয়তক্ষেত্রাকার জমি', child: Text('আয়তক্ষেত্র (দৈর্ঘ্য দেওয়া আছে, প্রস্থ নির্ণয়)', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'ট্রাপিজিয়াম (গড় বিস্তার)', child: Text('ট্রাপিজিয়াম (১ম বাহু ও উচ্চতা দেওয়া, ২য় বাহু নির্ণয়)', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'ত্রিভুজাকার জমি', child: Text('ত্রিভুজ (ভূমি দেওয়া, উচ্চতা/অপর বাহু নির্ণয়)', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _mode = val;
                            _solve();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _targetAreaDecCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'কাঙ্ক্ষিত জমির পরিমাণ (শতাংশ/শতক)'),
                      onChanged: (_) => _solve(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _knownSideCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'জ্ঞাত বাহু / ফ্রন্টেজ (ফুট)'),
                      onChanged: (_) => _solve(),
                    ),
                    if (_mode == 'ট্রাপিজিয়াম (গড় বিস্তার)') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _secondKnownCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'লম্ব উচ্চতা / বিস্তার (ফুট)'),
                        onChanged: (_) => _solve(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
