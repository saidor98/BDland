import '../models/land_unit.dart';

class UnitConverterService {
  UnitConverterService._();

  /// Convert a value from one unit to another
  static double convert({
    required double value,
    required LandUnit fromUnit,
    required LandUnit toUnit,
  }) {
    if (value == 0) return 0.0;
    if (fromUnit.type == toUnit.type) return value;

    // Convert from source unit to Base (Square Feet)
    final totalSqFt = value * fromUnit.sqFtEquivalent;

    // Convert from Square Feet to destination unit
    final converted = totalSqFt / toUnit.sqFtEquivalent;
    return converted;
  }

  /// Convert an input value to ALL supported Bangladesh land units simultaneously
  static Map<LandUnit, double> convertToAll({
    required double value,
    required LandUnit fromUnit,
  }) {
    final results = <LandUnit, double>{};
    final totalSqFt = value * fromUnit.sqFtEquivalent;

    for (final unit in LandUnit.allUnits) {
      results[unit] = totalSqFt / unit.sqFtEquivalent;
    }

    return results;
  }
}
