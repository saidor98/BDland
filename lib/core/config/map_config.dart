import 'dart:convert';

/// Global Map Configuration
/// Provides API tokens and Tile Server Endpoints for Mapbox, ESRI, and OpenStreetMap
class MapConfig {
  MapConfig._();

  // Obfuscated encoded key resolved at runtime or overridden via --dart-define=MAPBOX_ACCESS_TOKEN
  static String get mapboxAccessToken {
    const envToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
    if (envToken.isNotEmpty) return envToken;
    final bytes = base64Decode(
      'cGsuZXlKMUlqb2ljMkZwWkc5eU5qZ3pORGdpTENKaElqb2lZMjEzZFdsb2QyZG1NREJ2TURKNGNYbG9jM2szY2pNNGFTSjkubEJ5bGRPS0dLaGFWa2FUWVBRSE56QQ==',
    );
    return utf8.decode(bytes);
  }

  // Mapbox Style Identifiers
  static const String mapboxSatelliteStreetsStyle = 'mapbox/satellite-streets-v12';
  static const String mapboxSatellitePureStyle = 'mapbox/satellite-v9';
  static const String mapboxStreetsStyle = 'mapbox/streets-v12';
  static const String mapboxOutdoorsStyle = 'mapbox/outdoors-v12';

  // ESRI Endpoints
  static const String esriWorldImageryBase =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile';
  static const String esriWorldStreetBase =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile';

  // OpenStreetMap Endpoint
  static const String osmBase = 'https://tile.openstreetmap.org';

  /// Generates a Mapbox Slippy Tile URL (256x256 standard tile)
  static String getMapboxTileUrl(String styleId, int z, int x, int y) {
    final token = mapboxAccessToken;
    return 'https://api.mapbox.com/styles/v1/$styleId/tiles/256/$z/$x/$y?access_token=$token';
  }

  /// Generates an ESRI Slippy Tile URL
  static String getEsriTileUrl(String baseUrl, int z, int x, int y) {
    return '$baseUrl/$z/$y/$x';
  }

  /// Generates an OSM Slippy Tile URL
  static String getOsmTileUrl(int z, int x, int y) {
    return '$osmBase/$z/$x/$y.png';
  }
}
