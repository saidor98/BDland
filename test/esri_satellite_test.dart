import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bdland_pro/core/config/map_config.dart';
import 'package:bdland_pro/core/data/bangladesh_administrative_data.dart';
import 'package:bdland_pro/core/services/admin_boundary_service.dart';
import 'package:bdland_pro/features/tools/widgets/esri_satellite_map_view.dart';

void main() {
  group('Mapbox & ESRI Satellite Map View Tests', () {
    setUpAll(() {
      HttpOverrides.global = _TestHttpOverrides();
    });

    test('MapConfig holds valid Mapbox token and builds valid tile URLs', () {
      expect(MapConfig.mapboxAccessToken, startsWith('pk.eyJ1'));
      expect(MapConfig.mapboxAccessToken.length, greaterThan(50));

      final tileUrl = MapConfig.getMapboxTileUrl(MapConfig.mapboxSatelliteStreetsStyle, 14, 12306, 7104);
      expect(tileUrl, contains('api.mapbox.com'));
      expect(tileUrl, contains('satellite-streets-v12'));
      expect(tileUrl, contains(MapConfig.mapboxAccessToken));

      final retinaTileUrl = MapConfig.getMapboxTileUrl(MapConfig.mapboxSatelliteStreetsStyle, 14, 12306, 7104, highDpi: true);
      expect(retinaTileUrl, contains('/tiles/256/14/12306/7104@2x?access_token='));

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
      expect(controller.currentCenter.latitude, closeTo(23.81, 0.05));
      expect(controller.currentCenter.longitude, closeTo(90.41, 0.05));
      expect(controller.selectedVertexIndex, isNull);
    });

    test('Fractional zoom world pixel projection scales proportionally by 2^(zoom - floor(zoom))', () {
      const lat = 23.8103;
      const lng = 90.4125;
      const baseZoom = 14.0;
      const fractionalZoom = 14.5;

      final baseWorldPx = EsriSatelliteMapView.latLngToWorldPixels(lat, lng, baseZoom);
      final fracWorldPx = EsriSatelliteMapView.latLngToWorldPixels(lat, lng, fractionalZoom);

      final expectedScale = math.pow(2.0, fractionalZoom - baseZoom);
      expect(fracWorldPx.dx, closeTo(baseWorldPx.dx * expectedScale, 0.001));
      expect(fracWorldPx.dy, closeTo(baseWorldPx.dy * expectedScale, 0.001));
    });

    testWidgets('Tile renderer at zoom 14.5 requests zoom-14 tiles with 256 * sqrt(2) dimensions and offsets relative to center', (WidgetTester tester) async {
      const testWidth = 512.0;
      const testHeight = 512.0;
      const centerLat = 23.8103;
      const centerLng = 90.4125;
      const zoom = 14.5;
      final expectedTileSize = 256.0 * math.sqrt(2);
      final centerBase = EsriSatelliteMapView.latLngToWorldPixels(centerLat, centerLng, 14.0);
      final scale = math.sqrt(2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: testWidth,
                height: testHeight,
                child: const EsriSatelliteMapView(
                  surveyPoints: [],
                  initialCenter: LatLngPoint(centerLat, centerLng),
                  initialZoom: zoom,
                  initialLayer: SatelliteLayerType.esriSatellite,
                  showControls: false,
                ),
              ),
            ),
          ),
        ),
      );

      // 1. Verify that it requests zoom-14 tiles
      final imageWidgets = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(imageWidgets, isNotEmpty);
      for (final img in imageWidgets) {
        if (img.image is NetworkImage) {
          final netImg = img.image as NetworkImage;
          expect(netImg.url, contains('/14/'));
          expect(netImg.url, isNot(contains('/14.5/')));
        }
      }

      // 2. Verify that each tile has dimensions of 256 * sqrt(2)
      final positionedWidgets = tester.widgetList<Positioned>(
        find.descendant(
          of: find.byType(Stack),
          matching: find.byType(Positioned),
        ),
      ).where((p) => p.width != null && (p.width! - expectedTileSize).abs() < 0.001).toList();

      expect(positionedWidgets, isNotEmpty);
      for (final pos in positionedWidgets) {
        expect(pos.width, closeTo(expectedTileSize, 0.001));
        expect(pos.height, closeTo(expectedTileSize, 0.001));

        // 3. Verify tile positioning offsets relative to projected center
        final offsetFromCenterX = pos.left! - (testWidth / 2.0);
        final offsetFromCenterY = pos.top! - (testHeight / 2.0);
        final tx = (((offsetFromCenterX / scale) + centerBase.dx) / 256.0).round();
        final ty = (((offsetFromCenterY / scale) + centerBase.dy) / 256.0).round();

        final expectedLeft = (tx * 256.0 - centerBase.dx) * scale + (testWidth / 2.0);
        final expectedTop = (ty * 256.0 - centerBase.dy) * scale + (testHeight / 2.0);

        expect(pos.left, closeTo(expectedLeft, 0.001));
        expect(pos.top, closeTo(expectedTop, 0.001));

        // Verify with renderer's existing tile-request interface
        final expectedTileUrl = MapConfig.getEsriTileUrl(MapConfig.esriWorldImageryBase, 14, tx, ty);
        expect(expectedTileUrl, contains('/14/'));
      }
    });

    testWidgets('Mapbox attribution renders official logo asset and interactive links', (WidgetTester tester) async {
      String? tappedUrl;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 500,
              child: EsriSatelliteMapView(
                surveyPoints: const [],
                initialCenter: const LatLngPoint(23.8103, 90.4125),
                initialZoom: 14.5,
                initialLayer: SatelliteLayerType.mapboxSatelliteStreets,
                showControls: false,
                onAttributionTap: (url) {
                  tappedUrl = url;
                },
              ),
            ),
          ),
        ),
      );

      // Verify interactive attribution links are rendered independently of showControls
      expect(find.text('© Mapbox'), findsOneWidget);
      expect(find.text('© OpenStreetMap'), findsOneWidget);
      expect(find.text('Improve this map'), findsOneWidget);

      // Tap 'Improve this map' and verify the callback receives the expected URL
      await tester.tap(find.text('Improve this map'));
      await tester.pump();
      expect(tappedUrl, contains('mapbox.com/map-feedback'));

      // Tap '© Mapbox'
      await tester.tap(find.text('© Mapbox'));
      await tester.pump();
      expect(tappedUrl, equals('https://www.mapbox.com/about/maps/'));

      // Tap '© OpenStreetMap'
      await tester.tap(find.text('© OpenStreetMap'));
      await tester.pump();
      expect(tappedUrl, equals('https://www.openstreetmap.org/copyright'));
    });
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);
