import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';

class AnaGondaKeypad extends StatelessWidget {
  final ValueChanged<int> onAnaSelected;
  final ValueChanged<int> onGondaSelected;
  final ValueChanged<int> onKoraSelected;
  final ValueChanged<int> onKrantiSelected;
  final ValueChanged<int> onTilSelected;

  const AnaGondaKeypad({
    super.key,
    required this.onAnaSelected,
    required this.onGondaSelected,
    required this.onKoraSelected,
    required this.onKrantiSelected,
    required this.onTilSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.keyboard_outlined, size: 18, color: AppColors.primaryGreen),
              SizedBox(width: 6),
              Text(
                'প্রথাগত খতিয়ান হিস্যা কীপ্যাড (আনা-গণ্ডা-কড়া-ক্রান্তি)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreenDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Ana Row (1 to 16 Ana with symbols)
          const Text('আনা নির্বাচন করুন (১-১৬ আনা):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(16, (i) {
                final ana = i + 1;
                // Traditional symbols: 1 ana = ৵, 2 ana = ৶, 3 ana = ৸, 4 ana = ১//
                String symbol = '$ana';
                if (ana == 1) symbol = '৵ ১';
                if (ana == 2) symbol = '৶ ২';
                if (ana == 3) symbol = '৸ ৩';
                if (ana == 4) symbol = '১ আনা';
                if (ana == 8) symbol = '৮ আনা';
                if (ana == 16) symbol = '১৬ আনা';

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    backgroundColor: ana == 16 ? AppColors.primaryGreenLight : const Color(0xFFF8FAFC),
                    side: BorderSide(color: ana == 16 ? AppColors.primaryGreen : Colors.grey.shade300),
                    label: Text(
                      symbol,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: ana == 16 ? AppColors.primaryGreen : Colors.black87,
                      ),
                    ),
                    onPressed: () => onAnaSelected(ana),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 10),

          // Gonda Row (1 to 20 Gonda)
          const Text('গণ্ডা নির্বাচন করুন (১-২০ গণ্ডা):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 14, 15, 16, 18, 19, 20].map((g) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    backgroundColor: const Color(0xFFFFFBEB),
                    side: BorderSide(color: Colors.amber.shade300),
                    label: Text(
                      '${BanglaNumerals.toBangla(g)} গণ্ডা',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF92400E)),
                    ),
                    onPressed: () => onGondaSelected(g),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // Kora (1-4) & Kranti (1-3) Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('কড়া (১-৪):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [1, 2, 3, 4].map((k) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(BanglaNumerals.toBangla(k)),
                            onPressed: () => onKoraSelected(k),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ক্রান্তি (১-৩):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [1, 2, 3].map((kr) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(BanglaNumerals.toBangla(kr)),
                            onPressed: () => onKrantiSelected(kr),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
