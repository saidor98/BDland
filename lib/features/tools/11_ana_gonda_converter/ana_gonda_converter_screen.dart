import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../khatian/models/ana_gonda_share.dart';
import '../widgets/ana_gonda_keypad.dart';

class AnaGondaConverterScreen extends StatefulWidget {
  const AnaGondaConverterScreen({super.key});

  @override
  State<AnaGondaConverterScreen> createState() => _AnaGondaConverterScreenState();
}

class _AnaGondaConverterScreenState extends State<AnaGondaConverterScreen> {
  final _anaCtrl = TextEditingController(text: '4');
  final _gondaCtrl = TextEditingController(text: '10');
  final _koraCtrl = TextEditingController(text: '2');
  final _krantiCtrl = TextEditingController(text: '1');
  final _tilCtrl = TextEditingController(text: '10');
  final _totalLandCtrl = TextEditingController(text: '100');

  // Inverse
  final _reverseDecimalCtrl = TextEditingController(text: '0.28125');
  AnaGondaShare? _reverseShare;

  @override
  void initState() {
    super.initState();
    _recomputeReverse();
  }

  void _recomputeReverse() {
    final val = double.tryParse(_reverseDecimalCtrl.text) ?? 0.0;
    if (val > 0) {
      setState(() {
        _reverseShare = AnaGondaShare.fromFraction(val);
      });
    }
  }

  AnaGondaShare get _share {
    return AnaGondaShare(
      ana: int.tryParse(_anaCtrl.text) ?? 0,
      gonda: int.tryParse(_gondaCtrl.text) ?? 0,
      kora: int.tryParse(_koraCtrl.text) ?? 0,
      kranti: int.tryParse(_krantiCtrl.text) ?? 0,
      til: int.tryParse(_tilCtrl.text) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _share;
    final totalLand = double.tryParse(_totalLandCtrl.text) ?? 100.0;
    final allocatedDec = s.calculateLand(totalLand);
    final allocatedSqFt = allocatedDec * 435.60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('আনা-গণ্ডা কনভার্টার (প্রথাগত একক)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Traditional Symbol Display Card
            Card(
              color: AppColors.primaryGreenLight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('ঐতিহ্যবাহী বাংলা সংকেত ও প্রতীক', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(
                      s.toSymbolRepresentation(),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryGreenDark),
                    ),
                    Text(s.toBanglaText(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('মোট তিল', '${BanglaNumerals.toBangla(s.toTotalTil())} / ৭৬,৮০০'),
                        _buildStat('দশমিক অংশ', s.toFraction().toStringAsFixed(6)),
                        _buildStat('শতকরা হার', BanglaFormatter.formatPercentage(s.toPercentage())),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 16-Ana Fractional Breakdown Formula Card (Page 7)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.functions, color: AppColors.primaryGreen, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '১৬ আনা হিস্যা ভগ্নাংশ বিভাজন সূত্র',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        '(${BanglaNumerals.toBangla(s.ana)}/১৬) + (${BanglaNumerals.toBangla(s.gonda)}/৩২০) + (${BanglaNumerals.toBangla(s.kora)}/১২৮০) + (${BanglaNumerals.toBangla(s.kranti)}/৩৮৪০) + (${BanglaNumerals.toBangla(s.til)}/৭৬৮০০)',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F5A38),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '= মোট ${BanglaNumerals.toBangla(s.toTotalTil())} তিল / ৭৬,৮০০ তিল (অনুপাত: ${s.toFraction().toStringAsFixed(6)})',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Share Inputs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('আনা-গণ্ডা-কড়া-ক্রান্তি-তিল ইনপুট', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildInput('আনা (০-১৬)', _anaCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildInput('গণ্ডা (০-১৯)', _gondaCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildInput('কড়া (০-৩)', _koraCtrl)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildInput('ক্রান্তি (০-২)', _krantiCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildInput('তিল (০-১৯)', _tilCtrl)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _totalLandCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'মোট জমি (শতক)'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // On-screen Virtual Keypad
            AnaGondaKeypad(
              onAnaSelected: (val) => setState(() => _anaCtrl.text = val.toString()),
              onGondaSelected: (val) => setState(() => _gondaCtrl.text = val.toString()),
              onKoraSelected: (val) => setState(() => _koraCtrl.text = val.toString()),
              onKrantiSelected: (val) => setState(() => _krantiCtrl.text = val.toString()),
              onTilSelected: (val) => setState(() => _tilCtrl.text = val.toString()),
            ),
            const SizedBox(height: 14),

            // Land Allocation Result Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('প্রাপ্ত জমির পরিমাণ:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${BanglaFormatter.formatNumber(allocatedDec, fractionDigits: 3)} শতক',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryGreen)),
                      ],
                    ),
                    const Divider(height: 14),
                    Text('বর্গফুটে: ${BanglaFormatter.formatNumber(allocatedSqFt)} ft²'),
                    Text('বিস্তারিত: ${BanglaFormatter.formatLandBreakdown(allocatedSqFt)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Reverse Converter
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('বিপরীত রূপান্তর: অংশ/দশমিক থেকে আনা-গণ্ডা', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _reverseDecimalCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'দশমিক হিস্যা (যেমন: 0.28125)'),
                      onChanged: (_) => _recomputeReverse(),
                    ),
                    if (_reverseShare != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.secondaryGoldLight, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('হিস্যা: ${_reverseShare!.toBanglaText()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondaryGoldDark)),
                            Text('প্রতীক: ${_reverseShare!.toSymbolRepresentation()}'),
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

  Widget _buildStat(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
