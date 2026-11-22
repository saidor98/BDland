import 'dart:math' as math;
import '../models/geometry_models.dart';

class GeometryCalculator {
  static const double sqFtPerDecimal = 435.60;
  static const double sqFtPerKatha = 720.00;
  static const double cftPerCubicMeter = 35.3146667;

  GeometryCalculator._();

  /// Calculate Irregular Quadrilateral using Heron's formula on two triangles (split by diagonal)
  /// and compare with traditional Amin Average Method.
  static QuadrilateralResult calculateQuadrilateral({
    required double north,
    required double east,
    required double south,
    required double west,
    required double diagonal,
  }) {
    // Check Triangle 1 (North, East, Diagonal)
    final isValidT1 = (north + east > diagonal) &&
        (north + diagonal > east) &&
        (east + diagonal > north);

    // Check Triangle 2 (South, West, Diagonal)
    final isValidT2 = (south + west > diagonal) &&
        (south + diagonal > west) &&
        (west + diagonal > south);

    if (!isValidT1 || !isValidT2) {
      return QuadrilateralResult(
        sideNorth: north,
        sideEast: east,
        sideSouth: south,
        sideWest: west,
        diagonal: diagonal,
        triangle1AreaSqFt: 0,
        triangle2AreaSqFt: 0,
        exactAreaSqFt: 0,
        exactAreaDecimal: 0,
        exactAreaKatha: 0,
        averageAreaSqFt: 0,
        averageAreaDecimal: 0,
        averageAreaKatha: 0,
        diffSqFt: 0,
        diffDecimal: 0,
        percentageError: 0,
        isValid: false,
        messageBangla:
            'প্রদত্ত কর্ণের মান দিয়ে ত্রিভুজ গঠন সম্ভব নয়। যেকোনো দুই বাহুর যোগফল কর্ণের চেয়ে বড় হতে হবে।',
      );
    }

    // Heron's formula for Triangle 1
    final s1 = (north + east + diagonal) / 2.0;
    final t1Area = math.sqrt(s1 * (s1 - north) * (s1 - east) * (s1 - diagonal));

    // Heron's formula for Triangle 2
    final s2 = (south + west + diagonal) / 2.0;
    final t2Area = math.sqrt(s2 * (s2 - south) * (s2 - west) * (s2 - diagonal));

    final exactSqFt = t1Area + t2Area;
    final exactDecimal = exactSqFt / sqFtPerDecimal;
    final exactKatha = exactSqFt / sqFtPerKatha;

    // Traditional Amin Average Method: ((North + South)/2) * ((East + West)/2)
    final avgLength = (north + south) / 2.0;
    final avgWidth = (east + west) / 2.0;
    final avgSqFt = avgLength * avgWidth;
    final avgDecimal = avgSqFt / sqFtPerDecimal;
    final avgKatha = avgSqFt / sqFtPerKatha;

    final diffSqFt = avgSqFt - exactSqFt;
    final diffDecimal = diffSqFt / sqFtPerDecimal;
    final percentageError = exactSqFt > 0 ? (diffSqFt.abs() / exactSqFt) * 100 : 0.0;

    String note;
    if (percentageError < 0.1) {
      note = 'জমিটি প্রায় নিখুঁত আয়তক্ষেত্রাকার। গড় পদ্ধতি ও হেরন্স পদ্ধতির ফলাফল প্রায় সমান।';
    } else if (diffSqFt > 0) {
      note =
          'ঐতিহ্যবাহী গড় পদ্ধতিতে প্রকৃত ক্ষেত্রফলের চেয়ে জমি বেশি দেখাচ্ছে। এতে সীমানা বা বণ্টনে বিরোধ সৃষ্টি হতে পারে।';
    } else {
      note =
          'ঐতিহ্যবাহী গড় পদ্ধতিতে প্রকৃত ক্ষেত্রফলের চেয়ে জমি কম দেখাচ্ছে। নিখুঁত মাপের জন্য সর্বদা হেরন্স পদ্ধতি ব্যবহার করুন।';
    }

    return QuadrilateralResult(
      sideNorth: north,
      sideEast: east,
      sideSouth: south,
      sideWest: west,
      diagonal: diagonal,
      triangle1AreaSqFt: t1Area,
      triangle2AreaSqFt: t2Area,
      exactAreaSqFt: exactSqFt,
      exactAreaDecimal: exactDecimal,
      exactAreaKatha: exactKatha,
      averageAreaSqFt: avgSqFt,
      averageAreaDecimal: avgDecimal,
      averageAreaKatha: avgKatha,
      diffSqFt: diffSqFt,
      diffDecimal: diffDecimal,
      percentageError: percentageError,
      isValid: true,
      messageBangla: note,
    );
  }

