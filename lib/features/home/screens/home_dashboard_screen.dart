import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/pinned_tools_service.dart';
import '../../history/screens/history_screen.dart';
import '../data/tools_data.dart';
import '../models/tool_item.dart';
import '../widgets/sidebar_drawer.dart';
import '../widgets/tool_card.dart';
import '../widgets/review_section.dart';
import '../widgets/user_guide_view.dart';
import '../../tools/01_google_map_survey/google_map_survey_screen.dart';
import '../../tools/02_mouza_simple/mouza_map_simple_screen.dart';
import '../../tools/24_surveyor_memo/surveyor_memo_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _sidebarIndex = 0;
  int _topTabIndex = 0; // 0: সকল টুলস, 1: পিন টুলস, 2: ব্যবহারবিধি

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Set<String> _pinnedToolIds = {};

  @override
  void initState() {
    super.initState();
    _loadPinnedTools();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPinnedTools() async {
    final pinned = await PinnedToolsService.instance.getPinnedToolIds();
    if (mounted) {
      setState(() {
        _pinnedToolIds = pinned;
      });
    }
  }

  Future<void> _togglePin(String toolId) async {
    await PinnedToolsService.instance.togglePin(toolId);
    setState(() {
      if (_pinnedToolIds.contains(toolId)) {
        _pinnedToolIds.remove(toolId);
      } else {
        _pinnedToolIds.add(toolId);
      }
    });
  }

  void _handleSidebarSelect(int index) {
    setState(() => _sidebarIndex = index);
    if (index == 0) {
      // Home
      setState(() => _topTabIndex = 0);
    } else if (index == 1) {
      // Tools
      setState(() => _topTabIndex = 0);
    } else if (index == 2) {
      // Search
      _searchFocusNode.requestFocus();
    } else if (index == 3) {
      // Tab / History
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HistoryScreen()),
      );
    } else if (index == 4) {
      // Post Job / Surveyor Memo
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SurveyorMemoScreen()),
      );
    } else if (index == 5) {
      // Profile
      _showProfileDialog();
    }
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('সার্ভেয়ার প্রোফাইল'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryGreen,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text('বিডি ল্যান্ড প্রো ইউজার', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('সার্টিফাইড ল্যান্ড সার্ভে ও খতিয়ান বিশারদ'),
            ),
            Divider(),
            Text('• সংস্করণ: ১.০.০ (ওপেন সোর্স)'),
            SizedBox(height: 4),
            Text('• সকল ২৪টি টুল আনলকড ও অফলাইন প্রস্তুত'),
            SizedBox(height: 4),
            Text('• ডেটা স্টোরেজ: লোকাল ডিভাইস এনক্রিপ্টেড'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ঠিক আছে'),
          ),
        ],
      ),
    );
  }

  List<ToolItem> _getFilteredTools() {
    List<ToolItem> list;
    if (_topTabIndex == 1) {
      list = ToolsData.allTools.where((t) => _pinnedToolIds.contains(t.id)).toList();
    } else {
      list = ToolsData.allTools;
    }

    if (_searchQuery.trim().isEmpty) {
      return list;
    }

    final query = _searchQuery.trim().toLowerCase();
    return list.where((tool) {
      final inTitle = tool.title.toLowerCase().contains(query);
      final inSub = tool.subtitle.toLowerCase().contains(query);
      final inKeywords = tool.keywords.any((k) => k.toLowerCase().contains(query));
      return inTitle || inSub || inKeywords;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF9),
          appBar: isDesktop
              ? null
              : AppBar(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0.5,
                  title: const Text(
                    'বিডি ল্যান্ড প্রো',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.history, color: AppColors.primaryGreen),
                      tooltip: 'পরিমাপের হিস্ট্রি',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HistoryScreen()),
                        );
                      },
                    ),
                  ],
                ),
          drawer: isDesktop
              ? null
              : Drawer(
                  child: SafeArea(
                    child: SidebarDrawer(
                      selectedIndex: _sidebarIndex,
                      onItemSelected: (idx) {
                        Navigator.pop(context);
                        _handleSidebarSelect(idx);
                      },
                    ),
                  ),
                ),
          body: Row(
            children: [
              if (isDesktop)
                SidebarDrawer(
                  selectedIndex: _sidebarIndex,
                  onItemSelected: _handleSidebarSelect,
                ),
              Expanded(
                child: _buildMainDashboard(constraints),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainDashboard(BoxConstraints constraints) {
    return SafeArea(
      child: Column(
        children: [
          // Top Bar: Tabs & Search
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Filter Tabs: সকল টুলস / পিন টুলস / ব্যবহারবিধি
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTopTabPill(
                                icon: Icons.grid_view,
                                label: 'সকল টুলস',
                                index: 0,
                              ),
                            ),
                            Expanded(
                              child: _buildTopTabPill(
                                icon: Icons.push_pin,
                                label: 'পিন টুলস (${_pinnedToolIds.length})',
                                index: 1,
                              ),
                            ),
                            Expanded(
                              child: _buildTopTabPill(
                                icon: Icons.info_outline,
                                label: 'ব্যবহারবিধি',
                                index: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Search Bar
                if (_topTabIndex != 2)
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: const InputDecoration(
                              hintText: 'টুল বা হিসাবের নাম দিয়ে খুঁজুন (যেমন: মৌজা, ফারায়েজ, cad, khatian)...',
                              hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(fontSize: 13.5),
                            onChanged: (val) {
                              setState(() => _searchQuery = val);
                            },
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          InkWell(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Icon(Icons.close, size: 18, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Body Content
          Expanded(
            child: _topTabIndex == 2
                ? const UserGuideView()
                : _buildToolsGridWithReviews(constraints),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTabPill({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _topTabIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _topTabIndex = index);
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primaryGreen : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primaryGreen : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsGridWithReviews(BoxConstraints constraints) {
    final filteredTools = _getFilteredTools();

    // Calculate grid crossAxisCount
    int crossAxisCount = 2;
    double childAspectRatio = 1.05;
    final width = constraints.maxWidth;

    if (width >= 1200) {
      crossAxisCount = 5;
      childAspectRatio = 1.15;
    } else if (width >= 900) {
      crossAxisCount = 4;
      childAspectRatio = 1.12;
    } else if (width >= 650) {
      crossAxisCount = 3;
      childAspectRatio = 1.1;
    } else {
      crossAxisCount = 2;
      childAspectRatio = 0.98;
    }

    if (filteredTools.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _topTabIndex == 1 ? Icons.push_pin_outlined : Icons.search_off,
                size: 56,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 14),
              Text(
                _topTabIndex == 1
                    ? 'কোনো টুল এখনও পিন করা হয়নি'
                    : 'কোনো টুল পাওয়া যায়নি',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _topTabIndex == 1
                    ? 'যেকোনো টুল কার্ডের ডানপাশের পিন আইকনে ট্যাপ করে এখানে যুক্ত করুন।'
                    : 'ভিন্ন কোনো কীওয়ার্ড দিয়ে পুনরায় চেষ্টা করুন।',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_topTabIndex == 0 && _searchQuery.trim().isEmpty) ...[
            _buildStitchHeroDeck(width >= 650),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.engineering, size: 17, color: AppColors.primaryGreen),
                SizedBox(width: 6),
                Text(
                  'সকল ২৪টি প্রফেশনাল জরিপ টুলস',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredTools.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (ctx, idx) {
              final tool = filteredTools[idx];
              final isPinned = _pinnedToolIds.contains(tool.id);
              return ToolCard(
                item: tool,
                isPinned: isPinned,
                onPinToggle: () => _togglePin(tool.id),
              );
            },
          ),

          const SizedBox(height: 28),

          // Bottom Review Section
          const ReviewSection(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStitchHeroDeck(bool isWide) {
    final gpsHeroCard = InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GoogleMapSurveyScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppColors.greenHeaderGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondaryGold, width: 1.3),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF38BDF8)),
              ),
              child: const Icon(Icons.my_location, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'লাইভ GPS স্যাটেলাইট জরিপ',
                    style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'নিজের বর্তমান অবস্থান অনুযায়ী ম্যাপ ও বাউন্ডারি মাপ',
                    style: TextStyle(color: Colors.white70, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFFFBBF24), size: 15),
          ],
        ),
      ),
    );

    final mouzaHeroCard = InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MouzaMapSimpleScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.45), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondaryGold),
              ),
              child: const Icon(Icons.architecture, color: AppColors.secondaryGoldDark, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'মৌজা ম্যাপ জুম ও CAD পরিমাপ',
                    style: TextStyle(color: Color(0xFF0F172A), fontSize: 14.5, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '১৬"/৩২"/৬৪" স্কেল · ৮x জুম · ফোন থেকে ফাইল/PDF লোড',
                    style: TextStyle(color: Color(0xFF475569), fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.primaryGreen, size: 15),
          ],
        ),
      ),
    );

    if (isWide) {
      return Row(
        children: [
          Expanded(child: gpsHeroCard),
          const SizedBox(width: 12),
          Expanded(child: mouzaHeroCard),
        ],
      );
    }
    return Column(
      children: [
        gpsHeroCard,
        const SizedBox(height: 10),
        mouzaHeroCard,
      ],
    );
  }
}
