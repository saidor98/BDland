import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ReviewSection extends StatefulWidget {
  const ReviewSection({super.key});

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  int _tabIndex = 0; // 0 = রিভিউ, 1 = বিশেষজ্ঞ

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs: রিভিউ / বিশেষজ্ঞ
        Center(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSubTab(
                  icon: Icons.star_outline,
                  label: 'রিভিউ',
                  isActive: _tabIndex == 0,
                  onTap: () => setState(() => _tabIndex = 0),
                ),
                const SizedBox(width: 4),
                _buildSubTab(
                  icon: Icons.badge_outlined,
                  label: 'বিশেষজ্ঞ',
                  isActive: _tabIndex == 1,
                  onTap: () => setState(() => _tabIndex = 1),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Rating Summary Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Row(
                  children: List.generate(
                    5,
                    (i) => const Icon(
                      Icons.star,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '৪.৯ • ১০২টি যাচাইকৃত রিভিউ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                _showAllReviewsDialog(context);
              },
              child: const Row(
                children: [
                  Text(
                    'সব রিভিউ দেখুন',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: AppColors.primaryGreen,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Review Cards (Responsive Grid or Wrap)
        LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 650;
            if (isWide) {
              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _ReviewCard1()),
                  SizedBox(width: 14),
                  Expanded(child: _ReviewCard2()),
                ],
              );
            } else {
              return const Column(
                children: [
                  _ReviewCard1(),
                  SizedBox(height: 12),
                  _ReviewCard2(),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildSubTab({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppColors.primaryGreen : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppColors.primaryGreen : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllReviewsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('গ্রাহক মতামত ও প্রতিক্রিয়া'),
          ],
        ),
        content: const SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ReviewCard1(),
                SizedBox(height: 12),
                _ReviewCard2(),
                SizedBox(height: 12),
                _ReviewCard3(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বন্ধ করুন'),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard1 extends StatelessWidget {
  const _ReviewCard1();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                child: const Icon(Icons.person, color: Colors.grey, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Azam munshi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 13,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'যাচাইকৃত গ্রাহক • ৪ আগস্ট ২০২৬',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
              (i) => const Icon(
                Icons.star,
                size: 14,
                color: Color(0xFFF59E0B),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'আমি বিডি ল্যান্ড প্রো অ্যাপটির একজন শুভাকাঙ্ক্ষী ও সেবাগ্রহীতা। দীর্ঘ দিন ধরে অ্যাপটি আমি অত্যন্ত সুচারুরূপে ব্যবহার করে আসছি। ভূমি পরিমাপ ও ভাগ বণ্টন, মৌজা ম্যাপ পরিমাপ, মৌজা ম্যাপ ওভারল্যাপিং, জয়েন্টসহ সংশ্লিষ্ট আরো বহু কাজ খুবই অনায়াসে করা যায়। ডিজিটালাইজ সময়ের অংশ হিসেবে এ্যাপটির গুরুত্ব অনস্বীকার্য।',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade700,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard2 extends StatelessWidget {
  const _ReviewCard2();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryGreen.withOpacity(0.12),
                child: const Text(
                  'JH',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jahidul Hasan444',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 13,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'যাচাইকৃত গ্রাহক • ১৫ আগস্ট ২০২৬',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
              (i) => const Icon(
                Icons.star,
                size: 14,
                color: Color(0xFFF59E0B),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'খুব চমৎকার একটি সফটওয়্যার। আমিন এবং সাধারণ জমি মালিকদের জন্য একটি অনন্য সংযোজন। খতিয়ানের আনা-গণ্ডা হিসাব ও ফারায়েজ বন্টন নিখুঁতভাবে হয়।',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade700,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard3 extends StatelessWidget {
  const _ReviewCard3();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryGreen.withOpacity(0.12),
                child: const Icon(Icons.person, color: AppColors.primaryGreen),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'আমিন মোঃ রফিকুল ইসলাম',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'পেশাদার সার্ভেয়ার, ঢাকা • ১০ আগস্ট ২০২৬',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'চতুর্ভুজ পরিমাপে হিরন ও গড় পদ্ধতির পার্থক্য তাৎক্ষণিক বের করে দেওয়া এবং মৌজা নকশার গান্টার স্কেল ক্যালিব্রেশন মাঠ পর্যায়ে অনেক সময় বাঁচিয়ে দেয়।',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
