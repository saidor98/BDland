import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/config/map_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/bangla_numerals.dart';
import '../../../core/data/bangladesh_administrative_data.dart';
import '../../../core/utils/bangla_formatter.dart';

enum SatelliteLayerType {
  esriSatellite,
  mapboxSatelliteStreets,
  mapboxSatellitePure,
  mapboxStreets,
  mapboxOutdoors,
  esriTopo,
  osmRoads,
}

class LatLngPoint {
  final double latitude;
  final double longitude;

  const LatLngPoint(this.latitude, this.longitude);

  @override
  String toString() => '(${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)})';
}

/// Controller to programmatically control the ESRI/Mapbox Satellite Map
class EsriMapController {
  _EsriSatelliteMapViewState? _state;

  void attach(_EsriSatelliteMapViewState state) {
    _state = state;
  }

  void detach() {
    _state = null;
  }

  void zoomIn() => _state?.zoomIn();
  void zoomOut() => _state?.zoomOut();
  void jumpTo(double lat, double lng, {double zoom = 17.0}) => _state?.jumpTo(lat, lng, zoom: zoom);
  void setLayer(SatelliteLayerType layer) => _state?.setLayer(layer);
  SatelliteLayerType get activeLayer => _state?.activeLayer ?? SatelliteLayerType.esriSatellite;
  double get currentZoom => _state?.currentZoom ?? 17.0;
  void showLayerDialog(BuildContext context) => _state?.showLayerSelectorDialog();
  void showJumpDialog(BuildContext context) => _state?.showLocationJumpDialog();
}

class EsriSatelliteMapView extends StatefulWidget {
  final List<LatLngPoint> surveyPoints;
  final ValueChanged<List<LatLngPoint>>? onPointsChanged;
  final bool isDrawingMode;
  final bool showDimensions;
  final bool showAngles;
  final SatelliteLayerType initialLayer;
  final LatLngPoint initialCenter;
  final double initialZoom;
  final Widget? overlayChild;
  final EsriMapController? controller;
  final bool showControls;
  final bool showLayerTag;
  final bool showZoomButtons;
  final bool showLayerSwitcher;
  final bool showLocationJump;

  const EsriSatelliteMapView({
    super.key,
    required this.surveyPoints,
    this.onPointsChanged,
    this.isDrawingMode = true,
    this.showDimensions = true,
    this.showAngles = true,
    this.initialLayer = SatelliteLayerType.mapboxSatelliteStreets,
    this.initialCenter = const LatLngPoint(23.8103, 90.4125), // Dhaka, Bangladesh
    this.initialZoom = 17.0, // High-resolution cadastral survey level
    this.overlayChild,
    this.controller,
    this.showControls = true,
    this.showLayerTag = true,
    this.showZoomButtons = true,
    this.showLayerSwitcher = true,
    this.showLocationJump = true,
  });

  @override
  State<EsriSatelliteMapView> createState() => _EsriSatelliteMapViewState();

  // Hyperbolic math functions (not present in standard dart:math)
  static double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2.0;
  static double _asinh(double x) => math.log(x + math.sqrt(x * x + 1.0));

  // Mathematical utility functions for Web Mercator (EPSG:3857)
  static Offset latLngToWorldPixels(double lat, double lng, double zoom) {
    final worldSize = 256.0 * math.pow(2.0, zoom);
    final px = (lng + 180.0) / 360.0 * worldSize;
    final latRad = lat * math.pi / 180.0;
    final clampedLatRad = latRad.clamp(-1.4844, 1.4844); // ~85 degrees
    final py = (1.0 - math.log(math.tan(clampedLatRad) + 1.0 / math.cos(clampedLatRad)) / math.pi) / 2.0 * worldSize;
    return Offset(px, py);
  }

  static LatLngPoint worldPixelsToLatLng(double px, double py, double zoom) {
    final worldSize = 256.0 * math.pow(2.0, zoom);
    final lng = (px / worldSize * 360.0) - 180.0;
    final n = math.pi - (py / worldSize * 2.0 * math.pi);
    final lat = 180.0 / math.pi * math.atan(_sinh(n));
    return LatLngPoint(lat, lng);
  }

