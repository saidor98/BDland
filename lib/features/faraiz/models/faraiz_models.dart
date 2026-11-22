enum DeceasedGender {
  male,
  female,
}

enum HeirType {
  husband, // স্বামী
  wife, // স্ত্রী (১-৪)
  son, // ছেলে / পুত্র
  daughter, // মেয়ে / কন্যা
  father, // পিতা
  mother, // মাতা
  paternalGrandfather, // দাদা
  paternalGrandmother, // দাদী
  maternalGrandmother, // নানী
  fullBrother, // সহোদর ভাই
  fullSister, // সহোদর বোন
  consanguineBrother, // বৈমাত্রেয় ভাই
  consanguineSister, // বৈমাত্রেয় বোন
  uterineBrother, // বৈপিত্রেয় ভাই
  uterineSister, // বৈপিত্রেয় বোন
  sonSon, // পৌত্র (ছেলের ছেলে)
  sonDaughter, // পৌত্রী (ছেলের মেয়ে)
}

class HeirMeta {
  final HeirType type;
  final String banglaName;
  final bool isSharer;
  final bool isResiduary;
  final String descriptionBangla;

  const HeirMeta({
    required this.type,
    required this.banglaName,
    required this.isSharer,
    required this.isResiduary,
    required this.descriptionBangla,
  });

  static const Map<HeirType, HeirMeta> metaMap = {
    HeirType.husband: HeirMeta(
      type: HeirType.husband,
      banglaName: 'স্বামী',
      isSharer: true,
      isResiduary: false,
      descriptionBangla: 'সন্তান না থাকলে ১/২, সন্তান থাকলে ১/৪ অংশ',
    ),
    HeirType.wife: HeirMeta(
      type: HeirType.wife,
      banglaName: 'স্ত্রী (১ থেকে ৪ জন)',
      isSharer: true,
      isResiduary: false,
      descriptionBangla: 'সন্তান না থাকলে ১/৪, সন্তান থাকলে ১/৮ অংশ (একাধিক স্ত্রী সমবণ্টন)',
    ),
    HeirType.son: HeirMeta(
      type: HeirType.son,
      banglaName: 'ছেলে / পুত্র',
      isSharer: false,
      isResiduary: true,
      descriptionBangla: 'প্রধান আসাবা (কন্যাদের সাথে ২:১ অনুপাতে অবশিষ্ট সম্পত্তি)',
    ),
    HeirType.daughter: HeirMeta(
      type: HeirType.daughter,
      banglaName: 'মেয়ে / কন্যা',
      isSharer: true,
      isResiduary: true,
      descriptionBangla: 'ছেলে না থাকলে ১ জনের জন্য ১/২, একাধিক জনের জন্য ২/৩; ছেলের সাথে ২:১ অনুপাত',
    ),
    HeirType.father: HeirMeta(
      type: HeirType.father,
      banglaName: 'পিতা / বাবা',
      isSharer: true,
      isResiduary: true,
      descriptionBangla: 'পুত্র থাকলে ১/৬, কেবল কন্যা থাকলে ১/৬ + আসাবা, সন্তান না থাকলে পূর্ণ আসাবা',
    ),
    HeirType.mother: HeirMeta(
      type: HeirType.mother,
      banglaName: 'মাতা / মা',
      isSharer: true,
      isResiduary: false,
      descriptionBangla: 'সন্তান বা ২+ ভাইবোন থাকলে ১/৬, অন্যথায় ১/৩ অংশ',
    ),
    HeirType.paternalGrandfather: HeirMeta(
      type: HeirType.paternalGrandfather,
      banglaName: 'দাদা (পিতার পিতা)',
      isSharer: true,
      isResiduary: true,
      descriptionBangla: 'পিতা না থাকলে পিতার স্থলাভিষিক্ত হন',
    ),
    HeirType.paternalGrandmother: HeirMeta(
      type: HeirType.paternalGrandmother,
      banglaName: 'দাদী (পিতার মাতা)',
      isSharer: true,
      isResiduary: false,
      descriptionBangla: 'মাতা ও পিতা না থাকলে ১/৬ অংশ (নানী থাকলে সমবণ্টন)',
    ),
    HeirType.maternalGrandmother: HeirMeta(
      type: HeirType.maternalGrandmother,
      banglaName: 'নানী (মাতার মাতা)',
      isSharer: true,
      isResiduary: false,
      descriptionBangla: 'মাতা না থাকলে ১/৬ অংশ',
    ),
    HeirType.fullBrother: HeirMeta(
      type: HeirType.fullBrother,
      banglaName: 'সহোদর ভাই',
      isSharer: false,
      isResiduary: true,
      descriptionBangla: 'পুত্র/পিতা না থাকলে আসাবা (সহোদর বোনদের সাথে ২:১ অনুপাত)',
    ),
    HeirType.fullSister: HeirMeta(
      type: HeirType.fullSister,
      banglaName: 'সহোদর বোন',
      isSharer: true,
      isResiduary: true,
      descriptionBangla: 'ভাই/সন্তান না থাকলে ১ জনের জন্য ১/২, একাধিক হলে ২/৩ অংশ',
    ),
    HeirType.consanguineBrother: HeirMeta(
      type: HeirType.consanguineBrother,
      banglaName: 'বৈমাত্রেয় ভাই',
      isSharer: false,
      isResiduary: true,
      descriptionBangla: 'এক পিতা কিন্তু ভিন্ন মাতা; সহোদর ভাই থাকলে বঞ্চিত',
    ),
    HeirType.consanguineSister: HeirMeta(
      type: HeirType.consanguineSister,
      banglaName: 'বৈমাত্রেয় বোন',
      isSharer: true,
      isResiduary: true,
      descriptionBangla: 'সহোদর বোন ১ জন থাকলে অবশিষ্ট পূরণার্থে ১/৬ অংশ',
    ),
    HeirType.uterineBrother: HeirMeta(
      type: HeirType.uterineBrother,
      banglaName: 'বৈপিত্রেয় ভাই',
      isSharer: true,
      isResiduary: false,
      descriptionBangla: 'এক মাতা কিন্তু ভিন্ন পিতা; ১ জনের জন্য ১/৬, একাধিক হলে ১/৩ (নারী-পুরুষ সমান)',
    ),
    HeirType.uterineSister: HeirMeta(
      type: HeirType.uterineSister,
      banglaName: 'বৈপিত্রেয় বোন',
      isSharer: true,
      isResiduary: false,
      descriptionBangla: 'বৈপিত্রেয় ভাইয়ের সাথে ১:১ সমবণ্টন',
    ),
    HeirType.sonSon: HeirMeta(
      type: HeirType.sonSon,
      banglaName: 'পৌত্র (ছেলের ছেলে)',
      isSharer: false,
      isResiduary: true,
      descriptionBangla: 'পুত্র না থাকলে পুত্রের স্থানে আসাবা হিসেবে হিস্যা পান',
    ),
    HeirType.sonDaughter: HeirMeta(
      type: HeirType.sonDaughter,
      banglaName: 'পৌত্রী (ছেলের মেয়ে)',
      isSharer: true,
      isResiduary: true,
      descriptionBangla: 'কন্যা না থাকলে কন্যার স্থলাভিষিক্ত',
    ),
  };
}

