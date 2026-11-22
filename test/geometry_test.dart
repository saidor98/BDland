import 'package:flutter_test/flutter_test.dart';
import 'package:bdland_pro/features/geometry/services/geometry_calculator.dart';

void main() {
  group('GeometryCalculator Tests', () {
    test('Heron Formula Triangle Calculation (60, 80, 100 ft)', () {
      final result = GeometryCalculator.calculateTriangleHeron(
        a: 60,
        b: 80,
        c: 100,
      );

      expect(result.isValid, isTrue);
      // Right triangle 60 x 80 -> Area = 0.5 * 60 * 80 = 2400 sq ft
      expect(result.areaSqFt, closeTo(2400.0, 0.01));
      // 2400 / 435.6 = 5.5096418... decimal
      expect(result.areaDecimal, closeTo(5.5096, 0.001));
      // 2400 / 720 = 3.3333... katha
      expect(result.areaKatha, closeTo(3.3333, 0.001));
    });

    test('Triangle Base x Height Calculation', () {
      final result = GeometryCalculator.calculateTriangleBaseHeight(
        base: 80,
        height: 60,
      );

      expect(result.isValid, isTrue);
      expect(result.areaSqFt, closeTo(2400.0, 0.01));
    });

    test('Triangle Inequality Failure check', () {
      final result = GeometryCalculator.calculateTriangleHeron(
        a: 20,
        b: 30,
        c: 60, // 20 + 30 < 60 -> invalid triangle
      );

      expect(result.isValid, isFalse);
      expect(result.areaSqFt, equals(0.0));
    });

    test('Quadrilateral Heron vs Average Method Comparison', () {
      // 4 sides: North 100, East 80, South 100, West 80, Diagonal: sqrt(100^2 + 80^2) = 128.062
      final result = GeometryCalculator.calculateQuadrilateral(
        north: 100,
        east: 80,
        south: 100,
        west: 80,
        diagonal: 128.06248,
      );

      expect(result.isValid, isTrue);
      // Perfect rectangle: exact area should be 8000 sq ft
      expect(result.exactAreaSqFt, closeTo(8000.0, 0.5));
      expect(result.averageAreaSqFt, closeTo(8000.0, 0.01));
      // In perfect rectangle, error difference should be almost 0
      expect(result.percentageError, lessThan(0.1));
    });

    test('Trapezoid Area Calculation', () {
      final result = GeometryCalculator.calculateTrapezoid(
        parallelA: 90,
        parallelB: 120,
        height: 60,
      );

      // Area = ((90 + 120) / 2) * 60 = 105 * 60 = 6300 sq ft
      expect(result.areaSqFt, closeTo(6300.0, 0.01));
      expect(result.areaDecimal, closeTo(6300.0 / 435.60, 0.001));
    });

    test('Circle and Sector Area Calculation', () {
      final circle = GeometryCalculator.calculateCircle(radius: 10);
      // pi * 10^2 = 314.159265
      expect(circle.areaSqFt, closeTo(314.159, 0.01));
      expect(circle.perimeterOrArcLength, closeTo(62.8318, 0.01));

      // 90 degree quadrant sector
      final sector = GeometryCalculator.calculateCircle(radius: 10, angleDegrees: 90);
      expect(sector.isSector, isTrue);
      expect(sector.areaSqFt, closeTo(314.159 / 4.0, 0.01));
    });

    test('Earthwork Pond Excavation Prismoidal Volume', () {
      final result = GeometryCalculator.calculateEarthwork(
        topLength: 100,
        topWidth: 60,
        depth: 10,
        sideSlopeRatio: 1.5,
        ratePer100Cft: 800.0,
      );

      // Bottom length = 100 - 2*(1.5*10) = 100 - 30 = 70 ft
      // Bottom width = 60 - 2*(1.5*10) = 60 - 30 = 30 ft
      expect(result.bottomLength, closeTo(70.0, 0.01));
      expect(result.bottomWidth, closeTo(30.0, 0.01));
      expect(result.volumeCFT, greaterThan(0.0));
      expect(result.estimatedCostTaka, equals((result.volumeCFT / 100.0) * 800.0));
    });
  });
}