  static math.Point<int> getTileCoords(double lat, double lng, int zoom) {
    final latRad = lat * math.pi / 180.0;
    final n = math.pow(2.0, zoom);
    final x = ((lng + 180.0) / 360.0 * n).floor();
    final y = ((1.0 - _asinh(math.tan(latRad)) / math.pi) / 2.0 * n).floor();
    return math.Point<int>(x, y);
  }

  static double haversineFeet(LatLngPoint p1, LatLngPoint p2) {
    const rFeet = 20902231.0; // Earth radius in feet (WGS84 approx 6,371,000m)
    final dLat = (p2.latitude - p1.latitude) * math.pi / 180.0;
    final dLng = (p2.longitude - p1.longitude) * math.pi / 180.0;
    final a = math.sin(dLat / 2.0) * math.sin(dLat / 2.0) +
        math.cos(p1.latitude * math.pi / 180.0) *
            math.cos(p2.latitude * math.pi / 180.0) *
            math.sin(dLng / 2.0) *
            math.sin(dLng / 2.0);
    final c = 2.0 * math.atan2(math.sqrt(a), math.sqrt((1.0 - a).clamp(0.0, 1.0)));
    return rFeet * c;
  }

  static double calculateGeodesicAreaSqFt(List<LatLngPoint> points) {
    if (points.length < 3) return 0.0;
    const rFeet = 20902231.0;
    double total = 0.0;
    for (int i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      final lat1 = p1.latitude * math.pi / 180.0;
      final lat2 = p2.latitude * math.pi / 180.0;
      final dLng = (p2.longitude - p1.longitude) * math.pi / 180.0;
      total += dLng * (2.0 + math.sin(lat1) + math.sin(lat2));
    }
    total = (total * rFeet * rFeet / 2.0).abs();
    return total;
  }

  static double calculateInteriorAngleDegrees(Offset prev, Offset curr, Offset next) {
    final v1x = prev.dx - curr.dx;
    final v1y = prev.dy - curr.dy;
    final v2x = next.dx - curr.dx;
    final v2y = next.dy - curr.dy;

    final dot = v1x * v2x + v1y * v2y;
    final mag1 = math.sqrt(v1x * v1x + v1y * v1y);
    final mag2 = math.sqrt(v2x * v2x + v2y * v2y);
    if (mag1 == 0 || mag2 == 0) return 180.0;

    final cosTheta = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    return math.acos(cosTheta) * 180.0 / math.pi;
  }
}

class _EsriSatelliteMapViewState extends State<EsriSatelliteMapView> {
  late double _centerLat;
  late double _centerLng;
  late double _zoom;
  late SatelliteLayerType _activeLayer;

  int? _draggedVertexIndex;

  SatelliteLayerType get activeLayer => _activeLayer;
  double get currentZoom => _zoom;

  @override
  void initState() {
    super.initState();
    _centerLat = widget.initialCenter.latitude;
    _centerLng = widget.initialCenter.longitude;
    _zoom = widget.initialZoom;
    _activeLayer = widget.initialLayer;
    widget.controller?.attach(this);
  }

  @override
  void didUpdateWidget(covariant EsriSatelliteMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach();
      widget.controller?.attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?.detach();
    super.dispose();
  }

  void zoomIn() {
    setState(() {
      _zoom = (_zoom + 0.5).clamp(10.0, 20.0);
    });
  }

  void zoomOut() {
    setState(() {
      _zoom = (_zoom - 0.5).clamp(10.0, 20.0);
    });
  }

  void jumpTo(double lat, double lng, {double zoom = 17.0}) {
    setState(() {
      _centerLat = lat;
      _centerLng = lng;
      _zoom = zoom;
    });
  }

  void setLayer(SatelliteLayerType layer) {
    setState(() {
      _activeLayer = layer;
    });
  }

