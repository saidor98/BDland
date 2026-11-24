import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bdland_pro/features/tools/widgets/esri_satellite_map_view.dart';

void main() {
  group('ESRI Satellite Map View & Geodesic Math Tests', () {
    test('Web Mercator projection latLngToWorldPixels & worldPixelsToLatLng roundtrip', () {
      const lat = 23.8103; // Dhaka Latitude
      const lng = 90.4125; // Dhaka Longitude
      const zoom = 17.0;

      final worldPx = EsriSatelliteMapView.latLngToWorldPixels(lat, lng, zoom);
      expect(worldPx.dx, isPositive);
      expect(worldPx.dy, isPositive);

      final roundtripLatLng = EsriSatelliteMapView.worldPixelsToLatLng(worldPx.dx, worldPx.dy, zoom);
      expect(roundtripLatLng.latitude, closeTo(lat, 0.00001));
      expect(roundtripLatLng.longitude, closeTo(lng, 0.00001));
    });

    test('Tile coordinate calculation for Dhaka at zoom 17', () {
      const lat = 23.8103;
      const lng = 90.4125;
      const zoom = 17;

      final tileCoords = EsriSatelliteMapView.getTileCoords(lat, lng, zoom);
      expect(tileCoords.x, isPositive);
      expect(tileCoords.y, isPositive);
      // For Dhaka at z=17, X should be around 98450-98465, Y around 56830-56845
      expect(tileCoords.x, inInclusiveRange(98000, 99000));
      expect(tileCoords.y, inInclusiveRange(56000, 57000));
    });

    test('Haversine distance calculation in feet', () {
      // 1 minute of latitude (~6076 feet / 1 nautical mile)
      const p1 = LatLngPoint(23.8100, 90.4100);
      const p2 = LatLngPoint(23.826667, 90.4100); // 1 minute north

      final distFeet = EsriSatelliteMapView.haversineFeet(p1, p2);
      expect(distFeet, closeTo(6076.0, 50.0));
    });

    test('Geodesic area calculation for Cadastral polygon', () {
      // Approximate 100m x 100m (328 ft x 328 ft ~ 107,584 sq ft) square in Dhaka
      const lat = 23.8100;
      const lng = 90.4100;
      const dLat = 0.00090; // ~100 meters
      const dLng = 0.00098; // ~100 meters at lat 23.8°

      final points = [
        const LatLngPoint(lat, lng),
        const LatLngPoint(lat + dLat, lng),
        const LatLngPoint(lat + dLat, lng + dLng),
        const LatLngPoint(lat, lng + dLng),
      ];

      final areaSqFt = EsriSatelliteMapView.calculateGeodesicAreaSqFt(points);
      expect(areaSqFt, isPositive);
      // Area should be approximately 100,000 to 120,000 sq ft (~2.3 to 2.8 bigha)
      expect(areaSqFt, inInclusiveRange(90000.0, 130000.0));

      final areaDecimal = areaSqFt / 435.60;
      expect(areaDecimal, inInclusiveRange(200.0, 300.0));
    });

    test('Interior angle calculation for right-angled corners', () {
      // 90 degree corner: (0, 100) -> (0, 0) -> (100, 0)
      const prev = Offset(0, 100);
      const curr = Offset(0, 0);
      const next = Offset(100, 0);

      final angle = EsriSatelliteMapView.calculateInteriorAngleDegrees(prev, curr, next);
      expect(angle, closeTo(90.0, 0.01));
    });

    test('Interior angle calculation for 60 degree equilateral triangle corner', () {
      // Angle between (1, 0) and (cos(60°), sin(60°)) = (0.5, 0.866)
      const prev = Offset(100, 0);
      const curr = Offset(0, 0);
      const next = Offset(50, 86.60254);

      final angle = EsriSatelliteMapView.calculateInteriorAngleDegrees(prev, curr, next);
      expect(angle, closeTo(60.0, 0.1));
    });

    test('EsriMapController initialization and defaults', () {
      final controller = EsriMapController();
      expect(controller.activeLayer, equals(SatelliteLayerType.esriSatellite));
      expect(controller.currentZoom, equals(17.0));
    });
  });
}
