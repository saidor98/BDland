import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/history_service.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../converter/models/land_unit.dart';
import '../../history/models/calculation_history_item.dart';

class SmartLandUnitConverterScreen extends StatefulWidget {
  const SmartLandUnitConverterScreen({super.key});

  @override
  State<SmartLandUnitConverterScreen> createState() => _SmartLandUnitConverterScreenState();
}

class _SmartLandUnitConverterScreenState extends State<SmartLandUnitConverterScreen> {
  final _inputCtrl = TextEditingController(text: '1.0');
  LandUnit _fromUnit = LandUnit.getByType(LandUnitType.decimal);
  LandUnit _toUnit = LandUnit.getByType(LandUnitType.katha);

  // Regional custom katha settings (default 720 sq ft)
  double _customKathaSqFt = 720.0;

  double _effectiveSqFt(LandUnit unit) {
    if ((_customKathaSqFt - 720.0).abs() > 0.01) {
      if (unit.type == LandUnitType.katha) return _customKathaSqFt;
      if (unit.type == LandUnitType.chhatak) return _customKathaSqFt / 16.0;
      if (unit.type == LandUnitType.bigha) return _customKathaSqFt * 20.0;
    }
    return unit.sqFtEquivalent;
  }

  Future<void> _saveToHistory(double inputVal, double converted, double totalSqFt) async {
    await HistoryService.instance.saveItem(
      CalculationHistoryItem(
        id: 'conv_unit_${DateTime.now().millisecondsSinceEpoch}',
        title: 'একক রূপান্তর (${_fromUnit.symbolBangla} → ${_toUnit.symbolBangla})',
        category: 'একক রূপান্তর',
        timestamp: DateTime.now(),
        inputSummary: '${BanglaFormatter.formatNumber(inputVal)} ${_fromUnit.banglaName}',
        resultSummary: '${BanglaFormatter.formatNumber(converted, fractionDigits: 4)} ${_toUnit.symbolBangla}',
        fullReportBangla: 'মোট বর্গফুট: ${BanglaFormatter.formatNumber(totalSqFt)} ft²\nআঞ্চলিক কাঠা: $_customKathaSqFt বর্গফুট',
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('হিসাব ইতিহাসে সেভ করা হয়েছে'), backgroundColor: AppColors.primaryGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputVal = double.tryParse(_inputCtrl.text) ?? 0.0;
    final fromFactor = _effectiveSqFt(_fromUnit);
    final toFactor = _effectiveSqFt(_toUnit);
    final totalSqFt = inputVal * fromFactor;
    final converted = (_fromUnit.type == _toUnit.type)
        ? inputVal
        : (toFactor > 0 ? totalSqFt / toFactor : 0.0);

    final all = <LandUnit, double>{};
    for (final unit in LandUnit.allUnits) {
      final f = _effectiveSqFt(unit);
      all[unit] = f > 0 ? totalSqFt / f : 0.0;
    }
    final isCustomKatha = (_customKathaSqFt - 720.0).abs() > 0.01;

    return Scaffold(
      appBar: AppBar(
        title: const Text('শতক-কাঠা-বিঘা-একর স্মার্ট রূপান্তর'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'ইতিহাসে সেভ',
            onPressed: () => _saveToHistory(inputVal, converted, totalSqFt),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'আঞ্চলিক কাঠার মাপ নির্ধারণ',
            onPressed: () => _showRegionalKathaDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isCustomKatha)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryGoldLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.secondaryGoldDark.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune, size: 18, color: AppColors.secondaryGoldDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'কাস্টম আঞ্চলিক কাঠা সক্রিয়: ১ কাঠা = ${BanglaFormatter.formatNumber(_customKathaSqFt, fractionDigits: 1)} বর্গফুট',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _customKathaSqFt = 720.0),
                      child: const Text('৭২০-এ ফিরুন'),
                    ),
                  ],
                ),
              ),
            // Quick preset chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('১ শতক', 1, LandUnitType.decimal),
                  _chip('১ কাঠা', 1, LandUnitType.katha),
                  _chip('১ বিঘা', 1, LandUnitType.bigha),
                  _chip('১ একর', 1, LandUnitType.acre),
                  _chip('১ কানি (৪০)', 1, LandUnitType.kaniStandard),
                  _chip('১ কানি (১২০)', 1, LandUnitType.kaniComilla),
                  _chip('১ শাহী কানি (১৬০)', 1, LandUnitType.kaniShahi),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Conversion Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _inputCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(labelText: 'জমির পরিমাণ ইনপুট দিন'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<LandUnit>(
                            value: _fromUnit,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'যে একক থেকে (From)'),
                            items: LandUnit.allUnits
                                .map((u) => DropdownMenuItem(value: u, child: Text(u.banglaName, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (u) => setState(() => _fromUnit = u!),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.swap_horiz, size: 28, color: AppColors.primaryGreen),
                          onPressed: () {
                            setState(() {
                              final temp = _fromUnit;
                              _fromUnit = _toUnit;
                              _toUnit = temp;
                            });
                          },
                        ),
                        Expanded(
                          child: DropdownButtonFormField<LandUnit>(
                            value: _toUnit,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'যে এককে (To)'),
                            items: LandUnit.allUnits
                                .map((u) => DropdownMenuItem(value: u, child: Text(u.banglaName, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (u) => setState(() => _toUnit = u!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Primary Highlight Card
            Card(
              color: AppColors.primaryGreenLight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('${BanglaFormatter.formatNumber(inputVal)} ${_fromUnit.banglaName} =',
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      '${BanglaFormatter.formatNumber(converted, fractionDigits: 4)} ${_toUnit.symbolBangla}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryGreenDark),
                    ),
                    const SizedBox(height: 6),
                    Text('মোট বর্গফুট: ${BanglaFormatter.formatNumber(totalSqFt)} ft²', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                      child: Text('ঐতিহ্যবাহী ভাগ: ${BanglaFormatter.formatLandBreakdown(totalSqFt)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Full Conversion List
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('সকল ১৮+ এককে তাৎক্ষণিক রূপান্তর', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 8),

            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: LandUnit.allUnits.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final u = LandUnit.allUnits[index];
                  final val = all[u] ?? 0;
                  final isSelected = u.type == _toUnit.type;
                  return ListTile(
                    tileColor: isSelected ? AppColors.secondaryGoldLight : null,
                    title: Text(u.banglaName, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text(u.descriptionBangla, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${BanglaFormatter.formatNumber(val, fractionDigits: 4)} ${u.symbolBangla}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppColors.secondaryGoldDark : AppColors.primaryGreen),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: '${BanglaFormatter.formatNumber(val, fractionDigits: 4)} ${u.symbolBangla}'));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${u.banglaName} কপি হয়েছে!')));
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, double val, LandUnitType type) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label),
        onPressed: () {
          setState(() {
            _inputCtrl.text = val.toString();
            _fromUnit = LandUnit.getByType(type);
          });
        },
      ),
    );
  }

  void _showRegionalKathaDialog() {
    final ctrl = TextEditingController(text: _customKathaSqFt.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('আঞ্চলিক কাঠার মাপ নির্ধারণ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('সরকারি মান অনুযায়ী ১ কাঠা = ৭২০ বর্গফুট। তবে আপনার এলাকায় ভিন্ন মান হলে তা নিচে লিখুন:'),
            const SizedBox(height: 12),
            TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '১ কাঠা = কত বর্গফুট?')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null && v >= 100 && v <= 5000) {
                setState(() => _customKathaSqFt = v);
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('সঠিক বর্গফুট মান দিন (যেমন ৭২০, ৯৯০ বা ১৬২০)')),
                );
              }
            },
            child: const Text('সংরক্ষণ করুন'),
          ),
        ],
      ),
    );
  }
}
