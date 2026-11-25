import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

class LandSurveyFormulasScreen extends StatefulWidget {
  const LandSurveyFormulasScreen({super.key});

  @override
  State<LandSurveyFormulasScreen> createState() => _LandSurveyFormulasScreenState();
}

class _LandSurveyFormulasScreenState extends State<LandSurveyFormulasScreen> {
  String _searchQuery = '';

  static const List<Map<String, String>> _sections = [
    {
      'title': '১. গান্টার্স চেইন ও লিংক পরিমাপ সূত্র (Gunter\'s Chain)',
      'content': '''• ১ চেইন = ৬৬ ফুট = ১০০ লিংক = ৪৪ হাত = ২২ গজ = ৪ রড = ২০.১১৬৮ মিটার
• ১ লিংক = ৭.৯২ ইঞ্চি = ০.৬৬ ফুট = ০.৪৪ হাত = ০.২০১২ মিটার
• ১ বর্গচেইন = ১০ শতক = ৪,৩৫৬ বর্গফুট = ১০০০০ বর্গলিংক
• ১০০০ বর্গলিংক = ১ শতক / শতাংশ
• ১০০,০০০ বর্গলিংক = ১ একর = ১০০ শতক''',
    },
    {
      'title': '২. বাংলাদেশ ভূমি এককের আন্তর্জাতিক ও সরকারি মান',
      'content': '''• ১ শতক (Decimal) = ৪৩৫.৬০ বর্গফুট = ৪০.৪৬৮ বর্গমিটার = ১০০০ বর্গলিংক
• ১ কাঠা (সরকারি মান) = ৭২০ বর্গফুট = ১.৬৫৩ শতক = ১৬ ছটাক
• ১ বিঘা (সরকারি ৩৩ শতক) = ১৪,৩৭৪.৮ বর্গফুট (বা ২০ কাঠা = ১৪,৪০০ বর্গফুট)
• ১ একর = ১০০ শতক = ৪৩,৫৬০ বর্গফুট = ৩ বিঘা ৮ ছটাক
• ১ হেক্টর = ২.৪৭১ একর = ২৪৭.১০৫ শতক = ১০,০০০ বর্গমিটার = ১০৭,৬৩৯ বর্গফুট
• ১ ছটাক = ৪৫ বর্গফুট | ১ হাত = ১৮ ইঞ্চি = ১.৫ ফুট
• ১ বর্গহাত = ২.২৫ বর্গফুট (১৯৩.৬ বর্গহাত = ১ শতক)''',
    },
    {
      'title': '৩. আঞ্চলিক কানি ও গণ্ডা হিসাব',
      'content': '''• কানি (সরকারি মান) = ৪০ শতক = ১৭,৪২৪ বর্গফুট = ২০ গণ্ডা
• কানি (কুমিল্লা/নোয়াখালী) = ১২০ শতক = ৫২,২৭২ বর্গফুট
• শাহী কানি (সিলেট/চট্টগ্রাম) = ১৬০ শতক = ৬৯,৬৯৬ বর্গফুট
• ১ কানি = ২০ গণ্ডা | ১ গণ্ডা = ৪ কড়া = ২ শতক (৪০ শতক কানির হিসাবে)
• ১ কড়া = ৩ ক্রান্তি = ০.৫০ শতক = ২১৭.৮ বর্গফুট
• ১ ক্রান্তি = ২০ তিল = ৭২.৬০ বর্গফুট | ১ তিল = ৩.৬৩ বর্গফুট''',
    },
    {
      'title': '৪. জ্যামিতিক ক্ষেত্রফল সূত্রাবলী',
      'content': '''• ত্রিভুজ (হেরন্স ফর্মুলা): s = (a + b + c) / 2, ক্ষেত্রফল = √[s(s - a)(s - b)(s - c)]
• অনিয়মিত চতুর্ভুজ: ১টি কর্ণ টেনে ২টি ত্রিভুজে বিভক্ত করে হেরন্স ফর্মুলায় ক্ষেত্রফল নির্ণয়।
• ট্রাপিজিয়াম: ক্ষেত্রফল = ((সমান্তরাল বাহু ১ + সমান্তরাল বাহু ২) / ২) × লম্ব উচ্চতা
• সামান্তরিক: ক্ষেত্রফল = ভূমি × লম্ব উচ্চতা
• বৃত্ত: ক্ষেত্রফল = π × r² (পরিধি = ২ × π × r) | উপবৃত্ত: π × a × b
• পুকুর খনন (প্রিজময়েডাল সূত্র): V = (H / 6) × (A₁ + 4Am + A₂)''',
    },
    {
      'title': '৫. মৌজা নকশা স্কেল রূপান্তর চার্ট',
      'content': '''• ১৬" = ১ মাইল (CS, SA, RS): ১ ইঞ্চি = ৩৩০ ফুট = ৫ চেইন = ৫০০ লিংক
• ৩২" = ১ মাইল: ১ ইঞ্চি = ১৬৫ ফুট = ২.৫ চেইন = ২৫০ লিংক
• ৬৪" = ১ মাইল (পৌরসভা/বাজার): ১ ইঞ্চি = ৮২.৫ ফুট = ১.২৫ চেইন = ১২৫ লিংক
• ৮০" = ১ মাইল (সিটি জরিপ): ১ ইঞ্চি = ৬৬ ফুট = ১ চেইন = ১০০ লিংক''',
    },
    {
      'title': '৬. নামজারি (Mutation) প্রক্রিয়া ও প্রয়োজনীয় কাগজপত্র',
      'content': '''• অনলাইন আবেদন: land.gov.bd পোর্টালে নির্ধারিত কোর্ট ফি ও নোটিশ জারি ফি প্রদান করে E-Mutation আবেদন করতে হয়।
• প্রয়োজনীয় কাগজ: মূল দলিলের সার্টিফাইড/ফটোকপি, বায়া/পিট দলিল, সর্বশেষ এসএ/আরএস/বিএস খতিয়ান (পর্চা), দাখিলা (খাজনা রসিদ) ও জাতীয় পরিচয়পত্র।
• অনুমোদন সময়সীমা: সরকারি বিধি মোতাবেক সাধারণ নামজারি নিষ্পত্তির সময় ২৮ কার্যদিবস; প্রবাসী ও বীর মুক্তিযোদ্ধাদের ক্ষেত্রে অগ্রাধিকার প্রযোজ্য।
• নামজারি হিস্যা সূত্র: নামজারি অংশ (১০০০ স্কেল) = (হস্তান্তরিত জমি ÷ দাগে মোট জমি) × ১০০০।''',
    },
    {
      'title': '৭. ভূমি উন্নয়ন কর (খাজনা) ও হিসাব নিয়মাবলি',
      'content': '''• বাংলা সন (বৈশাখ-চৈত্র) অনুযায়ী অনলাইন ভূমি উন্নয়ন কর (LDTax) পরিশোধ করে QR-কোডযুক্ত দাখিলা সংগ্রহ করুন।
• কৃষি জমি (২৫ বিঘা পর্যন্ত): সরকারি বিধান অনুসারে ২৫ বিঘা (৮.২৫ একর) পর্যন্ত কৃষি জমির ভূমি উন্নয়ন কর মওকুফ (ন্যূনতম দাখিলা ফি প্রযোজ্য)।
• আবাসিক ও বাণিজ্যিক জমি: মৌজার শ্রেণি ও অবস্থান (সিটি কর্পোরেশন/পৌরসভা/ইউনিয়ন) অনুযায়ী শতকপ্রতি নির্ধারিত হারে খাজনা দিতে হয়।''',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _sections.where((sec) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      return sec['title']!.toLowerCase().contains(q) || sec['content']!.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('জমির সকল পরিমাপ সূত্র ও নির্দেশিকা'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'সূত্র, স্কেল, নামজারি বা খাজনা খুঁজুন...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: filtered.length,
              itemBuilder: (ctx, idx) {
                final sec = filtered[idx];
                return _buildCard(
                  context: context,
                  title: sec['title']!,
                  content: sec['content']!,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required BuildContext context, required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: AppColors.primaryGreen)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_outlined, size: 18, color: AppColors.secondaryGoldDark),
                          tooltip: 'সূত্র কপি করুন',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: '$title\n$content'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('সূত্রটি ক্লিপবোর্ডে কপি হয়েছে!'), duration: Duration(seconds: 1)),
                            );
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 14),
                    Text(content, style: const TextStyle(fontSize: 13.5, height: 1.55, color: AppColors.textPrimary)),
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
