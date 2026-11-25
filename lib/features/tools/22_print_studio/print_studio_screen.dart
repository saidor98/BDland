import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/history_service.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/utils/pdf_report_helper.dart';
import '../../history/models/calculation_history_item.dart';

class PrintStudioScreen extends StatefulWidget {
  const PrintStudioScreen({super.key});

  @override
  State<PrintStudioScreen> createState() => _PrintStudioScreenState();
}

class _PrintStudioScreenState extends State<PrintStudioScreen> {
  final _clientNameCtrl = TextEditingController(text: 'মো: আব্দুল করিম');
  final _surveyorNameCtrl = TextEditingController(text: 'সার্ভেয়ার মোঃ সাইদুর রহমান (আমিন)');
  final _surveyorPhoneCtrl = TextEditingController(text: '০১৭১২-৩৪৫৬৭৮');
  final _mouzaCtrl = TextEditingController(text: 'জাফরাবাদ');
  final _dagCtrl = TextEditingController(text: '৫০১');
  final _areaDecimalCtrl = TextEditingController(text: '12.50');
  final _notesCtrl = TextEditingController(text: 'হেরন্স ফর্মুলায় সরেজমিনে সীমানা পরিমাপপূর্বক দখল বুঝিয়ে দেওয়া হইল।');