  /// Calculate Triangle area using Heron's Formula (3 sides)
  static TriangleResult calculateTriangleHeron({
    required double a,
    required double b,
    required double c,
  }) {
    final isValid = (a + b > c) && (a + c > b) && (b + c > a);
    if (!isValid) {
      return TriangleResult(
        sideA: a,
        sideB: b,
        sideC: c,
        isHeron: true,
        areaSqFt: 0,
        areaDecimal: 0,
        areaKatha: 0,
        perimeter: a + b + c,
        isValid: false,
        messageBangla:
            'প্রদত্ত বাহু তিনটি দিয়ে ত্রিভুজ গঠন সম্ভব নয়। যেকোনো দুই বাহুর যোগফল তৃতীয় বাহুর চেয়ে বড় হতে হবে।',
      );
    }

    final s = (a + b + c) / 2.0;
    final areaSqFt = math.sqrt(s * (s - a) * (s - b) * (s - c));
    return TriangleResult(
      sideA: a,
      sideB: b,
      sideC: c,
      isHeron: true,
      areaSqFt: areaSqFt,
      areaDecimal: areaSqFt / sqFtPerDecimal,
      areaKatha: areaSqFt / sqFtPerKatha,
      perimeter: a + b + c,
      isValid: true,
      messageBangla: 'হেরন্স ফর্মুলায় ত্রিভুজের ক্ষেত্রফল সফলভাবে নির্ণয় হয়েছে।',
    );
  }

  /// Calculate Triangle area using Base and Perpendicular Height
  static TriangleResult calculateTriangleBaseHeight({
    required double base,
    required double height,
  }) {
    if (base <= 0 || height <= 0) {
      return const TriangleResult(
        sideA: 0,
        sideB: 0,
        sideC: 0,
        isHeron: false,
        areaSqFt: 0,
        areaDecimal: 0,
        areaKatha: 0,
        perimeter: 0,
        isValid: false,
        messageBangla: 'ভূমি ও উচ্চতা অবশ্যই শূন্যের চেয়ে বেশি হতে হবে।',
      );
    }

    final areaSqFt = 0.5 * base * height;
    return TriangleResult(
      sideA: base,
      sideB: height,
      sideC: 0,
      base: base,
      height: height,
      isHeron: false,
      areaSqFt: areaSqFt,
      areaDecimal: areaSqFt / sqFtPerDecimal,
      areaKatha: areaSqFt / sqFtPerKatha,
      perimeter: 0,
      isValid: true,
      messageBangla: 'ভূমি ও উচ্চতা পদ্ধতিতে ত্রিভুজের ক্ষেত্রফল নির্ণয় হয়েছে।',
    );
  }

  /// Calculate Trapezoid area: Area = ((a + b) / 2) * h
  static TrapezoidResult calculateTrapezoid({
    required double parallelA,
    required double parallelB,
    required double height,
  }) {
    final areaSqFt = ((parallelA + parallelB) / 2.0) * height;
    return TrapezoidResult(
      parallelA: parallelA,
      parallelB: parallelB,
      height: height,
      areaSqFt: areaSqFt,
      areaDecimal: areaSqFt / sqFtPerDecimal,
      areaKatha: areaSqFt / sqFtPerKatha,
    );
  }

