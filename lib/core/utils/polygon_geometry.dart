import 'dart:math' as math;
import 'dart:ui';

class BisectionCutResult {
  final Offset cutStart;
  final Offset cutEnd;
  final double cutLength;
  final double offsetFromEdge;
  final double portionArea;

  const BisectionCutResult({
    required this.cutStart,
    required this.cutEnd,
    required this.cutLength,
    required this.offsetFromEdge,
    required this.portionArea,
  });
}

class SplitAreasResult {
  final double areaLeft;
  final double areaRight;

  const SplitAreasResult({required this.areaLeft, required this.areaRight});
}

/// Shared computational geometry helpers for surveying, CAD, and plot division.
class PolygonGeometry {
  PolygonGeometry._();

  static double calculateArea(List<Offset> pts) {
    if (pts.length < 3) return 0.0;
    double sum = 0.0;
    for (int i = 0; i < pts.length; i++) {
      final p1 = pts[i];
      final p2 = pts[(i + 1) % pts.length];
      sum += (p1.dx * p2.dy) - (p2.dx * p1.dy);
    }
    return sum.abs() / 2.0;
  }

  static double calculatePerimeter(List<Offset> pts) {
    if (pts.length < 2) return 0.0;
    double perim = 0.0;
    for (int i = 0; i < pts.length; i++) {
      final p1 = pts[i];
      final p2 = pts[(i + 1) % pts.length];
      perim += (p2 - p1).distance;
    }
    return perim;
  }

  static double calculateInteriorAngleDegrees(Offset prev, Offset curr, Offset next) {
    final v1 = prev - curr;
    final v2 = next - curr;
    final mag1 = v1.distance;
    final mag2 = v2.distance;
    if (mag1 == 0 || mag2 == 0) return 180.0;
    final dot = (v1.dx * v2.dx) + (v1.dy * v2.dy);
    final cosAngle = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    return math.acos(cosAngle) * (180.0 / math.pi);
  }

  /// Sutherland-Hodgman polygon clipping against the half-plane defined by directed edge lineA -> lineB.
  static List<Offset> clipPolygonByHalfPlane(
    List<Offset> poly,
    Offset lineA,
    Offset lineB, {
    required bool keepLeft,
  }) {
    if (poly.length < 3) return const [];
    final dxLine = lineB.dx - lineA.dx;
    final dyLine = lineB.dy - lineA.dy;

    double signedDist(Offset p) {
      final cross = dxLine * (p.dy - lineA.dy) - dyLine * (p.dx - lineA.dx);
      return keepLeft ? cross : -cross;
    }

    Offset intersect(Offset p1, Offset p2) {
      final d1 = signedDist(p1);
      final d2 = signedDist(p2);
      final denom = d1 - d2;
      if (denom.abs() < 1e-12) return p1;
      final t = (d1 / denom).clamp(0.0, 1.0);
      return Offset(
        p1.dx + t * (p2.dx - p1.dx),
        p1.dy + t * (p2.dy - p1.dy),
      );
    }

    final output = <Offset>[];
    for (int i = 0; i < poly.length; i++) {
      final curr = poly[i];
      final prev = poly[(i - 1 + poly.length) % poly.length];
      final currIn = signedDist(curr) >= -1e-9;
      final prevIn = signedDist(prev) >= -1e-9;

      if (currIn) {
        if (!prevIn) {
          output.add(intersect(prev, curr));
        }
        output.add(curr);
      } else if (prevIn) {
        output.add(intersect(prev, curr));
      }
    }
    return output;
  }

  /// Computes exact areas on both sides of an arbitrary infinite line through splitStart -> splitEnd.
  static SplitAreasResult computeSplitLineAreas(
    List<Offset> poly,
    Offset splitStart,
    Offset splitEnd,
  ) {
    final leftPoly = clipPolygonByHalfPlane(poly, splitStart, splitEnd, keepLeft: true);
    final rightPoly = clipPolygonByHalfPlane(poly, splitStart, splitEnd, keepLeft: false);
    return SplitAreasResult(
      areaLeft: calculateArea(leftPoly),
      areaRight: calculateArea(rightPoly),
    );
  }

