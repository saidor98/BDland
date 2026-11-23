import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
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

  String _operation = '+ (যোগ)';

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

    final resultShare = _operation.startsWith('+') ? (s1 + s2) : (s1 - s2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('হিস্যা ক্যালকুলেটর (আনা-গণ্ডা হিসাব)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'কপি',
            onPressed: () {
              final text = '''
=== হিস্যা হিসাব ফলাফল ===
হিস্যা ১: ${s1.toBanglaText()} (${s1.toFraction().toStringAsFixed(6)})
অপারেশন: $_operation
হিস্যা ২: ${s2.toBanglaText()} (${s2.toFraction().toStringAsFixed(6)})
ফলাফল: ${resultShare.toBanglaText()} [প্রতীক: ${resultShare.toSymbolRepresentation()}]
দশমিক অংশ: ${resultShare.toFraction().toStringAsFixed(6)}
মোট তিল: ${BanglaNumerals.toBangla(resultShare.toTotalTil())}
অ্যাপ: BDLandPro
''';
              Clipboard.setData(ClipboardData(text: text));
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

            // Operation selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('+ হিস্যা যোগ'),
                  selected: _operation.startsWith('+'),
                  onSelected: (val) => setState(() => _operation = '+ (যোগ)'),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('- হিস্যা বিয়োগ'),
                  selected: _operation.startsWith('-'),
                  onSelected: (val) => setState(() => _operation = '- (বিয়োগ)'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Share 2 Input
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
