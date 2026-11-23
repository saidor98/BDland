import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';

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
    final pdf = pw.Document();

    final client = _clientNameCtrl.text;
    final surveyor = _surveyorNameCtrl.text;
    final phone = _surveyorPhoneCtrl.text;
    final mouza = _mouzaCtrl.text;
    final dag = _dagCtrl.text;
    final dec = double.tryParse(_areaDecimalCtrl.text) ?? 0.0;
    final sqFt = dec * 435.60;
    final katha = sqFt / 720.00;
    final notes = _notesCtrl.text;

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
                    pw.Text('BDLANDPRO - LAND SURVEY MEASUREMENT REPORT',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                    pw.SizedBox(height: 4),
                    pw.Text('Government Standard Land Cadastral & Area Certificate',
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
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Client Name:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(client)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Date:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(DateTime.now().toString().split(' ')[0])),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Mouza & Dag:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$mouza, Plot #$dag')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Surveyor:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$surveyor ($phone)')),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Measurement Table
              pw.Text('Land Area Summary (Certified Measurement):', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.green50),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Unit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Area Value', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Standard Factor', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Decimal / Shotok')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$dec Decimal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('1 Decimal = 435.60 Sq. Ft')),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Katha (Govt)')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${katha.toStringAsFixed(3)} Katha')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('1 Katha = 720 Sq. Ft')),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Square Feet (Sq. Ft)')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${sqFt.toStringAsFixed(1)} ft²')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Direct Cadastral Area')),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Surveyor Comments
              pw.Text('Surveyor Field Notes & Chouhoddi:', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
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
                      pw.Text('Client / Land Owner Signature', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.grey700),
                      pw.SizedBox(height: 4),
                      pw.Text('Licensed Surveyor Signature & Seal', style: const pw.TextStyle(fontSize: 10)),
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
