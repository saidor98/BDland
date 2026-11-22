import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';

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

  void _showSheetPreview(MouzaDirectoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'মৌজা: ${item.mouzaName} (জে.এল. নং: ${item.jlNo})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              Text(
                'উপজেলা: ${item.upazila}, জেলা: ${item.district} (${item.division} বিভাগ)',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const Divider(height: 20),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF6EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2D6C0)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map, size: 72, color: AppColors.primaryGreen),
                        const SizedBox(height: 12),
                        Text(
                          'মৌজা নকশা শিট ১ (জরিপ: ${item.surveyType})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text('মোট শিট: ${BanglaNumerals.toBangla(item.totalSheets)} টি | মোট দাগ: ${BanglaNumerals.toBangla(item.totalPlots)} টি'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${item.mouzaName} মৌজা ম্যাপ সফলভাবে লোড হয়েছে!')),
                            );
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('পরিমাপক টুলে লোড করুন'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('সারাদেশের সকল মৌজা ম্যাপ'),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchQuery = ''))
                        : null,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _divisions.map((div) {
                      final isSelected = _selectedDivision == div;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(div),
                          selected: isSelected,
                          selectedColor: AppColors.primaryGreen.withOpacity(0.18),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primaryGreenDark : AppColors.textPrimary,
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
          const Divider(height: 1),

          // Mouza List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _filteredList.length,
              itemBuilder: (context, index) {
                final item = _filteredList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.map_outlined, color: AppColors.primaryGreen),
                    ),
                    title: Text(
                      'মৌজা: ${item.mouzaName} (জে.এল: ${item.jlNo})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('${item.upazila}, ${item.district} | জরিপ: ${item.surveyType}'),
                        Text(
                          'মোট শিট: ${BanglaNumerals.toBangla(item.totalSheets)} টি | মোট দাগ: ${BanglaNumerals.toBangla(item.totalPlots)} টি',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
                    onTap: () => _showSheetPreview(item),
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
