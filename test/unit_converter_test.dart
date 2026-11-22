import 'package:flutter_test/flutter_test.dart';
import 'package:bdland_pro/features/converter/models/land_unit.dart';
import 'package:bdland_pro/features/converter/services/unit_converter_service.dart';

void main() {
  group('Bangladesh Land Unit Converter Tests', () {
    final decimalUnit = LandUnit.getByType(LandUnitType.decimal);
    final sqFeetUnit = LandUnit.getByType(LandUnitType.sqFeet);
    final acreUnit = LandUnit.getByType(LandUnitType.acre);
    final kathaUnit = LandUnit.getByType(LandUnitType.katha);
    final sqLinkUnit = LandUnit.getByType(LandUnitType.sqLink);
    final kaniUnit = LandUnit.getByType(LandUnitType.kaniStandard);
    final gondaUnit = LandUnit.getByType(LandUnitType.gonda);
    final koraUnit = LandUnit.getByType(LandUnitType.kora);
    final krantiUnit = LandUnit.getByType(LandUnitType.kranti);
    final tilUnit = LandUnit.getByType(LandUnitType.til);

    test('1 Decimal equals 435.60 Sq Feet', () {
      final sqFt = UnitConverterService.convert(
        value: 1.0,
        fromUnit: decimalUnit,
        toUnit: sqFeetUnit,
      );
      expect(sqFt, closeTo(435.60, 0.001));
    });

    test('1000 Sq Links equals 1 Decimal', () {
      final dec = UnitConverterService.convert(
        value: 1000.0,
        fromUnit: sqLinkUnit,
        toUnit: decimalUnit,
      );
      expect(dec, closeTo(1.0, 0.001));
    });

    test('1 Acre equals 100 Decimals and 43,560 Sq Feet', () {
      final dec = UnitConverterService.convert(
        value: 1.0,
        fromUnit: acreUnit,
        toUnit: decimalUnit,
      );
      final sqFt = UnitConverterService.convert(
        value: 1.0,
        fromUnit: acreUnit,
        toUnit: sqFeetUnit,
      );

      expect(dec, closeTo(100.0, 0.001));
      expect(sqFt, closeTo(43560.0, 0.001));
    });

    test('1 Katha equals 720 Sq Feet', () {
      final sqFt = UnitConverterService.convert(
        value: 1.0,
        fromUnit: kathaUnit,
        toUnit: sqFeetUnit,
      );
      expect(sqFt, closeTo(720.0, 0.001));
    });

    test('Standard Kani (40 Decimals) hierarchy check', () {
      // 1 Kani = 40 Decimals
      final dec = UnitConverterService.convert(
        value: 1.0,
        fromUnit: kaniUnit,
        toUnit: decimalUnit,
      );
      expect(dec, closeTo(40.0, 0.001));

      // 1 Kani = 20 Gonda -> 1 Gonda = 2 Decimals
      final gondaInDec = UnitConverterService.convert(
        value: 1.0,
        fromUnit: gondaUnit,
        toUnit: decimalUnit,
      );
      expect(gondaInDec, closeTo(2.0, 0.001));

      // 1 Gonda = 4 Kora -> 1 Kora = 0.5 Decimals
      final koraInDec = UnitConverterService.convert(
        value: 1.0,
        fromUnit: koraUnit,
        toUnit: decimalUnit,
      );
      expect(koraInDec, closeTo(0.5, 0.001));

      // 1 Kora = 3 Kranti -> 1 Kranti = 72.6 sq ft
      final krantiSqFt = UnitConverterService.convert(
        value: 1.0,
        fromUnit: krantiUnit,
        toUnit: sqFeetUnit,
      );
      expect(krantiSqFt, closeTo(72.60, 0.001));

      // 1 Kranti = 20 Til -> 1 Til = 3.63 sq ft
      final tilSqFt = UnitConverterService.convert(
        value: 1.0,
        fromUnit: tilUnit,
        toUnit: sqFeetUnit,
      );
      expect(tilSqFt, closeTo(3.63, 0.001));
    });

    test('Instant bidirectional conversion consistency (Roundtrip)', () {
      const originalValue = 15.75;
      final inSqFt = UnitConverterService.convert(
        value: originalValue,
        fromUnit: decimalUnit,
        toUnit: sqFeetUnit,
      );
      final backToDecimal = UnitConverterService.convert(
        value: inSqFt,
        fromUnit: sqFeetUnit,
        toUnit: decimalUnit,
      );
      expect(backToDecimal, closeTo(originalValue, 0.0001));
    });
  });
}