  String _getTileUrl(int z, int x, int y) {
    switch (_activeLayer) {
      case SatelliteLayerType.mapboxSatelliteStreets:
        return MapConfig.getMapboxTileUrl(MapConfig.mapboxSatelliteStreetsStyle, z, x, y);
      case SatelliteLayerType.mapboxSatellitePure:
        return MapConfig.getMapboxTileUrl(MapConfig.mapboxSatellitePureStyle, z, x, y);
      case SatelliteLayerType.mapboxStreets:
        return MapConfig.getMapboxTileUrl(MapConfig.mapboxStreetsStyle, z, x, y);
      case SatelliteLayerType.mapboxOutdoors:
        return MapConfig.getMapboxTileUrl(MapConfig.mapboxOutdoorsStyle, z, x, y);
      case SatelliteLayerType.esriSatellite:
        return MapConfig.getEsriTileUrl(MapConfig.esriWorldImageryBase, z, x, y);
      case SatelliteLayerType.esriTopo:
        return MapConfig.getEsriTileUrl(MapConfig.esriWorldStreetBase, z, x, y);
      case SatelliteLayerType.osmRoads:
        return MapConfig.getOsmTileUrl(z, x, y);
    }
  }

  String _getLayerDisplayName() {
    switch (_activeLayer) {
      case SatelliteLayerType.mapboxSatelliteStreets:
        return 'Mapbox স্যাটেলাইট ও পথঘাট (HD)';
      case SatelliteLayerType.mapboxSatellitePure:
        return 'Mapbox পিওর স্যাটেলাইট';
      case SatelliteLayerType.mapboxStreets:
        return 'Mapbox স্ট্রিট ও জরিপ ম্যাপ';
      case SatelliteLayerType.mapboxOutdoors:
        return 'Mapbox আউটডোর ও টপোগ্রাফি';
      case SatelliteLayerType.esriSatellite:
        return 'ESRI স্যাটেলাইট (HD Free)';
      case SatelliteLayerType.esriTopo:
        return 'ESRI টপোগ্রাফিক্যাল';
      case SatelliteLayerType.osmRoads:
        return 'OpenStreetMap (OSM)';
    }
  }

  Offset _latLngToScreen(LatLngPoint pt, Size size) {
    final centerWorld = EsriSatelliteMapView.latLngToWorldPixels(_centerLat, _centerLng, _zoom);
    final ptWorld = EsriSatelliteMapView.latLngToWorldPixels(pt.latitude, pt.longitude, _zoom);
    final screenX = (size.width / 2.0) + (ptWorld.dx - centerWorld.dx);
    final screenY = (size.height / 2.0) + (ptWorld.dy - centerWorld.dy);
    return Offset(screenX, screenY);
  }

  LatLngPoint _screenToLatLng(Offset screenPos, Size size) {
    final centerWorld = EsriSatelliteMapView.latLngToWorldPixels(_centerLat, _centerLng, _zoom);
    final ptWorldX = centerWorld.dx + (screenPos.dx - size.width / 2.0);
    final ptWorldY = centerWorld.dy + (screenPos.dy - size.height / 2.0);
    return EsriSatelliteMapView.worldPixelsToLatLng(ptWorldX, ptWorldY, _zoom);
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (_draggedVertexIndex != null) {
      // Moving a survey point
      final updatedPoint = _screenToLatLng(details.localPosition, size);
      final list = List<LatLngPoint>.from(widget.surveyPoints);
      list[_draggedVertexIndex!] = updatedPoint;
      widget.onPointsChanged?.call(list);
    } else {
      // Panning the satellite map
      final centerWorld = EsriSatelliteMapView.latLngToWorldPixels(_centerLat, _centerLng, _zoom);
      final newCenterX = centerWorld.dx - details.delta.dx;
      final newCenterY = centerWorld.dy - details.delta.dy;
      final newCenter = EsriSatelliteMapView.worldPixelsToLatLng(newCenterX, newCenterY, _zoom);
      setState(() {
        _centerLat = newCenter.latitude;
        _centerLng = newCenter.longitude;
      });
    }
  }

