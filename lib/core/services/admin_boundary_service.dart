import 'dart:convert';
import 'package:flutter/services.dart';
import '../../features/tools/widgets/esri_satellite_map_view.dart';

/// Represents a parsed Administrative Boundary Polygon (from Shapefile / GeoJSON)
class AdminBoundaryFeature {
  final String id;
  final String nameEn;
  final String nameBn;
  final int level; // 0=Country, 1=Division, 2=District, 3=Subdistrict/Thana
  final String type;
  final List<double> bbox; // [minLng, minLat, maxLng, maxLat]
  final List<List<LatLngPoint>> rings; // Polygons and rings with coordinates

  const AdminBoundaryFeature({
    required this.id,
    required this.nameEn,
    required this.nameBn,
    required this.level,
    required this.type,
    required this.bbox,
    required this.rings,
  });

  LatLngPoint get centroid {
    if (rings.isEmpty || rings.first.isEmpty) {
      return LatLngPoint((bbox[1] + bbox[3]) / 2, (bbox[0] + bbox[2]) / 2);
    }
    double sumLat = 0;
    double sumLng = 0;
    int count = 0;
    for (final ring in rings) {
      for (final pt in ring) {
        sumLat += pt.latitude;
        sumLng += pt.longitude;
        count++;
      }
    }
    return count > 0 ? LatLngPoint(sumLat / count, sumLng / count) : LatLngPoint(23.8103, 90.4125);
  }
}

/// Service to load and query High-Precision Bangladesh Administrative Boundary Shapefiles
class AdminBoundaryService {
  AdminBoundaryService._();
  static final AdminBoundaryService instance = AdminBoundaryService._();

  static const String assetPath = 'assets/geo/bangladesh_adm_sample.geojson';

  List<AdminBoundaryFeature> _cachedFeatures = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<AdminBoundaryFeature> get allFeatures => _cachedFeatures;

  /// Loads GeoJSON from asset bundle or parsed string
  Future<List<AdminBoundaryFeature>> loadBoundaries([String? rawJson]) async {
    if (_isLoaded && rawJson == null) {
      return _cachedFeatures;
    }

    try {
      final jsonString = rawJson ?? await rootBundle.loadString(assetPath);
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final rawFeatures = data['features'] as List<dynamic>? ?? [];

      final List<AdminBoundaryFeature> parsed = [];

      for (final f in rawFeatures) {
        final props = f['properties'] as Map<String, dynamic>? ?? {};
        final geom = f['geometry'] as Map<String, dynamic>? ?? {};

        final geomType = geom['type'] as String? ?? '';
        final rawCoords = geom['coordinates'] as List<dynamic>? ?? [];

        final List<List<LatLngPoint>> rings = [];

        if (geomType == 'Polygon') {
          for (final rawRing in rawCoords) {
            final List<LatLngPoint> ring = [];
            for (final rawPt in rawRing) {
              final double lng = (rawPt[0] as num).toDouble();
              final double lat = (rawPt[1] as num).toDouble();
              ring.add(LatLngPoint(lat, lng));
            }
            if (ring.isNotEmpty) rings.add(ring);
          }
        } else if (geomType == 'MultiPolygon') {
          for (final rawPoly in rawCoords) {
            for (final rawRing in rawPoly) {
              final List<LatLngPoint> ring = [];
              for (final rawPt in rawRing) {
                final double lng = (rawPt[0] as num).toDouble();
                final double lat = (rawPt[1] as num).toDouble();
                ring.add(LatLngPoint(lat, lng));
              }
              if (ring.isNotEmpty) rings.add(ring);
            }
          }
        }

        final rawBbox = props['bbox'] as List<dynamic>? ?? [0, 0, 0, 0];
        final List<double> bbox = rawBbox.map((b) => (b as num).toDouble()).toList();

        parsed.add(AdminBoundaryFeature(
          id: props['id']?.toString() ?? '',
          nameEn: props['name_en']?.toString() ?? '',
          nameBn: props['name_bn']?.toString() ?? '',
          level: (props['level'] as num?)?.toInt() ?? 0,
          type: props['type']?.toString() ?? '',
          bbox: bbox,
          rings: rings,
        ));
      }

      _cachedFeatures = parsed;
      _isLoaded = true;
      return _cachedFeatures;
    } catch (e) {
      return [];
    }
  }

  /// Get all subdistricts / thanas (level 3)
  List<AdminBoundaryFeature> getSubdistricts() {
    return _cachedFeatures.where((f) => f.level == 3).toList();
  }

  /// Get district boundary (level 2)
  List<AdminBoundaryFeature> getDistricts() {
    return _cachedFeatures.where((f) => f.level == 2).toList();
  }

  /// Search boundaries by name
  List<AdminBoundaryFeature> search(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return _cachedFeatures;
    return _cachedFeatures.where((f) =>
      f.nameEn.toLowerCase().contains(q) ||
      f.nameBn.contains(q)
    ).toList();
  }
}
