class QuadrilateralResult {
  final double sideNorth;
  final double sideEast;
  final double sideSouth;
  final double sideWest;
  final double diagonal;

  final double triangle1AreaSqFt;
  final double triangle2AreaSqFt;
  final double exactAreaSqFt;
  final double exactAreaDecimal;
  final double exactAreaKatha;

  final double averageAreaSqFt;
  final double averageAreaDecimal;
  final double averageAreaKatha;

  final double diffSqFt;
  final double diffDecimal;
  final double percentageError;
  final bool isValid;
  final String messageBangla;

  const QuadrilateralResult({
    required this.sideNorth,
    required this.sideEast,
    required this.sideSouth,
    required this.sideWest,
    required this.diagonal,
    required this.triangle1AreaSqFt,
    required this.triangle2AreaSqFt,
    required this.exactAreaSqFt,
    required this.exactAreaDecimal,
    required this.exactAreaKatha,
    required this.averageAreaSqFt,
    required this.averageAreaDecimal,
    required this.averageAreaKatha,
    required this.diffSqFt,
    required this.diffDecimal,
    required this.percentageError,
    required this.isValid,
    required this.messageBangla,
  });
}

class TriangleResult {
  final double sideA;
  final double sideB;
  final double sideC;
  final double? base;
  final double? height;
  final bool isHeron;
  final double areaSqFt;
  final double areaDecimal;
  final double areaKatha;
  final double perimeter;
  final bool isValid;
  final String messageBangla;

  const TriangleResult({
    required this.sideA,
    required this.sideB,
    required this.sideC,
    this.base,
    this.height,
    required this.isHeron,
    required this.areaSqFt,
    required this.areaDecimal,
    required this.areaKatha,
    required this.perimeter,
    required this.isValid,
    required this.messageBangla,
  });
}

class TrapezoidResult {
  final double parallelA;
  final double parallelB;
  final double height;
  final double areaSqFt;
  final double areaDecimal;
  final double areaKatha;

  const TrapezoidResult({
    required this.parallelA,
    required this.parallelB,
    required this.height,
    required this.areaSqFt,
    required this.areaDecimal,
    required this.areaKatha,
  });
}

class CircleResult {
  final double radius;
  final double diameter;
  final double? angleDegrees;
  final bool isSector;
  final double areaSqFt;
  final double areaDecimal;
  final double areaKatha;
  final double perimeterOrArcLength;

  const CircleResult({
    required this.radius,
    required this.diameter,
    this.angleDegrees,
    required this.isSector,
    required this.areaSqFt,
    required this.areaDecimal,
    required this.areaKatha,
    required this.perimeterOrArcLength,
  });
}

class PolygonTrianglePart {
  final int index;
  final double sideA;
  final double sideB;
  final double sideC;
  final double areaSqFt;
  final double areaDecimal;
  final bool isValid;

  const PolygonTrianglePart({
    required this.index,
    required this.sideA,
    required this.sideB,
    required this.sideC,
    required this.areaSqFt,
    required this.areaDecimal,
    required this.isValid,
  });
}

class PolygonResult {
  final List<PolygonTrianglePart> parts;
  final double totalAreaSqFt;
  final double totalAreaDecimal;
  final double totalAreaKatha;

  const PolygonResult({
    required this.parts,
    required this.totalAreaSqFt,
    required this.totalAreaDecimal,
    required this.totalAreaKatha,
  });
}

class EarthworkResult {
  final double topLength;
  final double topWidth;
  final double bottomLength;
  final double bottomWidth;
  final double depth;
  final double sideSlopeRatio; // 1:z, where z is horizontal per 1 vertical
  final double volumeCFT; // Cubic feet / সেফটি
  final double volumeCubicMeter;
  final double topSurfaceAreaSqFt;
  final double bottomSurfaceAreaSqFt;
  final double excavationSideAreaSqFt;
  final double estimatedCostTaka;

  const EarthworkResult({
    required this.topLength,
    required this.topWidth,
    required this.bottomLength,
    required this.bottomWidth,
    required this.depth,
    required this.sideSlopeRatio,
    required this.volumeCFT,
    required this.volumeCubicMeter,
    required this.topSurfaceAreaSqFt,
    required this.bottomSurfaceAreaSqFt,
    required this.excavationSideAreaSqFt,
    required this.estimatedCostTaka,
  });
}