  Future<void> _generateAndPrintPdf() async {
    final client = _clientNameCtrl.text;
    final surveyor = _surveyorNameCtrl.text;
    final phone = _surveyorPhoneCtrl.text;
    final mouza = _mouzaCtrl.text;
    final dag = _dagCtrl.text;
    final dec = double.tryParse(_areaDecimalCtrl.text) ?? 0.0;
    final sqFt = dec * 435.60;
    final katha = sqFt / 720.00;
    final bigha = dec / 33.0;
    final acre = dec / 100.0;
    final notes = _notesCtrl.text;

    await HistoryService.instance.saveItem(
      CalculationHistoryItem(
        id: 'print_${DateTime.now().millisecondsSinceEpoch}',
        title: 'সার্ভে সার্টিফিকেট: $mouza (দাগ $dag)',
        category: 'জ্যামিতি',
        timestamp: DateTime.now(),
        inputSummary: 'মালিক: $client | মৌজা: $mouza, দাগ: $dag',
        resultSummary: '${BanglaFormatter.formatNumber(dec, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(katha, fractionDigits: 3)} কাঠা)',
        fullReportBangla: 'ক্লায়েন্ট: $client\nসার্ভেয়ার: $surveyor ($phone)\nমৌজা: $mouza, দাগ: $dag\nজমি: $dec শতক\nমন্তব্য: $notes',
      ),
    );

    final esc = PdfReportHelper.escapeHtml;
    final bodyHtml = '''
      <div class="kpi-grid">
        <div class="kpi-box">
          <div class="kpi-label">শতাংশ / শতক</div>
          <div class="kpi-val">${esc(BanglaFormatter.formatNumber(dec, fractionDigits: 3))} শতক</div>
        </div>
        <div class="kpi-box">
          <div class="kpi-label">কাঠা (সরকারি মান)</div>
          <div class="kpi-val">${esc(BanglaFormatter.formatNumber(katha, fractionDigits: 3))} কাঠা</div>
        </div>
        <div class="kpi-box">
          <div class="kpi-label">বর্গফুট (Sq. Ft)</div>
          <div class="kpi-val">${esc(BanglaFormatter.formatNumber(sqFt, fractionDigits: 1))} ft²</div>
        </div>
      </div>

      <h3 class="section-title">গ্রাহক ও জরিপকারীর পরিচিতি</h3>
      <table>
        <tr>
          <th style="width:22%">জমির মালিক</th><td>${esc(client)}</td>
          <th style="width:20%">তারিখ</th><td>${esc(BanglaFormatter.formatDateTime(DateTime.now()))}</td>
        </tr>
        <tr>
          <th>মৌজা ও দাগ নং</th><td>${esc(mouza)}, দাগ #${esc(dag)}</td>
          <th>সার্ভেয়ার (আমিন)</th><td>${esc(surveyor)} (${esc(phone)})</td>
        </tr>
      </table>

      <h3 class="section-title">জমির ক্ষেত্রফল সারসংক্ষেপ (প্রত্যয়িত পরিমাপ)</h3>
      <table>
        <tr><th>জমির একক</th><th>পরিমাপকৃত পরিমাণ</th><th>সরকারি হিসাব মানদণ্ড</th></tr>
        <tr><td><strong>শতাংশ / শতক</strong></td><td><strong>${esc(BanglaFormatter.formatNumber(dec, fractionDigits: 3))} শতক</strong></td><td>১ শতক = ৪৩৫.৬০ বর্গফুট</td></tr>
        <tr><td>কাঠা (সরকারি মান)</td><td>${esc(BanglaFormatter.formatNumber(katha, fractionDigits: 3))} কাঠা</td><td>১ কাঠা = ৭২০ বর্গফুট</td></tr>
        <tr><td>বিঘা ও একর</td><td>${esc(BanglaFormatter.formatNumber(bigha, fractionDigits: 3))} বিঘা / ${esc(BanglaFormatter.formatNumber(acre, fractionDigits: 4))} একর</td><td>১ একর = ১০০ শতক (৩.০৩ বিঘা)</td></tr>
        <tr><td>বর্গফুট (Sq. Ft)</td><td>${esc(BanglaFormatter.formatNumber(sqFt, fractionDigits: 1))} বর্গফুট</td><td>সরাসরি ক্যাডাস্ট্রাল ক্ষেত্রফল</td></tr>
      </table>

      <h3 class="section-title">সার্ভেয়ারের মাঠ পর্যায়ের নোট ও সীমানা মন্তব্য</h3>
      <div class="info-panel">${esc(notes)}</div>
    ''';

    final html = PdfReportHelper.buildCadastralHtmlDocument(
      title: 'বিডি ল্যান্ড প্রো — ভূমি পরিমাপ ও জরিপ প্রতিবেদন',
      subtitle: 'সরকারি ক্যাডাস্ট্রাল মানদণ্ড অনুযায়ী জমি ও সীমানা প্রত্যয়নপত্র',
      badgeText: 'দাগ #$dag',
      bodyHtml: bodyHtml,
      leftSignatureLabel: 'জমির মালিক / গ্রাহকের স্বাক্ষর',
      rightSignatureLabel: 'সার্ভেয়ার / আমিনের স্বাক্ষর ও সিল',
    );

    await PdfReportHelper.printHtmlPdf(
      html: html,
      jobName: 'BDLandPro_Certificate_${mouza}_$dag.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রিন্ট স্টুডিও (A4 রিপোর্ট ও PDF)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('রিপোর্টের তথ্য ইনপুট দিন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextField(controller: _clientNameCtrl, decoration: const InputDecoration(labelText: 'ক্লায়েন্ট / জমির মালিকের নাম')),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _surveyorNameCtrl, decoration: const InputDecoration(labelText: 'সার্ভেয়ার / আমিনের নাম'))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: _surveyorPhoneCtrl, decoration: const InputDecoration(labelText: 'মোবাইল নং'))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _mouzaCtrl, decoration: const InputDecoration(labelText: 'মৌজা'))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: _dagCtrl, decoration: const InputDecoration(labelText: 'দাগ নং'))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _areaDecimalCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'পরিমাপকৃত জমি (শতাংশ/শতক)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'সার্ভেয়ার নোট ও সীমানা মন্তব্য'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _generateAndPrintPdf,
              icon: const Icon(Icons.print),
              label: const Text('A4 সাইজ PDF রিপোর্ট প্রিভিউ ও প্রিন্ট করুন'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
