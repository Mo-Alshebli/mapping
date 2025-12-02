import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Manages Mapbox annotation managers (Polygon, Polyline, Point)
class MapAnnotationManager {
  PolygonAnnotationManager? _polygonManager;
  PolylineAnnotationManager? _polylineManager;
  PointAnnotationManager? _pointManager;
  PointAnnotationManager? _centerPointManager;

  PolygonAnnotationManager? get polygonManager => _polygonManager;
  PolylineAnnotationManager? get polylineManager => _polylineManager;
  PointAnnotationManager? get pointManager => _pointManager;
  PointAnnotationManager? get centerPointManager => _centerPointManager;

  /// Initialize all annotation managers
  Future<void> initialize(MapboxMap mapboxMap) async {
    _polygonManager =
        await mapboxMap.annotations.createPolygonAnnotationManager();
    _polylineManager =
        await mapboxMap.annotations.createPolylineAnnotationManager();
    _pointManager = await mapboxMap.annotations.createPointAnnotationManager();
    _centerPointManager =
        await mapboxMap.annotations.createPointAnnotationManager();
  }

  /// Clear all annotations
  Future<void> clearAll() async {
    await _polygonManager?.deleteAll();
    await _polylineManager?.deleteAll();
    await _pointManager?.deleteAll();
    await _centerPointManager?.deleteAll();
  }

  /// Dispose managers
  void dispose() {
    _polygonManager = null;
    _polylineManager = null;
    _pointManager = null;
    _centerPointManager = null;
  }
}
