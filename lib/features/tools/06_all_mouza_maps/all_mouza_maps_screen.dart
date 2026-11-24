import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/services/mouza_cloud_service.dart';
import '../02_mouza_simple/mouza_map_simple_screen.dart';
import '../widgets/digital_gunia_scale.dart';

class MouzaDirectoryItem {
  final String division;
  final String district;
  final String upazila;
  final String mouzaName;
  final String jlNo;
  final String surveyType; // CS, SA, RS, BS, City
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
  // Page 3 Tab & Source States
  int _activeTopTab = 0; // 0: সকল ম্যাপ, 1: প্রিয় ম্যাপ, 2: সেভ ম্যাপ
  int _activeSource = 1; // 1: সোর্স ১ (free.mouzamap.tech), 2: সোর্স ২, 3: সোর্স ৩

  int _selectedDriveIndex = 0; // 0: Dhaka
  String _currentDivisionName = 'ঢাকা';
  String _currentPath = '';
  final List<String> _pathHistory = [];

  bool _isLoading = false;
  List<MouzaCloudItem> _cloudItems = [];
  String _searchQuery = '';

  final MouzaCloudService _cloudService = MouzaCloudService();

  // Static fallback catalog for high-speed offline search
  static const List<MouzaDirectoryItem> mouzaCatalog = [
    MouzaDirectoryItem(
      division: 'ঢাকা',
      district: 'ঢাকা',
      upazila: 'ধানমন্ডি',
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

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  Future<void> _loadDirectory() async {
    setState(() => _isLoading = true);
    final items = await _cloudService.fetchDirectory(
      driveIndex: _selectedDriveIndex,
      path: _currentPath,
    );
    if (mounted) {
      setState(() {
        _cloudItems = items;
        _isLoading = false;
      });
    }
  }

  void _onDivisionSelected(Map<String, dynamic> div) {
    setState(() {
      _selectedDriveIndex = div['drive'] as int;
      _currentDivisionName = div['name'] as String;
      _currentPath = '';
      _pathHistory.clear();
      _searchQuery = '';
    });
    _loadDirectory();
  }

  void _onItemTapped(MouzaCloudItem item) {
    if (item.isFolder) {
      setState(() {
        _pathHistory.add(_currentPath);
        _currentPath = item.path;
      });
      _loadDirectory();
    } else {
      // It's a real mouza map PDF sheet! Open the Cadastral Sheet Viewer
      _openCadastralViewerFromCloud(item);
    }
  }

  void _navigateBackPath() {
    if (_pathHistory.isNotEmpty) {
      setState(() {
        _currentPath = _pathHistory.removeLast();
      });
      _loadDirectory();
    } else if (_currentPath.isNotEmpty) {
      setState(() {
        _currentPath = '';
      });
      _loadDirectory();
    }
  }

  void _openCadastralViewerFromCloud(MouzaCloudItem file) {
    // Extract sheet and mouza name from file title
    final cleanName = file.name
        .replaceAll(' - (www.mouzamap.tech).jpg', '')
        .replaceAll(' - (www.mouzamap.tech).pdf', '')
        .replaceAll('.jpg', '')
        .replaceAll('.pdf', '')
        .replaceAll('_result_result', '');

    final pathParts = _currentPath.split('/');
    final district = pathParts.isNotEmpty && pathParts[0].isNotEmpty ? pathParts[0] : 'ঢাকা';
    final upazila = pathParts.length > 1 && pathParts[1].isNotEmpty ? pathParts[1] : 'সদর';

    final item = MouzaDirectoryItem(
      division: _currentDivisionName,
      district: district,
      upazila: upazila,
      mouzaName: cleanName,
      jlNo: '৩৪',
      surveyType: _currentPath.contains('RS') ? 'RS' : (_currentPath.contains('CS') ? 'CS' : 'CS / RS'),
      totalSheets: 3,
      totalPlots: 850,
    );

    _openCadastralViewer(item, cloudItem: file);
  }

  void _openCadastralViewer(MouzaDirectoryItem item, {MouzaCloudItem? cloudItem}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CadastralSheetModal(item: item, cloudItem: cloudItem),
    );
  }

  IconData _getDivisionIcon(String iconKey) {
    switch (iconKey) {
      case 'building':
        return Icons.apartment;
      case 'ship':
        return Icons.directions_boat;
      case 'forest':
        return Icons.park;
      case 'eco':
        return Icons.eco;
      case 'waves':
        return Icons.waves;
      case 'landscape':
        return Icons.terrain;
      case 'agriculture':
        return Icons.agriculture;
      case 'grass':
        return Icons.yard;
      default:
        return Icons.map;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _cloudItems.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep dark theme matching Page 3
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B21A8), // Purple header matching Page 3
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'মৌজা ম্যাপ',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'সারাদেশের সকল মৌজা ম্যাপ (free.mouzamap.tech)',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            tooltip: 'সাহায্য',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('মৌজা ম্যাপ সংগ্রহ ও ব্যবহার'),
                  content: const Text('১. আপনার বিভাগ নির্বাচন করুন।\n২. জেলা ও উপজেলা ফোল্ডারে প্রবেশ করে আপনার কাঙ্ক্ষিত মৌজা শিট নির্বাচন করুন।\n৩. "নকশায় জমি মাপুন" বাটনে চাপ দিয়ে সরাসরি CAD পরিমাপে যান।'),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বুঝেছি'))],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_fill, color: Colors.redAccent),
            tooltip: 'ভিডিও গাইড',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('মৌজা ম্যাপ ব্যবহারের পূর্ণাঙ্গ ভিডিও টিউটোরিয়াল চালু হচ্ছে...')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. TOP TABS: সকল ম্যাপ | প্রিয় ম্যাপ | সেভ ম্যাপ (Matching Page 3)
          Container(
            color: const Color(0xFF6B21A8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildTopTabItem(0, 'সকল ম্যাপ', Icons.folder_copy_outlined),
                const SizedBox(width: 8),
                _buildTopTabItem(1, 'প্রিয় ম্যাপ', Icons.favorite_border),
                const SizedBox(width: 8),
                _buildTopTabItem(2, 'সেভ ম্যাপ', Icons.bookmark_border),
              ],
            ),
          ),

          // 2. SOURCE PILLS: সোর্স ১ | সোর্স ২ | সোর্স ৩ (Matching Page 3)
          Container(
            color: const Color(0xFF1E1B4B),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildSourcePill(1, 'সোর্স ১', Icons.auto_stories),
                const SizedBox(width: 8),
                _buildSourcePill(2, 'সোর্স ২', Icons.cloud_outlined),
                const SizedBox(width: 8),
                _buildSourcePill(3, 'সোর্স ৩', Icons.public),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                // OFFLINE BUNDLED MAPS SECTION (Free.mouzamap.tech high-res scanned sheets)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0x4D0F5A38),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.offline_pin, color: Color(0xFF4ADE80), size: 18),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'অফলাইনে সংরক্ষিত আসল মৌজা শিট',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14532D),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ফুল HD স্ক্যান',
                              style: TextStyle(color: Color(0xFF86EFAC), fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...MouzaCloudService.bundledMaps.map((mapInfo) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444), size: 28),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mapInfo['title'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${mapInfo['district']} • ${mapInfo['survey']} • সাইজ: ${mapInfo['size']}',
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MouzaMapSimpleScreen(
                                        initialMouzaName: mapInfo['mouza'] ?? 'আমিনপুর',
                                        initialSheetNo: 'শিট ${mapInfo['sheetNo'] ?? '১'}',
                                        initialJlNo: mapInfo['jlNo'] ?? '৩৪',
                                        initialPoints: const [
                                          Offset(60, 60),
                                          Offset(260, 60),
                                          Offset(280, 220),
                                          Offset(40, 200),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F5A38),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.straighten, size: 14),
                                    SizedBox(width: 4),
                                    Text('মাপুন', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // 3. SECTION: আপনার বিভাগ নির্বাচন করুন (Page 3)
                const Text(
                  'আপনার বিভাগ নির্বাচন করুন',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
                const SizedBox(height: 10),

                // 8 DIVISION GRID (Page 3)
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.15,
                  children: MouzaCloudService.divisions.map((div) {
                    final isSel = _selectedDriveIndex == div['drive'];
                    return InkWell(
                      onTap: () => _onDivisionSelected(div),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF8B5CF6) : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel ? const Color(0xFFA78BFA) : const Color(0xFF334155),
                            width: 1.2,
                          ),
                          boxShadow: isSel
                              ? [
                                  BoxShadow(
                                    color: const Color(0x598B5CF6),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getDivisionIcon(div['icon'] as String),
                              size: 26,
                              color: isSel ? Colors.white : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              div['name'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSel ? Colors.white : const Color(0xFFE2E8F0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // 4. SEARCH INPUT (Page 3: ফাইল খুঁজুন...)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'ফাইল খুঁজুন...',
                      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Color(0xFF94A3B8), size: 18),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),

                const SizedBox(height: 12),

                // 5. BREADCRUMB NAVIGATION (Page 3: <- -> ঢাকা)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 18, color: Colors.white),
                        tooltip: 'উপরে যান',
                        onPressed: _currentPath.isNotEmpty ? _navigateBackPath : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _currentPath.isEmpty ? _currentDivisionName : '$_currentDivisionName / $_currentPath',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF38BDF8), // Cyan link color
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 6. FOLDER & FILE LIST (Page 3)
                if (filteredItems.isEmpty && !_isLoading)
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.folder_open, size: 48, color: Color(0xFF475569)),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty ? 'এই ফোল্ডারে কোনো ফাইল নেই' : 'কোনো ফলাফল পাওয়া যায়নি',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final item = filteredItems[idx];
                      return Material(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => _onItemTapped(item),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                // Folder / PDF Icon
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: item.isFolder
                                        ? const Color(0x4D6B21A8)
                                        : const Color(0x33DC2626),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    item.isFolder ? Icons.folder : Icons.picture_as_pdf,
                                    color: item.isFolder ? const Color(0xFFA855F7) : const Color(0xFFEF4444),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.isFolder
                                            ? '১৩ সেপ্টেম্বর ২০২৫ • ডিরেক্টরি'
                                            : '${item.size != null ? "${(item.size! / (1024 * 1024)).toStringAsFixed(1)} MB" : "PDF নকশা"} • ক্যাডাস্ট্রাল ভেক্টর',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTabItem(int index, String label, IconData icon) {
    final isSel = _activeTopTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTopTab = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFF8B5CF6) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: isSel ? Colors.white : Colors.white70),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? Colors.white : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourcePill(int sourceNum, String label, IconData icon) {
    final isSel = _activeSource == sourceNum;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _activeSource = sourceNum);
          _loadDirectory();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFF8B5CF6) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSel ? const Color(0xFFA78BFA) : const Color(0xFF475569)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSel ? Colors.white : const Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? Colors.white : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CadastralSheetModal extends StatefulWidget {
  final MouzaDirectoryItem item;
  final MouzaCloudItem? cloudItem;

  const _CadastralSheetModal({
    required this.item,
    this.cloudItem,
  });

  @override
  State<_CadastralSheetModal> createState() => _CadastralSheetModalState();
}

class _CadastralSheetModalState extends State<_CadastralSheetModal> {
  int _selectedSheetIndex = 1;
  late bool _showAuthenticScan;
  bool _showGunia = false;
  bool _isMeasuring = false;
  final List<Offset> _sheetMeasurePoints = [];
  String _selectedScale = '১৬" = ১ মাইল';
  final List<String> _scaleOptions = const ['১৬" = ১ মাইল', '৩২" = ১ মাইল', '৬৪" = ১ মাইল', '৮০" = ১ মাইল'];

  // Download state
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _downloadedFilePath;
  int _imageKey = 0; // for force reload

  int _selectedPlotIndex = 4; // Default to Dag 105 (Area: 33,000 sq ft, 75.758 dec)
  String? _selectedDagInfo = 'দাগ ১০৫ নির্বাচিত | খতিয়ান নং: ১২ | আনুমানিক: ৭৫.৭৫৮ শতক (৩৩,০০০ sq ft)';

  static const List<List<Offset>> _plotPolygons = [
    // Top Left Plots (101, 102, 103)
    [Offset(30, 40), Offset(150, 40), Offset(140, 140), Offset(30, 130)],
    [Offset(150, 40), Offset(280, 40), Offset(270, 140), Offset(140, 140)],
    [Offset(280, 40), Offset(420, 40), Offset(400, 140), Offset(270, 140)],

    // Mid Plots above river (104, 105, 106)
    [Offset(30, 130), Offset(140, 140), Offset(130, 210), Offset(30, 200)],
    [Offset(140, 140), Offset(270, 140), Offset(260, 215), Offset(130, 210)], // 105
    [Offset(270, 140), Offset(400, 140), Offset(420, 220), Offset(260, 215)],

    // Bottom Plots below river (107, 108, 109)
    [Offset(40, 260), Offset(160, 265), Offset(150, 360), Offset(40, 350)],
    [Offset(160, 265), Offset(290, 275), Offset(280, 370), Offset(150, 360)],
    [Offset(290, 275), Offset(440, 280), Offset(430, 375), Offset(280, 370)],

    // Very Bottom Plots (110, 111, 112)
    [Offset(40, 350), Offset(150, 360), Offset(140, 460), Offset(40, 450)],
    [Offset(150, 360), Offset(280, 370), Offset(270, 465), Offset(140, 460)],
    [Offset(280, 370), Offset(430, 375), Offset(420, 470), Offset(270, 465)],
  ];

  @override
  void initState() {
    super.initState();
    // Default to authentic scan if cloud file exists
    _showAuthenticScan = (widget.cloudItem != null && widget.cloudItem!.downloadUrl != null);
  }

  double get _scaleFeetPerPixel {
    switch (_selectedScale) {
      case '১৬" = ১ মাইল':
        return 330.0 / 60.0; // 5.5 ft per pt
      case '৩২" = ১ মাইল':
        return 165.0 / 60.0; // 2.75 ft per pt
      case '৬৪" = ১ মাইল':
        return 82.5 / 60.0; // 1.375 ft per pt
      case '৮০" = ১ মাইল':
        return 66.0 / 60.0; // 1.1 ft per pt
      default:
        return 5.5;
    }
  }

  void _onMapTapped(Offset localPos) {
    if (_isMeasuring) {
      setState(() {
        _sheetMeasurePoints.add(localPos);
      });
      return;
    }

    for (int i = 0; i < _plotPolygons.length; i++) {
      final poly = _plotPolygons[i];
      if (_isPointInsidePolygon(localPos, poly)) {
        final dagNo = 101 + i;
        setState(() {
          _selectedPlotIndex = i;
          if (dagNo == 105) {
            _selectedDagInfo = 'দাগ ১০৫ নির্বাচিত | খতিয়ান নং: ১২ | আনুমানিক: ৭৫.৭৫৮ শতক (৩৩,০০০ sq ft)';
          } else {
            final approxDec = (20.0 + (i * 4.7)).toStringAsFixed(3);
            _selectedDagInfo =
                'দাগ ${BanglaNumerals.toBangla(dagNo)} নির্বাচিত | খতিয়ান নং: ${BanglaNumerals.toBangla(i + 8)} | আনুমানিক: $approxDec শতক';
          }
        });
        break;
      }
    }
  }

  bool _isPointInsidePolygon(Offset point, List<Offset> poly) {
    bool inside = false;
    for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      if (((poly[i].dy > point.dy) != (poly[j].dy > point.dy)) &&
          (point.dx <
              (poly[j].dx - poly[i].dx) * (point.dy - poly[i].dy) / (poly[j].dy - poly[i].dy) + poly[i].dx)) {
        inside = !inside;
      }
    }
    return inside;
  }

  List<Offset> _getNormalizedCadPoints() {
    if (_selectedPlotIndex == 4) {
      return const [
        Offset(60, 60),
        Offset(260, 60),
        Offset(280, 220),
        Offset(40, 200),
      ];
    }
    final raw = _plotPolygons[_selectedPlotIndex];
    return raw.map((p) => Offset((p.dx - 20) * 0.8 + 40, (p.dy - 20) * 0.7 + 50)).toList();
  }

  Future<void> _downloadMouzaMapFile() async {
    if (widget.cloudItem?.downloadUrl == null) {
      _downloadMapPdf();
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final path = await MouzaCloudService().downloadMouzaFile(
        downloadUrl: widget.cloudItem!.downloadUrl!,
        fileName: widget.cloudItem!.name,
        onProgress: (p) {
          if (mounted) setState(() => _downloadProgress = p);
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadedFilePath = path;
        });

        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('নকশা ডাউনলোড সম্পন্ন হয়েছে!\nসংরক্ষিত: $path'),
              backgroundColor: AppColors.primaryGreen,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ডাউনলোড সম্পন্ন হয়নি। সরাসরি ব্রাউজারে লিংক ওপেন করুন।'),
              backgroundColor: AppColors.accentCrimson,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

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
                    pw.Text('জরিপ: ${widget.item.surveyType} | শিট নং: $_selectedSheetIndex'),
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
                    child: pw.Text('নকশা ড্রয়িং ও ক্যাডাস্ট্রাল প্লট ম্যাপ\n(স্কেল: $_selectedScale / গান্টার চেইন)'),
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
      name: '${widget.item.mouzaName}_JL${widget.item.jlNo}_Sheet$_selectedSheetIndex.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCloudFile = widget.cloudItem != null && widget.cloudItem!.downloadUrl != null;

    // Measurement computations
    double measuredPerimeterFt = 0.0;
    double measuredAreaSqFt = 0.0;
    if (_sheetMeasurePoints.length >= 2) {
      for (int i = 0; i < _sheetMeasurePoints.length - 1; i++) {
        final p1 = _sheetMeasurePoints[i];
        final p2 = _sheetMeasurePoints[i + 1];
        measuredPerimeterFt += (p2 - p1).distance * _scaleFeetPerPixel;
      }
    }
    if (_sheetMeasurePoints.length >= 3) {
      // Shoelace formula
      double areaPx = 0.0;
      for (int i = 0; i < _sheetMeasurePoints.length; i++) {
        final p1 = _sheetMeasurePoints[i];
        final p2 = _sheetMeasurePoints[(i + 1) % _sheetMeasurePoints.length];
        areaPx += (p1.dx * p2.dy) - (p2.dx * p1.dy);
      }
      measuredAreaSqFt = (areaPx.abs() / 2.0) * (_scaleFeetPerPixel * _scaleFeetPerPixel);
    }
    final measuredDecimal = measuredAreaSqFt / 435.60;
    final measuredKatha = measuredAreaSqFt / 720.00;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 1. Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.cloudItem != null
                                  ? widget.cloudItem!.name
                                  : 'মৌজা: ${widget.item.mouzaName} (জে.এল. ${widget.item.jlNo})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.cloudItem != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0x33FFFFFF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.cloudItem!.name.endsWith('.pdf') ? 'PDF নকশা' : 'অরিজিনাল স্ক্যান',
                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.item.upazila}, ${widget.item.district} | ${widget.item.surveyType}'
                        '${widget.cloudItem?.size != null ? ' | ${(widget.cloudItem!.size! / 1048576).toStringAsFixed(1)} MB' : ''}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // 2. Mode Selector Bar (Original Scan vs CAD Vector)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFFF1F5F9),
            child: Row(
              children: [
                if (hasCloudFile) ...[
                  InkWell(
                    onTap: () => setState(() => _showAuthenticScan = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _showAuthenticScan ? AppColors.primaryGreen : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _showAuthenticScan ? AppColors.primaryGreen : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.image,
                            size: 14,
                            color: _showAuthenticScan ? Colors.white : Colors.black87,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'আসল স্ক্যান নকশা',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _showAuthenticScan ? FontWeight.bold : FontWeight.normal,
                              color: _showAuthenticScan ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => setState(() => _showAuthenticScan = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: !_showAuthenticScan ? AppColors.primaryGreen : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: !_showAuthenticScan ? AppColors.primaryGreen : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.polyline,
                            size: 14,
                            color: !_showAuthenticScan ? Colors.white : Colors.black87,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ক্যাডাস্ট্রাল ভেক্টর',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: !_showAuthenticScan ? FontWeight.bold : FontWeight.normal,
                              color: !_showAuthenticScan ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                // Gunia toggle chip
                FilterChip(
                  label: const Text('গুনিয়া স্কেল', style: TextStyle(fontSize: 11)),
                  selected: _showGunia,
                  selectedColor: Colors.amber.shade200,
                  onSelected: (val) => setState(() => _showGunia = val),
                ),
                const SizedBox(width: 6),
                // On-sheet measurement toggle chip
                FilterChip(
                  label: const Text('নকশায় মাপুন', style: TextStyle(fontSize: 11)),
                  selected: _isMeasuring,
                  selectedColor: const Color(0xFFBAE6FD),
                  onSelected: (val) => setState(() => _isMeasuring = val),
                ),
              ],
            ),
          ),

          // 3. Scale & Measurement Options Sub-bar (when measuring or in authentic scan)
          if (_isMeasuring || _showAuthenticScan)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: const Color(0xFFE2E8F0),
              child: Row(
                children: [
                  const Text('মৌজা স্কেল: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: _selectedScale,
                    isDense: true,
                    style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold),
                    items: _scaleOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedScale = val);
                    },
                  ),
                  const Spacer(),
                  if (_sheetMeasurePoints.isNotEmpty) ...[
                    Text(
                      'পয়েন্ট: ${BanglaNumerals.toBangla(_sheetMeasurePoints.length)} টি',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreenDark),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => setState(() => _sheetMeasurePoints.clear()),
                      child: const Text('মুছুন', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),

          // 4. Interactive Canvas (Authentic Scan or CAD Vector)
          Expanded(
            child: Stack(
              children: [
                if (_showAuthenticScan && hasCloudFile)
                  // Authentic High-Resolution Scanned Cadastral Sheet Viewer
                  InteractiveViewer(
                    boundaryMargin: const EdgeInsets.all(200),
                    minScale: 0.1,
                    maxScale: 25.0,
                    child: Center(
                      child: GestureDetector(
                        onTapUp: (details) => _onMapTapped(details.localPosition),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF6EE),
                                border: Border.all(color: const Color(0xFF78350F), width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Image.network(
                                widget.cloudItem!.downloadUrl!,
                                key: ValueKey('mouza_img_${widget.cloudItem!.name}_$_imageKey'),
                                fit: BoxFit.contain,
                                headers: const {
                                  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) BDLandPro/1.0',
                                },
                                loadingBuilder: (ctx, child, progress) {
                                  if (progress == null) return child;
                                  final total = progress.expectedTotalBytes;
                                  final loaded = progress.cumulativeBytesLoaded;
                                  final pct = total != null && total > 0 ? (loaded / total * 100).toStringAsFixed(0) : '';

                                  return Container(
                                    width: 480,
                                    height: 520,
                                    color: const Color(0xFFFAF6EE),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(color: AppColors.primaryGreen),
                                          const SizedBox(height: 16),
                                          Text(
                                            'অরিজিনাল মৌজা নকশা লোড হচ্ছে... ${pct.isNotEmpty ? '$pct%' : ''}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${(loaded / 1048576).toStringAsFixed(1)} MB'
                                            '${total != null ? ' / ${(total / 1048576).toStringAsFixed(1)} MB' : ''}',
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (ctx, err, stack) {
                                  return Container(
                                    width: 480,
                                    height: 520,
                                    padding: const EdgeInsets.all(24),
                                    color: const Color(0xFFFEF2F2),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.cloud_off, color: Color(0xFFEF4444), size: 48),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'অনলাইন সার্ভার থেকে সরাসরি নকশা লোড হতে দেরি হচ্ছে',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            '(গুগল ড্রাইভ প্রক্সি কোটা লিমিট বা নেটওয়ার্ক ধীরগতি হতে পারে)',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 14),
                                          ElevatedButton.icon(
                                            onPressed: () => setState(() => _imageKey++),
                                            icon: const Icon(Icons.refresh),
                                            label: const Text('পুনরায় চেষ্টা করুন (Retry)'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primaryGreen,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          OutlinedButton.icon(
                                            onPressed: () => setState(() => _showAuthenticScan = false),
                                            icon: const Icon(Icons.polyline),
                                            label: const Text('ক্যাড ভেক্টর মোডে দেখুন'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // On-sheet Custom Measurement Overlay
                            if (_sheetMeasurePoints.isNotEmpty)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _SheetMeasurementPainter(
                                    points: _sheetMeasurePoints,
                                    feetPerPixel: _scaleFeetPerPixel,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  // CAD Vector Plot Simulation Canvas
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
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTapUp: (details) => _onMapTapped(details.localPosition),
                          child: CustomPaint(
                            painter: _InteractiveMouzaPainter(
                              mouzaName: widget.item.mouzaName,
                              sheetNo: _selectedSheetIndex,
                              jlNo: widget.item.jlNo,
                              selectedPlotIndex: _selectedPlotIndex,
                            ),
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

                // Selected Dag Floating Banner (for vector mode)
                if (!_showAuthenticScan && _selectedDagInfo != null)
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Color(0x1F000000), blurRadius: 6),
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

                // Live On-Sheet Measurement Result Card (for authentic scan mode)
                if (_showAuthenticScan && _sheetMeasurePoints.length >= 2)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xF20F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0284C7), width: 1.2),
                        boxShadow: const [
                          BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.straighten, color: Color(0xFF38BDF8), size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'নকশায় ফিল্ড মেজারমেন্ট',
                                    style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                              Text(
                                'স্কেল: $_selectedScale',
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('পরিসীমা', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                                  Text(
                                    '${BanglaFormatter.formatNumber(measuredPerimeterFt, fractionDigits: 1)} ft',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    '(${BanglaFormatter.formatNumber(measuredPerimeterFt / 0.66, fractionDigits: 1)} link)',
                                    style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 10),
                                  ),
                                ],
                              ),
                              if (_sheetMeasurePoints.length >= 3) ...[
                                Column(
                                  children: [
                                    const Text('জমির পরিমাণ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                                    Text(
                                      '${BanglaFormatter.formatNumber(measuredDecimal, fractionDigits: 3)} শতক',
                                      style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      '${BanglaFormatter.formatNumber(measuredKatha, fractionDigits: 2)} কাঠা',
                                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 10),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('বর্গফুট', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                                    Text(
                                      '${BanglaFormatter.formatNumber(measuredAreaSqFt, fractionDigits: 0)} sq ft',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Download Progress Overlay
                if (_isDownloading)
                  Container(
                    color: const Color(0x99000000),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: AppColors.primaryGreen),
                            const SizedBox(height: 16),
                            const Text(
                              'আসল মৌজা নকশা ডাউনলোড হচ্ছে...',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 200,
                              child: LinearProgressIndicator(
                                value: _downloadProgress > 0 ? _downloadProgress : null,
                                color: AppColors.primaryGreen,
                                backgroundColor: Colors.grey.shade200,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 5. Bottom Action Bar: Measure & Download
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
                    onPressed: _isDownloading ? null : _downloadMouzaMapFile,
                    icon: Icon(
                      widget.cloudItem?.name.endsWith('.pdf') == true
                          ? Icons.picture_as_pdf
                          : Icons.download_for_offline,
                    ),
                    label: Text(
                      widget.cloudItem != null
                          ? (widget.cloudItem!.name.endsWith('.pdf') ? 'নকশা PDF ডাউনলোড' : 'আসল নকশা ডাউনলোড')
                          : 'নকশা PDF ডাউনলোড',
                    ),
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
                          builder: (_) => MouzaMapSimpleScreen(
                            initialMouzaName: widget.item.mouzaName,
                            initialSheetNo: 'শিট ${BanglaNumerals.toBangla(_selectedSheetIndex)}',
                            initialJlNo: widget.item.jlNo,
                            initialPoints: _getNormalizedCadPoints(),
                          ),
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

class _SheetMeasurementPainter extends CustomPainter {
  final List<Offset> points;
  final double feetPerPixel;

  const _SheetMeasurementPainter({
    required this.points,
    required this.feetPerPixel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final linePaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final closedPaint = Paint()
      ..color = const Color(0x330284C7)
      ..style = PaintingStyle.fill;

    // 1. Draw polygon fill if 3+ points
    if (points.length >= 3) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.close();
      canvas.drawPath(path, closedPaint);
      canvas.drawPath(path, linePaint);
    } else if (points.length == 2) {
      canvas.drawLine(points[0], points[1], linePaint);
    }

    // 2. Draw side measurements
    final segCount = points.length >= 3 ? points.length : points.length - 1;
    for (int i = 0; i < segCount; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      final distPx = (p2 - p1).distance;
      final distFt = distPx * feetPerPixel;
      final distLink = distFt / 0.66;

      final mid = Offset((p1.dx + p2.dx) / 2.0, (p1.dy + p2.dy) / 2.0);

      _drawMeasurementLabel(
        canvas,
        '${distFt.toStringAsFixed(1)} ft (${distLink.toStringAsFixed(0)} link)',
        mid,
      );
    }

    // 3. Draw vertex pins
    for (int i = 0; i < points.length; i++) {
      final p = points[i];

      final pinOuter = Paint()
        ..color = const Color(0xFF0369A1)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 10, pinOuter);

      final pinInner = Paint()
        ..color = const Color(0xFF38BDF8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 6, pinInner);

      final whiteDot = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 2.5, whiteDot);
    }
  }

  void _drawMeasurementLabel(Canvas canvas, String text, Offset center) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: tp.width + 10,
        height: tp.height + 6,
      ),
      const Radius.circular(4),
    );

    final bgPaint = Paint()..color = const Color(0xCC0F172A);
    canvas.drawRRect(bgRect, bgPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(bgRect, borderPaint);

    tp.paint(canvas, Offset(center.dx - tp.width / 2.0, center.dy - tp.height / 2.0));
  }

  @override
  bool shouldRepaint(covariant _SheetMeasurementPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.feetPerPixel != feetPerPixel;
}

class _InteractiveMouzaPainter extends CustomPainter {
  final String mouzaName;
  final int sheetNo;
  final String jlNo;
  final int selectedPlotIndex;

  _InteractiveMouzaPainter({
    required this.mouzaName,
    required this.sheetNo,
    required this.jlNo,
    this.selectedPlotIndex = 4,
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

    // 2. Road/River passing through mouza
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

    final plots = _CadastralSheetModalState._plotPolygons;

    int dagIndex = 101;
    for (int i = 0; i < plots.length; i++) {
      final pList = plots[i];
      final path = Path()..moveTo(pList[0].dx, pList[0].dy);
      for (int k = 1; k < pList.length; k++) {
        path.lineTo(pList[k].dx, pList[k].dy);
      }
      path.close();

      // Highlight selected plot with cyan glow fill
      if (i == selectedPlotIndex) {
        final fillPaint = Paint()
          ..color = const Color(0x4006B6D4)
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, fillPaint);

        final selStroke = Paint()
          ..color = const Color(0xFF0284C7)
          ..strokeWidth = 2.4
          ..style = PaintingStyle.stroke;
        canvas.drawPath(path, selStroke);
      } else {
        canvas.drawPath(path, plotPaint);
      }

      // Plot center
      double cx = 0, cy = 0;
      for (final p in pList) {
        cx += p.dx;
        cy += p.dy;
      }
      cx /= pList.length;
      cy /= pList.length;

      _drawText(
        canvas,
        'দাগ ${BanglaNumerals.toBangla(dagIndex)}',
        Offset(cx - 18, cy - 6),
        isBold: true,
        color: i == selectedPlotIndex ? const Color(0xFF0369A1) : const Color(0xFF4A3B2C),
      );
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
      oldDelegate.mouzaName != mouzaName ||
      oldDelegate.sheetNo != sheetNo ||
      oldDelegate.selectedPlotIndex != selectedPlotIndex;
}
