import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class UserGuideView extends StatelessWidget {
  const UserGuideView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0F3E2E),
                  AppColors.primaryGreen,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.menu_book, color: Colors.white, size: 36),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'বিডি ল্যান্ড প্রো ব্যবহারবিধি ও গাইডলাইন',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'সহজে জমি পরিমাপ, নকশা যাচাই ও খতিয়ান বিশ্লেষণের সম্পূর্ণ নির্দেশিকা',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildGuideItem(
            step: '১',
            title: 'মৌজা ম্যাপ ক্যালিব্রেশন ও ডিজিটাল পরিমাপ',
            description:
                '১. "মৌজা ম্যাপ পরিমাপ" টুলে গিয়ে আপনার সিটের ছবি বা স্ক্যান কপি আপলোড করুন।\n'
                '২. স্কেল নির্বাচন করুন (১৬ ইঞ্চি = ১ মাইল, ৩২ ইঞ্চি = ১ মাইল, বা ৬৪ ইঞ্চি)।\n'
                '৩. মানচিত্রে জানা দূরত্বের যেকোনো রেখায় ২টি পয়েন্ট সেট করে ক্যালিব্রেট করুন।\n'
                '৪. এরপর যেকোনো প্লটের সীমানায় ট্যাপ করলেই স্বয়ংক্রিয়ভাবে লিংক, ফুট এবং শতাংশে ক্ষেত্রফল দেখতে পাবেন।',
            icon: Icons.architecture,
          ),

          const SizedBox(height: 14),

          _buildGuideItem(
            step: '২',
            title: 'চতুর্ভুজ পরিমাপে হিরন বনাম আমিন গড় পদ্ধতির পার্থক্য',
            description:
                'প্রথাগত আমিনরা (উঃ + দঃ)/২ × (পূঃ + পঃ)/২ সূত্রে গড় পদ্ধতিতে জমি মাপেন, যাতে অনেক ক্ষেত্রে জমির মাপে মারাত্মক ভুল ও ঘাটতি দেখা যায়।\n'
                'সঠিক নিয়মে ৪টি বাহুর সাথে অন্তত ১টি কর্ণ মেপে দুটি ত্রিভুজে ভাগ করে হিরন (Heron\'s) সূত্রে মাপুন। এই অ্যাপের QuadMaster টুলে স্বয়ংক্রিয়ভাবে দুটি পদ্ধতির নির্ভুল পার্থক্য ও বণ্টন অনুপাত গণনা করে দেওয়া হয়।',
            icon: Icons.crop_square,
          ),

          const SizedBox(height: 14),

          _buildGuideItem(
            step: '৩',
            title: 'আনা-গণ্ডা-কড়া-ক্রান্তি-তিল রূপান্তর ও খতিয়ান হিস্যা',
            description:
                '১ আনা = ২০ গণ্ডা\n'
                '১ গণ্ডা = ৪ কড়া\n'
                '১ কড়া = ৩ ক্রান্তি\n'
                '১ ক্রান্তি = ২০ তিল\n'
                'সুতরাং মোট ১৬ আনা = ৩২০ গণ্ডা = ১২৮০ কড়া = ৩৮৪০ ক্রান্তি = ৭৬৮০০ তিল।\n'
                'খতিয়ান বিশ্লেষক টুলে খতিয়ানের ১৬ আনা পূর্ণ হয়েছে কি না তা ১ ক্লিকেই স্বয়ংক্রিয় যাচাই করা যায়।',
            icon: Icons.sync_alt,
          ),

          const SizedBox(height: 14),

          _buildGuideItem(
            step: '৪',
            title: 'মুসলিম ফারায়েজ ও ওয়ারিশ সম্পত্তি বণ্টন',
            description:
                'হানাফী আইন অনুসারে আসহাবে ফুরুজ ও আসাবা নীতিতে স্বয়ংক্রিয় গণনা সম্পন্ন হয়।\n'
                'যদি অংশীদারদের মোট অংশের যোগফল ১ এর বেশি হয় তবে "আওল" (Awl) নিয়মে আনুপাতিক হ্রাস করা হয়, এবং ১ এর কম হলে "রদ" (Radd) নীতিতে অবশিষ্ট অংশ ফেরত বণ্টন করা হয়।',
            icon: Icons.account_tree,
          ),

          const SizedBox(height: 14),

          _buildGuideItem(
            step: '৫',
            title: 'অফলাইন ও রিপোর্ট এক্সপোর্ট',
            description:
                'এই অ্যাপের সকল হিসাব ১০০% অফলাইনে কাজ করে। প্রিন্ট স্টুডিও বা সার্ভেয়ার মেমো থেকে যেকোনো সময় সরাসরি ক্লায়েন্ট চালান ও A4 সাইজের দাগ ও খতিয়ান সার্টিফিকেট PDF ডাউনলোড বা শেয়ার করা যায়।',
            icon: Icons.picture_as_pdf,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGuideItem({
    required String step,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Icon(icon, color: AppColors.primaryGreen, size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
