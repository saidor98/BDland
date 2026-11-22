enum MouzaScaleRatio {
  scale16, // 16" = 1 mile (Standard CS/SA/RS rural)
  scale32, // 32" = 1 mile (Suburban/dense)
  scale64, // 64" = 1 mile (Urban/Bazaar)
  scale80, // 80" = 1 mile (City Survey / Dense Commercial)
}

class MouzaScaleInfo {
  final MouzaScaleRatio ratio;
  final String titleBangla;
  final String descriptionBangla;
  final double feetPerInch; // Actual ground feet represented by 1 map inch
  final double linksPerInch; // Actual ground links represented by 1 map inch
  final double chainsPerInch; // Actual ground chains represented by 1 map inch

  const MouzaScaleInfo({
    required this.ratio,
    required this.titleBangla,
    required this.descriptionBangla,
    required this.feetPerInch,
    required this.linksPerInch,
    required this.chainsPerInch,
  });

  static const List<MouzaScaleInfo> scales = [
    MouzaScaleInfo(
      ratio: MouzaScaleRatio.scale16,
      titleBangla: '১৬ ইঞ্চি = ১ মাইল (16" = 1 Mile)',
      descriptionBangla: 'বাংলাদেশের গ্রাম্য মৌজা নকশার সাধারণ মান (CS, SA, RS জরিপ)। ১ ইঞ্চি = ৩৩০ ফুট (৫০০ লিংক বা ৫ চেইন)।',
      feetPerInch: 330.0,
      linksPerInch: 500.0,
      chainsPerInch: 5.0,
    ),
    MouzaScaleInfo(
      ratio: MouzaScaleRatio.scale32,
      titleBangla: '৩২ ইঞ্চি = ১ মাইল (32" = 1 Mile)',
      descriptionBangla: 'ঘনবসতিপূর্ণ বা ছোট প্লটের গ্রামীণ/উপশহর এলাকা। ১ ইঞ্চি = ১৬৫ ফুট (২৫০ লিংক বা ২.৫ চেইন)।',
      feetPerInch: 165.0,
      linksPerInch: 250.0,
      chainsPerInch: 2.5,
    ),
    MouzaScaleInfo(
      ratio: MouzaScaleRatio.scale64,
      titleBangla: '৬৪ ইঞ্চি = ১ মাইল (64" = 1 Mile)',
      descriptionBangla: 'পৌরসভা, বাজার ও শহর এলাকা যেখানে জমির দাগ খুব ক্ষুদ্র। ১ ইঞ্চি = ৮২.৫ ফুট (১২৫ লিংক বা ১.২৫ চেইন)।',
      feetPerInch: 82.5,
      linksPerInch: 125.0,
      chainsPerInch: 1.25,
    ),
    MouzaScaleInfo(
      ratio: MouzaScaleRatio.scale80,
      titleBangla: '৮০ ইঞ্চি = ১ মাইল (80" = 1 Mile)',
      descriptionBangla: 'ঢাকা ও প্রধান প্রধান সিটি কর্পোরেশনের সিটি জরিপ নকশা। ১ ইঞ্চি = ৬৬ ফুট (১০০ লিংক বা ১ চেইন)।',
      feetPerInch: 66.0,
      linksPerInch: 100.0,
      chainsPerInch: 1.0,
    ),
  ];

  static MouzaScaleInfo getByRatio(MouzaScaleRatio ratio) {
    return scales.firstWhere((element) => element.ratio == ratio, orElse: () => scales.first);
  }
}

class GroundDistanceResult {
  final double groundFeet;
  final double groundMeters;
  final double groundLinks;
  final double groundChains;
  final double groundHath;

  const GroundDistanceResult({
    required this.groundFeet,
    required this.groundMeters,
    required this.groundLinks,
    required this.groundChains,
    required this.groundHath,
  });
}

class GroundAreaResult {
  final double groundAreaSqFt;
  final double groundAreaDecimal;
  final double groundAreaKatha;
  final double lengthFeet;
  final double widthFeet;

  const GroundAreaResult({
    required this.groundAreaSqFt,
    required this.groundAreaDecimal,
    required this.groundAreaKatha,
    required this.lengthFeet,
    required this.widthFeet,
  });
}
