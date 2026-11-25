import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/services/history_service.dart';
import '../../history/models/calculation_history_item.dart';
import '../../khatian/models/ana_gonda_share.dart';

class HissyaCalculatorScreen extends StatefulWidget {
  const HissyaCalculatorScreen({super.key});

  @override
  State<HissyaCalculatorScreen> createState() => _HissyaCalculatorScreenState();
}

class _HissyaCalculatorScreenState extends State<HissyaCalculatorScreen> {
  // Share 1
  final _ana1 = TextEditingController(text: '4');
  final _gonda1 = TextEditingController(text: '10');
  final _kora1 = TextEditingController(text: '0');

  // Share 2
  final _ana2 = TextEditingController(text: '3');
  final _gonda2 = TextEditingController(text: '5');
  final _kora2 = TextEditingController(text: '2');

  // Scalar factor for multiplication / division (e.g., split among 3 heirs)
  final _factorCtrl = TextEditingController(text: '2');

  String _operation = '+ (যোগ)';

  @override
  void dispose() {
    _ana1.dispose();
    _gonda1.dispose();
    _kora1.dispose();
    _ana2.dispose();
    _gonda2.dispose();
    _kora2.dispose();
    _factorCtrl.dispose();
    super.dispose();
  }

  AnaGondaShare _computeResult(AnaGondaShare s1, AnaGondaShare s2, double factor) {
    if (_operation.startsWith('+')) return s1 + s2;
    if (_operation.startsWith('-')) return s1 - s2;
    if (_operation.startsWith('×')) {
      return AnaGondaShare.fromTotalTil((s1.toTotalTil() * factor).round());
    }
    // Division
    if (factor <= 0) return const AnaGondaShare();
    return AnaGondaShare.fromTotalTil((s1.toTotalTil() / factor).round());
  }

  @override
  Widget build(BuildContext context) {
    final s1 = AnaGondaShare(
      ana: int.tryParse(_ana1.text) ?? 0,
      gonda: int.tryParse(_gonda1.text) ?? 0,
      kora: int.tryParse(_kora1.text) ?? 0,
    );

    final s2 = AnaGondaShare(
      ana: int.tryParse(_ana2.text) ?? 0,
      gonda: int.tryParse(_gonda2.text) ?? 0,
      kora: int.tryParse(_kora2.text) ?? 0,
    );

    final factor = double.tryParse(_factorCtrl.text) ?? 1.0;
    final isScalarOp = _operation.startsWith('×') || _operation.startsWith('÷');
    final resultShare = _computeResult(s1, s2, factor);

    final reportText = '''
=== হিস্যা হিসাব ফলাফল ===
হিস্যা ১: ${s1.toBanglaText()} (${s1.toFraction().toStringAsFixed(6)})
অপারেশন: $_operation
${isScalarOp ? 'গুণক/ভাগ মান: $factor' : 'হিস্যা ২: ${s2.toBanglaText()} (${s2.toFraction().toStringAsFixed(6)})'}
ফলাফল: ${resultShare.toBanglaText()} [প্রতীক: ${resultShare.toSymbolRepresentation()}]
দশমিক অংশ: ${resultShare.toFraction().toStringAsFixed(6)}
মোট তিল: ${BanglaNumerals.toBangla(resultShare.toTotalTil())}
অ্যাপ: BDLandPro
''';

    return Scaffold(
      appBar: AppBar(
        title: const Text('হিস্যা ক্যালকুলেটর (যোগ-বিয়োগ-গুণ-ভাগ)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'সেভ',
            onPressed: () async {
              await HistoryService.instance.saveItem(
                CalculationHistoryItem(
                  id: 'hissya_${DateTime.now().millisecondsSinceEpoch}',
                  title: 'হিস্যা $_operation',
                  category: 'খতিয়ান',
                  timestamp: DateTime.now(),
                  inputSummary: '${s1.toBanglaText()} $_operation ${isScalarOp ? factor : s2.toBanglaText()}',
                  resultSummary: '${resultShare.toBanglaText()} (${resultShare.toFraction().toStringAsFixed(4)})',
                  fullReportBangla: reportText,
                ),
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('হিস্যা হিসাব ইতিহাসে সেভ হয়েছে!'), backgroundColor: AppColors.primaryGreen),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'কপি',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: reportText));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('হিস্যা ফলাফল কপি হয়েছে!')));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Result Banner
            Card(
              color: AppColors.primaryGreenLight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('গণনাকৃত হিস্যার ফলাফল:', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Text(
                      resultShare.toSymbolRepresentation(),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryGreenDark),
                    ),
                    Text(resultShare.toBanglaText(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('দশমিক: ${resultShare.toFraction().toStringAsFixed(6)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('তিল: ${BanglaNumerals.toBangla(resultShare.toTotalTil())} / ৭৬,৮০০'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Share 1 Input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('১ম হিস্যা:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildInput('আনা', _ana1)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildInput('গণ্ডা', _gonda1)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildInput('কড়া', _kora1)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Operation selector (যোগ, বিয়োগ, গুণ, ভাগ)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('+ যোগ'),
                  selected: _operation.startsWith('+'),
                  onSelected: (_) => setState(() => _operation = '+ (যোগ)'),
                ),
                ChoiceChip(
                  label: const Text('- বিয়োগ'),
                  selected: _operation.startsWith('-'),
                  onSelected: (_) => setState(() => _operation = '- (বিয়োগ)'),
                ),
                ChoiceChip(
                  label: const Text('× গুণ'),
                  selected: _operation.startsWith('×'),
                  onSelected: (_) => setState(() => _operation = '× (গুণ)'),
                ),
                ChoiceChip(
                  label: const Text('÷ ভাগ'),
                  selected: _operation.startsWith('÷'),
                  onSelected: (_) => setState(() => _operation = '÷ (ভাগ)'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Share 2 or Factor Input
            if (isScalarOp)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _operation.startsWith('×') ? 'গুণক সংখ্যা (কত গুণ করবেন):' : 'ভাগ সংখ্যা (কত অংশে/জনে ভাগ করবেন):',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _factorCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'সংখ্যা দিন (যেমন ২, ৩, ৪)', isDense: true),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('২য় হিস্যা:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildInput('আনা', _ana2)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildInput('গণ্ডা', _gonda2)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildInput('কড়া', _kora2)),
                        ],
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

  Widget _buildInput(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, isDense: true),
      onChanged: (_) => setState(() {}),
    );
  }
}
