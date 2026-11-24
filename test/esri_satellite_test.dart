import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bdland_pro/core/config/map_config.dart';
import 'package:bdland_pro/core/data/bangladesh_administrative_data.dart';
import 'package:bdland_pro/core/services/admin_boundary_service.dart';
import 'package:bdland_pro/features/tools/widgets/esri_satellite_map_view.dart';

void main() {
  group('Mapbox & ESRI Satellite Map View Tests', () {
    test('MapConfig holds valid Mapbox token and builds valid tile URLs', () {
      expect(MapConfig.mapboxAccessToken, startsWith('pk.eyJ1'));
      expect(MapConfig.mapboxAccessToken.length, greaterThan(50));

      final tileUrl = MapConfig.getMapboxTileUrl(MapConfig.mapboxSatelliteStreetsStyle, 14, 12306, 7104);
      expect(tileUrl, contains('api.mapbox.com'));
      expect(tileUrl, contains('satellite-streets-v12'));
      expect(tileUrl, contains(MapConfig.mapboxAccessToken));

      final esriUrl = MapConfig.getEsriTileUrl(MapConfig.esriWorldImageryBase, 17, 98455, 56838);
      expect(esriUrl, contains('arcgisonline.com'));
      expect(esriUrl, contains('World_Imagery'));
      expect(esriUrl, endsWith('17/56838/98455'));
    });

    test('BangladeshAdministrativeData contains 8 divisions and 64 districts', () {
      expect(BangladeshAdministrativeData.divisions.length, equals(8));
      expect(BangladeshAdministrativeData.districts.length, equals(64));

      // Verify Dhaka division and its districts
      final dhakaDiv = BangladeshAdministrativeData.findDivisionById('3');
      expect(dhakaDiv, isNotNull);
      expect(dhakaDiv!.name, equals('Dhaka'));
      expect(dhakaDiv.bnName, equals('ঢাকা'));
      expect(dhakaDiv.lat, closeTo(23.81, 0.05));

      final dhakaDistricts = BangladeshAdministrativeData.getDistrictsByDivision('3');
      expect(dhakaDistricts.length, equals(13)); // Dhaka division has 13 districts

      // Verify search
      final narayanganjSearch = BangladeshAdministrativeData.searchDistricts('নারায়ণগঞ্জ');
      expect(narayanganjSearch, isNotEmpty);
      expect(narayanganjSearch.first.name, equals('Narayanganj'));

      final boguraSearch = BangladeshAdministrativeData.searchDistricts('Bogura');
      expect(boguraSearch, isNotEmpty);
      expect(boguraSearch.first.bnName, contains('বগুড়া'));

      final coxsBazarSearch = BangladeshAdministrativeData.searchDistricts("Cox's Bazar");
      expect(coxsBazarSearch, isNotEmpty);
      expect(coxsBazarSearch.first.bnName, equals('কক্স বাজার'));
    });

    test('BangladeshAdministrativeData contains 30 high-precision subdistricts/thanas', () {
      expect(BangladeshAdministrativeData.subdistricts.length, equals(30));

      final dhanmondi = BangladeshAdministrativeData.searchSubdistricts('ধানমন্ডি');
      expect(dhanmondi, isNotEmpty);
      expect(dhanmondi.first.name, equals('Dhanmondi'));
      expect(dhanmondi.first.lat, closeTo(23.74, 0.05));

      final gulshan = BangladeshAdministrativeData.searchSubdistricts('Gulshan');
      expect(gulshan, isNotEmpty);
      expect(gulshan.first.bnName, equals('গুলশান'));

      final savar = BangladeshAdministrativeData.searchSubdistricts('সাভার');
      expect(savar, isNotEmpty);
      expect(savar.first.name, equals('Savar'));
    });

    test('AdminBoundaryService parses sample GeoJSON features', () async {
      const sampleGeoJson = '''{
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "properties": {
              "id": "20005629",
              "level": 3,
              "name_en": "Dhanmondi",
              "name_bn": "ধানমন্ডি",
              "type": "Subdistricts",
              "bbox": [90.3664, 23.7311, 90.3931, 23.7585]
            },
            "geometry": {
              "type": "Polygon",
              "coordinates": [
                [[90.3664, 23.7311], [90.3931, 23.7311], [90.3931, 23.7585], [90.3664, 23.7585], [90.3664, 23.7311]]
              ]
            }
          }
        ]
      }''';

      final service = AdminBoundaryService.instance;
      final features = await service.loadBoundaries(sampleGeoJson);
      expect(features.length, equals(1));

      final feature = features.first;
      expect(feature.nameEn, equals('Dhanmondi'));
      expect(feature.nameBn, equals('ধানমন্ডি'));
      expect(feature.level, equals(3));
      expect(feature.rings.length, equals(1));
      expect(feature.rings.first.length, equals(5));
      expect(feature.centroid.latitude, closeTo(23.74, 0.05));
    });

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
      expect(tileCoords.x, inInclusiveRange(98000, 99000));
      expect(tileCoords.y, inInclusiveRange(56000, 57000));
    });

    test('Haversine distance calculation in feet', () {
      const p1 = LatLngPoint(23.8100, 90.4100);
      const p2 = LatLngPoint(23.826667, 90.4100); // 1 minute north

      final distFeet = EsriSatelliteMapView.haversineFeet(p1, p2);
      expect(distFeet, closeTo(6076.0, 50.0));
    });

    test('Geodesic area calculation for Cadastral polygon', () {
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
      expect(areaSqFt, inInclusiveRange(90000.0, 130000.0));

      final areaDecimal = areaSqFt / 435.60;
      expect(areaDecimal, inInclusiveRange(200.0, 300.0));
    });

    test('Interior angle calculation for right-angled corners', () {
      const prev = Offset(0, 100);
      const curr = Offset(0, 0);
      const next = Offset(100, 0);

      final angle = EsriSatelliteMapView.calculateInteriorAngleDegrees(prev, curr, next);
      expect(angle, closeTo(90.0, 0.01));
    });

    test('Interior angle calculation for 60 degree equilateral triangle corner', () {
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
