import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../config/mapbox_config.dart';
import '../../models/land_parcel.dart';
import '../../providers/drawing_provider.dart';
import '../../providers/parcels_provider.dart';
import '../../providers/map_state_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/turf_service.dart';
import '../../utils/colors.dart';
import '../../utils/draw_shape.dart';
import '../../utils/drawing_mode.dart';
import '../drawing/shape_controls.dart';
import 'parcel_edit_dialog.dart';

/// Mapbox map widget with drawing capabilities
class MapboxView extends StatefulWidget {
  const MapboxView({super.key});

  @override
  State<MapboxView> createState() => MapboxViewState();
}

class MapboxViewState extends State<MapboxView> {
  MapboxMap? _mapboxMap;
  PolygonAnnotationManager? _polygonManager;
  PolylineAnnotationManager? _polylineManager;
  PointAnnotationManager? _pointManager;
  PointAnnotationManager? _centerPointManager;
  CircleAnnotationManager? _labelCircleManager; // For stable parcel labels
  PointAnnotationManager? _labelTextManager; // For stable text labels

  // Drawing state
  final List<Position> _drawingPoints = [];
  LatLngPoint? _lastFreehandPoint;
  bool _isFreehandDrawing = false;
  Offset? _centerHandlePosition;

  static const double _freehandMinDistanceMeters = 2.0;
  static const double _centerHandleSize = 36.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Use Consumer2 for MapStateProvider & LocationProvider لتحديد مركز الخريطة
        Consumer2<MapStateProvider, LocationProvider>(
          builder: (context, mapState, location, child) {
            // إذا توفر موقع المستخدم نستخدمه كمركز افتراضي، وإلا نستخدم حالة الخريطة
            final initialCenter = location.currentLatLng ?? mapState.center;
            final initialZoom = mapState.zoom;

            return MapWidget(
              key: const ValueKey("mapWidget"),
              // Only set camera on first creation - don't reset on rebuild
              cameraOptions: _mapboxMap == null
                  ? CameraOptions(
                      center: Point(
                        coordinates: Position(
                          initialCenter.longitude,
                          initialCenter.latitude,
                        ),
                      ),
                      zoom: initialZoom,
                    )
                  : null, // Don't reset camera after initial creation
              styleUri: mapState.isSatelliteView
                  ? MapboxConfig.satelliteStreets
                  : MapboxConfig.streets,
              textureView: true,
              onMapCreated: _onMapCreated,
              onTapListener: (context) {
                // Check if user tapped on a parcel
                final tappedPoint = LatLngPoint(
                  latitude: context.point.coordinates.lat.toDouble(),
                  longitude: context.point.coordinates.lng.toDouble(),
                );
                _findParcelAtLatLng(tappedPoint).then((parcel) {
                  if (parcel != null && mounted) {
                    _showParcelDetails(parcel);
                  }
                });
              },
            );
          },
        ),

        // Separate Consumer for DrawingProvider to handle GestureDetector overlay
        Consumer<DrawingProvider>(
          builder: (context, drawingProvider, _) {
            if (!drawingProvider.isDrawing) return const SizedBox.shrink();

            if (drawingProvider.currentMode == DrawingMode.freehand &&
                drawingProvider.isMapFrozen) {
              return Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (details) =>
                      _handleFreehandPanStart(details, context),
                  onPanUpdate: (details) =>
                      _handleFreehandPanUpdate(details, context),
                  onPanEnd: (_) => _handleFreehandPanEnd(),
                ),
              );
            }

            if (drawingProvider.isMapFrozen &&
                (drawingProvider.currentMode == DrawingMode.predefinedShape ||
                    drawingProvider.currentPoints.isNotEmpty)) {
              return Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onScaleStart: (details) {
                    // Initialize gesture - required for onScaleUpdate to work
                    _previousRotation = 0;
                    context.read<DrawingProvider>().saveState();
                  },
                  onScaleUpdate: (details) =>
                      _handleScaleUpdate(details, context),
                  onScaleEnd: _handleScaleEnd,
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),

        // Existing parcels overlays
        Consumer<ParcelsProvider>(
          builder: (context, parcels, _) {
            return const SizedBox.shrink(); // Charts will be added later
          },
        ),

