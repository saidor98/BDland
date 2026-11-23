import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../02_mouza_simple/mouza_map_simple_screen.dart';
import '../widgets/digital_gunia_scale.dart';

class MouzaDirectoryItem {
  final String division;
  final String district;
  final String upazila;
  final String mouzaName;
  final String jlNo;
  final String surveyType; // CS, SA, RS, BS
  final int totalSheets;
  final int totalPlots;

  const MouzaDirectoryItem({
    required this.division,
    required this.district,
    required this.upazila,
    required this.mouzaName,
    required this.jlNo,
    required this.surveyType,
    required this.totalSheets,
    required this.totalPlots,
  });
}

class AllMouzaMapsScreen extends StatefulWidget {
  const AllMouzaMapsScreen({super.key});

  @override
  State<AllMouzaMapsScreen> createState() => _AllMouzaMapsScreenState();
}

class _AllMouzaMapsScreenState extends State<AllMouzaMapsScreen> {
  String _searchQuery = '';
  String _selectedDivision = 'সকল বিভাগ';

  final List<String> _divisions = [
    'সকল বিভাগ',
    'ঢাকা',
    'চট্টগ্রাম',
    'রাজশাহী',
    'খুলনা',
    'বরিশাল',
    'সিলেট',
    'রংপুর',
    'ময়মনসিংহ',
  ];

  final List<MouzaDirectoryItem> _mouzaList = const [
    MouzaDirectoryItem(
      division: 'ঢাকা',
      district: 'ঢাকা',
      upazila: 'ধানমন্ডি / মোহাম্মদপুর',
      mouzaName: 'জাফরাবাদ',
      jlNo: '১২২',
      surveyType: 'RS / City Survey',
      totalSheets: 4,
      totalPlots: 1250,
    ),
    MouzaDirectoryItem(
      division: 'ঢাকা',
      district: 'গাজীপুর',
      upazila: 'শ্রীপুর',
      mouzaName: 'মাওনা',
      jlNo: '৫৬',
      surveyType: 'RS / BS',
      totalSheets: 6,
      totalPlots: 2400,
    ),
    MouzaDirectoryItem(
      division: 'ঢাকা',
      district: 'নারায়ণগঞ্জ',
      upazila: 'সোনারগাঁ',
      mouzaName: 'আমিনপুর',
      jlNo: '৩৪',
      surveyType: 'CS / RS',
      totalSheets: 3,
      totalPlots: 850,
    ),
    MouzaDirectoryItem(
      division: 'চট্টগ্রাম',
      district: 'চট্টগ্রাম',
      upazila: 'পটিয়া',
      mouzaName: 'কুসুমপুরা',
      jlNo: '৮৯',
      surveyType: 'RS',
      totalSheets: 3,
      totalPlots: 980,
    ),
    MouzaDirectoryItem(
      division: 'চট্টগ্রাম',
      district: 'কুমিল্লা',
      upazila: 'বুড়িচং',
      mouzaName: 'কংশনগর',
      jlNo: '৩৪',
      surveyType: 'SA / RS',
      totalSheets: 5,
      totalPlots: 1600,
    ),
    MouzaDirectoryItem(
      division: 'চট্টগ্রাম',
      district: 'কক্সবাজার',
      upazila: 'রামু',
      mouzaName: 'ফতেখাঁরকুল',
      jlNo: '১২',
      surveyType: 'BS',
      totalSheets: 4,
      totalPlots: 1320,
    ),
    MouzaDirectoryItem(
      division: 'সিলেট',
      district: 'সিলেট',
      upazila: 'গোলাপগঞ্জ',
      mouzaName: 'বাঘা',
      jlNo: '৭৮',
      surveyType: 'CS / RS',
      totalSheets: 4,
      totalPlots: 1100,
    ),
    MouzaDirectoryItem(
      division: 'সিলেট',
      district: 'মৌলভীবাজার',
      upazila: 'শ্রীমঙ্গল',
      mouzaName: 'কালাপুর',
      jlNo: '২৩',
      surveyType: 'CS / SA',
      totalSheets: 3,
      totalPlots: 920,
    ),
    MouzaDirectoryItem(
      division: 'রাজশাহী',
      district: 'বগুড়া',
      upazila: 'শেরপুর',
      mouzaName: 'ভবানীপুর',
      jlNo: '১০২',
      surveyType: 'RS / BS',
      totalSheets: 3,
      totalPlots: 890,
    ),
    MouzaDirectoryItem(
      division: 'রাজশাহী',
      district: 'রাজশাহী',
      upazila: 'পবা',
      mouzaName: 'নওহাটা',
      jlNo: '৪৫',
      surveyType: 'CS / RS',
      totalSheets: 5,
      totalPlots: 1750,
    ),
    MouzaDirectoryItem(
      division: 'খুলনা',
      district: 'যশোর',
      upazila: 'ঝিকরগাছা',
      mouzaName: 'গদখালী',
      jlNo: '৪৫',
      surveyType: 'RS',
      totalSheets: 4,
      totalPlots: 1450,
    ),
    MouzaDirectoryItem(
      division: 'খুলনা',
      district: 'কুষ্টিয়া',
      upazila: 'কুমারখালী',
      mouzaName: 'শিলাইদহ',
      jlNo: '১৬',
      surveyType: 'CS / SA / RS',
      totalSheets: 4,
      totalPlots: 1200,
    ),
    MouzaDirectoryItem(
      division: 'বরিশাল',
      district: 'বরিশাল',
      upazila: 'বাবুগঞ্জ',
      mouzaName: 'রহমতপুর',
      jlNo: '৬৭',
      surveyType: 'SA / RS',
      totalSheets: 3,
      totalPlots: 780,
    ),
    MouzaDirectoryItem(
      division: 'রংপুর',
      district: 'দিনাজপুর',
      upazila: 'বীরগঞ্জ',
      mouzaName: 'সুজালপুর',
      jlNo: '৮১',
      surveyType: 'CS / RS',
      totalSheets: 5,
      totalPlots: 1820,
    ),
    MouzaDirectoryItem(
      division: 'ময়মনসিংহ',
      district: 'ময়মনসিংহ',
      upazila: 'ত্রিশাল',
      mouzaName: 'রামপুর',
      jlNo: '২৯',
      surveyType: 'RS / BS',
      totalSheets: 4,
      totalPlots: 1340,
    ),
  ];