  /// Finds the exact axis-aligned boundary-to-boundary cut line yielding [targetArea]
  /// via binary search + polygon clipping.
  static BisectionCutResult? findAreaBisectionCutLine({
    required List<Offset> polygon,
    required double targetArea,
    required bool horizontalCut,
    bool fromStart = true,
  }) {
    if (polygon.length < 3) return null;
    final totalArea = calculateArea(polygon);
    if (totalArea <= 0) return null;

    final clampedTarget = targetArea.clamp(totalArea * 0.001, totalArea * 0.999);

    double minX = polygon[0].dx;
    double maxX = polygon[0].dx;
    double minY = polygon[0].dy;
    double maxY = polygon[0].dy;
    for (final p in polygon) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    double low = horizontalCut ? minY : minX;
    double high = horizontalCut ? maxY : maxX;
    double mid = (low + high) / 2.0;

    for (int iter = 0; iter < 42; iter++) {
      mid = (low + high) / 2.0;
      final Offset a;
      final Offset b;
      if (horizontalCut) {
        a = Offset(minX - 10, mid);
        b = Offset(maxX + 10, mid);
      } else {
        a = Offset(mid, minY - 10);
        b = Offset(mid, maxY + 10);
      }

      // If horizontal & fromStart (North/Top): points with y <= mid have cross <= 0 => keepLeft: false
      // If vertical & fromStart (West/Left): points with x <= mid have cross >= 0 => keepLeft: true
      final bool keepLeft = horizontalCut ? !fromStart : fromStart;
      final subPoly = clipPolygonByHalfPlane(polygon, a, b, keepLeft: keepLeft);
      final subArea = calculateArea(subPoly);

      if (fromStart) {
        if (subArea < clampedTarget) {
          low = mid;
        } else {
          high = mid;
        }
      } else {
        if (subArea < clampedTarget) {
          high = mid;
        } else {
          low = mid;
        }
      }
    }

    // Compute exact polygon boundary intersections along line mid
    final intersections = <Offset>[];
    for (int i = 0; i < polygon.length; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % polygon.length];
      final v1 = horizontalCut ? p1.dy : p1.dx;
      final v2 = horizontalCut ? p2.dy : p2.dx;
      if ((v1 <= mid && v2 >= mid) || (v2 <= mid && v1 >= mid)) {
        final denom = v2 - v1;
        if (denom.abs() < 1e-12) continue;
        final t = (mid - v1) / denom;
        final pt = Offset(
          p1.dx + t * (p2.dx - p1.dx),
          p1.dy + t * (p2.dy - p1.dy),
        );
        intersections.add(pt);
      }
    }

    if (intersections.length < 2) {
      final fallbackA = horizontalCut ? Offset(minX, mid) : Offset(mid, minY);
      final fallbackB = horizontalCut ? Offset(maxX, mid) : Offset(mid, maxY);
      return BisectionCutResult(
        cutStart: fallbackA,
        cutEnd: fallbackB,
        cutLength: (fallbackB - fallbackA).distance,
        offsetFromEdge: fromStart
            ? (mid - (horizontalCut ? minY : minX))
            : ((horizontalCut ? maxY : maxX) - mid),
        portionArea: clampedTarget,
      );
    }

    intersections.sort((a, b) =>
        horizontalCut ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy));
    final cutStart = intersections.first;
    final cutEnd = intersections.last;

    return BisectionCutResult(
      cutStart: cutStart,
      cutEnd: cutEnd,
      cutLength: (cutEnd - cutStart).distance,
      offsetFromEdge: fromStart
          ? (mid - (horizontalCut ? minY : minX))
          : ((horizontalCut ? maxY : maxX) - mid),
      portionArea: clampedTarget,
    );
  }

  /// Solves exact 2D vertices [A, B, C, D] for a quadrilateral using Law of Cosines
  /// where AB=north, BC=east, CD=south, DA=west, and AC=diagAC.
  /// Returns null if triangle inequalities fail.
  static List<Offset>? solveQuadrilateralVertices({
    required double north,
    required double east,
    required double south,
    required double west,
    required double diagAC,
  }) {
    if (north <= 0 || east <= 0 || south <= 0 || west <= 0 || diagAC <= 0) {
      return null;
    }
    // Check Triangle ABC and Triangle ADC inequalities
    if (north + east <= diagAC ||
        north + diagAC <= east ||
        east + diagAC <= north) {
      return null;
    }
    if (west + south <= diagAC ||
        west + diagAC <= south ||
        south + diagAC <= west) {
      return null;
    }

    const pA = Offset(0, 0);
    final pB = Offset(north, 0);

    final cosCAB = ((north * north + diagAC * diagAC - east * east) /
            (2.0 * north * diagAC))
        .clamp(-1.0, 1.0);
    final angleCAB = math.acos(cosCAB);
    final pC = Offset(diagAC * math.cos(angleCAB), diagAC * math.sin(angleCAB));

    final cosDAC = ((west * west + diagAC * diagAC - south * south) /
            (2.0 * west * diagAC))
        .clamp(-1.0, 1.0);
    final angleDAC = math.acos(cosDAC);
    final thetaAC = math.atan2(pC.dy, pC.dx);
    final angleAD = thetaAC + angleDAC;
    final pD = Offset(west * math.cos(angleAD), west * math.sin(angleAD));

    return [pA, pB, pC, pD];
  }
}
