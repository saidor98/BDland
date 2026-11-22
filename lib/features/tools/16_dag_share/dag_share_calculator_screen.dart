import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../khatian/models/ana_gonda_share.dart';

class DagPlotItem {
  final String dagNo;
  final double totalAreaDecimal;
  const DagPlotItem({required this.dagNo, required this.totalAreaDecimal});
}

class DagShareCalculatorScreen extends StatefulWidget {
  const DagShareCalculatorScreen({super.key});

  @override
  State<DagShareCalculatorScreen> createState() => _DagShareCalculatorScreenState();
}

class _DagShareCalculatorScreenState extends State<DagShareCalculatorScreen> {
  final _ownerNameCtrl = TextEditingController(text: 'মো: আব্দুল মালেক');
  final _khatianNoCtrl = TextEditingController(text: '১০৫');
  final _shareDecimalCtrl = TextEditingController(text: '0.1250'); // 2 Ana / 12.5%

  final List<DagPlotItem> _plots = [
    const DagPlotItem(dagNo: '১০১', totalAreaDecimal: 50.0),
    const DagPlotItem(dagNo: '১০২', totalAreaDecimal: 80.0),
    const DagPlotItem(dagNo: '১০৫', totalAreaDecimal: 35.0),
  ];

  void _addPlot() {
    final dagCtrl = TextEditingController();
    final areaCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('নতুন দাগ যোগ করুন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: dagCtrl, decoration: const InputDecoration(labelText: 'দাগ নং')),
            const SizedBox(height: 10),
            TextField(controller: areaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'দাগের মোট জমি (শতক)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () {
              final dNo = dagCtrl.text.trim();
              final a = double.tryParse(areaCtrl.text) ?? 0.0;
              if (dNo.isNotEmpty && a > 0) {
                setState(() => _plots.add(DagPlotItem(dagNo: dNo, totalAreaDecimal: a)));
              }
              Navigator.pop(ctx);
            },
            child: const Text('যোগ করুন'),
          ),
        ],
      ),
    );
  }

  void _copyReport() {
    final share = double.tryParse(_shareDecimalCtrl.text) ?? 0.0;
    double totalAccumulated = 0;

    final buffer = StringBuffer();
    buffer.writeln('=== দাগওয়ারী অংশ ও জমি বণ্টন রিপোর্ট ===');
    buffer.writeln('তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}');
    buffer.writeln('মালিকের নাম: ${_ownerNameCtrl.text}');
    buffer.writeln('খতিয়ান নং: ${_khatianNoCtrl.text}');
    buffer.writeln('খতিয়ানে হিস্যা: ${BanglaFormatter.formatNumber(share, fractionDigits: 6)} (${BanglaFormatter.formatPercentage(share * 100)})\n');

    buffer.writeln('[দাগসমূহের বিবরণ]');
    for (final p in _plots) {
      final alloc = p.totalAreaDecimal * share;
      totalAccumulated += alloc;
      buffer.writeln('• দাগ নং ${p.dagNo}: মোট জমি ${BanglaFormatter.formatNumber(p.totalAreaDecimal)} শতক -> প্রাপ্ত জমি: ${BanglaFormatter.formatNumber(alloc, fractionDigits: 3)} শতক');
    }
    buffer.writeln('\n----------------------------------------');
    buffer.writeln('সর্বমোট প্রাপ্ত জমি: ${BanglaFormatter.formatNumber(totalAccumulated, fractionDigits: 3)} শতক (${BanglaFormatter.formatLandBreakdown(totalAccumulated * 435.60)})');
    buffer.writeln('অ্যাপ: BDLandPro - পেশাদার বাংলাদেশ ভূমি জরিপ');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('দাগের অংশ রিপোর্ট কপি করা হয়েছে!')));
  }

  @override
  Widget build(BuildContext context) {
    final share = double.tryParse(_shareDecimalCtrl.text) ?? 0.0;
    double totalAllocated = 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('দাগের অংশ ক্যালকুলেটর'),
        actions: [
          IconButton(icon: const Icon(Icons.copy), tooltip: 'কপি রিপোর্ট', onPressed: _copyReport),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Owner & Share Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(controller: _ownerNameCtrl, decoration: const InputDecoration(labelText: 'মালিকের নাম')),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _khatianNoCtrl, decoration: const InputDecoration(labelText: 'খতিয়ান নং'))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _shareDecimalCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'হিস্যা (যেমন 0.1250)'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Dag Plot List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('খতিয়ানের অন্তর্ভুক্ত দাগসমূহ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ElevatedButton.icon(onPressed: _addPlot, icon: const Icon(Icons.add, size: 18), label: const Text('দাগ যোগ')),
                      ],
                    ),
                    const Divider(height: 16),
                    ..._plots.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final p = entry.value;
                      final alloc = p.totalAreaDecimal * share;
                      totalAllocated += alloc;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Text('দাগ নং ${p.dagNo}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Text('মোট: ${BanglaFormatter.formatNumber(p.totalAreaDecimal)} শতক'),
                            const Spacer(),
                            Text(
                              'প্রাপ্ত: ${BanglaFormatter.formatNumber(alloc, fractionDigits: 3)} শতক',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.accentCrimson),
                              onPressed: () => setState(() => _plots.removeAt(idx)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Total Allocated Card
            Card(
              color: AppColors.primaryGreenLight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('সর্বমোট প্রাপ্ত জমি:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${BanglaFormatter.formatNumber(totalAllocated, fractionDigits: 3)} শতক',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryGreenDark)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('বিস্তারিত: ${BanglaFormatter.formatLandBreakdown(totalAllocated * 435.60)}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
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
