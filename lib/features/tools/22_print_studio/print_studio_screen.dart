import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
    final theme = await PdfReportHelper.loadBengaliTheme();
    final pdf = pw.Document(theme: theme);

    final client = _clientNameCtrl.text;
    final surveyor = _surveyorNameCtrl.text;
    final phone = _surveyorPhoneCtrl.text;
    final mouza = _mouzaCtrl.text;
    final dag = _dagCtrl.text;
    final dec = double.tryParse(_areaDecimalCtrl.text) ?? 0.0;
    final sqFt = dec * 435.60;
    final katha = sqFt / 720.00;
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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.only(bottom: 12),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 2, color: PdfColors.green800)),
                ),
                child: pw.Column(
                  children: [
                    pw.Text('বিডি ল্যান্ড প্রো — ভূমি পরিমাপ ও জরিপ প্রতিবেদন',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                    pw.SizedBox(height: 4),
                    pw.Text('সরকারি ক্যাডাস্ট্রাল মানদণ্ড অনুযায়ী জমি ও সীমানা প্রত্যয়নপত্র',
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Surveyor and Client Details Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('গ্রাহকের নাম:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(client)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('তারিখ:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(DateTime.now().toString().split(' ')[0])),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('মৌজা ও দাগ:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$mouza, দাগ #$dag')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('সার্ভেয়ার:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$surveyor ($phone)')),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Measurement Table
              pw.Text('জমির ক্ষেত্রফল সারসংক্ষেপ (প্রত্যয়িত পরিমাপ):', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.green50),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('জমির একক', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('পরিমাপকৃত পরিমাণ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('সরকারি হিসাব মান', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('শতাংশ / শতক')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${dec.toStringAsFixed(3)} শতক', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('১ শতক = ৪৩৫.৬০ বর্গফুট')),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('কাঠা (সরকারি মান)')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${katha.toStringAsFixed(3)} কাঠা')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('১ কাঠা = ৭২০ বর্গফুট')),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('বর্গফুট (Sq. Ft)')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${sqFt.toStringAsFixed(1)} বর্গফুট')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('সরাসরি ক্যাডাস্ট্রাল ক্ষেত্রফল')),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Surveyor Comments
              pw.Text('সার্ভেয়ারের মাঠ পর্যায়ের নোট ও চৌহদ্দি:', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  color: PdfColors.grey50,
                ),
                child: pw.Text(notes, style: const pw.TextStyle(fontSize: 11)),
              ),

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.grey700),
                      pw.SizedBox(height: 4),
                      pw.Text('জমির মালিক / গ্রাহকের স্বাক্ষর', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.grey700),
                      pw.SizedBox(height: 4),
                      pw.Text('সার্ভেয়ার / আমিনের স্বাক্ষর ও সিল', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
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