  /// Calculate Circle or Sector area
  static CircleResult calculateCircle({
    required double radius,
    double? angleDegrees,
  }) {
    final diameter = radius * 2.0;
    final isSector = angleDegrees != null && angleDegrees > 0 && angleDegrees < 360;

    double areaSqFt;
    double perimeterOrArc;

    if (isSector) {
      final fraction = angleDegrees / 360.0;
      areaSqFt = math.pi * radius * radius * fraction;
      perimeterOrArc = (2 * math.pi * radius * fraction) + (2 * radius);
    } else {
      areaSqFt = math.pi * radius * radius;
      perimeterOrArc = 2 * math.pi * radius;
    }

    return CircleResult(
      radius: radius,
      diameter: diameter,
      angleDegrees: angleDegrees,
      isSector: isSector,
      areaSqFt: areaSqFt,
      areaDecimal: areaSqFt / sqFtPerDecimal,
      areaKatha: areaSqFt / sqFtPerKatha,
      perimeterOrArcLength: perimeterOrArc,
    );
  }

  /// Calculate Irregular Multi-sided Polygon using Triangulation method
  static PolygonResult calculatePolygonTriangulation(List<List<double>> triangles) {
    final parts = <PolygonTrianglePart>[];
    double totalSqFt = 0;

    for (int i = 0; i < triangles.length; i++) {
      final t = triangles[i];
      if (t.length < 3) continue;
      final a = t[0];
      final b = t[1];
      final c = t[2];

      final isValid = (a + b > c) && (a + c > b) && (b + c > a);
      double area = 0;
      if (isValid) {
        final s = (a + b + c) / 2.0;
        area = math.sqrt(s * (s - a) * (s - b) * (s - c));
        totalSqFt += area;
      }

      parts.add(PolygonTrianglePart(
        index: i + 1,
        sideA: a,
        sideB: b,
        sideC: c,
        areaSqFt: area,
        areaDecimal: area / sqFtPerDecimal,
        isValid: isValid,
      ));
    }

    return PolygonResult(
      parts: parts,
      totalAreaSqFt: totalSqFt,
      totalAreaDecimal: totalSqFt / sqFtPerDecimal,
      totalAreaKatha: totalSqFt / sqFtPerKatha,
    );
  }

  /// Calculate Road/Canal/Pond Earthwork (Excavation volume in CFT and cost)
  /// Uses Prismoidal Formula: V = (H / 6) * (A1 + 4*Am + A2)
  static EarthworkResult calculateEarthwork({
    required double topLength,
    required double topWidth,
    required double depth,
    double? bottomLength,
    double? bottomWidth,
    double sideSlopeRatio = 1.5, // 1 vertical to 1.5 horizontal
    double ratePer100Cft = 0.0,
  }) {
    // If bottom dimensions are not explicitly provided, calculate using side slope:
    // Bottom Length = Top Length - 2 * (slope * depth)
    final bLen = bottomLength ?? math.max(0.0, topLength - (2.0 * sideSlopeRatio * depth));
    final bWid = bottomWidth ?? math.max(0.0, topWidth - (2.0 * sideSlopeRatio * depth));

    final a1 = topLength * topWidth; // Top area
    final a2 = bLen * bWid; // Bottom area
    final midLength = (topLength + bLen) / 2.0;
    final midWidth = (topWidth + bWid) / 2.0;
    final am = midLength * midWidth; // Mid-section area

    // Prismoidal Volume in CFT (Cubic Feet)
    final volumeCFT = (depth / 6.0) * (a1 + (4.0 * am) + a2);
    final volumeCubicMeter = volumeCFT / cftPerCubicMeter;

    // Excavation side wall area (approximate wetted/sloped perimeter area)
    final slantHeight = math.sqrt((depth * depth) + math.pow(sideSlopeRatio * depth, 2));
    final excavationSideArea = 2 * ((topLength + bLen) / 2.0 * slantHeight) +
        2 * ((topWidth + bWid) / 2.0 * slantHeight);

    final estimatedCost = (volumeCFT / 100.0) * ratePer100Cft;

    return EarthworkResult(
      topLength: topLength,
      topWidth: topWidth,
      bottomLength: bLen,
      bottomWidth: bWid,
      depth: depth,
      sideSlopeRatio: sideSlopeRatio,
      volumeCFT: volumeCFT,
      volumeCubicMeter: volumeCubicMeter,
      topSurfaceAreaSqFt: a1,
      bottomSurfaceAreaSqFt: a2,
      excavationSideAreaSqFt: excavationSideArea,
      estimatedCostTaka: estimatedCost,
    );
  }
}
