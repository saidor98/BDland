import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'quadrilateral_screen.dart';
import 'triangle_screen.dart';
import 'trapezoid_screen.dart';
import 'circle_screen.dart';
import 'polygon_screen.dart';
import 'earthwork_screen.dart';

class GeometryHubScreen extends StatelessWidget {
  const GeometryHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      _GeometryToolItem(
        title: 'অনিয়মিত চতুর্ভুজ',
        subtitle: '৪ বাহু ও ১ কর্ণ দিয়ে হেরন্স ফর্মুলায় নিখুঁত পরিমাপ ও গড়ের সাথে তুলনা',
        icon: Icons.crop_square,
        color: AppColors.primaryGreen,
        screen: const QuadrilateralScreen(),
      ),
      _GeometryToolItem(
        title: 'ত্রিভুজাকার জমি',
        subtitle: '৩ বাহুর হেরন্স ফর্মুলা এবং ভূমি ও উচ্চতা ভিত্তিক ত্রিভুজ পরিমাপ',
        icon: Icons.change_history,
        color: AppColors.accentTeal,
        screen: const TriangleScreen(),
      ),
      _GeometryToolItem(
        title: 'ট্রাপিজিয়াম জমি',
        subtitle: 'দুই সমান্তরাল বাহু ও লম্ব উচ্চতা থেকে জমির ক্ষেত্রফল ও শতক',
        icon: Icons.architecture,
        color: AppColors.secondaryGoldDark,
        screen: const TrapezoidScreen(),
      ),
      _GeometryToolItem(
        title: 'বৃত্ত ও বৃত্তাংশ (Sector)',
        subtitle: 'গোল জমি, পুকুর বা বৃত্তাকার খণ্ডের ক্ষেত্রফল ও পরিধি নির্ণয়',
        icon: Icons.circle_outlined,
        color: AppColors.accentNavy,
        screen: const CircleScreen(),
      ),
      _GeometryToolItem(
        title: 'বহুভুজ জমি (ত্রিভুজায়ন)',
        subtitle: '৫ বা ততোধিক বাহুর জমিকে একাধিক ত্রিভুজে ভাগ করে আমিন পদ্ধতিতে হিসাব',
        icon: Icons.polyline,
        color: AppColors.accentPurple,
        screen: const PolygonScreen(),
      ),
      _GeometryToolItem(
        title: 'পুকুর, খাল ও মাটি খনন',
        subtitle: 'ঢাল, উপরের-নিচের বিস্তার ও গভীরতা থেকে সেফটি (CFT) ও খনন খরচ',
        icon: Icons.water,
        color: const Color(0xFF0284C7),
        screen: const EarthworkScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('জমি ও জ্যামিতিক পরিমাপ'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final tool = tools[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 14.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => tool.screen),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: tool.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(tool.icon, color: tool.color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tool.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tool.subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GeometryToolItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;

  const _GeometryToolItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.screen,
  });
}
