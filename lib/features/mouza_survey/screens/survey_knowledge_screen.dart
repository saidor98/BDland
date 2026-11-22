import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SurveyKnowledgeScreen extends StatelessWidget {
  const SurveyKnowledgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ভূমি আইন ও জরিপ নির্দেশিকা'),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: AppColors.secondaryGold,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'দলিল রেজিস্ট্রি খরচ'),
              Tab(text: 'ই-নামজারি প্রক্রিয়া'),
              Tab(text: 'ভূমি উন্নয়ন কর (LD Tax)'),
              Tab(text: 'জরিপ পরিভাষা ডিকশনারি'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRegistrationFeeTab(),
            _buildMutationTab(),
            _buildLdTaxTab(),
            _buildGlossaryTab(),
          ],
        ),
      ),
    );
  }

  // Tab 1: দলিল রেজিস্ট্রি খরচ
  Widget _buildRegistrationFeeTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildInfoCard(
          title: 'জমির সাফ-কবলা দলিল রেজিস্ট্রেশন খরচ (সরকারি হার)',
          content: '''
১. রেজিস্ট্রেশন ফি (Registration Fee): দলিলের মোট মূল্যের ১% (পৌরসভা/সিটি কর্পোরেশনের বাইরে) অথবা ২%।
২. স্ট্যাম্প শুল্ক (Stamp Duty): দলিলের মোট মূল্যের ১.৫% (সর্বোচ্চ প্রযোজ্য কোড অনুযায়ী)।
৩. স্থানীয় সরকার কর (Local Govt Tax):
   • ইউনিয়ন পরিষদ এলাকা: ১%
   • পৌরসভা এলাকা: ২%
   • সিটি কর্পোরেশন ও ক্যান্টনমেন্ট বোর্ড এলাকা: ৩%
৪. উৎসে আয়কর (AIT - ধারা ৫৩ এইচ):
   • এলাকাভিত্তিক কাঠা বা শতাংশ প্রতি নির্ধারিত ন্যূনতম কর (যেমন: গুলশান, বনানী, মতিঝিল, ধানমন্ডি বাণিজ্যিক এলাকায় কাঠাপ্রতি সর্বোচ্চ কর; উপজেলা পর্যায়ে ন্যূনতম কর)।
৫. হলফনামা স্ট্যাম্প: ৩০০/- টাকা।
৬. এন-ফি (নকলনবিশের পারিশ্রমিক): প্রতি ৩০০ শব্দ বা তার অংশের জন্য ২৪/- টাকা।
৭. ই-ফি (E-Fee): ১০০/- টাকা। কোট ফি: ২০/- টাকা।
''',
        ),
        _buildInfoCard(
          title: 'হেবা বা দানপত্র (Gift) দলিল রেজিস্ট্রেশন খরচ',
          content: '''
মুসলিম আইনে রক্তের সম্পর্কের মধ্যে (যেমন: স্বামী-স্ত্রী, পিতা-মাতা ও সন্তান, সহোদর ভাই-বোন, দাদা-দাদী ও নাতি-নাতনী) হেবা দলিলের ক্ষেত্রে বিশেষ রেয়াত প্রযোজ্য:
• রেজিস্ট্রেশন ফি: মাত্র ১০০/- টাকা (স্থির ফি)।
• স্ট্যাম্প শুল্ক: মাত্র ২০০/- টাকা।
• হলফনামা স্ট্যাম্প: ৩০০/- টাকা।
• ই-ফি: ১০০/- টাকা, এন-ফি ও স্থানীয় সরকার কর প্রযোজ্য নয়।
(রক্তের সম্পর্ক বহির্ভূত ব্যক্তির দানপত্রে স্বাভাবিক সাফ-কবলা দলিলের সমপরিমাণ শুল্ক ও ফি প্রযোজ্য হবে)।
''',
        ),
      ],
    );
  }

  // Tab 2: ই-নামজারি (E-Mutation)
  Widget _buildMutationTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildInfoCard(
          title: 'ই-নামজারি (Mutation) কেন প্রয়োজন?',
          content: '''
জমি ক্রয়, ওয়ারিশ সূত্রে প্রাপ্তি বা হেবা দলিলের মাধ্যমে মালিকানা পরিবর্তনের পর সরকারি রেকর্ড বা খতিয়ানে পূর্ববর্তী মালিকের নাম কেটে নতুন ক্রেতা বা মালিকের নাম লিপিবদ্ধ করার আইনি প্রক্রিয়াকে "নামজারি" (Mutation) বলা হয়।
নামজারি না থাকলে:
• আপনি সরকারের কাছে সরাসরি ভূমি উন্নয়ন কর (খাজনা) প্রদান করতে পারবেন না।
• ভবিষ্যতে জমি বিক্রয়, ব্যাংক ঋণ বা দলিল তৈরিতে জটিলতা সৃষ্টি হবে।
''',
        ),
        _buildInfoCard(
          title: 'সরকারি নির্দিষ্ট ই-নামজারি ফি: সর্বমোট ১,১৭০/- টাকা',
          content: '''
১. আবেদন ফি (কোর্ট ফি): ২০/- টাকা।
২. নোটিশ জারি ফি: ৫০/- টাকা।
৩. রেকর্ড সংশোধন ফি: ১,০০০/- টাকা।
৪. নতুন খতিয়ান ও ডিসিআর (DCR) ফি: ১০০/- টাকা।
সর্বমোট সরকারি ফি = ১,১৭০/- টাকা (অনলাইনে একপে বা মোবাইল ব্যাংকিংয়ে পরিশোধযোগ্য)। এর অতিরিক্ত কোনো অর্থ কাউকে দেওয়ার প্রয়োজন নেই।
''',
        ),
        _buildInfoCard(
          title: 'আবেদনের প্রয়োজনীয় কাগজপত্র ও ট্র্যাকিং',
          content: '''
• আবেদনকারীর জাতীয় পরিচয়পত্র (NID) ও মোবাইল নম্বর।
• মূল দলিল বা সার্টিফাইড দলিলের কপি।
• ওয়ারিশান সূত্রে হলে স্থানীয় চেয়ারম্যান/কাউন্সিলর কর্তৃক ওয়ারিশ সনদ।
• পিটিয়া খতিয়ান (পূর্ববর্তী সকল বায়া খতিয়ান ও সিএস/এসএ/আরএস খতিয়ান)।
• হালনাগাদ ভূমি উন্নয়ন কর (খাজনা) পরিশোধের দাখিলা।
ওয়েবসাইট: mutation.land.gov.bd তে গিয়ে আবেদন ও ট্র্যাক করা যায়।
''',
        ),
      ],
    );
  }

  // Tab 3: ভূমি উন্নয়ন কর (LD Tax)
  Widget _buildLdTaxTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildInfoCard(
          title: 'কৃষি জমির ভূমি উন্নয়ন কর হার',
          content: '''
• ২৫ বিঘা (৮.২৫ একর) পর্যন্ত কৃষি জমি: কর মওকুফ (শূন্য টাকা)। তবে মালিকানা প্রমাণের স্বার্থে প্রতিবছর মাত্র ১০ টাকা দাখিলা ফি দিয়ে "মওকুফ দাখিলা" সংগ্রহ করা বাধ্যতামূলক।
• ২৫ বিঘার অধিক কিন্তু ১০ একর পর্যন্ত: প্রতি শতাংশে ৫০ পয়সা।
• ১০ একরের অধিক কৃষি জমি: প্রতি শতাংশে ১.০০ টাকা।
''',
        ),
        _buildInfoCard(
          title: 'অকৃষি (বাণিজ্যিক, শিল্প ও আবাসিক) জমির কর ধাপ',
          content: '''
১. বিশেষ বাণিজ্যিক ও শিল্প এলাকা (ঢাকা, চট্টগ্রাম মেট্রোপলিটন): প্রতি শতাংশে সর্বোচ্চ নির্ধারিত হার (বাণিজ্যিক প্রায় ৩০০-৪০০ টাকা/শতাংশ)।
২. জেলা পৌরসভা এলাকা: আবাসিক ও বাণিজ্যিক ভিত্তিতে শ্রেণিভেদে ১৫ থেকে ৫০ টাকা প্রতি শতাংশ।
৩. উপজেলা পৌরসভা ও ইউনিয়ন এলাকা: ন্যূনতম ৫ থেকে ২০ টাকা প্রতি শতাংশ।
নাগরিকরা ldtax.gov.bd পোর্টালে নিজ খতিয়ান ও দাগ যুক্ত করে সরাসরি বিকাশ/নগদে খাজনা পরিশোধ করতে পারেন।
''',
        ),
      ],
    );
  }

  // Tab 4: জরিপ পরিভাষা ডিকশনারি
  Widget _buildGlossaryTab() {
    final terms = [
      {'term': 'CS জরিপ (Cadastral Survey)', 'def': '১৮৮৮ থেকে ১৯৪০ সালে ব্রিটিশ শাসনামলে পরিচালিত ভারত উপমহাদেশের সর্বপ্রথম বিজ্ঞানসম্মত প্লটভিত্তিক ভূমি জরিপ ও নকশা। একে ভারতচন্দ্র জরিপ বা কিস্তোয়ার জরিপও বলা হয়।'},
      {'term': 'SA জরিপ (State Acquisition)', 'def': '১৯৫০ সালের জমিদারি অধিগ্রহণ ও প্রজাস্বত্ব আইনের পর ১৯৫৬ থেকে ১৯৬২ সালে দ্রুততার সাথে জমিদারদের থেকে জমি হস্তান্তরের উদ্দেশ্যে তৈরি রেকর্ড। একে পিএস (PS) জরিপও বলা হয়।'},
      {'term': 'RS জরিপ (Revisional Survey)', 'def': 'সিএস ও এসএ রেকর্ডের ভুলত্রুটি সংশোধন করে সরেজমিনে জমি পরিমাপের মাধ্যমে প্রস্তুতকৃত আধুনিক নির্ভরযোগ খতিয়ান ও মৌজা নকশা।'},
      {'term': 'BS / BRS / সিটি জরিপ', 'def': 'বাংলাদেশ সার্ভে (Bangladesh Survey) বা আধুনিক ডিজিটাল ট্রাভার্স সার্ভে। ঢাকা মেট্রোপলিটন এলাকায় একে সিটি জরিপ বলা হয়।'},
      {'term': 'খতিয়ান (Khatian / পরচা)', 'def': 'নির্দিষ্ট মৌজায় কোনো একজন বা একাধিক প্রজার জমির মালিকানা, হিস্যা, দাগ নম্বর, জমির শ্রেণি ও খাজনার বিবরণ সংবলিত সরকারি রেজিস্টার বা রেকর্ড অব রাইটস (ROR)।'},
      {'term': 'দাগ নম্বর (Plot Number)', 'def': 'মৌজা নকশায় নির্দিষ্ট সীমানা দ্বারা চিহ্নিত প্রতিটি জমি বা ভূখণ্ডের স্বতন্ত্র পরিচিতি নম্বর।'},
      {'term': 'ছুট দাগ (Chhut Dag)', 'def': 'জরিপ চলাকালে কোনো কারণে যদি কোনো প্লট বা দাগ বাদ পড়ে যায় এবং পরে জরিপ শেষ হওয়ার পর তা নতুন দাগে অন্তর্ভুক্ত হয়, তাকে ছুট দাগ বলে।'},
      {'term': 'বাটা দাগ (Bata Dag)', 'def': 'একটি মূল দাগ ভেঙে দুই বা ততোধিক নতুন দাগ সৃষ্টি হলে বা বাদ পড়া দাগ মূল দাগের নিচে ভগ্নাংশ আকারে লেখা হলে (যেমন: ৫০১/১৫০) তাকে বাটা দাগ বলে।'},
      {'term': 'চিতা (Chita)', 'def': 'খতিয়ান তৈরির পূর্বে কিস্তোয়ারের সময় সরজমিনে পরিমাপের যে প্রাথমিক ফিল্ড রেজিস্টার তৈরি করা হয়।'},
      {'term': 'তৌজি (Tauzi)', 'def': 'কালেক্টরেটের রাজস্ব আদায়ের সুবিধার্থে জমিদারি বা জোতের যে মূল হিসাব নম্বর বরাদ্দ ছিল।'},
      {'term': 'ডিসিআর (DCR)', 'def': 'Duplicate Carbon Receipt - ভূমি অফিসে নামজারি ফি, বকেয়া খাজনা বা সরকারি দাবি আদায় রশিদ।'},
      {'term': 'দাখিলা (Dakhila)', 'def': 'ভূমি উন্নয়ন কর (খাজনা) পরিশোধের প্রমাণস্বরূপ তহসিলদার বা ভূমি কর্মকর্তা কর্তৃক প্রদত্ত সরকারি রসিদ।'},
      {'term': 'হিস্যা (Hissya)', 'def': 'খতিয়ানে বা দাগে একাধিক অংশীদারের মধ্যে কার কত অংশ (আনা-গণ্ডা-কড়া বা দশমিকে) তার অনুপাত।'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: terms.length,
      itemBuilder: (context, index) {
        final t = terms[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t['term']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t['def']!,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, height: 1.4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({required String title, required String content}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const Divider(height: 16),
            Text(
              content.trim(),
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
