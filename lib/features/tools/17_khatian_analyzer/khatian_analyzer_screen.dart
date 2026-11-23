import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/bangla_formatter.dart';

class KhatianAuditOwner {
  final String name;
  final double shareDecimal;
  const KhatianAuditOwner({required this.name, required this.shareDecimal});
}

class KhatianAnalyzerScreen extends StatefulWidget {
  const KhatianAnalyzerScreen({super.key});

  @override
  State<KhatianAnalyzerScreen> createState() => _KhatianAnalyzerScreenState();
}

class _KhatianAnalyzerScreenState extends State<KhatianAnalyzerScreen> {
  String _surveyType = 'RS খতিয়ান';
  final _khatianNoCtrl = TextEditingController(text: '১০৫');
  final _mouzaCtrl = TextEditingController(text: 'জাফরাবাদ');
  final _jlCtrl = TextEditingController(text: '১২২');
  final _totalLandCtrl = TextEditingController(text: '120.0'); // 120 decimal

  final List<KhatianAuditOwner> _owners = [
    const KhatianAuditOwner(name: 'মো: আব্দুল করিম', shareDecimal: 0.5000), // 8 Ana
    const KhatianAuditOwner(name: 'মোছা: রাহেলা খাতুন', shareDecimal: 0.2500), // 4 Ana
    const KhatianAuditOwner(name: 'মো: শফিকুল ইসলাম', shareDecimal: 0.2500), // 4 Ana
  ];

  void _addOwner() {
    final nameCtrl = TextEditingController();
    final shareCtrl = TextEditingController(text: '0.1250');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('খতিয়ানের অংশীদার যোগ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'মালিকের নাম')),
            const SizedBox(height: 10),
            TextField(controller: shareCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'হিস্যা (দশমিকে)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () {
              final n = nameCtrl.text.trim();
              final s = double.tryParse(shareCtrl.text) ?? 0.0;
              if (n.isNotEmpty && s > 0) {
                setState(() => _owners.add(KhatianAuditOwner(name: n, shareDecimal: s)));
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
    final totalLand = double.tryParse(_totalLandCtrl.text) ?? 0;
    final sumShare = _owners.fold<double>(0, (sum, o) => sum + o.shareDecimal);
    final isValid = (sumShare - 1.0).abs() < 0.0001;

    final buffer = StringBuffer();
    buffer.writeln('=== খতিয়ান পর্যালোচনা ও অডিট রিপোর্ট ===');
    buffer.writeln('তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}');
    buffer.writeln('জরিপ প্রকার: $_surveyType | খতিয়ান নং: ${_khatianNoCtrl.text}');
    buffer.writeln('মৌজা: ${_mouzaCtrl.text} (জে.এল: ${_jlCtrl.text})');
    buffer.writeln('খতিয়ানের মোট জমি: ${BanglaFormatter.formatNumber(totalLand)} শতক\n');

    buffer.writeln('[মালিক ও হিস্যা বিশ্লেষণ]');
    for (final o in _owners) {
      final alloc = totalLand * o.shareDecimal;
      buffer.writeln('• ${o.name}: হিস্যা ${BanglaFormatter.formatNumber(o.shareDecimal, fractionDigits: 6)} (${BanglaFormatter.formatPercentage(o.shareDecimal * 100)}) -> ${BanglaFormatter.formatNumber(alloc, fractionDigits: 3)} শতক');
    }
    buffer.writeln('\n----------------------------------------');
    buffer.writeln('মোট হিস্যা যোগফল: ${BanglaFormatter.formatNumber(sumShare, fractionDigits: 6)}');
    buffer.writeln(isValid ? 'স্ট্যাটাস: খতিয়ানের হিস্যা ষোল আনা (১.০০০০০০) সম্পূর্ণ সঠিক।' : 'সতর্কতা: হিস্যার যোগফলে গরমিল বিদ্যমান (${BanglaFormatter.formatNumber((sumShare - 1.0).abs(), fractionDigits: 6)})');
    buffer.writeln('\nঅ্যাপ: BDLandPro - পেশাদার বাংলাদেশ ভূমি জরিপ');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('খতিয়ান অডিট রিপোর্ট কপি করা হয়েছে!')));
  }

  @override
  Widget build(BuildContext context) {
    final totalLand = double.tryParse(_totalLandCtrl.text) ?? 0;
    final sumShare = _owners.fold<double>(0, (sum, o) => sum + o.shareDecimal);
    final is16Ana = (sumShare - 1.0).abs() < 0.0001;

    return Scaffold(
      appBar: AppBar(
        title: const Text('খতিয়ান বিশ্লেষণ ও অডিট'),
        actions: [
          IconButton(icon: const Icon(Icons.copy), tooltip: 'কপি রিপোর্ট', onPressed: _copyReport),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Khatian Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _surveyType,
                            decoration: const InputDecoration(labelText: 'জরিপ প্রকার'),
                            items: const [
                              DropdownMenuItem(value: 'CS খতিয়ান', child: Text('CS খতিয়ান')),
                              DropdownMenuItem(value: 'SA খতিয়ান', child: Text('SA খতিয়ান')),
                              DropdownMenuItem(value: 'RS খতিয়ান', child: Text('RS খতিয়ান')),
                              DropdownMenuItem(value: 'BS / সিটি জরিপ', child: Text('BS / সিটি জরিপ')),
                            ],
                            onChanged: (val) => setState(() => _surveyType = val!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: _khatianNoCtrl, decoration: const InputDecoration(labelText: 'খতিয়ান নং'))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _mouzaCtrl, decoration: const InputDecoration(labelText: 'মৌজার নাম'))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: _jlCtrl, decoration: const InputDecoration(labelText: 'জে.এল. নং'))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _totalLandCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'খতিয়ানের মোট জমি (শতাংশ/শতক)'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Share Verification Status Card
            Card(
              color: is16Ana ? AppColors.primaryGreenLight : Colors.amber.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: is16Ana ? AppColors.primaryGreen : Colors.amber.shade700, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(is16Ana ? Icons.verified : Icons.warning_amber_rounded,
                        color: is16Ana ? AppColors.primaryGreen : Colors.amber.shade800, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            is16Ana ? 'হিস্যা ষোল আনা (১.০০০০০০) পূর্ণ সঠিক' : 'হিস্যার যোগফলে গরমিল রয়েছে!',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: is16Ana ? AppColors.primaryGreenDark : Colors.amber.shade900),
                          ),
                          Text(
                            'মোট হিস্যা যোগফল: ${BanglaFormatter.formatNumber(sumShare, fractionDigits: 6)} (আদর্শ: ১.০০০০০০)',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Owners Table
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('মালিকগণের হিস্যা ও জমি তালিকা', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ElevatedButton.icon(onPressed: _addOwner, icon: const Icon(Icons.add, size: 18), label: const Text('মালিক যোগ')),
                      ],
                    ),
                    const Divider(height: 16),
                    ..._owners.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final o = entry.value;
                      final alloc = totalLand * o.shareDecimal;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(o.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('হিস্যা: ${BanglaFormatter.formatNumber(o.shareDecimal, fractionDigits: 6)} (${BanglaFormatter.formatPercentage(o.shareDecimal * 100)})',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Text(
                              '${BanglaFormatter.formatNumber(alloc, fractionDigits: 3)} শতক',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                            ),
                            if (_owners.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.accentCrimson),
                                onPressed: () => setState(() => _owners.removeAt(idx)),
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
