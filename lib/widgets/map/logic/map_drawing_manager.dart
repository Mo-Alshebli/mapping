import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../providers/drawing_provider.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/drawing_mode.dart';
import '../../../../utils/draw_shape.dart';
import 'map_annotation_manager.dart';

/// Manages drawing visuals and updates on the map
class MapDrawingManager {
  final MapAnnotationManager _annotationManager;
  final Function(Offset?) onUpdateCenterHandle;

  // Throttling for drawing updates
  DateTime _lastDrawingUpdate = DateTime.now();
  final List<Position> _drawingPoints = [];

  MapDrawingManager(this._annotationManager,
      {required this.onUpdateCenterHandle});

  /// Update all drawing visuals (points, lines, center marker)
  Future<void> updateDrawingVisuals(
    DrawingProvider drawingProvider, {
    bool force = false,
    MapboxMap? mapboxMap,
  }) async {
    // Throttle updates to max 30fps to prevent UI freeze, unless forced
    final now = DateTime.now();
    if (!force && now.difference(_lastDrawingUpdate).inMilliseconds < 32) {
      return;
    }
    _lastDrawingUpdate = now;

    final points = drawingProvider.currentPoints;

    if (points.isEmpty) {
      await clearDrawingVisuals(keepCenter: true);
      return;
    }

    // Convert to Positions
    _drawingPoints.clear();
    for (final point in points) {
      _drawingPoints.add(Position(point.longitude, point.latitude));
    }

    // Draw points and lines in parallel
    await Future.wait([
      _drawPoints(drawingProvider),
      if (_drawingPoints.length >= 2) _drawTempLine(),
    ]);
  }

  Future<void> _drawPoints(DrawingProvider drawingProvider) async {
    final pointManager = _annotationManager.pointManager;
    if (pointManager == null) return;

    await pointManager.deleteAll();

    final iconName = drawingProvider.selectedShape.iconName;
    final iconSize = drawingProvider.pointSize * 1.5;

    final pointsSnapshot = List<Position>.from(_drawingPoints);

    for (final point in pointsSnapshot) {
      final options = PointAnnotationOptions(
        geometry: Point(coordinates: point),
        iconImage: iconName,
        iconColor: AppColors.drawingPoint.toARGB32(),
        iconSize: iconSize,
      );
      await pointManager.create(options);
    }
  }

  Future<void> _drawTempLine() async {
    final polylineManager = _annotationManager.polylineManager;
    if (polylineManager == null) return;

    await polylineManager.deleteAll();

    final linePoints = List<Position>.from(_drawingPoints);

    if (linePoints.length >= 3) {
      linePoints.add(linePoints.first);
    }

    final options = PolylineAnnotationOptions(
      geometry: LineString(coordinates: linePoints),
      lineColor: AppColors.drawingLine.toARGB32(),
      lineWidth: 3.0,
    );

    await polylineManager.create(options);
  }

  /// Clear all drawing visuals
  Future<void> clearDrawingVisuals({bool keepCenter = false}) async {
    _drawingPoints.clear();
    await _annotationManager.pointManager?.deleteAll();
    await _annotationManager.polylineManager?.deleteAll();

    if (!keepCenter) {
      await _annotationManager.centerPointManager?.deleteAll();
      onUpdateCenterHandle(null);
    }
  }

  /// Update center marker and handle
  Future<void> updateCenterMarker(
    DrawingProvider drawing,
    MapboxMap? mapboxMap,
  ) async {
    await _updatePredefinedCenterMarker(drawing);
    await _updateCenterHandleOverlay(drawing, mapboxMap);
  }

  Future<void> _updatePredefinedCenterMarker(DrawingProvider drawing) async {
    final centerManager = _annotationManager.centerPointManager;
    if (centerManager == null) return;

    final shouldShowPredefinedCenter = drawing.shapeCenter != null &&
        drawing.currentMode == DrawingMode.predefinedShape &&
        drawing.currentPoints.isEmpty;

    await centerManager.deleteAll();

    if (!shouldShowPredefinedCenter) return;

    await centerManager.create(
      PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            drawing.shapeCenter!.longitude,
            drawing.shapeCenter!.latitude,
          ),
        ),
        iconImage: 'circle-15',
        iconColor: AppColors.primary.toARGB32(),
        iconSize: 1.5,
      ),
    );
  }

  Future<void> _updateCenterHandleOverlay(
    DrawingProvider drawing,
    MapboxMap? mapboxMap,
  ) async {
    if (mapboxMap == null) return;

    final shouldShowHandle = _shouldShowCenterHandle(drawing);

    if (!shouldShowHandle) {
      onUpdateCenterHandle(null);
      return;
    }

    try {
      final screen = await mapboxMap.pixelForCoordinate(
        Point(
          coordinates: Position(
            drawing.shapeCenter!.longitude,
            drawing.shapeCenter!.latitude,
          ),
        ),
      );
      onUpdateCenterHandle(Offset(screen.x, screen.y));
    } catch (_) {
      // Ignore errors if map is not ready
    }
  }

  bool _shouldShowCenterHandle(DrawingProvider drawing) {
    return drawing.isDrawing &&
        drawing.currentMode == DrawingMode.customPoints &&
        drawing.isMapFrozen &&
        drawing.shapeCenter != null &&
        drawing.currentPoints.length >= 2;
  }
}