  List<MouzaDirectoryItem> get _filteredList {
    return _mouzaList.where((item) {
      final matchesDiv = _selectedDivision == 'সকল বিভাগ' || item.division == _selectedDivision;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          item.mouzaName.toLowerCase().contains(q) ||
          item.district.toLowerCase().contains(q) ||
          item.upazila.toLowerCase().contains(q) ||
          item.jlNo.contains(q);
      return matchesDiv && matchesSearch;
    }).toList();
  }

  void _openCadastralViewer(MouzaDirectoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CadastralSheetModal(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('সারাদেশের সকল মৌজা ম্যাপ (MouzaMap Hub)'),
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'মৌজার নাম, জেলা, উপজেলা বা জে.এল নং দিয়ে খুঁজুন...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _divisions.map((div) {
                      final isSelected = _selectedDivision == div;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label: Text(div),
                          selected: isSelected,
                          selectedColor: AppColors.primaryGreen,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) => setState(() => _selectedDivision = div),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Total Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.primaryGreenLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'মোট অন্তর্ভুক্ত মৌজা: ${BanglaNumerals.toBangla(_filteredList.length)} টি',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreenDark),
                ),
                const Text(
                  'CS / SA / RS / BS ডিজিটাল জরিপ',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Mouza List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12.0),
              itemCount: _filteredList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final item = _filteredList[idx];
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.map_outlined, color: AppColors.primaryGreen),
                    ),
                    title: Row(
                      children: [
                        Text(
                          item.mouzaName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'JL: ${item.jlNo}',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${item.upazila}, ${item.district} | জরিপ: ${item.surveyType}\nশিট সংখ্যা: ${BanglaNumerals.toBangla(item.totalSheets)} টি | মোট প্লট: ${BanglaNumerals.toBangla(item.totalPlots)} টি',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primaryGreen),
                    onTap: () => _openCadastralViewer(item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CadastralSheetModal extends StatefulWidget {
  final MouzaDirectoryItem item;

  const _CadastralSheetModal({required this.item});

  @override
  State<_CadastralSheetModal> createState() => _CadastralSheetModalState();
}

class _CadastralSheetModalState extends State<_CadastralSheetModal> {
  int _selectedSheetIndex = 1;
  bool _showGunia = false;
  String? _selectedDagInfo;

  void _downloadMapPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('মৌজা: ${widget.item.mouzaName} (জে.এল. নং: ${widget.item.jlNo})',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text('জরিপ: ${widget.item.surveyType} | শিট নং: ${_selectedSheetIndex}'),
                  ],
                ),
              ),
              pw.Text('উপজেলা: ${widget.item.upazila}, জেলা: ${widget.item.district} (${widget.item.division} বিভাগ)'),
              pw.SizedBox(height: 10),
              pw.Expanded(
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.brown),
                    color: PdfColors.amber50,
                  ),
                  child: pw.Center(
                    child: pw.Text('নকশা ড্রয়িং ও ক্যাডাস্ট্রাল প্লট ম্যাপ\n(স্কেল: ১৬ ইঞ্চি = ১ মাইল / গান্টার চেইন)'),
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('বিডি ল্যান্ড প্রো - বাংলাদেশ ভূমি জরিপ ও মৌজা ডিজিটাল আর্কাইভ (mouzamap.tech সমমানের ওপেন প্ল্যাটফর্ম)'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${widget.item.mouzaName}_JL${widget.item.jlNo}_Sheet${_selectedSheetIndex}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'মৌজা: ${widget.item.mouzaName} (জে.এল. ${widget.item.jlNo})',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${widget.item.upazila}, ${widget.item.district} | ${widget.item.surveyType}',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Sheet Selector Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const Text('শিট নির্বাচন: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 6,
                  children: List.generate(widget.item.totalSheets, (i) {
                    final sheetNum = i + 1;
                    final isSel = _selectedSheetIndex == sheetNum;
                    return InkWell(
                      onTap: () => setState(() => _selectedSheetIndex = sheetNum),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primaryGreen : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSel ? AppColors.primaryGreen : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          'শিট ${BanglaNumerals.toBangla(sheetNum)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const Spacer(),
                // Gunia toggle
                FilterChip(
                  label: const Text('গুনিয়া স্কেল', style: TextStyle(fontSize: 11)),
                  selected: _showGunia,
                  selectedColor: Colors.amber.shade200,
                  onSelected: (val) => setState(() => _showGunia = val),
                ),
              ],
            ),
          ),

          // Interactive Map Canvas Area
          Expanded(
            child: Stack(
              children: [
                InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(50),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF6EE),
                        border: Border.all(color: const Color(0xFFC7B299), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _InteractiveMouzaPainter(
                          mouzaName: widget.item.mouzaName,
                          sheetNo: _selectedSheetIndex,
                          jlNo: widget.item.jlNo,
                        ),
                      ),
                    ),
                  ),
                ),

                // Floating Gunia Scale Overlay
                if (_showGunia)
                  DigitalGuniaScale(
                    pixelsPer100Links: 33.0,
                    onClose: () => setState(() => _showGunia = false),
                  ),

                // Selected Dag Floating Banner
                if (_selectedDagInfo != null)
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primaryGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedDagInfo!,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _selectedDagInfo = null),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Action Bar: Measure & Download
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _downloadMapPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('নকশা PDF ডাউনলোড'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MouzaMapSimpleScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.straighten),
                    label: const Text('নকশায় জমি মাপুন'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveMouzaPainter extends CustomPainter {
  final String mouzaName;
  final int sheetNo;
  final String jlNo;

  _InteractiveMouzaPainter({
    required this.mouzaName,
    required this.sheetNo,
    required this.jlNo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Grid
    final gridPaint = Paint()
      ..color = const Color(0xFFE2D6C0)
      ..strokeWidth = 0.8;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Road passing through mouza
    final roadPaint = Paint()
      ..color = const Color(0xFFD1C7B7)
      ..strokeWidth = 26
      ..style = PaintingStyle.stroke;
    final roadPath = Path()
      ..moveTo(0, size.height * 0.45)
      ..cubicTo(size.width * 0.3, size.height * 0.40, size.width * 0.6, size.height * 0.55, size.width, size.height * 0.50);
    canvas.drawPath(roadPath, roadPaint);

    final roadBorderPaint = Paint()
      ..color = const Color(0xFF8C7B65)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawPath(roadPath, roadBorderPaint);

    // 3. Cadastral Plots
    final plotPaint = Paint()
      ..color = const Color(0xFF4A3B2C)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final plots = [
      // Top Left Plots
      [const Offset(30, 40), const Offset(150, 40), const Offset(140, 140), const Offset(30, 130)],
      [const Offset(150, 40), const Offset(280, 40), const Offset(270, 140), const Offset(140, 140)],
      [const Offset(280, 40), const Offset(420, 40), const Offset(400, 140), const Offset(270, 140)],

      // Mid Plots (above road)
      [const Offset(30, 130), const Offset(140, 140), const Offset(130, 210), const Offset(30, 200)],
      [const Offset(140, 140), const Offset(270, 140), const Offset(260, 215), const Offset(130, 210)],
      [const Offset(270, 140), const Offset(400, 140), const Offset(420, 220), const Offset(260, 215)],

      // Bottom Plots (below road)
      [const Offset(40, 260), const Offset(160, 265), const Offset(150, 360), const Offset(40, 350)],
      [const Offset(160, 265), const Offset(290, 275), const Offset(280, 370), const Offset(150, 360)],
      [const Offset(290, 275), const Offset(440, 280), const Offset(430, 375), const Offset(280, 370)],

      // Very Bottom Plots
      [const Offset(40, 350), const Offset(150, 360), const Offset(140, 460), const Offset(40, 450)],
      [const Offset(150, 360), const Offset(280, 370), const Offset(270, 465), const Offset(140, 460)],
      [const Offset(280, 370), const Offset(430, 375), const Offset(420, 470), const Offset(270, 465)],
    ];

    int dagIndex = 101;
    for (final pList in plots) {
      final path = Path()..moveTo(pList[0].dx, pList[0].dy);
      for (int i = 1; i < pList.length; i++) {
        path.lineTo(pList[i].dx, pList[i].dy);
      }
      path.close();
      canvas.drawPath(path, plotPaint);

      // Plot center
      double cx = 0, cy = 0;
      for (final p in pList) {
        cx += p.dx;
        cy += p.dy;
      }
      cx /= pList.length;
      cy /= pList.length;

      _drawText(canvas, 'দাগ ${BanglaNumerals.toBangla(dagIndex)}', Offset(cx - 18, cy - 6), isBold: true);
      dagIndex++;
    }

    // Sheet Title Header on Map
    _drawText(
      canvas,
      'মৌজা: $mouzaName | জে.এল. $jlNo | শিট নং: ${BanglaNumerals.toBangla(sheetNo)} (স্কেল: ১৬" = ১ মাইল)',
      const Offset(50, 16),
      isBold: true,
      color: const Color(0xFF78350F),
    );

    // North Indicator
    final northPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(460, 60), const Offset(460, 20), northPaint);
    canvas.drawLine(const Offset(460, 20), const Offset(454, 30), northPaint);
    canvas.drawLine(const Offset(460, 20), const Offset(466, 30), northPaint);
    _drawText(canvas, 'উঃ (N)', const Offset(450, 62), isBold: true);
  }

  void _drawText(Canvas canvas, String text, Offset pos, {bool isBold = false, Color color = const Color(0xFF4A3B2C)}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 10, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _InteractiveMouzaPainter oldDelegate) =>
      oldDelegate.mouzaName != mouzaName || oldDelegate.sheetNo != sheetNo;
}
