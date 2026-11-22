import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/utils/bangla_formatter.dart';

class SharerRatioItem {
  final String name;
  final double ratioWeight;
  const SharerRatioItem({required this.name, required this.ratioWeight});
}

class LandRatioDividerScreen extends StatefulWidget {
  const LandRatioDividerScreen({super.key});

  @override
  State<LandRatioDividerScreen> createState() => _LandRatioDividerScreenState();
}

class _LandRatioDividerScreenState extends State<LandRatioDividerScreen> {
  final _totalLandDecCtrl = TextEditingController(text: '30.0'); // 30 decimal
  final _totalFrontageFtCtrl = TextEditingController(text: '120.0'); // 120 ft road frontage

  final List<SharerRatioItem> _sharers = [
    const SharerRatioItem(name: 'অংশীদার ১ (ক)', ratioWeight: 5.0),
    const SharerRatioItem(name: 'অংশীদার ২ (খ)', ratioWeight: 3.0),
    const SharerRatioItem(name: 'অংশীদার ৩ (গ)', ratioWeight: 2.0),
  ];

  void _addSharer() {
    final nameCtrl = TextEditingController(text: 'অংশীদার ${_sharers.length + 1}');
    final ratioCtrl = TextEditingController(text: '1.0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('নতুন অংশীদার যোগ করুন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'নাম')),
            const SizedBox(height: 10),
            TextField(controller: ratioCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'অনুপাত / ইনভেস্টমেন্ট')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () {
              final r = double.tryParse(ratioCtrl.text) ?? 1.0;
              setState(() {
                _sharers.add(SharerRatioItem(name: nameCtrl.text.trim(), ratioWeight: r));
              });
              Navigator.pop(ctx);
            },
            child: const Text('যোগ করুন'),
          ),
        ],
      ),
    );
  }

  void _copyReport() {
    final totalLand = double.tryParse(_totalLandDecCtrl.text) ?? 0;
    final totalFront = double.tryParse(_totalFrontageFtCtrl.text) ?? 0;
    final sumRatio = _sharers.fold<double>(0, (sum, item) => sum + item.ratioWeight);

    final buffer = StringBuffer();
    buffer.writeln('=== অনুপাত ও ফ্রন্টেজ বণ্টন রিপোর্ট ===');
    buffer.writeln('তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}');
    buffer.writeln('মোট জমি: ${BanglaFormatter.formatNumber(totalLand)} শতক');
    buffer.writeln('মোট রাস্তার মুখ (Frontage): ${BanglaFormatter.formatNumber(totalFront)} ফুট\n');

    for (final s in _sharers) {
      final pct = sumRatio > 0 ? (s.ratioWeight / sumRatio) * 100 : 0;
      final land = totalLand * (pct / 100);
      final front = totalFront * (pct / 100);
      buffer.writeln('• ${s.name}:');
      buffer.writeln('   অনুপাত: ${s.ratioWeight} (${BanglaFormatter.formatPercentage(pct.toDouble())})');
      buffer.writeln('   প্রাপ্ত জমি: ${BanglaFormatter.formatNumber(land.toDouble(), fractionDigits: 3)} শতক');
      buffer.writeln('   রাস্তার মুখ: ${BanglaFormatter.formatNumber(front.toDouble())} ফুট\n');
    }
    buffer.writeln('অ্যাপ: BDLandPro - পেশাদার বাংলাদেশ ভূমি জরিপ');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('অনুপাত বণ্টন রিপোর্ট কপি করা হয়েছে!')));
  }

  @override
  Widget build(BuildContext context) {
    final totalLand = double.tryParse(_totalLandDecCtrl.text) ?? 0;
    final totalFront = double.tryParse(_totalFrontageFtCtrl.text) ?? 0;
    final sumRatio = _sharers.fold<double>(0, (sum, item) => sum + item.ratioWeight);

    return Scaffold(
      appBar: AppBar(
        title: const Text('অনুপাত ও ফ্রন্টেজ ক্যালকুলেটর'),
        actions: [
          IconButton(icon: const Icon(Icons.copy), tooltip: 'কপি রিপোর্ট', onPressed: _copyReport),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Inputs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _totalLandDecCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'মোট জমি (শতক)'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _totalFrontageFtCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'রাস্তার মুখ / ফ্রন্ট (ফুট)'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Sharers List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('অংশীদারগণের অনুপাত তালিকা', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton.filledTonal(onPressed: _addSharer, icon: const Icon(Icons.person_add, size: 20)),
                      ],
                    ),
                    const Divider(height: 16),
                    ..._sharers.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final s = entry.value;
                      final pct = sumRatio > 0 ? (s.ratioWeight / sumRatio) * 100 : 0;
                      final allocLand = totalLand * (pct / 100);
                      final allocFront = totalFront * (pct / 100);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${BanglaNumerals.toBangla(idx + 1)}. ${s.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (_sharers.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.accentCrimson, size: 18),
                                    onPressed: () => setState(() => _sharers.removeAt(idx)),
                                  ),
                              ],
                            ),
                            Text('অনুপাত মান: ${BanglaNumerals.toBangla(s.ratioWeight)} (${BanglaFormatter.formatPercentage(pct.toDouble())})'),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('প্রাপ্ত জমি: ${BanglaFormatter.formatNumber(allocLand.toDouble(), fractionDigits: 3)} শতক',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                                Text('রাস্তার মুখ: ${BanglaFormatter.formatNumber(allocFront.toDouble())} ফুট',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondaryGoldDark)),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
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