        // Shape controls overlay
        Consumer<DrawingProvider>(
          builder: (context, drawing, _) {
            if (!drawing.isDrawing) return const SizedBox.shrink();

            // Show controls when shape is being drawn
            if (drawing.currentMode == DrawingMode.predefinedShape &&
                (drawing.shapeCenter != null ||
                    drawing.currentPoints.isNotEmpty)) {
              return const ShapeControls();
            }
            return const SizedBox.shrink();
          },
        ),

        // Center drag handle for custom shapes
        Consumer<DrawingProvider>(
          builder: (context, drawing, _) {
            if (!_shouldShowCenterHandle(drawing) ||
                _centerHandlePosition == null) {
              return const SizedBox.shrink();
            }

            return Positioned(
              left: _centerHandlePosition!.dx - (_centerHandleSize / 2),
              top: _centerHandlePosition!.dy - (_centerHandleSize / 2),
              child: GestureDetector(
                onPanUpdate: (details) =>
                    _handleCenterHandleDrag(details, drawing),
                child: _buildCenterHandle(),
              ),
            );
          },
        ),

        // Drawing mode indicator
        Consumer<DrawingProvider>(
          builder: (context, drawing, _) {
            if (!drawing.isDrawing) return const SizedBox.shrink();

            return Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildDrawingModeIndicator(drawing),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDrawingModeIndicator(DrawingProvider drawing) {
    String title = '';
    String subtitle = '';
    IconData icon = Icons.edit;
    Color color = AppColors.primary;

    switch (drawing.currentMode) {
      case DrawingMode.predefinedShape:
        switch (drawing.selectedPredefinedShape!) {
          case PredefinedShape.circle:
            title = 'رسم دائرة';
            icon = Icons.circle_outlined;
            break;
          case PredefinedShape.square:
            title = 'رسم مربع';
            icon = Icons.square_outlined;
            break;
          case PredefinedShape.trapezoid:
            title = 'رسم شبه منحرف';
            icon = Icons.change_history_outlined;
            break;
          case PredefinedShape.ellipse:
            title = 'رسم بيضاوي';
            icon = Icons.radio_button_unchecked;
            break;
        }
        if (drawing.shapeCenter == null) {
          // جميع الأشكال الجاهزة: ضغطة واحدة لتحديد المركز وإنشاء شكل افتراضي
          subtitle = 'اضغط مرة واحدة لتحديد المركز، ثم كبّر/صغّر واسحب الشكل';
          color = Colors.orange;
        } else {
          // الشكل ظاهر ويمكن تعديله بالإيماءات
          subtitle = 'اسحب للتكبير/التصغير والتحريك، ثم اضغط "إكمال" للحفظ';
          color = Colors.green;
        }
        break;

      case DrawingMode.customPoints:
        title = 'رسم مخصص';
        icon = Icons.timeline;
        if (drawing.pointsCount < 3) {
          subtitle = 'أضف ${3 - drawing.pointsCount} نقاط أخرى';
          color = Colors.orange;
        } else if (drawing.isMapFrozen) {
          subtitle = 'اسحب مقبض المركز لتحريك الشكل';
          color = Colors.green;
        } else {
          subtitle = '${drawing.pointsCount} نقاط • اضغط إكمال للحفظ';
          color = Colors.green;
        }
        break;

      case DrawingMode.freehand:
        title = 'رسم حر';
        icon = Icons.gesture;
        subtitle = 'ارسم على الخريطة';
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Lock indicator
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: drawing.isMapFrozen
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              drawing.isMapFrozen ? Icons.lock : Icons.lock_open,
              color: drawing.isMapFrozen ? Colors.orange : Colors.green,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    // Initialize annotation managers
    _polygonManager =
        await _mapboxMap?.annotations.createPolygonAnnotationManager();
    _polylineManager =
        await _mapboxMap?.annotations.createPolylineAnnotationManager();
    _pointManager =
        await _mapboxMap?.annotations.createPointAnnotationManager();
    _centerPointManager =
        await _mapboxMap?.annotations.createPointAnnotationManager();
    _labelCircleManager =
        await _mapboxMap?.annotations.createCircleAnnotationManager();

    // Load existing parcels
    _loadExistingParcels();

    // Listen to drawing state changes to handle map gestures
    if (mounted) {
      final drawingProvider = context.read<DrawingProvider>();
      drawingProvider.addListener(_onDrawingStateChanged);
      drawingProvider.addListener(_onDrawingDataChanged);
    }
    // Note: 3D terrain requires additional configuration
    // Will be added in future updates

    // Zoom to current location on startup
    if (mounted) {
      final locationProvider = context.read<LocationProvider>();
      final position = await locationProvider.getCurrentLocation();
      if (position != null && mounted) {
        await moveCamera(
          LatLngPoint(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
          zoom: 15.0,
        );
      }
    }
  }

  void _onDrawingStateChanged() {
    if (!mounted) return;
    final drawingProvider = context.read<DrawingProvider>();
    final shouldFreeze =
        drawingProvider.isDrawing && drawingProvider.isMapFrozen;
    _updateMapGestures(shouldFreeze);
  }

  DateTime? _lastVisualUpdate;
  static const _visualUpdateInterval =
      Duration(milliseconds: 32); // Cap at ~30fps

  void _onDrawingDataChanged() {
    if (!mounted) return;
    final drawingProvider = context.read<DrawingProvider>();
    if (!drawingProvider.isDrawing) {
      _isFreehandDrawing = false;
      _lastFreehandPoint = null;
    }

    // Throttle visual updates to prevent ANR
    final now = DateTime.now();
    if (_lastVisualUpdate != null &&
        now.difference(_lastVisualUpdate!) < _visualUpdateInterval) {
      return;
    }
    _lastVisualUpdate = now;

    _syncDrawingVisuals(drawingProvider);
  }

  void _updateMapGestures(bool shouldFreeze) async {
    if (_mapboxMap == null) return;

    // Disable map gestures when drawing AND map is frozen
    // User can toggle freeze to temporarily enable map movement
    await _mapboxMap?.gestures.updateSettings(
      GesturesSettings(
        scrollEnabled: !shouldFreeze,
        pinchToZoomEnabled: !shouldFreeze,
        doubleTouchToZoomOutEnabled: !shouldFreeze,
        rotateEnabled: !shouldFreeze,
        pitchEnabled: !shouldFreeze,
        doubleTapToZoomInEnabled: !shouldFreeze,
      ),
    );
  }

  // Throttling for gesture updates
  DateTime? _lastGestureUpdate;
  static const _gestureUpdateInterval =
      Duration(milliseconds: 16); // ~60 updates/sec for smoothness
  double _previousRotation = 0;

  void _handleScaleUpdate(
      ScaleUpdateDetails details, BuildContext context) async {
    final drawingProvider = context.read<DrawingProvider>();

    // Throttle updates to prevent lag
    final now = DateTime.now();
    if (_lastGestureUpdate != null &&
        now.difference(_lastGestureUpdate!) < _gestureUpdateInterval) {
      return; // Skip this update
    }
    _lastGestureUpdate = now;

    // Only handle shape gestures if map is frozen and we have content
    if (drawingProvider.isMapFrozen &&
        (drawingProvider.currentMode == DrawingMode.predefinedShape ||
            drawingProvider.currentPoints.isNotEmpty)) {
      // Handle Scaling (Pinch) - works for all shapes
      if ((details.scale - 1.0).abs() > 0.01) {
        // Use smoother scale factor
        final scaleDiff = details.scale - 1.0;
        final factor =
            1.0 + (scaleDiff * 0.08); // Increased responsiveness (was 0.05)

        if (factor != 1.0) {
          // Don't add to history during continuous gesture
          drawingProvider.scaleShape(factor, addToHistory: false);
        }
      }

      // Handle rotation
      final rotationDelta = details.rotation - _previousRotation;
      if (rotationDelta.abs() > 0.005) {
        drawingProvider.rotateShape(rotationDelta * 180 / math.pi,
            addToHistory: false);
        _previousRotation = details.rotation;
      }

      // Handle Panning (Move) - only when not pinching
      if (details.scale > 0.95 && details.scale < 1.05) {
        // Sensitivity based on shape type
        const sensitivity =
            1.5; // Increased sensitivity (was 1.0) for easier movement
        final dxMeters = details.focalPointDelta.dx * sensitivity;
        final dyMeters = -details.focalPointDelta.dy * sensitivity;

        if (dxMeters.abs() > 0.01 || dyMeters.abs() > 0.01) {
          drawingProvider.moveShape(dxMeters, dyMeters, addToHistory: false);
        }
      }

      // Note: We removed the direct calls to _updateDrawingVisuals here
      // The DrawingProvider.notifyListeners() will trigger _onDrawingDataChanged
      // which handles the visual update. This prevents double-rendering.
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _previousRotation = 0;
    // Force a final update to ensure the shape is in the correct position and high quality
    if (mounted) {
      final drawingProvider = context.read<DrawingProvider>();
      drawingProvider.finalizeShape();
      // _syncDrawingVisuals will be triggered by notifyListeners in finalizeShape
    }
  }

  bool _shouldShowCenterHandle(DrawingProvider drawing) {
    if (!drawing.isDrawing || !drawing.isMapFrozen) {
      return false;
    }

    // For predefined shapes, we need a center
    if (drawing.currentMode == DrawingMode.predefinedShape &&
        drawing.shapeCenter == null) {
      return false;
    }

    // Show handle for custom points if we have enough points
    if (drawing.currentMode == DrawingMode.customPoints &&
        drawing.currentPoints.length >= 2) {
      return true;
    }

    // Show handle for predefined shapes if they are initialized
    if (drawing.currentMode == DrawingMode.predefinedShape) {
      return true;
    }

    return false;
  }

  Widget _buildCenterHandle() {
    return Container(
      width: _centerHandleSize,
      height: _centerHandleSize,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: const Icon(
        Icons.open_with,
        color: AppColors.primary,
        size: 18,
      ),
    );
  }

  void _handleCenterHandleDrag(
      DragUpdateDetails details, DrawingProvider drawing) {
    if (drawing.shapeCenter == null) return;

    const sensitivity = 1.0; // Increased sensitivity
    final dxMeters = details.delta.dx * sensitivity;
    final dyMeters = -details.delta.dy * sensitivity;

    if (dxMeters.abs() < 0.01 && dyMeters.abs() < 0.01) return;

    drawing.moveShape(dxMeters, dyMeters);
    _updateDrawingVisuals(drawing);
    _updateCenterMarker(drawing);
  }

  void _handleFreehandPanStart(DragStartDetails details, BuildContext context) {
    _isFreehandDrawing = true;
    _processFreehandPoint(details.localPosition, context, force: true);
  }

  void _handleFreehandPanUpdate(
      DragUpdateDetails details, BuildContext context) {
    if (!_isFreehandDrawing) return;
    _processFreehandPoint(details.localPosition, context);
  }

  void _handleFreehandPanEnd() {
    _isFreehandDrawing = false;
    _lastFreehandPoint = null;
  }

  void _processFreehandPoint(
    Offset position,
    BuildContext context, {
    bool force = false,
  }) {
    if (_mapboxMap == null) return;

    final screenCoordinate = ScreenCoordinate(x: position.dx, y: position.dy);
    _mapboxMap!.coordinateForPixel(screenCoordinate).then((point) {
      if (!mounted) return;
      final drawing = context.read<DrawingProvider>();
      if (drawing.currentMode != DrawingMode.freehand) return;

      final latLng = LatLngPoint(
        latitude: point.coordinates.lat.toDouble(),
        longitude: point.coordinates.lng.toDouble(),
      );

      if (_lastFreehandPoint != null && !force) {
        final distance = TurfService.calculateDistance(
          _lastFreehandPoint!,
          latLng,
        );
        if (distance < _freehandMinDistanceMeters) {
          return;
        }
      }

      drawing.addPoint(latLng);
      _lastFreehandPoint = latLng;
      _updateDrawingVisuals(drawing);
    }).catchError((_) {});
  }

  void _onMapTapped(MapContentGestureContext gestureContext) async {
    if (!mounted) return;

    final drawingProvider = context.read<DrawingProvider>();

    final tapLatLng = LatLngPoint(
      latitude: gestureContext.point.coordinates.lat.toDouble(),
      longitude: gestureContext.point.coordinates.lng.toDouble(),
    );

    // Only handle taps when in drawing mode
    if (!drawingProvider.isDrawing) {
      // Check if tap is on a saved parcel
      final tappedParcel = await _findParcelAtLatLng(tapLatLng);
      if (tappedParcel != null) {
        await _showParcelDetails(tappedParcel);
        return;
      }
      // Return to allow Mapbox to handle normal gestures (pan, zoom, etc.)
      return;
    }

    // Get the coordinate directly from gesture context
    final latLng = tapLatLng;

    // Handle based on current drawing mode
    if (drawingProvider.currentMode == DrawingMode.predefinedShape) {
      _handlePredefinedShapeTap(latLng, drawingProvider);
    } else {
      // Custom points or freehand mode
      drawingProvider.addPoint(latLng);
      _updateDrawingVisuals(drawingProvider, force: true);
      _updateCenterMarker(drawingProvider);
    }
  }

  /// Handle predefined shape tap
  void _handlePredefinedShapeTap(LatLngPoint latLng, DrawingProvider provider) {
    if (provider.selectedPredefinedShape == null) return;

    // جميع الأشكال الجاهزة (دائرة، مربع، مستطيل، مضلع):
    // ضغطة واحدة لتحديد المركز وإنشاء شكل افتراضي، ثم التعديل يكون فقط عبر الإيماءات
    if (provider.shapeCenter == null) {
      provider.setShapeCenter(latLng);
      provider.createDefaultPredefinedShapePreview();
      _updateCenterMarker(provider);
      _updateDrawingVisuals(provider, force: true);
      _showInfo(
          'استخدم أصابعك للتكبير/التصغير والتحريك، ثم اضغط "إكمال" للحفظ');
    }
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.black87,
      ),
    );
  }

  // Throttling for drawing updates
  DateTime _lastDrawingUpdate = DateTime.now();

  void _updateDrawingVisuals(DrawingProvider drawingProvider,
      {bool force = false}) async {
    // Throttle updates to max 30fps to prevent UI freeze, unless forced
    final now = DateTime.now();
    if (!force && now.difference(_lastDrawingUpdate).inMilliseconds < 32) {
      return;
    }
    _lastDrawingUpdate = now;

    final points = drawingProvider.currentPoints;

    if (points.isEmpty) {
      _clearDrawingVisuals(keepCenter: true);
      return;
    }

    // Convert to Positions
    _drawingPoints.clear();
    for (final point in points) {
      _drawingPoints.add(Position(point.longitude, point.latitude));
    }

    // Draw points and lines in parallel to save time
    await Future.wait([
      _drawPoints(),
      if (_drawingPoints.length >= 2) _drawTempLine(),
    ]);
  }

  Future<void> _drawPoints() async {
    // Clear existing points
    await _pointManager?.deleteAll();

    if (!mounted) return;

    // Get current shape and size from drawing provider
    final drawingProvider = context.read<DrawingProvider>();

    // Skip drawing vertex points for high-vertex shapes or custom shapes during edit to prevent lag
    if (drawingProvider.currentMode == DrawingMode.predefinedShape) {
      if (drawingProvider.selectedPredefinedShape == PredefinedShape.circle ||
          drawingProvider.selectedPredefinedShape == PredefinedShape.ellipse) {
        return;
      }
    } else if (drawingProvider.currentMode == DrawingMode.customPoints &&
        drawingProvider.isMapFrozen) {
      // Don't draw individual vertex points when moving the shape (map frozen)
      // This significantly improves performance
      return;
    }

    final iconName = drawingProvider.selectedShape.iconName;
    final iconSize = drawingProvider.pointSize * 1.5; // Base size * multiplier

    final pointsSnapshot = List<Position>.from(_drawingPoints);
    final List<Future<void>> createFutures = [];

    // Add points in parallel
    for (final point in pointsSnapshot) {
      final options = PointAnnotationOptions(
        geometry: Point(coordinates: point),
        iconImage: iconName,
        iconColor: AppColors.drawingPoint.toARGB32(),
        iconSize: iconSize,
      );

      if (_pointManager != null) {
        createFutures.add(_pointManager!.create(options));
      }
    }

    if (createFutures.isNotEmpty) {
      await Future.wait(createFutures);
    }
  }

  Future<void> _drawTempLine() async {
    // Clear existing line
    await _polylineManager?.deleteAll();

    // Create line string
    final linePoints = List<Position>.from(_drawingPoints);

    // Close the polygon if we have 3+ points
    if (linePoints.length >= 3) {
      linePoints.add(linePoints.first);
    }

    final options = PolylineAnnotationOptions(
      geometry: LineString(coordinates: linePoints),
      lineColor: AppColors.drawingLine.toARGB32(),
      lineWidth: 3.0,
    );

    await _polylineManager?.create(options);
  }

  void _clearDrawingVisuals({bool keepCenter = false}) async {
    _drawingPoints.clear();
    await _pointManager?.deleteAll();
    await _polylineManager?.deleteAll();
    if (!keepCenter) {
      await _centerPointManager?.deleteAll();
      if (_centerHandlePosition != null && mounted) {
        setState(() {
          _centerHandlePosition = null;
        });
      }
    }
  }

  void _syncDrawingVisuals(DrawingProvider drawing) {
    if (drawing.currentPoints.isNotEmpty) {
      _updateDrawingVisuals(drawing);
      _updateCenterMarker(drawing);
    } else if (drawing.shapeCenter != null &&
        drawing.currentMode == DrawingMode.predefinedShape) {
      _updateCenterMarker(drawing);
    } else {
      _clearDrawingVisuals();
    }
  }

  Future<void> _updateCenterMarker(DrawingProvider drawing) async {
    await _updatePredefinedCenterMarker(drawing);
    await _updateCenterHandleOverlay(drawing);
  }

  Future<void> _updatePredefinedCenterMarker(DrawingProvider drawing) async {
    if (_centerPointManager == null) return;

    final shouldShowPredefinedCenter = drawing.shapeCenter != null &&
        drawing.currentMode == DrawingMode.predefinedShape &&
        drawing.currentPoints.isEmpty;

    await _centerPointManager?.deleteAll();

    if (!shouldShowPredefinedCenter) {
      return;
    }

    await _centerPointManager?.create(
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

  Future<void> _updateCenterHandleOverlay(DrawingProvider drawing) async {
    if (_mapboxMap == null) return;

    final shouldShowHandle = _shouldShowCenterHandle(drawing);

    if (!shouldShowHandle) {
      if (_centerHandlePosition != null && mounted) {
        setState(() {
          _centerHandlePosition = null;
        });
      }
      return;
    }

    LatLngPoint centerPoint;
    if (drawing.shapeCenter != null) {
      centerPoint = drawing.shapeCenter!;
    } else if (drawing.currentPoints.isNotEmpty) {
      // Calculate centroid for custom shapes
      centerPoint = TurfService.calculateCentroid(drawing.currentPoints);
    } else {
      return;
    }

    final screen = await _mapboxMap!.pixelForCoordinate(
      Point(
        coordinates: Position(
          centerPoint.longitude,
          centerPoint.latitude,
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      _centerHandlePosition = Offset(screen.x, screen.y);
    });
  }

  Future<LandParcel?> _findParcelAtLatLng(LatLngPoint point) async {
    final parcelsProvider = context.read<ParcelsProvider>();
    for (final parcel in parcelsProvider.parcels) {
      if (parcel.coordinates.length >= 3 &&
          TurfService.isPointInPolygon(point, parcel.coordinates)) {
        return parcel;
      }
    }
    return null;
  }

  Future<void> _showParcelDetails(LandParcel parcel) async {
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.landscape,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parcel.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (parcel.cropType != null)
                        Text(
                          parcel.cropType!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Details
            _buildDetailRow(
              Icons.square_foot,
              'المساحة',
              '${parcel.areaInHectares.toStringAsFixed(2)} هكتار',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.crop,
              'نوع المحصول',
              parcel.cropType ?? 'غير محدد',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.calendar_today,
              'تاريخ الإنشاء',
              '${parcel.createdAt.day}/${parcel.createdAt.month}/${parcel.createdAt.year}',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.location_on,
              'عدد النقاط',
              '${parcel.coordinates.length} نقطة',
            ),

            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      moveCamera(parcel.centroid, zoom: 17);
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text('التركيز'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final parcelsProvider = context.read<ParcelsProvider>();
                      final updatedParcel = await showDialog<LandParcel>(
                        context: context,
                        builder: (context) => ParcelEditDialog(
                          parcel: parcel,
                          availableCropTypes: parcelsProvider.getAllCropTypes(),
                        ),
                      );

                      if (updatedParcel != null && mounted) {
                        await parcelsProvider.updateParcel(updatedParcel);
                        // Refresh map labels
                        setState(() {});
                        // Re-open details with updated info
                        _showParcelDetails(updatedParcel);
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('تعديل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _loadExistingParcels() async {
    if (!mounted) return;
    final parcelsProvider = context.read<ParcelsProvider>();

    print('🔄 Loading ${parcelsProvider.parcels.length} existing parcels...');
    for (final parcel in parcelsProvider.parcels) {
      await _addParcelToMap(parcel);
    }
    print('✅ Finished loading parcels');
  }

  Future<void> _addParcelToMap(LandParcel parcel) async {
    if (_polygonManager == null) return;

    // Convert coordinates
    final positions = parcel.coordinates.map((coord) {
      return Position(coord.longitude, coord.latitude);
    }).toList();

    // Close the polygon
    if (positions.isNotEmpty && positions.first != positions.last) {
      positions.add(positions.first);
    }

    // Create polygon
    final options = PolygonAnnotationOptions(
      geometry: Polygon(coordinates: [positions]),
      fillColor: AppColors.polygonFill.toARGB32(),
      fillOutlineColor: AppColors.polygonStroke.toARGB32(),
    );

    await _polygonManager?.create(options);

    // Add elegant native circle label - completely stable with map
    if (_labelCircleManager != null) {
      try {
        final circleOptions = CircleAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              parcel.centroid.longitude,
              parcel.centroid.latitude,
            ),
          ),
          circleRadius: 12.0, // أكبر للوضوح
          circleColor: AppColors.primary.toARGB32(),
          circleOpacity: 0.95, // شفافية خفيفة
          circleStrokeWidth: 3.5, // إطار أعرض
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeOpacity: 1.0,
          circleBlur: 0.4, // حواف ناعمة
        );

        await _labelCircleManager?.create(circleOptions);

        // Add text label next to the circle
        if (_labelTextManager != null) {
          final textOptions = PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(
                parcel.centroid.longitude,
                parcel.centroid.latitude,
              ),
            ),
            textField: parcel.name,
            textSize: 14.0,
            textColor: Colors.white.toARGB32(),
            textHaloColor: Colors.black.toARGB32(),
            textHaloWidth: 2.0,
            textAnchor: TextAnchor.LEFT,
            textOffset: [1.5, 0.0], // Offset to the right of the circle
          );
          await _labelTextManager?.create(textOptions);
        }
      } catch (e) {
        print('Error creating label for ${parcel.name}: $e');
      }
    }
  }

  // Public method to add new parcel
  Future<void> addParcel(LandParcel parcel) async {
    await _addParcelToMap(parcel);
    _clearDrawingVisuals();
  }

  // Public method to move camera
  Future<void> moveCamera(LatLngPoint center, {double? zoom}) async {
    await _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(center.longitude, center.latitude),
        ),
        zoom: zoom,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  @override
  void dispose() {
    // Try-catch to avoid error if provider is already disposed
    try {
      final drawing = context.read<DrawingProvider>();
      drawing.removeListener(_onDrawingStateChanged);
      drawing.removeListener(_onDrawingDataChanged);
    } catch (_) {}

    _mapboxMap = null;
    _polygonManager = null;
    _polylineManager = null;
    _pointManager = null;
    _centerPointManager = null;
    _labelCircleManager = null;
    super.dispose();
  }
}
