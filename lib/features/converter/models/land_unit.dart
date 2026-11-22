enum LandUnitType {
  sqFeet,
  sqMeter,
  sqLink,
  sqChain,
  sqHath,
  decimal,
  katha,
  bigha,
  acre,
  hectare,
  chhatak,
  kaniStandard, // 40 Decimal
  kaniComilla, // 120 Decimal
  kaniShahi, // 160 Decimal
  gonda,
  kora,
  kranti,
  til,
}

class LandUnit {
  final LandUnitType type;
  final String banglaName;
  final String englishName;
  final String symbolBangla;
  final double sqFtEquivalent; // Factor: 1 unit = ? sq feet
  final String descriptionBangla;

  const LandUnit({
    required this.type,
    required this.banglaName,
    required this.englishName,
    required this.symbolBangla,
    required this.sqFtEquivalent,
    required this.descriptionBangla,
  });

  static const List<LandUnit> allUnits = [
    LandUnit(
      type: LandUnitType.decimal,
      banglaName: 'শতাংশ / শতক / ডেসিমেল',
      englishName: 'Decimal / Shotok',
      symbolBangla: 'শতক',
      sqFtEquivalent: 435.60,
      descriptionBangla: '১ শতক = ৪৩৫.৬০ বর্গফুট = ১০০০ বর্গলিংক',
    ),
    LandUnit(
      type: LandUnitType.katha,
      banglaName: 'কাঠা (সরকারি মান)',
      englishName: 'Katha (Govt Standard)',
      symbolBangla: 'কাঠা',
      sqFtEquivalent: 720.00,
      descriptionBangla: '১ কাঠা = ৭২০ বর্গফুট = ১.৬৫৩ শতক = ১৬ ছটাক',
    ),
    LandUnit(
      type: LandUnitType.bigha,
      banglaName: 'বিঘা (সরকারি ৩৩ শতক)',
      englishName: 'Bigha (Standard 33 Dec)',
      symbolBangla: 'বিঘা',
      sqFtEquivalent: 14374.80, // 33 * 435.60
      descriptionBangla: '১ বিঘা = ৩৩ শতক = ২০ কাঠা (১৪,৩৭৪.৮ বর্গফুট)',
    ),
    LandUnit(
      type: LandUnitType.acre,
      banglaName: 'একর',
      englishName: 'Acre',
      symbolBangla: 'একর',
      sqFtEquivalent: 43560.00,
      descriptionBangla: '১ একর = ১০০ শতক = ৪৩,৫৬০ বর্গফুট = ৩ বিঘা ৮ ছটাক',
    ),
    LandUnit(
      type: LandUnitType.hectare,
      banglaName: 'হেক্টর',
      englishName: 'Hectare',
      symbolBangla: 'হেক্টর',
      sqFtEquivalent: 107639.10, // 10,000 sq m * 10.7639
      descriptionBangla: '১ হেক্টর = ২.৪৭১ একর = ২৪৭.১০৫ শতক = ১০,০০০ বর্গমিটার',
    ),
    LandUnit(
      type: LandUnitType.sqFeet,
      banglaName: 'বর্গফুট',
      englishName: 'Sq. Feet',
      symbolBangla: 'বর্গফুট',
      sqFtEquivalent: 1.0,
      descriptionBangla: '১ বর্গফুট = ১৪৪ বর্গইঞ্চি',
    ),
    LandUnit(
      type: LandUnitType.sqMeter,
      banglaName: 'বর্গমিটার',
      englishName: 'Sq. Meter',
      symbolBangla: 'বর্গমিটার',
      sqFtEquivalent: 10.7639104,
      descriptionBangla: '১ বর্গমিটার = ১০.৭৬৪ বর্গফুট',
    ),
    LandUnit(
      type: LandUnitType.sqLink,
      banglaName: 'বর্গলিংক (Gunter\'s Link)',
      englishName: 'Sq. Link',
      symbolBangla: 'বর্গলিংক',
      sqFtEquivalent: 0.43560, // 0.66 ft * 0.66 ft
      descriptionBangla: '১ বর্গলিংক = ০.৪৩৫৬ বর্গফুট (১০০০ বর্গলিংক = ১ শতক)',
    ),
    LandUnit(
      type: LandUnitType.sqChain,
      banglaName: 'বর্গচেইন (Gunter\'s Chain)',
      englishName: 'Sq. Chain',
      symbolBangla: 'বর্গচেইন',
      sqFtEquivalent: 4356.00, // 66 ft * 66 ft
      descriptionBangla: '১ বর্গচেইন = ১০ শতক = ৪,৩৫৬ বর্গফুট = ১০০০০ বর্গলিংক',
    ),
    LandUnit(
      type: LandUnitType.sqHath,
      banglaName: 'বর্গহাত',
      englishName: 'Sq. Hath',
      symbolBangla: 'বর্গহাত',
      sqFtEquivalent: 2.25, // 1.5 ft * 1.5 ft
      descriptionBangla: '১ বর্গহাত = ২.২৫ বর্গফুট (১৯৩.৬ বর্গহাত = ১ শতক)',
    ),
    LandUnit(
      type: LandUnitType.chhatak,
      banglaName: 'ছটাক',
      englishName: 'Chhatak',
      symbolBangla: 'ছটাক',
      sqFtEquivalent: 45.00,
      descriptionBangla: '১ ছটাক = ৪৫ বর্গফুট = ১৬ ছটাকে ১ কাঠা',
    ),
    LandUnit(
      type: LandUnitType.kaniStandard,
      banglaName: 'কানি (সরকারি ৪০ শতক)',
      englishName: 'Kani (Standard 40 Dec)',
      symbolBangla: 'কানি',
      sqFtEquivalent: 17424.00, // 40 * 435.6
      descriptionBangla: '১ কানি = ৪০ শতক = ১৭,৪২৪ বর্গফুট = ২০ গণ্ডা',
    ),
    LandUnit(
      type: LandUnitType.kaniComilla,
      banglaName: 'কানি (কুমিল্লা/নোয়াখালী ১২০ শতক)',
      englishName: 'Kani (Comilla/Noakhali 120 Dec)',
      symbolBangla: 'কানি (১২০)',
      sqFtEquivalent: 52272.00, // 120 * 435.6
      descriptionBangla: 'আঞ্চলিক কানি = ১২০ শতক = ৫২,২৭২ বর্গফুট',
    ),
    LandUnit(
      type: LandUnitType.kaniShahi,
      banglaName: 'শাহী কানি (সিলেট/চট্টগ্রাম ১৬০ শতক)',
      englishName: 'Shahi Kani (Sylhet/Ctg 160 Dec)',
      symbolBangla: 'শাহী কানি',
      sqFtEquivalent: 69696.00, // 160 * 435.6
      descriptionBangla: 'শাহী কানি = ১৬০ শতক = ৬৯,৬৯৬ বর্গফুট',
    ),
    LandUnit(
      type: LandUnitType.gonda,
      banglaName: 'গণ্ডা (৪০ শতক কানির হিসাব)',
      englishName: 'Gonda',
      symbolBangla: 'গণ্ডা',
      sqFtEquivalent: 871.20, // 40 dec / 20 = 2 dec = 871.2 sq ft
      descriptionBangla: '১ গণ্ডা = ২ শতক = ৮৭১.২ বর্গফুট = ৪ কড়া',
    ),
    LandUnit(
      type: LandUnitType.kora,
      banglaName: 'কড়া',
      englishName: 'Kora',
      symbolBangla: 'কড়া',
      sqFtEquivalent: 217.80, // 0.5 dec
      descriptionBangla: '১ কড়া = ০.৫০ শতক = ২১৭.৮ বর্গফুট = ৩ ক্রান্তি',
    ),
    LandUnit(
      type: LandUnitType.kranti,
      banglaName: 'ক্রান্তি',
      englishName: 'Kranti',
      symbolBangla: 'ক্রান্তি',
      sqFtEquivalent: 72.60, // 217.8 / 3
      descriptionBangla: '১ ক্রান্তি = ৭২.৬০ বর্গফুট = ২০ তিল',
    ),
    LandUnit(
      type: LandUnitType.til,
      banglaName: 'তিল',
      englishName: 'Til',
      symbolBangla: 'তিল',
      sqFtEquivalent: 3.63, // 72.6 / 20
      descriptionBangla: '১ তিল = ৩.৬৩ বর্গফুট (ভূমি পরিমাপের ক্ষুদ্রতম একক)',
    ),
  ];

  static LandUnit getByType(LandUnitType type) {
    return allUnits.firstWhere(
      (element) => element.type == type,
      orElse: () => allUnits.first,
    );
  }
}
