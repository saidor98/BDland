import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/services/history_service.dart';
import '../../history/models/calculation_history_item.dart';
import '../models/land_unit.dart';
import '../services/unit_converter_service.dart';

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  final _inputController = TextEditingController(text: '1');

  LandUnit _fromUnit = LandUnit.getByType(LandUnitType.decimal);
  LandUnit _toUnit = LandUnit.getByType(LandUnitType.sqFeet);

  double _convertedValue = 0.0;
  Map<LandUnit, double> _allConversions = {};

  @override
  void initState() {
    super.initState();
    _performConversion();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _performConversion() {
    final val = double.tryParse(_inputController.text) ?? 0.0;
    setState(() {
      _convertedValue = UnitConverterService.convert(
        value: val,
        fromUnit: _fromUnit,
        toUnit: _toUnit,
      );
      _allConversions = UnitConverterService.convertToAll(
        value: val,
        fromUnit: _fromUnit,
      );
    });
  }

  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
      _performConversion();
    });
  }

  void _applyPreset(double val, LandUnit unit) {
    setState(() {
      _inputController.text = val.toString();
      _fromUnit = unit;
      _performConversion();
    });
  }

  String _generateReport() {
    final val = double.tryParse(_inputController.text) ?? 0.0;
    final totalSqFt = val * _fromUnit.sqFtEquivalent;

    final buffer = StringBuffer();
    buffer.writeln('=== বাংলাদেশ ভূমি রূপান্তর রিপোর্ট ===');
    buffer.writeln('তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}');
    buffer.writeln('মূল পরিমাণ: ${BanglaFormatter.formatNumber(val)} ${_fromUnit.banglaName}');
    buffer.writeln('রূপান্তরিত পরিমাণ: ${BanglaFormatter.formatNumber(_convertedValue, fractionDigits: 4)} ${_toUnit.banglaName}');
    buffer.writeln('মোট বর্গফুট: ${BanglaFormatter.formatNumber(totalSqFt)} বর্গফুট');
    buffer.writeln('বিস্তারিত হিসাব: ${BanglaFormatter.formatLandBreakdown(totalSqFt)}\n');

    buffer.writeln('[অন্যান্য সকল এককে রূপান্তর]');
    for (final entry in _allConversions.entries) {
      buffer.writeln('• ${entry.key.banglaName}: ${BanglaFormatter.formatNumber(entry.value, fractionDigits: 4)} ${entry.key.symbolBangla}');
    }

    buffer.writeln('\nঅ্যাপ: BDLandPro (বাংলাদেশ ভূমি জরিপ ও পরিমাপ)');
    return buffer.toString();
  }

  void _copyReport() {
    final report = _generateReport();
    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('একক রূপান্তরের সম্পূর্ণ রিপোর্ট কপি করা হয়েছে!'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  Future<void> _saveToHistory() async {
    final val = double.tryParse(_inputController.text) ?? 0.0;
    if (val <= 0) return;

    final item = CalculationHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'ভূমি রূপান্তর: ${BanglaFormatter.formatNumber(val)} ${_fromUnit.symbolBangla} = ${BanglaFormatter.formatNumber(_convertedValue, fractionDigits: 2)} ${_toUnit.symbolBangla}',
      category: 'একক রূপান্তর',
      timestamp: DateTime.now(),
      inputSummary: '${BanglaFormatter.formatNumber(val)} ${_fromUnit.banglaName}',
      resultSummary: '${BanglaFormatter.formatNumber(_convertedValue, fractionDigits: 4)} ${_toUnit.banglaName}',
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
    final currentInput = double.tryParse(_inputController.text) ?? 0.0;
    final totalSqFt = currentInput * _fromUnit.sqFtEquivalent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('বাংলাদেশ ভূমি একক রূপান্তরকারী'),
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
            // Quick Presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPresetChip('১ শতক', 1, LandUnitType.decimal),
                  _buildPresetChip('৫ শতক', 5, LandUnitType.decimal),
                  _buildPresetChip('১ কাঠা', 1, LandUnitType.katha),
                  _buildPresetChip('১ বিঘা', 1, LandUnitType.bigha),
                  _buildPresetChip('১ একর', 1, LandUnitType.acre),
                  _buildPresetChip('১ হেক্টর', 1, LandUnitType.hectare),
                  _buildPresetChip('১ কানি (৪০ শতক)', 1, LandUnitType.kaniStandard),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Conversion Form Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _inputController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        labelText: 'জমির পরিমাণ ইনপুট দিন',
                        prefixIcon: Icon(Icons.edit, color: AppColors.primaryGreen),
                      ),
                      onChanged: (_) => _performConversion(),
                    ),
                    const SizedBox(height: 16),

                    // From Unit Dropdown
                    DropdownButtonFormField<LandUnit>(
                      value: _fromUnit,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'যে একক থেকে (From)',
                        prefixIcon: Icon(Icons.arrow_upward, color: AppColors.primaryGreen),
                      ),
                      items: LandUnit.allUnits.map((u) {
                        return DropdownMenuItem<LandUnit>(
                          value: u,
                          child: Text(
                            u.banglaName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (newUnit) {
                        if (newUnit != null) {
                          setState(() {
                            _fromUnit = newUnit;
                            _performConversion();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),

                    // Swap Button
                    IconButton.filledTonal(
                      onPressed: _swapUnits,
                      icon: const Icon(Icons.swap_vert, size: 28),
                      tooltip: 'একক অদলবদল (Swap)',
                    ),
                    const SizedBox(height: 8),

                    // To Unit Dropdown
                    DropdownButtonFormField<LandUnit>(
                      value: _toUnit,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'যে এককে রূপান্তর (To)',
                        prefixIcon: Icon(Icons.arrow_downward, color: AppColors.secondaryGoldDark),
                      ),
                      items: LandUnit.allUnits.map((u) {
                        return DropdownMenuItem<LandUnit>(
                          value: u,
                          child: Text(
                            u.banglaName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (newUnit) {
                        if (newUnit != null) {
                          setState(() {
                            _toUnit = newUnit;
                            _performConversion();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Highlighted Result Card
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
                    Text(
                      '${BanglaFormatter.formatNumber(currentInput)} ${_fromUnit.banglaName} =',
                      style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${BanglaFormatter.formatNumber(_convertedValue, fractionDigits: 4)} ${_toUnit.symbolBangla}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreenDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'বর্গফুটে: ${BanglaFormatter.formatNumber(totalSqFt)} বর্গফুট',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ঐতিহ্যবাহী ভাগ: ${BanglaFormatter.formatLandBreakdown(totalSqFt)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // All Units Conversion Grid/Table
            const Text(
              'অন্যান্য সকল এককে তাৎক্ষণিক রূপান্তর তালিকা',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: LandUnit.allUnits.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final unit = LandUnit.allUnits[index];
                  final val = _allConversions[unit] ?? 0.0;
                  final isSelected = unit.type == _toUnit.type;

                  return ListTile(
                    tileColor: isSelected ? AppColors.secondaryGoldLight : null,
                    title: Text(
                      unit.banglaName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? AppColors.secondaryGoldDark : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      unit.descriptionBangla,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${BanglaFormatter.formatNumber(val, fractionDigits: 4)} ${unit.symbolBangla}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.secondaryGoldDark : AppColors.primaryGreen,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          tooltip: 'কপি',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(
                                text: '${BanglaFormatter.formatNumber(val, fractionDigits: 4)} ${unit.symbolBangla}'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${unit.banglaName} কপি করা হয়েছে!'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
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

  Widget _buildPresetChip(String label, double val, LandUnitType type) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label),
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.cardBorderLight),
        onPressed: () => _applyPreset(val, LandUnit.getByType(type)),
      ),
    );
  }
}
