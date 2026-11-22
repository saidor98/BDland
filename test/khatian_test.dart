import 'package:flutter_test/flutter_test.dart';
import 'package:bdland_pro/features/khatian/models/ana_gonda_share.dart';
import 'package:bdland_pro/features/khatian/models/khatian_owner.dart';
import 'package:bdland_pro/features/khatian/services/khatian_service.dart';

void main() {
  group('Khatian and Ana-Gonda Arithmetic Tests', () {
    test('16 Ana corresponds to 76,800 Til and 1.0 fraction', () {
      const fullShare = AnaGondaShare(ana: 16);
      expect(fullShare.toTotalTil(), equals(76800));
      expect(fullShare.toFraction(), equals(1.0));
      expect(fullShare.toPercentage(), equals(100.0));
    });

    test('4 Ana corresponds to 1/4 (0.25) or 25% share', () {
      const fourAna = AnaGondaShare(ana: 4);
      expect(fourAna.toTotalTil(), equals(19200));
      expect(fourAna.toFraction(), closeTo(0.25, 0.0001));
      expect(fourAna.toPercentage(), closeTo(25.0, 0.0001));
    });

    test('Share Addition (4 Ana + 6 Ana = 10 Ana)', () {
      const s1 = AnaGondaShare(ana: 4, gonda: 5);
      const s2 = AnaGondaShare(ana: 6, gonda: 15);
      final sum = s1 + s2;

      // 4 ana 5 gonda + 6 ana 15 gonda = 10 ana + 20 gonda = 11 ana 0 gonda
      expect(sum.ana, equals(11));
      expect(sum.gonda, equals(0));
    });

    test('Share Subtraction (16 Ana - 4 Ana = 12 Ana)', () {
      const total = AnaGondaShare(ana: 16);
      const part = AnaGondaShare(ana: 4);
      final diff = total - part;

      expect(diff.ana, equals(12));
      expect(diff.toFraction(), closeTo(0.75, 0.0001));
    });

    test('Conversion from Decimal Fraction to Ana-Gonda', () {
      // 0.5 fraction should produce 8 Ana
      final shareHalf = AnaGondaShare.fromFraction(0.5);
      expect(shareHalf.ana, equals(8));
      expect(shareHalf.gonda, equals(0));

      // 0.25 fraction should produce 4 Ana
      final shareQuarter = AnaGondaShare.fromFraction(0.25);
      expect(shareQuarter.ana, equals(4));
      expect(shareQuarter.gonda, equals(0));
    });

    test('Multi-owner Dag Land Distribution and 16 Ana check', () {
      final owners = [
        const KhatianOwner(
          id: '1',
          name: 'Owner 1',
          khatianNo: '101',
          share: AnaGondaShare(ana: 8), // 50%
          allocatedDecimal: 0,
          allocatedKatha: 0,
          allocatedSqFt: 0,
          percentage: 0,
        ),
        const KhatianOwner(
          id: '2',
          name: 'Owner 2',
          khatianNo: '101',
          share: AnaGondaShare(ana: 4), // 25%
          allocatedDecimal: 0,
          allocatedKatha: 0,
          allocatedSqFt: 0,
          percentage: 0,
        ),
        const KhatianOwner(
          id: '3',
          name: 'Owner 3',
          khatianNo: '102',
          share: AnaGondaShare(ana: 4), // 25%
          allocatedDecimal: 0,
          allocatedKatha: 0,
          allocatedSqFt: 0,
          percentage: 0,
        ),
      ];

      final result = KhatianService.distributeLand(
        totalPlotDecimal: 100.0,
        rawOwners: owners,
      );

      expect(result.isExactly16Ana, isTrue);
      expect(result.totalTil, equals(76800));
      expect(result.owners[0].allocatedDecimal, closeTo(50.0, 0.01));
      expect(result.owners[1].allocatedDecimal, closeTo(25.0, 0.01));
      expect(result.owners[2].allocatedDecimal, closeTo(25.0, 0.01));
    });
  });
}
