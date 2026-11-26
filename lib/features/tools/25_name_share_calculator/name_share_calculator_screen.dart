import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/services/history_service.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../../core/utils/pdf_report_helper.dart';
import '../../history/models/calculation_history_item.dart';
import 'name_share_model.dart';

class NameShareCalculatorScreen extends StatefulWidget {
  const NameShareCalculatorScreen({super.key});

  @override
  State<NameShareCalculatorScreen> createState() => _NameShareCalculatorScreenState();
}

class _NameShareCalculatorScreenState extends State<NameShareCalculatorScreen> {
  static const String _prefsKey = 'bdland_name_share_entries_v1';

  String _surveyType = 'RS / BRS খতিয়ান';
  final _mouzaCtrl = TextEditingController(text: 'জাফরাবাদ');
  final _khatianNoCtrl = TextEditingController(text: '১০৫');
  final _totalLandCtrl = TextEditingController(text: '100.0');
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  List<NameShareEntry> _entries = [
    const NameShareEntry(
      id: 'init_1',
      name: 'মো: আব্দুর রহমান',
      guardianName: 'মৃত: ফজলুর রহমান',
      roleLabel: 'খতিয়ান মালিক',
      shareFraction: 0.5000,
      inputMode: ShareInputMode.decimal,
      inputSummaryText: '০.৫০০০',
    ),
    const NameShareEntry(
      id: 'init_2',
      name: 'মোছা: আয়েশা বেগম',
      guardianName: 'স্বামী: আব্দুর রহমান',
      roleLabel: 'ওয়ারিশ / সহ-শরিক',
      shareFraction: 0.2500,
      inputMode: ShareInputMode.namjari1000,
      inputSummaryText: '২৫০/১০০০',
    ),
    const NameShareEntry(
      id: 'init_3',
      name: 'মো: সাইফুল ইসলাম',
      guardianName: 'পিতা: আব্দুর রহমান',
      roleLabel: 'ক্রেতা / নামজারি',
      shareFraction: 0.2500,
      inputMode: ShareInputMode.fraction,
      inputSummaryText: '১/৪ অংশ',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedEntries();
  }

  @override
  void dispose() {
    _mouzaCtrl.dispose();
    _khatianNoCtrl.dispose();
    _totalLandCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  double get _totalLandDec => (double.tryParse(_totalLandCtrl.text.trim()) ?? 0.0).clamp(0.0, 1000000.0);

  Future<void> _loadSavedEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefsKey);
      if (raw != null && raw.isNotEmpty && mounted) {
        final decoded = raw
            .map((s) => NameShareEntry.fromMap(jsonDecode(s) as Map<String, dynamic>))
            .toList();
        setState(() => _entries = decoded);
      }
    } catch (_) {}
  }

  Future<void> _persistEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _entries.map((e) => jsonEncode(e.toMap())).toList());
    } catch (_) {}
  }

  void _openAddOrEditDialog({int? editIndex, double? prefillRemainingShare}) {
    final existing = editIndex != null ? _entries[editIndex] : null;
    final audit = NameShareCalculatorLogic.summarizeShares(_entries);

    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final guardianCtrl = TextEditingController(text: existing?.guardianName ?? '');
    final dagCtrl = TextEditingController(text: existing?.dagNo ?? '');
    String roleLabel = existing?.roleLabel ?? 'খতিয়ান মালিক';

    ShareInputMode mode = existing?.inputMode ?? ShareInputMode.decimal;
    final initialFrac = prefillRemainingShare ?? existing?.shareFraction ?? (audit.remainingShare > 0.001 ? audit.remainingShare : 0.1250);

    final decimalCtrl = TextEditingController(text: initialFrac.toStringAsFixed(4));
    final namjariCtrl = TextEditingController(text: (initialFrac * 1000).round().toString());
    final numCtrl = TextEditingController(text: '1');
    final denCtrl = TextEditingController(text: '4');

    final anaInit = existing?.anaGonda;
    final anaCtrl = TextEditingController(text: (anaInit?.ana ?? 2).toString());
    final gondaCtrl = TextEditingController(text: (anaInit?.gonda ?? 0).toString());
    final koraCtrl = TextEditingController(text: (anaInit?.kora ?? 0).toString());
    final krantiCtrl = TextEditingController(text: (anaInit?.kranti ?? 0).toString());
    final tilCtrl = TextEditingController(text: (anaInit?.til ?? 0).toString());

    String? inlineError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final parsed = NameShareCalculatorLogic.parseShareInput(
            mode: mode,
            decimalText: decimalCtrl.text,
            namjariText: namjariCtrl.text,
            numeratorText: numCtrl.text,
            denominatorText: denCtrl.text,
            ana: int.tryParse(anaCtrl.text.trim()) ?? 0,
            gonda: int.tryParse(gondaCtrl.text.trim()) ?? 0,
            kora: int.tryParse(koraCtrl.text.trim()) ?? 0,
            kranti: int.tryParse(krantiCtrl.text.trim()) ?? 0,
            til: int.tryParse(tilCtrl.text.trim()) ?? 0,
          );

          final previewFrac = parsed.shareFraction ?? 0.0;
          final previewDec = _totalLandDec * previewFrac;
          final previewKatha = (previewDec * 435.60) / 720.0;

          return Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, MediaQuery.of(context).viewInsets.bottom + 18),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    existing == null ? 'নতুন নামের অংশ যোগ করুন' : 'মালিকের নাম ও অংশ সম্পাদনা',
                    style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'মালিক / অংশীদারের নাম *',
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryGreen),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: guardianCtrl,
                          decoration: const InputDecoration(labelText: 'পিতা / স্বামীর নাম (ঐচ্ছিক)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: roleLabel,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'মালিকানার ধরন'),
                          items: const [
                            DropdownMenuItem(value: 'খতিয়ান মালিক', child: Text('খতিয়ান মালিক', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'ওয়ারিশ / সহ-শরিক', child: Text('ওয়ারিশ / সহ-শরিক', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'ক্রেতা / নামজারি', child: Text('ক্রেতা / নামজারি', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'সমান অংশীদার', child: Text('সমান অংশীদার', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (v) {
                            if (v != null) setModalState(() => roleLabel = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: dagCtrl,
                    decoration: const InputDecoration(labelText: 'দাগ নং (ঐচ্ছিক, যেমন: ৫০১)'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('অংশ লেখার পদ্ধতি:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      if (audit.remainingShare > 0.0005 && existing == null)
                        ActionChip(
                          avatar: const Icon(Icons.auto_fix_high, size: 14, color: AppColors.primaryGreen),
                          label: Text(
                            'বাকি ${audit.remainingShare.toStringAsFixed(4)} বসান',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                          ),
                          backgroundColor: AppColors.primaryGreenLight,
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            setModalState(() {
                              mode = ShareInputMode.decimal;
                              decimalCtrl.text = audit.remainingShare.toStringAsFixed(4);
                              inlineError = null;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _modeChip('দশমিক (০.২৫)', ShareInputMode.decimal, mode, (m) => setModalState(() => mode = m)),
                      _modeChip('নামজারি (১০০০)', ShareInputMode.namjari1000, mode, (m) => setModalState(() => mode = m)),
                      _modeChip('ভগ্নাংশ (১/৪)', ShareInputMode.fraction, mode, (m) => setModalState(() => mode = m)),
                      _modeChip('আনা-গণ্ডা-তিল', ShareInputMode.anaGonda, mode, (m) => setModalState(() => mode = m)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (mode == ShareInputMode.decimal)
                    TextField(
                      controller: decimalCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'দশমিক অংশ (০.০০০১ থেকে ১.০০০০)'),
                      onChanged: (_) => setModalState(() => inlineError = null),
                    )
                  else if (mode == ShareInputMode.namjari1000)
                    TextField(
                      controller: namjariCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'নামজারি অংশ (১০০০ স্কেলে, যেমন ২৫০)'),
                      onChanged: (_) => setModalState(() => inlineError = null),
                    )
                  else if (mode == ShareInputMode.fraction)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: numCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'লব (যেমন: ১)'),
                            onChanged: (_) => setModalState(() => inlineError = null),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('/', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: denCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'হর (যেমন: ৪)'),
                            onChanged: (_) => setModalState(() => inlineError = null),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _numBox('আনা (০-১৬)', anaCtrl, () => setModalState(() {}))),
                            const SizedBox(width: 6),
                            Expanded(child: _numBox('গণ্ডা (০-১৯)', gondaCtrl, () => setModalState(() {}))),
                            const SizedBox(width: 6),
                            Expanded(child: _numBox('কড়া (০-৩)', koraCtrl, () => setModalState(() {}))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _numBox('ক্রান্তি (০-২)', krantiCtrl, () => setModalState(() {}))),
                            const SizedBox(width: 8),
                            Expanded(child: _numBox('তিল (০-১৯)', tilCtrl, () => setModalState(() {}))),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  if (inlineError != null || !parsed.isValid)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFFFDAD6), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        inlineError ?? parsed.errorBangla ?? '',
                        style: const TextStyle(color: Color(0xFF93000A), fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'হিস্যা: ${(previewFrac * 100).toStringAsFixed(2)}% (${(previewFrac * 1000).round()}/১০০০)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                          ),
                          Text(
                            'জমি: ${BanglaFormatter.formatNumber(previewDec, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(previewKatha, fractionDigits: 2)} কাঠা)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondaryGoldDark),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(existing == null ? Icons.person_add : Icons.check_circle_outline),
                      label: Text(existing == null ? 'নামের অংশ যোগ করুন' : 'তথ্য আপডেট করুন'),
                      onPressed: () {
                        final ownerName = nameCtrl.text.trim();
                        if (ownerName.isEmpty) {
                          setModalState(() => inlineError = 'অনুগ্রহ করে মালিক বা অংশীদারের নাম লিখুন।');
                          return;
                        }
                        if (!parsed.isValid || parsed.shareFraction == null) {
                          setModalState(() => inlineError = parsed.errorBangla ?? 'সঠিক অংশ দিন।');
                          return;
                        }
                        final updated = NameShareEntry(
                          id: existing?.id ?? 'name_${DateTime.now().microsecondsSinceEpoch}',
                          name: ownerName,
                          guardianName: guardianCtrl.text.trim(),
                          roleLabel: roleLabel,
                          dagNo: dagCtrl.text.trim(),
                          shareFraction: parsed.shareFraction!,
                          inputMode: mode,
                          inputSummaryText: parsed.normalizedLabel,
                        );
                        setState(() {
                          if (editIndex != null) {
                            _entries = [
                              ..._entries.sublist(0, editIndex),
                              updated,
                              ..._entries.sublist(editIndex + 1),
                            ];
                          } else {
                            _entries = [..._entries, updated];
                          }
                        });
                        _persistEntries();
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _modeChip(String label, ShareInputMode value, ShareInputMode active, ValueChanged<ShareInputMode> onTap) {
    final isSel = value == active;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600)),
      selected: isSel,
      selectedColor: AppColors.primaryGreen,
      backgroundColor: AppColors.surfaceContainer,
      visualDensity: VisualDensity.compact,
      onSelected: (_) => onTap(value),
    );
  }

  Widget _numBox(String label, TextEditingController ctrl, VoidCallback onUpdate) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, isDense: true),
      onChanged: (_) => onUpdate(),
    );
  }

  void _openEqualSplitDialog() {
    final namesCtrl = TextEditingController(text: 'ক. করিম\nখ. রহিম\nগ. সেলিম\nঘ. জব্বার');
    final fractionCtrl = TextEditingController(text: '1.0000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.groups_outlined, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Flexible(child: Text('একাধিক নামে সম-বণ্টন', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('প্রতি লাইনে বা কমা (,) দিয়ে অংশীদারদের নাম লিখুন:', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: namesCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'নামের তালিকা'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: fractionCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'বণ্টনযোগ্য মোট অংশ (পূর্ণ খতিয়ান = ১.০০০০)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () {
              final rawNames = namesCtrl.text
                  .split(RegExp(r'[\n,]+'))
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              final frac = (double.tryParse(fractionCtrl.text.trim()) ?? 1.0).clamp(0.0001, 1.0);
              if (rawNames.isEmpty) return;

              final generated = NameShareCalculatorLogic.distributeEqually(
                ownerNames: rawNames,
                totalFraction: frac,
              );
              setState(() => _entries = generated);
              _persistEntries();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${BanglaNumerals.toBangla(generated.length)} জনের নামে সমান অংশ বণ্টিত হয়েছে!'),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
            },
            child: const Text('সম-বণ্টন করুন'),
          ),
        ],
      ),
    );
  }

  String _buildFullReport() {
    final totalDec = _totalLandDec;
    final audit = NameShareCalculatorLogic.summarizeShares(_entries);
    final sb = StringBuffer();
    sb.writeln('=== নামের অংশ ও খতিয়ান হিস্যা বিবরণী ===');
    sb.writeln('তারিখ: ${BanglaFormatter.formatDateTime(DateTime.now())}');
    sb.writeln('জরিপ: $_surveyType | মৌজা: ${_mouzaCtrl.text} | খতিয়ান নং: ${_khatianNoCtrl.text}');
    sb.writeln('মোট জমি: ${BanglaFormatter.formatNumber(totalDec, fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber((totalDec * 435.60) / 720.0, fractionDigits: 2)} কাঠা)\n');

    for (int i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      sb.writeln('${BanglaNumerals.toBangla(i + 1)}. ${e.name}${e.guardianName.isNotEmpty ? ' (${e.guardianName})' : ''} [${e.roleLabel}]');
      sb.writeln('   অংশ: ${e.shareFraction.toStringAsFixed(6)} | ${e.anaGonda.toBanglaText()} | ${BanglaNumerals.toBangla(e.namjari1000)}/১০০০ (${BanglaFormatter.formatPercentage(e.percentage)})');
      sb.writeln('   প্রাপ্ত জমি: ${BanglaFormatter.formatNumber(e.landDecimal(totalDec), fractionDigits: 3)} শতক (${BanglaFormatter.formatNumber(e.landKatha(totalDec), fractionDigits: 2)} কাঠা | ${BanglaFormatter.formatNumber(e.landSqFt(totalDec), fractionDigits: 1)} sq ft)\n');
    }
    sb.writeln('----------------------------------------');
    sb.writeln('মোট বরাদ্দ অংশ: ${audit.totalShare.toStringAsFixed(6)} (${BanglaNumerals.toBangla(audit.totalNamjari1000)}/১০০০)');
    sb.writeln(audit.isExact16Ana
        ? 'স্ট্যাটাস: ১৬ আনা (১.০০০০) সম্পূর্ণ সঠিক।'
        : audit.hasExcess
            ? 'সতর্কতা: ১.০০০০ এর চেয়ে ${audit.excessShare.toStringAsFixed(4)} অংশ বেশি হয়েছে!'
            : 'অবশিষ্ট অংশ: ${audit.remainingShare.toStringAsFixed(4)}');
    sb.writeln('অ্যাপ: BDLandPro - বাংলাদেশ ভূমি জরিপ ও খতিয়ান সিস্টেম');
    return sb.toString();
  }

  Future<void> _saveToHistory() async {
    final audit = NameShareCalculatorLogic.summarizeShares(_entries);
    await HistoryService.instance.saveItem(
      CalculationHistoryItem(
        id: 'nameshare_${DateTime.now().millisecondsSinceEpoch}',
        title: 'নামের অংশ: ${_mouzaCtrl.text} (খতিয়ান ${_khatianNoCtrl.text})',
        category: 'খতিয়ান',
        timestamp: DateTime.now(),
        inputSummary: '${BanglaNumerals.toBangla(_entries.length)} জন মালিক | মোট ${BanglaFormatter.formatNumber(_totalLandDec, fractionDigits: 2)} শতক',
        resultSummary: 'মোট অংশ: ${audit.totalShare.toStringAsFixed(4)} (${BanglaNumerals.toBangla(audit.totalNamjari1000)}/১০০০)',
        fullReportBangla: _buildFullReport(),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('নামের অংশ হিসাব ইতিহাসে সংরক্ষণ করা হয়েছে!'), backgroundColor: AppColors.primaryGreen),
    );
  }

  Future<void> _printPdf() async {
    final totalDec = _totalLandDec;
    final audit = NameShareCalculatorLogic.summarizeShares(_entries);
    final esc = PdfReportHelper.escapeHtml;

    final rowsHtml = _entries.asMap().entries.map((item) {
      final idx = item.key + 1;
      final e = item.value;
      return '''
      <tr>
        <td>${esc(BanglaNumerals.toBangla(idx))}</td>
        <td>
          <strong>${esc(e.name)}</strong>
          ${e.guardianName.isNotEmpty ? '<br><small>${esc(e.guardianName)}</small>' : ''}
          <br><small style="color:#404942">${esc(e.roleLabel)}${e.dagNo.isNotEmpty ? ' • দাগ ${esc(e.dagNo)}' : ''}</small>
        </td>
        <td>
          <strong>${e.shareFraction.toStringAsFixed(4)}</strong><br>
          <small>${esc(e.anaGonda.toBanglaText())}</small><br>
          <small>${esc(BanglaNumerals.toBangla(e.namjari1000))}/১০০০ (${esc(BanglaFormatter.formatPercentage(e.percentage))})</small>
        </td>
        <td>
          <strong>${esc(BanglaFormatter.formatNumber(e.landDecimal(totalDec), fractionDigits: 3))} শতক</strong><br>
          <small>${esc(BanglaFormatter.formatNumber(e.landKatha(totalDec), fractionDigits: 2))} কাঠা • ${esc(BanglaFormatter.formatNumber(e.landSqFt(totalDec), fractionDigits: 1))} ft²</small>
        </td>
      </tr>''';
    }).join();

    final statusHtml = audit.isExact16Ana
        ? '<span class="status-paid">১৬ আনা (১.০০০০) পূর্ণ সঠিক</span>'
        : audit.hasExcess
            ? '<span class="status-due">সতর্কতা: ১.০০০০ অতিক্রম (${audit.excessShare.toStringAsFixed(4)})</span>'
            : '<span class="status-due">অবশিষ্ট বাকি: ${audit.remainingShare.toStringAsFixed(4)}</span>';

    final bodyHtml = '''
      <div class="kpi-grid">
        <div class="kpi-box"><div class="kpi-label">মোট জমি</div><div class="kpi-val">${esc(BanglaFormatter.formatNumber(totalDec, fractionDigits: 2))} শতক</div></div>
        <div class="kpi-box"><div class="kpi-label">মোট অংশীদার</div><div class="kpi-val">${esc(BanglaNumerals.toBangla(_entries.length))} জন</div></div>
        <div class="kpi-box"><div class="kpi-label">মোট বরাদ্দ হিস্যা</div><div class="kpi-val">${audit.totalShare.toStringAsFixed(4)} (${esc(BanglaNumerals.toBangla(audit.totalNamjari1000))}/১০০০)</div></div>
      </div>

      <div class="info-panel">
        <strong>জরিপ ও খতিয়ান:</strong> ${esc(_surveyType)} • মৌজা: ${esc(_mouzaCtrl.text)} • খতিয়ান নং: ${esc(_khatianNoCtrl.text)} • <strong>অডিট:</strong> $statusHtml
      </div>

      <h3 class="section-title">মালিকের নাম অনুযায়ী অংশ ও জমির বিবরণী</h3>
      <table>
        <tr>
          <th style="width:7%">ক্রম</th>
          <th style="width:33%">মালিক ও পিতা/স্বামীর নাম</th>
          <th style="width:30%">হিস্যা (দশমিক / আনা-গণ্ডা / ১০০০)</th>
          <th style="width:30%">প্রাপ্ত জমির পরিমাণ</th>
        </tr>
        $rowsHtml
      </table>
    ''';

    final html = PdfReportHelper.buildCadastralHtmlDocument(
      title: 'নামের অংশ ও খতিয়ান হিস্যা বিবরণী',
      subtitle: 'মৌজা: ${_mouzaCtrl.text} • খতিয়ান #${_khatianNoCtrl.text} • $_surveyType',
      badgeText: '${BanglaNumerals.toBangla(_entries.length)} জন মালিক',
      bodyHtml: bodyHtml,
    );

    await PdfReportHelper.printHtmlPdf(
      html: html,
      jobName: 'BDLandPro_Name_Share_${_khatianNoCtrl.text}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalDec = _totalLandDec;
    final audit = NameShareCalculatorLogic.summarizeShares(_entries);
    final filteredEntries = NameShareCalculatorLogic.filterEntries(_entries, _searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: const Text('নামের অংশ ক্যালকুলেটর'),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf_outlined), tooltip: 'A4 PDF প্রিন্ট', onPressed: _entries.isNotEmpty ? _printPdf : null),
          IconButton(icon: const Icon(Icons.bookmark_add_outlined), tooltip: 'ইতিহাসে সেভ', onPressed: _entries.isNotEmpty ? _saveToHistory : null),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'রিপোর্ট কপি',
            onPressed: _entries.isNotEmpty
                ? () {
                    Clipboard.setData(ClipboardData(text: _buildFullReport()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('নামের অংশ বিবরণী ক্লিপবোর্ডে কপি হয়েছে!'), backgroundColor: AppColors.primaryGreen),
                    );
                  }
                : null,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // 1. Dark Slate Cadastral Audit Telemetry Deck (Stitch Design)
          _buildAuditInstrumentDeck(audit, totalDec),
          const SizedBox(height: 14),

          // 2. Khatian & Plot Total Land Inputs
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _surveyType,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'খতিয়ানের ধরন'),
                          items: const [
                            DropdownMenuItem(value: 'RS / BRS খতিয়ান', child: Text('RS / BRS খতিয়ান', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'CS খতিয়ান', child: Text('CS খতিয়ান', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'SA খতিয়ান', child: Text('SA খতিয়ান', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'BS / সিটি জরিপ', child: Text('BS / সিটি জরিপ', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _surveyType = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _khatianNoCtrl,
                          decoration: const InputDecoration(labelText: 'খতিয়ান নং'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _mouzaCtrl,
                          decoration: const InputDecoration(labelText: 'মৌজার নাম'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _totalLandCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'মোট জমি (শতক)'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Name Search Bar
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'মালিক, পিতা/স্বামী বা দাগ নং দিয়ে খুঁজুন...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 12),

          // 4. Owner Name Cards
          if (filteredEntries.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  const Icon(Icons.person_search_outlined, size: 40, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text(
                    _entries.isEmpty ? 'এখনো কোনো নামের অংশ যোগ করা হয়নি' : 'খোঁজা নামের সাথে কোনো অংশীদার মেলেনি',
                    style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          else
            ...filteredEntries.map((entry) {
              final realIdx = _entries.indexOf(entry);
              return _buildOwnerLedgerCard(entry, realIdx, totalDec);
            }),

          const SizedBox(height: 70),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        onPressed: () => _openAddOrEditDialog(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('নাম ও অংশ যোগ', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAuditInstrumentDeck(ShareAuditSummary audit, double totalDec) {
    final statusBg = audit.hasExcess
        ? const Color(0xFF93000A)
        : (audit.isExact16Ana ? const Color(0xFF0F5A38) : const Color(0xFF7A5900));
    final statusLabel = audit.hasExcess
        ? 'সতর্কতা: +${audit.excessShare.toStringAsFixed(4)} বেশি'
        : (audit.isExact16Ana ? '১৬ আনা পূর্ণ সঠিক' : 'বাকি: ${audit.remainingShare.toStringAsFixed(4)}');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentNavy,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.14), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.badge_outlined, size: 18, color: AppColors.secondaryGoldLight),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'খতিয়ান হিস্যা অডিট (১.০০০০ / ১০০০)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                child: Text(statusLabel, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _deckMetricTile('মোট অংশ', audit.totalShare.toStringAsFixed(4), 'দশমিক (১.০০০০)', const Color(0xFF34D399)),
              const SizedBox(width: 8),
              _deckMetricTile('নামজারি স্কেল', '${BanglaNumerals.toBangla(audit.totalNamjari1000)}/১০০০', 'হাজার স্কেল', const Color(0xFFF6BE45)),
              const SizedBox(width: 8),
              _deckMetricTile('মোট মালিক', BanglaNumerals.toBangla(_entries.length), '${BanglaFormatter.formatNumber(totalDec, fractionDigits: 1)} শতক', const Color(0xFF93CCFF)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5A38),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _openAddOrEditDialog(),
                  icon: const Icon(Icons.person_add_outlined, size: 15),
                  label: const Text('+ নাম যোগ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _openEqualSplitDialog,
                  icon: const Icon(Icons.groups_outlined, size: 15),
                  label: const Text('সম-বণ্টন', style: TextStyle(fontSize: 11.5)),
                ),
              ),
              if (audit.remainingShare > 0.0005 && !audit.hasExcess) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryGoldDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _openAddOrEditDialog(prefillRemainingShare: audit.remainingShare),
                    icon: const Icon(Icons.pie_chart_outline, size: 15),
                    label: const Text('বাকি অংশ', style: TextStyle(fontSize: 11.5)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _deckMetricTile(String title, String val, String sub, Color valColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        decoration: BoxDecoration(color: const Color(0xFF0F172A).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
            const SizedBox(height: 2),
            Text(val, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valColor)),
            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerLedgerCard(NameShareEntry e, int index, double totalDec) {
    final allocDec = e.landDecimal(totalDec);
    final allocKatha = e.landKatha(totalDec);
    final allocSqFt = e.landSqFt(totalDec);
    final allocBigha = e.landBigha(totalDec);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4.5, color: AppColors.accentGold),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(6)),
                          child: Text(BanglaNumerals.toBangla(index + 1), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              if (e.guardianName.isNotEmpty)
                                Text(e.guardianName, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(6)),
                          child: Text(e.roleLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryGreen)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Text('দশমিক: ${e.shareFraction.toStringAsFixed(4)}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                          Text('আনা-গণ্ডা: ${e.anaGonda.toBanglaText()}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          Text('নামজারি: ${BanglaNumerals.toBangla(e.namjari1000)}/১০০০', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.secondaryGoldDark)),
                          Text('(${BanglaFormatter.formatPercentage(e.percentage)})', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.primaryGreenLight, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${BanglaFormatter.formatNumber(allocDec, fractionDigits: 3)} শতক',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGreenDark),
                              ),
                              Text(
                                '${BanglaFormatter.formatNumber(allocKatha, fractionDigits: 2)} কাঠা • ${BanglaFormatter.formatNumber(allocBigha, fractionDigits: 3)} বিঘা',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primaryGreen),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'বর্গফুট: ${BanglaFormatter.formatNumber(allocSqFt, fractionDigits: 1)} ft² (${BanglaFormatter.formatLandBreakdown(allocSqFt)})',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            final msg = '${e.name}: অংশ ${e.shareFraction.toStringAsFixed(4)} (${e.anaGonda.toBanglaText()} | ${BanglaNumerals.toBangla(e.namjari1000)}/১০০০) = ${BanglaFormatter.formatNumber(allocDec, fractionDigits: 3)} শতক';
                            Clipboard.setData(ClipboardData(text: msg));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${e.name}-এর অংশ কপি হয়েছে!'), duration: const Duration(seconds: 1)),
                            );
                          },
                          icon: const Icon(Icons.copy_outlined, size: 15),
                          label: const Text('কপি', style: TextStyle(fontSize: 11.5)),
                        ),
                        TextButton.icon(
                          onPressed: () => _openAddOrEditDialog(editIndex: index),
                          icon: const Icon(Icons.edit_outlined, size: 15),
                          label: const Text('সম্পাদনা', style: TextStyle(fontSize: 11.5)),
                        ),
                        if (_entries.length > 1)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _entries = [..._entries]..removeAt(index);
                              });
                              _persistEntries();
                            },
                            icon: const Icon(Icons.delete_outline, size: 15, color: AppColors.accentCrimson),
                            label: const Text('মুছুন', style: TextStyle(fontSize: 11.5, color: AppColors.accentCrimson)),
                          ),
                      ],
                    ),
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