  void _onTapUp(TapUpDetails details, Size size) {
    if (!widget.isDrawingMode) return;
    if (_draggedVertexIndex != null) return;

    final clickedPt = _screenToLatLng(details.localPosition, size);
    final list = List<LatLngPoint>.from(widget.surveyPoints);
    list.add(clickedPt);
    widget.onPointsChanged?.call(list);
  }

  void showLocationJumpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _LocationJumpTabsDialog(
        onSelectLocation: (lat, lng, zoom) {
          jumpTo(lat, lng, zoom: zoom);
        },
      ),
    );
  }

  void showLayerSelectorDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.layers, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('মানচিত্র ও স্যাটেলাইট লেয়ার'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<SatelliteLayerType>(
                value: SatelliteLayerType.mapboxSatelliteStreets,
                groupValue: _activeLayer,
                title: const Text('Mapbox স্যাটেলাইট ও রাস্তাঘাট (HD)'),
                subtitle: const Text('প্রিমিয়াম Mapbox হাই-রেজোলিউশন স্যাটেলাইট সাথে রোড ও প্লেস নেমস'),
                onChanged: (val) {
                  if (val != null) {
                    setLayer(val);
                    Navigator.pop(ctx);
                  }
                },
              ),
              RadioListTile<SatelliteLayerType>(
                value: SatelliteLayerType.mapboxSatellitePure,
                groupValue: _activeLayer,
                title: const Text('Mapbox পিওর স্যাটেলাইট'),
                subtitle: const Text('অরিজিনাল স্যাটেলাইট ফটোগ্রাফি (কোনো টেক্সট বা লেবেল ছাড়া)'),
                onChanged: (val) {
                  if (val != null) {
                    setLayer(val);
                    Navigator.pop(ctx);
                  }
                },
              ),
              RadioListTile<SatelliteLayerType>(
                value: SatelliteLayerType.mapboxStreets,
                groupValue: _activeLayer,
                title: const Text('Mapbox স্ট্রিট ও জরিপ মানচিত্র'),
                subtitle: const Text('রাস্তাঘাট, সীমানা ও মৌজা এলাকার স্পষ্ট ভেক্টর লেআউট'),
                onChanged: (val) {
                  if (val != null) {
                    setLayer(val);
                    Navigator.pop(ctx);
                  }
                },
              ),
              RadioListTile<SatelliteLayerType>(
                value: SatelliteLayerType.mapboxOutdoors,
                groupValue: _activeLayer,
                title: const Text('Mapbox আউটডোর ও টপোগ্রাফি'),
                subtitle: const Text('উঁচু-নিচু ভূমি, কনট্যুর লাইন ও জলাশয়ের টপোগ্রাফিক ভিউ'),
                onChanged: (val) {
                  if (val != null) {
                    setLayer(val);
                    Navigator.pop(ctx);
                  }
                },
              ),
              const Divider(),
              RadioListTile<SatelliteLayerType>(
                value: SatelliteLayerType.esriSatellite,
                groupValue: _activeLayer,
                title: const Text('ESRI হাই-রেজোলিউশন স্যাটেলাইট'),
                subtitle: const Text('আসল স্যাটেলাইট ছবি (গাছপালা, ঘরবাড়ি, নদী ও সীমানা)'),
                onChanged: (val) {
                  if (val != null) {
                    setLayer(val);
                    Navigator.pop(ctx);
                  }
                },
              ),
              RadioListTile<SatelliteLayerType>(
                value: SatelliteLayerType.esriTopo,
                groupValue: _activeLayer,
                title: const Text('ESRI টপোগ্রাফিক্যাল ও রোড ম্যাপ'),
                subtitle: const Text('রাস্তাঘাট, মহাসড়ক ও ভৌগোলিক তথ্য'),
                onChanged: (val) {
                  if (val != null) {
                    setLayer(val);
                    Navigator.pop(ctx);
                  }
                },
              ),
              RadioListTile<SatelliteLayerType>(
                value: SatelliteLayerType.osmRoads,
                groupValue: _activeLayer,
                title: const Text('OpenStreetMap (বাংলা রোড ও নদী)'),
                subtitle: const Text('বিস্তারিত এলাকা ও মৌজা সীমানা লেবেল'),
                onChanged: (val) {
                  if (val != null) {
                    setLayer(val);
                    Navigator.pop(ctx);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        // Calculate tile coverage
        final centerWorld = EsriSatelliteMapView.latLngToWorldPixels(_centerLat, _centerLng, _zoom);
        final intTileZoom = _zoom.floor();

        // Viewport bounds in world pixels
        final minWorldX = centerWorld.dx - (size.width / 2.0);
        final maxWorldX = centerWorld.dx + (size.width / 2.0);
        final minWorldY = centerWorld.dy - (size.height / 2.0);
        final maxWorldY = centerWorld.dy + (size.height / 2.0);

        final minTileX = (minWorldX / 256.0).floor();
        final maxTileX = (maxWorldX / 256.0).floor();
        final minTileY = (minWorldY / 256.0).floor();
        final maxTileY = (maxWorldY / 256.0).floor();

        final tiles = <Widget>[];
        for (int tx = minTileX; tx <= maxTileX; tx++) {
          for (int ty = minTileY; ty <= maxTileY; ty++) {
            final screenLeft = (tx * 256.0) - centerWorld.dx + (size.width / 2.0);
            final screenTop = (ty * 256.0) - centerWorld.dy + (size.height / 2.0);

            final tileUrl = _getTileUrl(intTileZoom, tx, ty);

            tiles.add(
              Positioned(
                left: screenLeft,
                top: screenTop,
                width: 256,
                height: 256,
                child: Image.network(
                  tileUrl,
                  fit: BoxFit.cover,
                  headers: const {'User-Agent': 'BDLandPro/1.0 (Bangladesh Cadastral Survey OS)'},
                  errorBuilder: (ctx, err, stack) => Container(
                    color: const Color(0xFF1E293B),
                    child: const Center(
                      child: Icon(Icons.satellite_alt, color: Color(0xFF334155), size: 24),
                    ),
                  ),
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: const Color(0xFF0F172A),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: const Color(0x800284C7),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }
        }

        // Convert survey points to screen coordinates
        final screenPoints = widget.surveyPoints.map((p) => _latLngToScreen(p, size)).toList();

        return Stack(
          children: [
            // 1. Interactive Satellite Map Tile Grid
            GestureDetector(
              onTapUp: (details) => _onTapUp(details, size),
              onPanStart: (details) {
                final pos = details.localPosition;
                for (int i = 0; i < screenPoints.length; i++) {
                  if ((screenPoints[i] - pos).distance < 28.0) {
                    setState(() => _draggedVertexIndex = i);
                    return;
                  }
                }
              },
              onPanUpdate: (details) => _onPanUpdate(details, size),
              onPanEnd: (_) => setState(() => _draggedVertexIndex = null),
              child: Stack(
                children: [
                  // Base Tile Layer
                  ...tiles,

                  // Optional Semi-Transparent Mouza Cadastral Sheet Overlay
                  if (widget.overlayChild != null) widget.overlayChild!,

                  // Vector Plot & Boundary Painter
                  CustomPaint(
                    size: size,
                    painter: _SatelliteCadastralPainter(
                      points: widget.surveyPoints,
                      screenPoints: screenPoints,
                      draggedIndex: _draggedVertexIndex,
                      showDimensions: widget.showDimensions,
                      showAngles: widget.showAngles,
                    ),
                  ),
                ],
              ),
            ),

            // 2. Top-Left: Active Satellite Layer Tag
            if (widget.showControls && widget.showLayerTag)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xE00F172A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF0284C7), width: 1.2),
                    boxShadow: [
                      BoxShadow(color: const Color(0x4D000000), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_getLayerDisplayName()} | z${_zoom.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 3. Top-Right: Layer Switcher & Location Jump
            if (widget.showControls && (widget.showLayerSwitcher || widget.showLocationJump))
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  children: [
                    if (widget.showLayerSwitcher) ...[
                      FloatingActionButton.small(
                        heroTag: 'map_layer_btn',
                        backgroundColor: const Color(0xE60F172A),
                        foregroundColor: const Color(0xFF38BDF8),
                        onPressed: showLayerSelectorDialog,
                        tooltip: 'লেয়ার পরিবর্তন',
                        child: const Icon(Icons.layers, size: 20),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (widget.showLocationJump)
                      FloatingActionButton.small(
                        heroTag: 'map_jump_btn',
                        backgroundColor: const Color(0xE60F172A),
                        foregroundColor: const Color(0xFFFBBF24),
                        onPressed: showLocationJumpDialog,
                        tooltip: 'বিভাগ ও জেলা নির্বাচন (GeoJSON)',
                        child: const Icon(Icons.location_searching, size: 20),
                      ),
                  ],
                ),
              ),

            // 4. Bottom-Right: Zoom In (+) and Zoom Out (-) Buttons
            if (widget.showControls && widget.showZoomButtons)
              Positioned(
                bottom: 20,
                right: 12,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'map_zoom_in',
                      backgroundColor: const Color(0xE60F172A),
                      foregroundColor: Colors.white,
                      onPressed: zoomIn,
                      tooltip: 'জুম ইন (+)',
                      child: const Icon(Icons.add, size: 20),
                    ),
                    const SizedBox(height: 6),
                    FloatingActionButton.small(
                      heroTag: 'map_zoom_out',
                      backgroundColor: const Color(0xE60F172A),
                      foregroundColor: Colors.white,
                      onPressed: zoomOut,
                      tooltip: 'জুম আউট (-)',
                      child: const Icon(Icons.remove, size: 20),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Dynamic Location Jump Dialog with Divisions (8) and Districts (64) Tabs
class _LocationJumpTabsDialog extends StatefulWidget {
  final void Function(double lat, double lng, double zoom) onSelectLocation;

  const _LocationJumpTabsDialog({required this.onSelectLocation});

  @override
  State<_LocationJumpTabsDialog> createState() => _LocationJumpTabsDialogState();
}

class _LocationJumpTabsDialogState extends State<_LocationJumpTabsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredDistricts = BangladeshAdministrativeData.searchDistricts(_searchQuery);
    final filteredSubdistricts = BangladeshAdministrativeData.searchSubdistricts(_searchQuery);

    return AlertDialog(
      title: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.location_searching, color: AppColors.primaryGreen),
              SizedBox(width: 8),
              Text('বাংলাদেশ ভৌগোলিক অবস্থান (Shapefile/GeoJSON)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryGreen,
            tabs: const [
              Tab(text: '৮ বিভাগ'),
              Tab(text: '৬৪ জেলা'),
              Tab(text: '৩০ থানা'),
              Tab(text: 'মৌজা হটস্পট'),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        height: 380,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: 8 Divisions
            ListView.separated(
              itemCount: BangladeshAdministrativeData.divisions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final d = BangladeshAdministrativeData.divisions[idx];
                final count = BangladeshAdministrativeData.getDistrictsByDivision(d.id).length;
                return ListTile(
                  dense: true,
                  leading: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFF0284C7),
                    child: Icon(Icons.location_city, color: Colors.white, size: 16),
                  ),
                  title: Text('${d.bnName} (${d.name})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Lat: ${d.lat.toStringAsFixed(4)}, Lng: ${d.lng.toStringAsFixed(4)}'),
                  trailing: Chip(
                    label: Text('${BanglaNumerals.toBangla(count)} জেলা', style: const TextStyle(fontSize: 11)),
                    backgroundColor: const Color(0xFFF1F5F9),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onSelectLocation(d.lat, d.lng, 14.5);
                  },
                );
              },
            ),

            // Tab 2: 64 Districts with Live Search
            Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'জেলা খুঁজুন (বাংলা বা ইংরেজি)...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredDistricts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final dist = filteredDistricts[idx];
                      final div = dist.divisionId != null
                          ? BangladeshAdministrativeData.findDivisionById(dist.divisionId!)
                          : null;
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.pin_drop, size: 18, color: Color(0xFF0284C7)),
                        title: Text('${dist.bnName} (${dist.name})', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                        subtitle: Text('${div != null ? "${div.bnName} বিভাগ | " : ""}Lat: ${dist.lat.toStringAsFixed(4)}, Lng: ${dist.lng.toStringAsFixed(4)}', style: const TextStyle(fontSize: 11)),
                        onTap: () {
                          Navigator.pop(context);
                          widget.onSelectLocation(dist.lat, dist.lng, 16.0);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            // Tab 3: 30 Thanas / Subdistricts (Shapefile High Precision)
            Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'থানা / উপজেলা খুঁজুন (যেমন: ধানমন্ডি, গুলশান)...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredSubdistricts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final sub = filteredSubdistricts[idx];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.share_location, size: 18, color: Color(0xFFD97706)),
                        title: Text('${sub.bnName} (${sub.name})', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                        subtitle: Text('ঢাকা জেলা | Lat: ${sub.lat.toStringAsFixed(4)}, Lng: ${sub.lng.toStringAsFixed(4)}', style: const TextStyle(fontSize: 11)),
                        trailing: const Chip(
                          label: Text('Shapefile CAD', style: TextStyle(fontSize: 10, color: Color(0xFF0284C7))),
                          backgroundColor: Color(0xFFF0F9FF),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          widget.onSelectLocation(sub.lat, sub.lng, 16.5);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            // Tab 4: Mouza Hotspots
            ListView(
              children: [
                _buildHotspotTile('সোনারগাঁও, নারায়ণগঞ্জ (আমিনপুর জে.এল. ৩৪)', 23.6472, 90.6015, 17.5),
                _buildHotspotTile('ধানমন্ডি, ঢাকা (জাফরাবাদ মৌজা)', 23.7500, 90.3667, 17.0),
                _buildHotspotTile('রূপগঞ্জ, নারায়ণগঞ্জ (তারাব মৌজা)', 23.7167, 90.5167, 17.0),
                _buildHotspotTile('শ্রীপুর, গাজীপুর (মাওনা মৌজা)', 24.1667, 90.4333, 17.0),
                _buildHotspotTile('পটিয়া, চট্টগ্রাম (কুসুমপুরা মৌজা)', 22.2833, 91.9500, 17.0),
                _buildHotspotTile('জাফলং, সিলেট (নদী ও পাথর কোয়ারি)', 25.1633, 92.0197, 16.5),
                _buildHotspotTile('পদ্মা পার, রাজশাহী (সদর মৌজা)', 24.3636, 88.6241, 16.5),
                _buildHotspotTile('রূপসা পার, খুলনা (দৌলতপুর)', 22.8456, 89.5403, 16.5),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('বন্ধ করুন')),
      ],
    );
  }

  Widget _buildHotspotTile(String name, double lat, double lng, double zoom) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.explore, color: AppColors.secondaryGoldDark, size: 20),
      title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      subtitle: Text('Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)} (z$zoom)'),
      onTap: () {
        Navigator.pop(context);
        widget.onSelectLocation(lat, lng, zoom);
      },
    );
  }
}

class _SatelliteCadastralPainter extends CustomPainter {
  final List<LatLngPoint> points;
  final List<Offset> screenPoints;
  final int? draggedIndex;
  final bool showDimensions;
  final bool showAngles;

  _SatelliteCadastralPainter({
    required this.points,
    required this.screenPoints,
    required this.draggedIndex,
    required this.showDimensions,
    required this.showAngles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (screenPoints.isEmpty) return;

    // 1. Draw glowing cyan boundary polygon
    final polyFill = Paint()
      ..color = const Color(0x400284C7)
      ..style = PaintingStyle.fill;

    final polyStroke = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(screenPoints[0].dx, screenPoints[0].dy);
    for (int i = 1; i < screenPoints.length; i++) {
      path.lineTo(screenPoints[i].dx, screenPoints[i].dy);
    }
    if (screenPoints.length >= 3) {
      path.close();
      canvas.drawPath(path, polyFill);
    }
    canvas.drawPath(path, polyStroke);

    // 2. Side length badges in real Haversine feet
    if (showDimensions && points.length >= 2) {
      for (int i = 0; i < points.length; i++) {
        final p1 = points[i];
        final p2 = points[(i + 1) % points.length];
        if (points.length < 3 && i == points.length - 1) break;

        final sp1 = screenPoints[i];
        final sp2 = screenPoints[(i + 1) % screenPoints.length];
        final mid = Offset((sp1.dx + sp2.dx) / 2.0, (sp1.dy + sp2.dy) / 2.0);

        final distFeet = EsriSatelliteMapView.haversineFeet(p1, p2);
        _drawPillLabel(canvas, '${BanglaFormatter.formatNumber(distFeet, fractionDigits: 1)} ft', mid);
      }
    }

    // 3. Draw Interior Angles at Vertices (Degrees in Bengali)
    if (showAngles && screenPoints.length >= 3) {
      final n = screenPoints.length;
      for (int i = 0; i < n; i++) {
        final prev = screenPoints[(i - 1 + n) % n];
        final curr = screenPoints[i];
        final next = screenPoints[(i + 1) % n];

        final angleDeg = EsriSatelliteMapView.calculateInteriorAngleDegrees(prev, curr, next);

        // Vector pointing inwards into polygon from vertex
        final v1 = Offset(prev.dx - curr.dx, prev.dy - curr.dy);
        final v2 = Offset(next.dx - curr.dx, next.dy - curr.dy);
        final d1 = math.sqrt(v1.dx * v1.dx + v1.dy * v1.dy);
        final d2 = math.sqrt(v2.dx * v2.dx + v2.dy * v2.dy);
        if (d1 > 0 && d2 > 0) {
          final bisectorX = (v1.dx / d1) + (v2.dx / d2);
          final bisectorY = (v1.dy / d1) + (v2.dy / d2);
          final bMag = math.sqrt(bisectorX * bisectorX + bisectorY * bisectorY);
          final anglePos = bMag > 0
              ? Offset(curr.dx - (bisectorX / bMag) * 22, curr.dy - (bisectorY / bMag) * 22)
              : Offset(curr.dx, curr.dy - 18);

          _drawAngleBadge(canvas, '${BanglaNumerals.toBangla(angleDeg.round())}°', anglePos);
        }
      }
    }

    // 4. Draw Cadastral Vertex Pins (draggable)
    for (int i = 0; i < screenPoints.length; i++) {
      final sp = screenPoints[i];
      final isDragged = draggedIndex == i;

      // Glow halo
      canvas.drawCircle(
        sp,
        isDragged ? 12.0 : 8.0,
        Paint()..color = isDragged ? const Color(0x66FFC107) : const Color(0x660284C7),
      );

      // Core pin
      canvas.drawCircle(
        sp,
        isDragged ? 8.0 : 6.0,
        Paint()..color = isDragged ? Colors.amber : Colors.yellowAccent,
      );
      canvas.drawCircle(
        sp,
        isDragged ? 8.0 : 6.0,
        Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Pin number
      final tp = TextPainter(
        text: TextSpan(
          text: BanglaNumerals.toBangla(i + 1),
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(sp.dx - tp.width / 2.0, sp.dy - tp.height / 2.0));
    }
  }

  void _drawAngleBadge(Canvas canvas, String text, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFFBBF24)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: tp.width + 6, height: tp.height + 4),
      const Radius.circular(4),
    );
    canvas.drawRRect(rrect, Paint()..color = const Color(0xE60F172A));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF475569)..style = PaintingStyle.stroke..strokeWidth = 0.8);
    tp.paint(canvas, Offset(pos.dx - tp.width / 2.0, pos.dy - tp.height / 2.0));
  }

  void _drawPillLabel(Canvas canvas, String text, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: tp.width + 12, height: tp.height + 6),
      const Radius.circular(6),
    );
    canvas.drawRRect(rrect, Paint()..color = const Color(0xE00F172A));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF334155)..style = PaintingStyle.stroke..strokeWidth = 1);
    tp.paint(canvas, Offset(pos.dx - tp.width / 2.0, pos.dy - tp.height / 2.0));
  }

  @override
  bool shouldRepaint(covariant _SatelliteCadastralPainter oldDelegate) => true;
}
