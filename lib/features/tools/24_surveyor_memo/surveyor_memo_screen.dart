import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/services/history_service.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/utils/pdf_report_helper.dart';
import '../../history/models/calculation_history_item.dart';

class MemoRecord {
  final String id;
  final String clientName;
  final String phone;
  final String mouza;
  final String dagNo;
  final String serviceType;
  final double totalFee;
  final double advancePaid;
  final DateTime date;

  const MemoRecord({
    required this.id,
    required this.clientName,
    required this.phone,
    required this.mouza,
    required this.dagNo,
    required this.serviceType,
    required this.totalFee,
    required this.advancePaid,
    required this.date,
  });

  double get due => totalFee - advancePaid;

  MemoRecord copyWith({
    String? clientName,
    String? phone,
    String? mouza,
    String? dagNo,
    String? serviceType,
    double? totalFee,
    double? advancePaid,
    DateTime? date,
  }) {
    return MemoRecord(
      id: id,
      clientName: clientName ?? this.clientName,
      phone: phone ?? this.phone,
      mouza: mouza ?? this.mouza,
      dagNo: dagNo ?? this.dagNo,
      serviceType: serviceType ?? this.serviceType,
      totalFee: totalFee ?? this.totalFee,
      advancePaid: advancePaid ?? this.advancePaid,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'clientName': clientName,
        'phone': phone,
        'mouza': mouza,
        'dagNo': dagNo,
        'serviceType': serviceType,
        'totalFee': totalFee,
        'advancePaid': advancePaid,
        'date': date.toIso8601String(),
      };

  factory MemoRecord.fromMap(Map<String, dynamic> map) => MemoRecord(
        id: map['id'] as String? ?? '0',
        clientName: map['clientName'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        mouza: map['mouza'] as String? ?? '',
        dagNo: map['dagNo'] as String? ?? '',
        serviceType: map['serviceType'] as String? ?? 'সরেজমিন জমি পরিমাপ ও সীমানা নির্ধারণ',
        totalFee: (map['totalFee'] as num?)?.toDouble() ?? 0.0,
        advancePaid: (map['advancePaid'] as num?)?.toDouble() ?? 0.0,
        date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      );
}

class SurveyorMemoScreen extends StatefulWidget {
  const SurveyorMemoScreen({super.key});

  @override
  State<SurveyorMemoScreen> createState() => _SurveyorMemoScreenState();
}

class _SurveyorMemoScreenState extends State<SurveyorMemoScreen> {
  static const String _prefsKey = 'bdland_surveyor_memos_v1';

  final _clientCtrl = TextEditingController(text: 'মো: জাহিদুল হাসান');
  final _phoneCtrl = TextEditingController(text: '০১৭০০-১২৩৪৫৬');
  final _mouzaCtrl = TextEditingController(text: 'জাফরাবাদ');
  final _dagCtrl = TextEditingController(text: '৫০১, ৫০২');
  final _totalFeeCtrl = TextEditingController(text: '5000');
  final _advanceCtrl = TextEditingController(text: '2000');
  String _serviceType = 'সরেজমিন জমি পরিমাপ ও সীমানা নির্ধারণ';

  final List<MemoRecord> _recentMemos = [
    MemoRecord(
      id: '1',
      clientName: 'মো: আজম মুন্সী',
      phone: '০১৭১১-২২৩৩৪৪',
      mouza: 'মাওনা',
      dagNo: '১২০',
      serviceType: 'বাটোয়ারা ও দাগ বণ্টন',
      totalFee: 6000,
      advancePaid: 6000,
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadMemos();
  }

  @override
  void dispose() {
    _clientCtrl.dispose();
    _phoneCtrl.dispose();
    _mouzaCtrl.dispose();
    _dagCtrl.dispose();
    _totalFeeCtrl.dispose();
    _advanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMemos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final loaded = raw
            .map((e) => MemoRecord.fromMap(jsonDecode(e) as Map<String, dynamic>))
            .toList();
        if (mounted) {
          setState(() {
            _recentMemos
              ..clear()
              ..addAll(loaded);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _persistMemos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = _recentMemos.map((m) => jsonEncode(m.toMap())).toList();
      await prefs.setStringList(_prefsKey, encoded);
    } catch (_) {}
  }

  String _generateMemoText() {
    final total = double.tryParse(_totalFeeCtrl.text) ?? 0;
    final advance = double.tryParse(_advanceCtrl.text) ?? 0;
    final due = total - advance;

    return '''
=====================================================
            সার্ভেয়ার মেমো ও ক্যাশ রসিদ (INVOICE)
=====================================================
রসিদ নং: MEMO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}
তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}

গ্রাহকের নাম: ${_clientCtrl.text}
মোবাইল: ${_phoneCtrl.text}
মৌজা: ${_mouzaCtrl.text} | দাগ নং: ${_dagCtrl.text}
কাজের বিবরণ: $_serviceType
-----------------------------------------------------
মোট নির্ধারিত ফি: ${BanglaFormatter.formatCurrency(total)}
জমা / অগ্রিম পরিশোধ: ${BanglaFormatter.formatCurrency(advance)}
অবশিষ্ট বকেয়া: ${BanglaFormatter.formatCurrency(due)}
-----------------------------------------------------
স্ট্যাটাস: ${due <= 0 ? "পরিশোধিত (PAID)" : "বকেয়া বিদ্যমান"}

আমিন / সার্ভেয়ার স্বাক্ষর ও সিল
BDLandPro - বাংলাদেশ ভূমি জরিপ ও সার্ভেয়ার মেমো
=====================================================
''';
  }

  void _copyMemo() {
    Clipboard.setData(ClipboardData(text: _generateMemoText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('সার্ভেয়ার মেমো ক্লিপবোর্ডে কপি করা হয়েছে!'), backgroundColor: AppColors.primaryGreen),
    );
  }

  Future<void> _printMemoPdf() async {
    final theme = await PdfReportHelper.loadBengaliTheme();
    final pdf = pw.Document(theme: theme);
    final memoText = _generateMemoText();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('BDLandPro - সার্ভেয়ার মেমো ও ক্যাশ রসিদ', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Text(memoText, style: const pw.TextStyle(fontSize: 12, lineSpacing: 3)),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'BDLandPro_Surveyor_Memo.pdf');
  }

  Future<void> _saveMemo() async {
    final total = double.tryParse(_totalFeeCtrl.text) ?? 0;
    final advance = double.tryParse(_advanceCtrl.text) ?? 0;

    setState(() {
      _recentMemos.insert(
        0,
        MemoRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          clientName: _clientCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          mouza: _mouzaCtrl.text.trim(),
          dagNo: _dagCtrl.text.trim(),
          serviceType: _serviceType,
          totalFee: total,
          advancePaid: advance,
          date: DateTime.now(),
        ),
      );
    });
    await _persistMemos();
    await HistoryService.instance.saveItem(
      CalculationHistoryItem(
        id: 'memo_${DateTime.now().millisecondsSinceEpoch}',
        title: 'সার্ভেয়ার মেমো: ${_clientCtrl.text.trim()}',
        category: 'মৌজা ম্যাপ',
        timestamp: DateTime.now(),
        inputSummary: '${_mouzaCtrl.text.trim()} (দাগ ${_dagCtrl.text.trim()}) | $_serviceType',
        resultSummary: 'মোট: ৳${total.toStringAsFixed(0)} | বকেয়া: ৳${(total - advance).toStringAsFixed(0)}',
        fullReportBangla: _generateMemoText(),
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('মেমো স্থায়ীভাবে সংরক্ষণ করা হয়েছে!'), backgroundColor: AppColors.primaryGreen),
    );
  }

  void _loadMemoIntoForm(MemoRecord m) {
    setState(() {
      _clientCtrl.text = m.clientName;
      _phoneCtrl.text = m.phone;
      _mouzaCtrl.text = m.mouza;
      _dagCtrl.text = m.dagNo;
      _totalFeeCtrl.text = m.totalFee.toStringAsFixed(0);
      _advanceCtrl.text = m.advancePaid.toStringAsFixed(0);
      _serviceType = m.serviceType;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${m.clientName}-এর মেমো ফর্মে লোড করা হয়েছে')),
    );
  }

  Future<void> _markAsPaid(int index) async {
    setState(() {
      final m = _recentMemos[index];
      _recentMemos[index] = m.copyWith(advancePaid: m.totalFee);
    });
    await _persistMemos();
  }

  Future<void> _deleteMemo(int index) async {
    setState(() => _recentMemos.removeAt(index));
    await _persistMemos();
  }

  @override
  Widget build(BuildContext context) {
    final total = double.tryParse(_totalFeeCtrl.text) ?? 0;
    final advance = double.tryParse(_advanceCtrl.text) ?? 0;
    final due = total - advance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('সার্ভেয়ার মেমো ও বিল তৈরি'),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf_outlined), tooltip: 'PDF প্রিন্ট', onPressed: _printMemoPdf),
          IconButton(icon: const Icon(Icons.copy), tooltip: 'কপি মেমো', onPressed: _copyMemo),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Bill input form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('গ্রাহক ও কাজের বিবরণ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextField(controller: _clientCtrl, decoration: const InputDecoration(labelText: 'ক্লায়েন্টের নাম')),
                    const SizedBox(height: 10),
                    TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'মোবাইল নং')),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _mouzaCtrl, decoration: const InputDecoration(labelText: 'মৌজা'))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: _dagCtrl, decoration: const InputDecoration(labelText: 'দাগ নং'))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _serviceType,
                      decoration: const InputDecoration(labelText: 'কাজের ধরন / সেবা'),
                      items: const [
                        DropdownMenuItem(value: 'সরেজমিন জমি পরিমাপ ও সীমানা নির্ধারণ', child: Text('জমি পরিমাপ ও সীমানা নির্ধারণ')),
                        DropdownMenuItem(value: 'বাটোয়ারা ও দাগ বণ্টন', child: Text('বাটোয়ারা ও দাগ বণ্টন')),
                        DropdownMenuItem(value: 'মৌজা নকশা ট্রেসিং ও ডিজিটাল অঙ্কন', child: Text('নকশা ট্রেসিং ও ডিজিটাল অঙ্কন')),
                        DropdownMenuItem(value: 'দলিল তফসিল যাচাই ও আদালত কমিশন', child: Text('দলিল তফসিল যাচাই / আদালত কমিশন')),
                      ],
                      onChanged: (val) => setState(() => _serviceType = val!),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _totalFeeCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'মোট বিল (টাকা)'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _advanceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'অগ্রিম জমা (টাকা)'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Due calculation
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: due <= 0 ? AppColors.primaryGreenLight : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('অবশিষ্ট বকেয়া:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            BanglaFormatter.formatCurrency(due),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: due <= 0 ? AppColors.primaryGreenDark : AppColors.accentCrimson,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(onPressed: _saveMemo, icon: const Icon(Icons.bookmark_add), label: const Text('সংরক্ষণ করুন')),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(onPressed: _copyMemo, icon: const Icon(Icons.copy), label: const Text('মেমো কপি করুন')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Recent Invoices List
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('সাম্প্রতিক মেমো ও গ্রাহক খতিয়ান', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 8),

            ..._recentMemos.asMap().entries.map((entry) {
              final idx = entry.key;
              final m = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  onTap: () => _loadMemoIntoForm(m),
                  title: Text('${m.clientName} (${m.phone})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${m.mouza}, দাগ: ${m.dagNo}\n${m.serviceType} | তারিখ: ${BanglaFormatter.formatDateTime(m.date).split(',')[0]}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(BanglaFormatter.formatCurrency(m.totalFee), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                          Text(m.due <= 0 ? 'পরিশোধিত' : 'বকেয়া: ৳ ${BanglaNumerals.toBangla(m.due.toInt())}',
                              style: TextStyle(fontSize: 11, color: m.due <= 0 ? AppColors.primaryGreen : AppColors.accentCrimson)),
                        ],
                      ),
                      const SizedBox(width: 4),
                      if (m.due > 0)
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline, color: AppColors.primaryGreen, size: 20),
                          tooltip: 'পরিশোধিত করুন',
                          onPressed: () => _markAsPaid(idx),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.accentCrimson, size: 20),
                        tooltip: 'মুছুন',
                        onPressed: () => _deleteMemo(idx),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
