import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/bangla_formatter.dart';
import '../../geometry/screens/geometry_hub_screen.dart';
import '../../converter/screens/unit_converter_screen.dart';
import '../../khatian/screens/khatian_calculator_screen.dart';
import '../../faraiz/screens/faraiz_calculator_screen.dart';
import '../../mouza_survey/screens/mouza_scale_screen.dart';
import '../../mouza_survey/screens/survey_knowledge_screen.dart';
import '../../history/screens/history_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    _DashboardView(),
    HistoryScreen(),
    SurveyKnowledgeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        indicatorColor: AppColors.primaryGreen.withOpacity(0.18),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primaryGreen),
            label: 'হোম ড্যাশবোর্ড',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: AppColors.primaryGreen),
            label: 'হিস্ট্রি',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book, color: AppColors.primaryGreen),
            label: 'ভূমি নির্দেশিকা',
          ),
        ],
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('বিডি ল্যান্ড প্রো (BDLandPro)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'পরিমাপের ইতিহাস',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Banner
            Container(
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                gradient: AppColors.greenHeaderGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.offline_pin, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              '১০০% অফলাইন সমর্থিত',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        BanglaFormatter.formatDateTime(DateTime.now()).split(',')[0],
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'বাংলাদেশ ভূমি জরিপ ও পরিমাপ সহকারী',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'হেরন্স ফর্মুলায় নিখুঁত জমি পরিমাপ, খতিয়ানের ১৬ আনা অংশ বণ্টন, একক রূপান্তর ও পূর্ণাঙ্গ ফারায়েজ ক্যালকুলেটর।',
                    style: TextStyle(fontSize: 13.5, color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Modules Grid
            const Text(
              'প্রধান মডিউল ও ক্যালকুলেটরসমূহ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
              children: [
                _buildFeatureCard(
                  context: context,
                  title: 'জমি ও জ্যামিতি পরিমাপ',
                  subtitle: 'চতুর্ভুজ (হেরন্স বনাম গড়), ত্রিভুজ, ট্রাপিজিয়াম, বহুভুজ, পুকুর খনন',
                  icon: Icons.architecture,
                  iconColor: AppColors.primaryGreen,
                  destination: const GeometryHubScreen(),
                ),
                _buildFeatureCard(
                  context: context,
                  title: 'একক রূপান্তরকারী',
                  subtitle: 'শতক, কাঠা, বিঘা, একর, কানি, গণ্ডা, কড়া, ক্রান্তি, তিল, বর্গলিংক',
                  icon: Icons.swap_horiz,
                  iconColor: AppColors.secondaryGoldDark,
                  destination: const UnitConverterScreen(),
                ),
                _buildFeatureCard(
                  context: context,
                  title: 'খতিয়ান ও আনা-গণ্ডা',
                  subtitle: '১৬ আনা হিস্যা যোগ-বিয়োগ, প্রতীক ও দাগের অংশ বণ্টন টেবিল',
                  icon: Icons.table_chart,
                  iconColor: AppColors.accentTeal,
                  destination: const KhatianCalculatorScreen(),
                ),
                _buildFeatureCard(
                  context: context,
                  title: 'মুসলিম ফারায়েজ ইঞ্জিন',
                  subtitle: 'হানাফি আইনশাস্ত্র অনুযায়ী আসহাবে ফুরুজ, আসাবা, আওল ও রদ বণ্টন',
                  icon: Icons.family_restroom,
                  iconColor: AppColors.accentPurple,
                  destination: const FaraizCalculatorScreen(),
                ),
                _buildFeatureCard(
                  context: context,
                  title: 'মৌজা ম্যাপ স্কেল',
                  subtitle: '১৬", ৩২", ৬৪", ৮০" স্কেল ও গুনিয়া থেকে নকশার পরিমাপ',
                  icon: Icons.map,
                  iconColor: const Color(0xFF0284C7),
                  destination: const MouzaScaleScreen(),
                ),
                _buildFeatureCard(
                  context: context,
                  title: 'ভূমি নির্দেশিকা ও আইন',
                  subtitle: 'দলিল রেজিস্ট্রি খরচ, ই-নামজারি প্রক্রিয়া, খাজনা ও পরিভাষা',
                  icon: Icons.menu_book,
                  iconColor: AppColors.accentOrange,
                  destination: const SurveyKnowledgeScreen(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tip of the Day Card
            Card(
              color: AppColors.secondaryGoldLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.secondaryGold),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: AppColors.secondaryGoldDark),
                        SizedBox(width: 8),
                        Text(
                          'সার্ভেয়ার টিপস: কেন আমিনের গড় পদ্ধতি পরিহার করবেন?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondaryGoldDark,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'অনিয়মিত চতুর্ভুজের ক্ষেত্রে উত্তর-দক্ষিণ এবং পূর্ব-পশ্চিমের বাহু গড় করে গুণ করলে অধিকাংশ ক্ষেত্রে জমির পরিমাণ বাস্তবে যা আছে তার চেয়ে বেশি দেখায়। ফলে সীমানা নির্ধারণ বা জমি বিক্রয়ে বিরোধ সৃষ্টি হয়। একটি কর্ণ মেপে জমিটিকে দুটি ত্রিভুজে ভাগ করে হেরন্স ফর্মুলায় পরিমাপ করাই একমাত্র আইনগত ও বিজ্ঞানসম্মত পদ্ধতি।',
                      style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
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

  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget destination,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorderLight),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => destination),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
