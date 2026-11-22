import '../../../core/constants/bangla_numerals.dart';
import '../models/faraiz_models.dart';

class FaraizEngine {
  FaraizEngine._();

  static const double sqFtPerDecimal = 435.60;
  static const double sqFtPerKatha = 720.00;

  /// Calculate Islamic inheritance under Sunni Hanafi jurisprudence
  static FaraizDistributionResult calculate({
    required DeceasedGender deceasedGender,
    required Map<HeirType, int> heirCounts,
    double totalEstateDecimal = 0.0,
    double totalEstateTaka = 0.0,
    bool applyMflo1961 = false, // Muslim Family Laws Ordinance 1961 Sec 4
  }) {
    // Clean up counts (ignore non-positive)
    final counts = <HeirType, int>{};
    heirCounts.forEach((key, value) {
      if (value > 0) counts[key] = value;
    });

    // Ensure opposite spouse only
    if (deceasedGender == DeceasedGender.male) {
      counts.remove(HeirType.husband);
    } else {
      counts.remove(HeirType.wife);
    }

    final hasSons = (counts[HeirType.son] ?? 0) > 0;
    final hasDaughters = (counts[HeirType.daughter] ?? 0) > 0;
    final hasSonSons = (counts[HeirType.sonSon] ?? 0) > 0;
    final hasSonDaughters = (counts[HeirType.sonDaughter] ?? 0) > 0;

    final hasChildren = hasSons || hasDaughters;
    final hasGrandchildren = hasSonSons || hasSonDaughters;
    final hasDescendants = hasChildren || hasGrandchildren;

    final hasFather = (counts[HeirType.father] ?? 0) > 0;
    final hasMother = (counts[HeirType.mother] ?? 0) > 0;
    final hasPaternalGrandfather = (counts[HeirType.paternalGrandfather] ?? 0) > 0;

    final fullBrothersCount = counts[HeirType.fullBrother] ?? 0;
    final fullSistersCount = counts[HeirType.fullSister] ?? 0;
    final consanguineBrothersCount = counts[HeirType.consanguineBrother] ?? 0;
    final consanguineSistersCount = counts[HeirType.consanguineSister] ?? 0;
    final uterineBrothersCount = counts[HeirType.uterineBrother] ?? 0;
    final uterineSistersCount = counts[HeirType.uterineSister] ?? 0;

    final totalSiblings = fullBrothersCount +
        fullSistersCount +
        consanguineBrothersCount +
        consanguineSistersCount +
        uterineBrothersCount +
        uterineSistersCount;

    // Track excluded heirs (হিজাব বা বঞ্চনা)
    final excluded = <HeirType, String>{};

    // 1. Exclusion Rules (হিজাব বা বঞ্চিতকরণ)
    if (hasSons) {
      if (!applyMflo1961) {
        if (hasSonSons) excluded[HeirType.sonSon] = 'পুত্রের উপস্থিতিতে পৌত্র মাহজুব (বঞ্চিত)';
        if (hasSonDaughters) excluded[HeirType.sonDaughter] = 'পুত্রের উপস্থিতিতে পৌত্রী মাহজুব (বঞ্চিত)';
      }
      if (fullBrothersCount > 0) excluded[HeirType.fullBrother] = 'পুত্রের উপস্থিতিতে ভাই বঞ্চিত';
      if (fullSistersCount > 0) excluded[HeirType.fullSister] = 'পুত্রের উপস্থিতিতে বোন বঞ্চিত';
      if (consanguineBrothersCount > 0) excluded[HeirType.consanguineBrother] = 'পুত্রের উপস্থিতিতে বৈমাত্রেয় ভাই বঞ্চিত';
      if (consanguineSistersCount > 0) excluded[HeirType.consanguineSister] = 'পুত্রের উপস্থিতিতে বৈমাত্রেয় বোন বঞ্চিত';
      if (uterineBrothersCount > 0) excluded[HeirType.uterineBrother] = 'পুত্রের উপস্থিতিতে বৈপিত্রেয় ভাই বঞ্চিত';
      if (uterineSistersCount > 0) excluded[HeirType.uterineSister] = 'পুত্রের উপস্থিতিতে বৈপিত্রেয় বোন বঞ্চিত';
    }

    if (hasFather) {
      if (hasPaternalGrandfather) excluded[HeirType.paternalGrandfather] = 'পিতার উপস্থিতিতে দাদা বঞ্চিত';
      if ((counts[HeirType.paternalGrandmother] ?? 0) > 0) {
        excluded[HeirType.paternalGrandmother] = 'পিতার উপস্থিতিতে পিতার মাতা (দাদী) বঞ্চিত';
      }
      if (fullBrothersCount > 0) excluded[HeirType.fullBrother] = 'পিতার উপস্থিতিতে ভাই বঞ্চিত';
      if (fullSistersCount > 0) excluded[HeirType.fullSister] = 'পিতার উপস্থিতিতে বোন বঞ্চিত';
      if (consanguineBrothersCount > 0) excluded[HeirType.consanguineBrother] = 'পিতার উপস্থিতিতে বৈমাত্রেয় ভাই বঞ্চিত';
      if (consanguineSistersCount > 0) excluded[HeirType.consanguineSister] = 'পিতার উপস্থিতিতে বৈমাত্রেয় বোন বঞ্চিত';
      if (uterineBrothersCount > 0) excluded[HeirType.uterineBrother] = 'পিতার উপস্থিতিতে বৈপিত্রেয় ভাই বঞ্চিত';
      if (uterineSistersCount > 0) excluded[HeirType.uterineSister] = 'পিতার উপস্থিতিতে বৈপিত্রেয় বোন বঞ্চিত';
    }

    if (hasMother) {
      if ((counts[HeirType.paternalGrandmother] ?? 0) > 0) {
        excluded[HeirType.paternalGrandmother] = 'মাতার উপস্থিতিতে দাদী বঞ্চিত';
      }
      if ((counts[HeirType.maternalGrandmother] ?? 0) > 0) {
        excluded[HeirType.maternalGrandmother] = 'মাতার উপস্থিতিতে নানী বঞ্চিত';
      }
    }

    if (!hasFather && hasPaternalGrandfather) {
      // Under Hanafi (Abu Hanifa), grandfather excludes all siblings
      if (fullBrothersCount > 0) excluded[HeirType.fullBrother] = 'দাদার উপস্থিতিতে ভাই মাহজুব (হানাফি মাযহাব)';
      if (fullSistersCount > 0) excluded[HeirType.fullSister] = 'দাদার উপস্থিতিতে বোন মাহজুব (হানাফি মাযহাব)';
      if (consanguineBrothersCount > 0) excluded[HeirType.consanguineBrother] = 'দাদার উপস্থিতিতে বৈমাত্রেয় ভাই মাহজুব';
      if (consanguineSistersCount > 0) excluded[HeirType.consanguineSister] = 'দাদার উপস্থিতিতে বৈমাত্রেয় বোন মাহজুব';
      if (uterineBrothersCount > 0) excluded[HeirType.uterineBrother] = 'দাদার উপস্থিতিতে বৈপিত্রেয় ভাই মাহজুব';
      if (uterineSistersCount > 0) excluded[HeirType.uterineSister] = 'দাদার উপস্থিতিতে বৈপিত্রেয় বোন মাহজুব';
    }

    if (hasDescendants && !hasSons) {
      // Daughters exclude uterine siblings
      if (uterineBrothersCount > 0) excluded[HeirType.uterineBrother] = 'সন্তান/পৌত্রীর উপস্থিতিতে বৈপিত্রেয় ভাই বঞ্চিত';
      if (uterineSistersCount > 0) excluded[HeirType.uterineSister] = 'সন্তান/পৌত্রীর উপস্থিতিতে বৈপিত্রেয় বোন বঞ্চিত';
    }

    if (fullBrothersCount > 0 && !excluded.containsKey(HeirType.fullBrother)) {
      if (consanguineBrothersCount > 0) {
        excluded[HeirType.consanguineBrother] = 'সহোদর ভাইয়ের উপস্থিতিতে বৈমাত্রেয় ভাই বঞ্চিত';
      }
      if (consanguineSistersCount > 0) {
        excluded[HeirType.consanguineSister] = 'সহোদর ভাইয়ের উপস্থিতিতে বৈমাত্রেয় বোন বঞ্চিত';
      }
    }

    // Determine Sharers' fractions (Ashab al-Furud)
    final sharerFractions = <HeirType, double>{};
    final legalNotes = <HeirType, String>{};

    // 1. Husband (স্বামী)
    if (counts.containsKey(HeirType.husband) && !excluded.containsKey(HeirType.husband)) {
      if (hasDescendants) {
        sharerFractions[HeirType.husband] = 1.0 / 4.0;
        legalNotes[HeirType.husband] = 'সন্তানের উপস্থিতিতে স্বামী পান ১/৪ অংশ (সূরা নিসা: ১২)';
      } else {
        sharerFractions[HeirType.husband] = 1.0 / 2.0;
        legalNotes[HeirType.husband] = 'সন্তান না থাকায় স্বামী পান ১/২ অংশ (সূরা নিসা: ১২)';
      }
    }

    // 2. Wife / Wives (স্ত্রী)
    if (counts.containsKey(HeirType.wife) && !excluded.containsKey(HeirType.wife)) {
      if (hasDescendants) {
        sharerFractions[HeirType.wife] = 1.0 / 8.0;
        legalNotes[HeirType.wife] = 'সন্তানের উপস্থিতিতে স্ত্রী(গণ) পান ১/৮ অংশ (সূরা নিসা: ১২)';
      } else {
        sharerFractions[HeirType.wife] = 1.0 / 4.0;
        legalNotes[HeirType.wife] = 'সন্তান না থাকায় স্ত্রী(গণ) পান ১/৪ অংশ (সূরা নিসা: ১২)';
      }
    }

    // 3. Mother (মাতা)
    if (hasMother && !excluded.containsKey(HeirType.mother)) {
      if (hasDescendants || totalSiblings >= 2) {
        sharerFractions[HeirType.mother] = 1.0 / 6.0;
        legalNotes[HeirType.mother] = 'সন্তান বা একাধিক ভাইবোন থাকায় মাতা পান ১/৬ অংশ (সূরা নিসা: ১১)';
      } else {
        // Umariyyatan check: only spouse + father + mother
        final isSpousePresent = counts.containsKey(HeirType.husband) || counts.containsKey(HeirType.wife);
        if (isSpousePresent && hasFather && !hasDescendants && totalSiblings == 0) {
          final spouseFraction = counts.containsKey(HeirType.husband) ? 0.5 : 0.25;
          sharerFractions[HeirType.mother] = (1.0 - spouseFraction) / 3.0;
          legalNotes[HeirType.mother] = 'উমারিয়্যাতান মাসআলা: স্বামী/স্ত্রীর অংশের পর অবশিষ্টের ১/৩ অংশ';
        } else {
          sharerFractions[HeirType.mother] = 1.0 / 3.0;
          legalNotes[HeirType.mother] = 'সন্তান বা একাধিক ভাইবোন না থাকায় মাতা পান ১/৩ অংশ (সূরা নিসা: ১১)';
        }
      }
    }

    // 4. Father (পিতা)
    if (hasFather && !excluded.containsKey(HeirType.father)) {
      if (hasSons || hasSonSons) {
        sharerFractions[HeirType.father] = 1.0 / 6.0;
        legalNotes[HeirType.father] = 'পুত্র বা পৌত্র থাকায় পিতা পান নির্দিষ্ট ১/৬ অংশ (সূরা নিসা: ১১)';
      } else if (hasDaughters || hasSonDaughters) {
        sharerFractions[HeirType.father] = 1.0 / 6.0; // Plus Asaba later
        legalNotes[HeirType.father] = 'কেবল কন্যা/পৌত্রী থাকায় পিতা পান ১/৬ অংশ + আসাবা হিসেবে অবশিষ্ট অংশ';
      } else {
        legalNotes[HeirType.father] = 'সন্তান না থাকায় পিতা পূর্ণ আসাবা (অবশিষ্টভোগী) হিসেবে উত্তরাধিকারী';
      }
    }

    // 5. Paternal Grandfather (দাদা)
    if (hasPaternalGrandfather && !excluded.containsKey(HeirType.paternalGrandfather)) {
      if (hasSons || hasSonSons) {
        sharerFractions[HeirType.paternalGrandfather] = 1.0 / 6.0;
        legalNotes[HeirType.paternalGrandfather] = 'পিতা না থাকায় এবং পুত্রের উপস্থিতিতে দাদা পান ১/৬ অংশ';
      } else if (hasDaughters || hasSonDaughters) {
        sharerFractions[HeirType.paternalGrandfather] = 1.0 / 6.0;
        legalNotes[HeirType.paternalGrandfather] = 'পিতা না থাকায় দাদা পান ১/৬ অংশ + আসাবা';
      } else {
        legalNotes[HeirType.paternalGrandfather] = 'পিতা ও সন্তান না থাকায় দাদা আসাবা হিসেবে পাবেন';
      }
    }

    // 6. Grandmothers (দাদী / নানী)
    final eligibleGrandmothers = <HeirType>[];
    if (counts.containsKey(HeirType.paternalGrandmother) && !excluded.containsKey(HeirType.paternalGrandmother)) {
      eligibleGrandmothers.add(HeirType.paternalGrandmother);
    }
    if (counts.containsKey(HeirType.maternalGrandmother) && !excluded.containsKey(HeirType.maternalGrandmother)) {
      eligibleGrandmothers.add(HeirType.maternalGrandmother);
    }
    if (eligibleGrandmothers.isNotEmpty) {
      final totalGmShare = 1.0 / 6.0;
      final perGm = totalGmShare / eligibleGrandmothers.length;
      for (final gm in eligibleGrandmothers) {
        sharerFractions[gm] = perGm;
        legalNotes[gm] = 'মাতা/পিতা না থাকায় দাদী/নানী পান ১/৬ অংশ (সমবণ্টন)';
      }
    }

    // 7. Daughters (কন্যা) - when NO sons
    if (hasDaughters && !hasSons && !excluded.containsKey(HeirType.daughter)) {
      final daughterCount = counts[HeirType.daughter]!;
      if (daughterCount == 1) {
        sharerFractions[HeirType.daughter] = 1.0 / 2.0;
        legalNotes[HeirType.daughter] = 'একমাত্র কন্যা হওয়ায় পান ১/২ অংশ (সূরা নিসা: ১১)';
      } else {
        sharerFractions[HeirType.daughter] = 2.0 / 3.0;
        legalNotes[HeirType.daughter] = 'একাধিক কন্যা হওয়ায় সকলে মিলে পান ২/৩ অংশ (সূরা নিসা: ১১)';
      }
    }

    // 8. Son's Daughters (পৌত্রী) - when no sons and no daughters
    if (hasSonDaughters && !hasSons && !excluded.containsKey(HeirType.sonDaughter)) {
      if (!hasDaughters) {
        final count = counts[HeirType.sonDaughter]!;
        if (count == 1) {
          sharerFractions[HeirType.sonDaughter] = 1.0 / 2.0;
          legalNotes[HeirType.sonDaughter] = 'সন্তান না থাকায় একমাত্র পৌত্রী পান ১/২ অংশ';
        } else {
          sharerFractions[HeirType.sonDaughter] = 2.0 / 3.0;
          legalNotes[HeirType.sonDaughter] = 'সন্তান না থাকায় একাধিক পৌত্রী মিলে পান ২/৩ অংশ';
        }
      } else if (counts[HeirType.daughter] == 1) {
        // 1 daughter takes 1/2, son's daughters take remaining to complete 2/3 (i.e. 1/6)
        sharerFractions[HeirType.sonDaughter] = 1.0 / 6.0;
        legalNotes[HeirType.sonDaughter] = '১ কন্যার সাথে পৌত্রী পান ২/৩ পূর্ণ করার নিমিত্তে ১/৬ অংশ';
      }
    }

    // 9. Full Sisters (সহোদর বোন) - when no children, no father, no brother
    if (fullSistersCount > 0 && !hasDescendants && !hasFather && fullBrothersCount == 0 && !excluded.containsKey(HeirType.fullSister)) {
      if (fullSistersCount == 1) {
        sharerFractions[HeirType.fullSister] = 1.0 / 2.0;
        legalNotes[HeirType.fullSister] = 'সন্তান ও ভাই না থাকায় ১ বোন পান ১/২ অংশ (সূরা নিসা: ১৭৬)';
      } else {
        sharerFractions[HeirType.fullSister] = 2.0 / 3.0;
        legalNotes[HeirType.fullSister] = 'সন্তান ও ভাই না থাকায় একাধিক বোন মিলে পান ২/৩ অংশ (সূরা নিসা: ১৭৬)';
      }
    }

    // 10. Uterine Siblings (বৈপিত্রেয় ভাই-বোন) - 1:1 equal share
    final eligibleUterine = <HeirType>[];
    if (uterineBrothersCount > 0 && !excluded.containsKey(HeirType.uterineBrother)) {
      eligibleUterine.add(HeirType.uterineBrother);
    }
    if (uterineSistersCount > 0 && !excluded.containsKey(HeirType.uterineSister)) {
      eligibleUterine.add(HeirType.uterineSister);
    }
    if (eligibleUterine.isNotEmpty) {
      final totalUterineCount = (eligibleUterine.contains(HeirType.uterineBrother) ? uterineBrothersCount : 0) +
          (eligibleUterine.contains(HeirType.uterineSister) ? uterineSistersCount : 0);
      final totalUterineShare = totalUterineCount == 1 ? (1.0 / 6.0) : (1.0 / 3.0);

      if (eligibleUterine.contains(HeirType.uterineBrother)) {
        final share = totalUterineShare * (uterineBrothersCount / totalUterineCount);
        sharerFractions[HeirType.uterineBrother] = share;
        legalNotes[HeirType.uterineBrother] = 'বৈপিত্রেয় ভাইয়ের হিস্যা (নারী-পুরুষ সমান ১:১ বন্টন)';
      }
      if (eligibleUterine.contains(HeirType.uterineSister)) {
        final share = totalUterineShare * (uterineSistersCount / totalUterineCount);
        sharerFractions[HeirType.uterineSister] = share;
        legalNotes[HeirType.uterineSister] = 'বৈপিত্রেয় বোনের হিস্যা (নারী-পুরুষ সমান ১:১ বন্টন)';
      }
    }

    // Calculate sum of sharer fractions
    double sumSharers = 0.0;
    sharerFractions.forEach((_, frac) => sumSharers += frac);

    bool isAwl = false;
    bool isRadd = false;

    final finalFractions = <HeirType, double>{};

    // Check if Awl occurs (sum of sharers > 1.0)
    if (sumSharers > 1.000001) {
      isAwl = true;
      // Proportional reduction: fraction / sumSharers
      sharerFractions.forEach((heir, frac) {
        finalFractions[heir] = frac / sumSharers;
      });
    } else {
      // Normal or Residue exists
      sharerFractions.forEach((heir, frac) {
        finalFractions[heir] = frac;
      });

      double residue = 1.0 - sumSharers;

      // Residuaries (Asaba / আসাবা) distribution
      if (residue > 0.000001) {
        // 1. Sons and Daughters (2:1 ratio)
        if (hasSons && !excluded.containsKey(HeirType.son)) {
          final sonCount = counts[HeirType.son]!;
          final daughterCount = counts[HeirType.daughter] ?? 0;
          final totalUnits = (sonCount * 2) + daughterCount;

          final sonShareTotal = residue * ((sonCount * 2) / totalUnits);
          final daughterShareTotal = residue * (daughterCount / totalUnits);

          finalFractions[HeirType.son] = sonShareTotal;
          legalNotes[HeirType.son] = 'আসাবা: পুত্র কন্যার সাথে ২:১ অনুপাতে অবশিষ্ট অংশ পাবে (সূরা নিসা: ১১)';

          if (daughterCount > 0) {
            finalFractions[HeirType.daughter] = daughterShareTotal;
            legalNotes[HeirType.daughter] = 'আসাবা বিল গাইর: পুত্রের সাথে ২:১ অনুপাতে অবশিষ্ট অংশ (সূরা নিসা: ১১)';
          }
          residue = 0.0;
        }
        // 2. Father as Asaba
        else if (hasFather && !excluded.containsKey(HeirType.father)) {
          final current = finalFractions[HeirType.father] ?? 0.0;
          finalFractions[HeirType.father] = current + residue;
          residue = 0.0;
        }
        // 3. Paternal Grandfather as Asaba
        else if (hasPaternalGrandfather && !excluded.containsKey(HeirType.paternalGrandfather)) {
          final current = finalFractions[HeirType.paternalGrandfather] ?? 0.0;
          finalFractions[HeirType.paternalGrandfather] = current + residue;
          residue = 0.0;
        }
        // 4. Brothers and Sisters as Asaba (2:1 ratio)
        else if (fullBrothersCount > 0 && !excluded.containsKey(HeirType.fullBrother)) {
          final sisterCount = fullSistersCount;
          final totalUnits = (fullBrothersCount * 2) + sisterCount;

          final brotherShare = residue * ((fullBrothersCount * 2) / totalUnits);
          final sisterShare = residue * (sisterCount / totalUnits);

          finalFractions[HeirType.fullBrother] = brotherShare;
          legalNotes[HeirType.fullBrother] = 'আসাবা: সহোদর বোনদের সাথে ২:১ অনুপাতে অবশিষ্ট অংশ';

          if (sisterCount > 0) {
            finalFractions[HeirType.fullSister] = sisterShare;
            legalNotes[HeirType.fullSister] = 'সহোদর ভাইয়ের সাথে ২:১ অনুপাতে অবশিষ্ট অংশ';
          }
          residue = 0.0;
        }
        // 5. Full Sisters as Asaba ma'a ghayriha (with daughters)
        else if (fullSistersCount > 0 && hasDaughters && !excluded.containsKey(HeirType.fullSister)) {
          finalFractions[HeirType.fullSister] = residue;
          legalNotes[HeirType.fullSister] = 'আসাবা মাআল গাইর: কন্যার উপস্থিতিতে বোন অবশিষ্টভোগী';
          residue = 0.0;
        }
        // 6. Radd (রদ - Proportional Return to Sharers excluding spouse)
        else if (residue > 0.000001) {
          isRadd = true;
          // Sum sharers excluding spouse
          double nonSpouseSharersSum = 0.0;
          finalFractions.forEach((heir, frac) {
            if (heir != HeirType.husband && heir != HeirType.wife) {
              nonSpouseSharersSum += frac;
            }
          });

          if (nonSpouseSharersSum > 0.000001) {
            final surplus = residue;
            final nonSpouseHeirs = finalFractions.keys
                .where((h) => h != HeirType.husband && h != HeirType.wife)
                .toList();

            for (final h in nonSpouseHeirs) {
              final original = finalFractions[h]!;
              final addition = surplus * (original / nonSpouseSharersSum);
              finalFractions[h] = original + addition;
              legalNotes[h] = '${legalNotes[h] ?? ""} [রদ নীতিতে অবশিষ্ট আনুপাতিক ফেরত]';
            }
          } else {
            // Only spouse exists (late Hanafi / statutory rule returns to spouse)
            final spouseKey = counts.containsKey(HeirType.husband) ? HeirType.husband : HeirType.wife;
            finalFractions[spouseKey] = 1.0;
            legalNotes[spouseKey] = 'অন্য কোনো ওয়ারিশ না থাকায় রদ নীতিতে স্বামী/স্ত্রী সম্পূর্ণ সম্পত্তি পাবেন';
          }
        }
      }
    }

    // Build Final Heir Results
    final heirResults = <HeirResult>[];

    // Add active heirs
    finalFractions.forEach((type, frac) {
      final count = counts[type] ?? 1;
      final pct = frac * 100.0;
      final allocDec = totalEstateDecimal * frac;
      final allocSqFt = allocDec * sqFtPerDecimal;
      final allocKatha = allocSqFt / sqFtPerKatha;
      final allocTaka = totalEstateTaka * frac;

      final meta = HeirMeta.metaMap[type]!;
      final basis = legalNotes[type] ?? meta.descriptionBangla;

      heirResults.add(HeirResult(
        type: type,
        titleBangla: meta.banglaName,
        count: count,
        fraction: frac,
        fractionText: _toSimpleFractionText(frac),
        percentage: pct,
        allocatedDecimal: allocDec,
        allocatedKatha: allocKatha,
        allocatedSqFt: allocSqFt,
        allocatedTaka: allocTaka,
        perPersonDecimal: count > 0 ? (allocDec / count) : 0,
        perPersonTaka: count > 0 ? (allocTaka / count) : 0,
        isExcluded: false,
        legalBasisBangla: basis,
      ));
    });

    // Add excluded heirs for complete transparency
    excluded.forEach((type, reason) {
      final count = counts[type] ?? 1;
      final meta = HeirMeta.metaMap[type]!;

      heirResults.add(HeirResult(
        type: type,
        titleBangla: meta.banglaName,
        count: count,
        fraction: 0.0,
        fractionText: '০ (বঞ্চিত)',
        percentage: 0.0,
        allocatedDecimal: 0.0,
        allocatedKatha: 0.0,
        allocatedSqFt: 0.0,
        allocatedTaka: 0.0,
        perPersonDecimal: 0.0,
        perPersonTaka: 0.0,
        isExcluded: true,
        legalBasisBangla: reason,
      ));
    });

    // Summary Explanation
    String explanation;
    if (isAwl) {
      explanation = 'আওল (Awl) মাসআলা: মোট নির্ধারিত অংশের যোগফল ১-এর বেশি হওয়ায় সকলের অংশে আনুপাতিক হ্রাস ঘটানো হয়েছে।';
    } else if (isRadd) {
      explanation = 'রদ (Radd) মাসআলা: কোনো আসাবা ওয়ারিশ না থাকায় এবং সম্পত্তি উদ্বৃত্ত থাকায় শারারদের মধ্যে আনুপাতিক বণ্টন করা হয়েছে।';
    } else {
      explanation = 'সুন্নি হানাফি শরীয়াহ অনুযায়ী সকল আসহাবে ফুরুজ ও আসাবার মাঝে সম্পত্তি যথাযথভাবে বণ্টিত হয়েছে।';
    }

    return FaraizDistributionResult(
      deceasedGender: deceasedGender,
      heirs: heirResults,
      isAwl: isAwl,
      isRadd: isRadd,
      totalEstateDecimal: totalEstateDecimal,
      totalEstateTaka: totalEstateTaka,
      summaryExplanationBangla: explanation,
    );
  }

  /// Helper to convert a float fraction to standard Quranic or irreducible representation
  static String _toSimpleFractionText(double val) {
    if ((val - 0.5).abs() < 0.001) return '১/২';
    if ((val - 0.25).abs() < 0.001) return '১/৪';
    if ((val - 0.125).abs() < 0.001) return '১/৮';
    if ((val - 0.333333).abs() < 0.005) return '১/৩';
    if ((val - 0.666667).abs() < 0.005) return '২/৩';
    if ((val - 0.166667).abs() < 0.005) return '১/৬';

    // Approximate common fraction
    for (int d = 2; d <= 96; d++) {
      final n = (val * d).round();
      if ((val - (n / d)).abs() < 0.0005) {
        return '${BanglaNumerals.toBangla(n)}/${BanglaNumerals.toBangla(d)}';
      }
    }
    return '${(val * 100).toStringAsFixed(2)}%';
  }
}
