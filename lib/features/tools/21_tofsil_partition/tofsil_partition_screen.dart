import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/utils/bangla_formatter.dart';

class TofsilPartitionScreen extends StatefulWidget {
  const TofsilPartitionScreen({super.key});

  @override
  State<TofsilPartitionScreen> createState() => _TofsilPartitionScreenState();
}

class _TofsilPartitionScreenState extends State<TofsilPartitionScreen> {
  final _districtCtrl = TextEditingController(text: 'ঢাকা');
  final _upazilaCtrl = TextEditingController(text: 'ধানমন্ডি');
  final _subRegistryCtrl = TextEditingController(text: 'ধানমন্ডি সাব-রেজিস্ট্রি অফিস');
  final _mouzaCtrl = TextEditingController(text: 'জাফরাবাদ');
  final _jlCtrl = TextEditingController(text: '১২২');
  final _khatianCtrl = TextEditingController(text: 'RS ১০৫');
  final _dagCtrl = TextEditingController(text: '৫০১');
  final _totalLandCtrl = TextEditingController(text: '12.50');
  final _partitionLandCtrl = TextEditingController(text: '6.25');

  // Chouhoddi (চৌহদ্দি)
  final _northCtrl = TextEditingController(text: '১০ ফুট প্রশস্ত সরকারি রাস্তা');
  final _southCtrl = TextEditingController(text: 'মো: আব্দুল মালেকের নিজ জমি');
  final _eastCtrl = TextEditingController(text: 'রহিম উল্লাহর বসতভিটা');
  final _westCtrl = TextEditingController(text: 'পুকুর ও সাধারণ সীমানা');

  String _generateFormalTofsilText() {
    final total = double.tryParse(_totalLandCtrl.text) ?? 0.0;
    final part = double.tryParse(_partitionLandCtrl.text) ?? 0.0;
    final sqFt = part * 435.60;
    final namjariShare1000 = total > 0 ? ((part / total) * 1000).round() : 0;
    final fractionShare = total > 0 ? (part / total).toStringAsFixed(4) : '0.0000';

    return '''
=====================================================
                    সম্পত্তির তফসিল বিবরণী
=====================================================

জেলা: ${_districtCtrl.text}, থানা/উপজেলা: ${_upazilaCtrl.text}, সাব-রেজিস্ট্রি অফিস: ${_subRegistryCtrl.text} এর অধীনস্থ মৌজা: ${_mouzaCtrl.text}, জে.এল. নং: ${_jlCtrl.text}।

খতিয়ান নং: ${_khatianCtrl.text}
দাগ নং: ${_dagCtrl.text}
শ্রেণি: নাল / বাস্তু
দাগে মোট জমির পরিমাণ: ${BanglaFormatter.formatNumber(total, fractionDigits: 2)} শতক।
নামজারি হিস্যা (১০০০ স্কেল): ${BanglaNumerals.toBangla(namjariShare1000)} / ১০০০ (অংশ: $fractionShare)।

অদ্য বাটোয়ারা/বণ্টন দলিলের বর্ণনা মতে উক্ত দাগের মধ্য হইতে অত্র দলিলগ্রহীতার অংশে নালিশী ভূমির পরিমাণ: ${BanglaFormatter.formatNumber(part, fractionDigits: 2)} শতক জমি [যাহা বর্গফুটে প্রায় ${BanglaFormatter.formatNumber(sqFt)} বর্গফুট] হস্তান্তরিত ও বণ্টিত হইল।

উক্ত হস্তান্তরকৃত ${BanglaFormatter.formatNumber(part, fractionDigits: 2)} শতক জমির চৌহদ্দি (সীমানা):
-----------------------------------------------------
উত্তরে: ${_northCtrl.text}
দক্ষিণে: ${_southCtrl.text}
পূর্বে: ${_eastCtrl.text}
পশ্চিমে: ${_westCtrl.text}
-----------------------------------------------------
উক্ত চৌহদ্দি মধ্যে অত্র তফসিলে বর্ণিত মোট ${BanglaFormatter.formatNumber(part, fractionDigits: 2)} শতক জমি ও উহার যাবতীয় স্বত্ব-স্বার্থ, এওয়াজ ও দখল সহ।
=====================================================
''';
  }

  void _copyTofsil() {
    Clipboard.setData(ClipboardData(text: _generateFormalTofsilText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('দলিলের আনুষ্ঠানিক তফসিল ক্লিপবোর্ডে কপি করা হয়েছে!'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _printTofsilPdf() async {
    final pdf = pw.Document();
    final text = _generateFormalTofsilText();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'সম্পত্তির তফসিল বিবরণী (Deed Schedule)',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Divider(thickness: 1.5),
                pw.SizedBox(height: 12),
                pw.Text(text, style: const pw.TextStyle(fontSize: 11, lineSpacing: 2)),
                pw.Spacer(),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('দখলকার / দলিলগ্রহীতার স্বাক্ষর: _______________'),
                    pw.Text('সার্ভেয়ার / আমিনের স্বাক্ষর: _______________'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Tofsil_${_mouzaCtrl.text}_Dag_${_dagCtrl.text}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('তফসিল বণ্টন ও চৌহদ্দি প্রস্তুতকারক'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'তফসিল কপি',
            onPressed: _copyTofsil,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // General Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('মৌজা ও সাব-রেজিস্ট্রি পরিচিতি', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _districtCtrl, decoration: const InputDecoration(labelText: 'জেলা'))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: _upazilaCtrl, decoration: const InputDecoration(labelText: 'উপজেলা/থানা'))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: _subRegistryCtrl, decoration: const InputDecoration(labelText: 'সাব-রেজিস্ট্রি অফিস')),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _mouzaCtrl, decoration: const InputDecoration(labelText: 'মৌজার নাম'))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: _jlCtrl, decoration: const InputDecoration(labelText: 'জে.এল. নং'))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Khatian, Dag & Area Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('খতিয়ান, দাগ ও হস্তান্তরিত জমির পরিমাণ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _khatianCtrl, decoration: const InputDecoration(labelText: 'খতিয়ান নং'))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: _dagCtrl, decoration: const InputDecoration(labelText: 'দাগ নং'))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _totalLandCtrl, decoration: const InputDecoration(labelText: 'দাগে মোট জমি (শতক)'))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: _partitionLandCtrl, decoration: const InputDecoration(labelText: 'বণ্টনকৃত অংশ (শতক)'))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Chouhoddi (চৌহদ্দি) Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('জমির চতুর্সীমা / চৌহদ্দি', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen)),
                    const SizedBox(height: 12),
                    TextField(controller: _northCtrl, decoration: const InputDecoration(labelText: 'উত্তরে সীমানা')),
                    const SizedBox(height: 10),
                    TextField(controller: _southCtrl, decoration: const InputDecoration(labelText: 'দক্ষিণে সীমানা')),
                    const SizedBox(height: 10),
                    TextField(controller: _eastCtrl, decoration: const InputDecoration(labelText: 'পূর্বে সীমানা')),
                    const SizedBox(height: 10),
                    TextField(controller: _westCtrl, decoration: const InputDecoration(labelText: 'পশ্চিমে সীমানা')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyTofsil,
                    icon: const Icon(Icons.copy),
                    label: const Text('তফসিল কপি'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _printTofsilPdf,
                    icon: const Icon(Icons.print),
                    label: const Text('তফসিল A4 PDF প্রিন্ট'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
