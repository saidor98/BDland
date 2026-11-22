import '../models/mouza_scale.dart';

class MouzaScaleService {
  MouzaScaleService._();

  static const double sqFtPerDecimal = 435.60;
  static const double sqFtPerKatha = 720.00;
  static const double metersPerFoot = 0.3048;
  static const double feetPerLink = 0.66;
  static const double feetPerChain = 66.0;
  static const double feetPerHath = 1.50;

  /// Calculate actual ground distance from map reading
  static GroundDistanceResult calculateDistance({
    required double mapReading,
    required MouzaScaleRatio ratio,
    required String inputUnit, // 'links', 'inches', 'mm'
  }) {
    final scaleInfo = MouzaScaleInfo.getByRatio(ratio);

    // Convert input reading to map inches
    double mapInches = 0.0;
    if (inputUnit == 'inches') {
      mapInches = mapReading;
    } else if (inputUnit == 'mm') {
      mapInches = mapReading / 25.4;
    } else {
      // 'links' measured directly via Gunia scale (which assumes 16" = 1 mile baseline)
      // On standard 16" scale, 500 links = 1 inch -> mapInches = reading / 500.0
      mapInches = mapReading / 500.0;
    }

    // Actual ground feet
    final groundFeet = mapInches * scaleInfo.feetPerInch;
    final groundMeters = groundFeet * metersPerFoot;
    final groundLinks = groundFeet / feetPerLink;
    final groundChains = groundFeet / feetPerChain;
    final groundHath = groundFeet / feetPerHath;

    return GroundDistanceResult(
      groundFeet: groundFeet,
      groundMeters: groundMeters,
      groundLinks: groundLinks,
      groundChains: groundChains,
      groundHath: groundHath,
    );
  }

  /// Calculate plot area from map length and width readings (measured in Gunia links)
  static GroundAreaResult calculatePlotArea({
    required double mapLengthLinks,
    required double mapWidthLinks,
    required MouzaScaleRatio ratio,
  }) {
    final dLength = calculateDistance(
      mapReading: mapLengthLinks,
      ratio: ratio,
      inputUnit: 'links',
    );
    final dWidth = calculateDistance(
      mapReading: mapWidthLinks,
      ratio: ratio,
      inputUnit: 'links',
    );

    final areaSqFt = dLength.groundFeet * dWidth.groundFeet;
    final areaDecimal = areaSqFt / sqFtPerDecimal;
    final areaKatha = areaSqFt / sqFtPerKatha;

    return GroundAreaResult(
      groundAreaSqFt: areaSqFt,
      groundAreaDecimal: areaDecimal,
      groundAreaKatha: areaKatha,
      lengthFeet: dLength.groundFeet,
      widthFeet: dWidth.groundFeet,
    );
  }
}