class HeirResult {
  final HeirType type;
  final String titleBangla;
  final int count;
  final double fraction; // Decimal fraction e.g. 0.125
  final String fractionText; // Text fraction e.g. "১/৮"
  final double percentage; // e.g. 12.5%
  final double allocatedDecimal; // Land in Decimal
  final double allocatedKatha; // Land in Katha
  final double allocatedSqFt; // Land in Sq Ft
  final double allocatedTaka; // Cash in BDT
  final double perPersonDecimal;
  final double perPersonTaka;
  final bool isExcluded;
  final String legalBasisBangla;

  const HeirResult({
    required this.type,
    required this.titleBangla,
    required this.count,
    required this.fraction,
    required this.fractionText,
    required this.percentage,
    required this.allocatedDecimal,
    required this.allocatedKatha,
    required this.allocatedSqFt,
    required this.allocatedTaka,
    required this.perPersonDecimal,
    required this.perPersonTaka,
    required this.isExcluded,
    required this.legalBasisBangla,
  });
}

class FaraizDistributionResult {
  final DeceasedGender deceasedGender;
  final List<HeirResult> heirs;
  final bool isAwl;
  final bool isRadd;
  final double totalEstateDecimal;
  final double totalEstateTaka;
  final String summaryExplanationBangla;

  const FaraizDistributionResult({
    required this.deceasedGender,
    required this.heirs,
    required this.isAwl,
    required this.isRadd,
    required this.totalEstateDecimal,
    required this.totalEstateTaka,
    required this.summaryExplanationBangla,
  });
}
