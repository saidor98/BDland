import 'package:flutter_test/flutter_test.dart';
import 'package:bdland_pro/features/faraiz/models/faraiz_models.dart';
import 'package:bdland_pro/features/faraiz/services/faraiz_engine.dart';

void main() {
  group('Muslim Inheritance (Faraiz) Sunni Hanafi Engine Tests', () {
    test('Standard Case: Wife, 1 Son, 1 Daughter', () {
      final result = FaraizEngine.calculate(
        deceasedGender: DeceasedGender.male,
        heirCounts: {
          HeirType.wife: 1,
          HeirType.son: 1,
          HeirType.daughter: 1,
        },
        totalEstateDecimal: 100.0,
      );

      expect(result.isAwl, isFalse);
      expect(result.isRadd, isFalse);

      final wife = result.heirs.firstWhere((h) => h.type == HeirType.wife);
      final son = result.heirs.firstWhere((h) => h.type == HeirType.son);
      final daughter = result.heirs.firstWhere((h) => h.type == HeirType.daughter);

      // Wife: 1/8 = 0.125
      expect(wife.fraction, closeTo(0.125, 0.0001));
      expect(wife.allocatedDecimal, closeTo(12.50, 0.01));

      // Residue: 7/8 = 0.875
      // Son (2 units): 0.875 * (2/3) = 0.583333 -> 58.333 decimal
      expect(son.fraction, closeTo(0.583333, 0.0001));
      expect(son.allocatedDecimal, closeTo(58.333, 0.01));

      // Daughter (1 unit): 0.875 * (1/3) = 0.291666 -> 29.166 decimal
      expect(daughter.fraction, closeTo(0.291666, 0.0001));
      expect(daughter.allocatedDecimal, closeTo(29.166, 0.01));

      // Sum equals 1.0
      final totalFraction = wife.fraction + son.fraction + daughter.fraction;
      expect(totalFraction, closeTo(1.0, 0.0001));
    });

    test('Awl (আওল) Proportional Reduction: Husband, Mother, 2 Daughters', () {
      final result = FaraizEngine.calculate(
        deceasedGender: DeceasedGender.female,
        heirCounts: {
          HeirType.husband: 1,
          HeirType.mother: 1,
          HeirType.daughter: 2,
        },
        totalEstateDecimal: 130.0,
      );

      // Husband 1/4 (3/12), Mother 1/6 (2/12), 2 Daughters 2/3 (8/12)
      // 3 + 2 + 8 = 13/12 -> Awl occurs!
      expect(result.isAwl, isTrue);

      final husband = result.heirs.firstWhere((h) => h.type == HeirType.husband);
      final mother = result.heirs.firstWhere((h) => h.type == HeirType.mother);
      final daughters = result.heirs.firstWhere((h) => h.type == HeirType.daughter);

      // Denominator becomes 13:
      // Husband: 3/13 = 0.230769
      expect(husband.fraction, closeTo(3.0 / 13.0, 0.0001));
      // Mother: 2/13 = 0.153846
      expect(mother.fraction, closeTo(2.0 / 13.0, 0.0001));
      // Daughters: 8/13 = 0.615384
      expect(daughters.fraction, closeTo(8.0 / 13.0, 0.0001));

      // Sum equals 1.0
      final totalFraction = husband.fraction + mother.fraction + daughters.fraction;
      expect(totalFraction, closeTo(1.0, 0.0001));
    });

    test('Radd (রদ) Proportional Return: Mother and 1 Daughter (no Asaba)', () {
      final result = FaraizEngine.calculate(
        deceasedGender: DeceasedGender.male,
        heirCounts: {
          HeirType.mother: 1,
          HeirType.daughter: 1,
        },
        totalEstateDecimal: 100.0,
      );

      // Mother fixed: 1/6; Daughter fixed: 1/2 = 3/6. Sum = 4/6.
      // Surplus 2/6 returned in ratio 1:3 -> Mother gets 1/4 (25%), Daughter gets 3/4 (75%).
      expect(result.isRadd, isTrue);

      final mother = result.heirs.firstWhere((h) => h.type == HeirType.mother);
      final daughter = result.heirs.firstWhere((h) => h.type == HeirType.daughter);

      expect(mother.fraction, closeTo(0.25, 0.0001));
      expect(daughter.fraction, closeTo(0.75, 0.0001));
      expect(mother.fraction + daughter.fraction, closeTo(1.0, 0.0001));
    });

    test('Hijab (Exclusion): Son excludes brother and sister', () {
      final result = FaraizEngine.calculate(
        deceasedGender: DeceasedGender.male,
        heirCounts: {
          HeirType.son: 1,
          HeirType.fullBrother: 2,
          HeirType.fullSister: 1,
        },
        totalEstateDecimal: 100.0,
      );

      final brother = result.heirs.firstWhere((h) => h.type == HeirType.fullBrother);
      final sister = result.heirs.firstWhere((h) => h.type == HeirType.fullSister);
      final son = result.heirs.firstWhere((h) => h.type == HeirType.son);

      expect(brother.isExcluded, isTrue);
      expect(sister.isExcluded, isTrue);
      expect(son.fraction, equals(1.0));
    });
  });
}
