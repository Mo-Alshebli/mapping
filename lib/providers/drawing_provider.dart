import 'dart:math' show cos, sin, pi;
import 'package:flutter/foundation.dart';
import '../models/land_parcel.dart';
import '../services/turf_service.dart';
import '../services/geo_calculations.dart';
import '../utils/draw_shape.dart';
import '../utils/drawing_mode.dart';
import 'package:uuid/uuid.dart';

/// Provider for managing polygon drawing state
class DrawingProvider extends ChangeNotifier {
  // Drawing mode state
  bool _isDrawing = false;
  DrawingMode _currentMode = DrawingMode.customPoints;

  // Predefined shape mode
  PredefinedShape? _selectedPredefinedShape;
  LatLngPoint? _shapeCenter; // Center point for predefined shapes
  double? _shapeRadius; // Radius for circle/square/primary axis for ellipse
  double?
      _ellipseSecondaryRadius; // Secondary radius for ellipse (vertical axis)
  int _polygonSides = 5; // Number of sides for regular polygon
  double _rotationAngle = 0; // Rotation angle for predefined shapes

  // Custom point mode
  final List<LatLngPoint> _currentPoints = [];

  // Drawing appearance
  DrawShape _selectedShape = DrawShape.point; // For markers
  double _pointSize = 1.0; // Size multiplier

  // State
  LandParcel? _completedParcel;
  String? _error;

  // History for undo/redo
  final List<List<LatLngPoint>> _history = [];
  int _historyIndex = -1;

  // Map freeze state (for drawing mode)
  bool _isMapFrozen = true; // Frozen by default when drawing

  // Area unit preference (for farmers)
  AreaUnit _preferredUnit = AreaUnit.donum; // Default to donum

  // Template metadata
  String? _templateCropType;

  // Getters
  bool get isDrawing => _isDrawing;
  bool get isMapFrozen => _isMapFrozen;
  DrawingMode get currentMode => _currentMode;
  String? get templateCropType => _templateCropType;
  PredefinedShape? get selectedPredefinedShape => _selectedPredefinedShape;
  LatLngPoint? get shapeCenter => _shapeCenter;
  double? get shapeRadius => _shapeRadius;
  int get polygonSides => _polygonSides;
  double get rotationAngle => _rotationAngle;
  DrawShape get selectedShape => _selectedShape;
  double get pointSize => _pointSize;
  List<LatLngPoint> get currentPoints => List.unmodifiable(_currentPoints);
  LandParcel? get completedParcel => _completedParcel;
  String? get error => _error;
  int get pointsCount => _currentPoints.length;
  bool get canComplete {
    // For predefined shapes, check if shape is ready (has center and points)
    if (_currentMode == DrawingMode.predefinedShape &&
        _selectedPredefinedShape != null &&
        _shapeCenter != null &&
        _currentPoints.length >= 3) {
      return true;
    }
    // For other modes, check point count
    return _currentPoints.length >=
        (selectedShape == DrawShape.freehand ? 2 : 3);
  }

  // Undo/Redo getters
  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  // Area unit getters
  AreaUnit get preferredUnit => _preferredUnit;

  /// Get current area in square meters (null if not enough points)
  double? get currentArea {
    if (_currentPoints.length < 3) return null;
    try {
      return TurfService.calculateArea(_currentPoints);
    } catch (e) {
      return null;
    }
  }

  /// Get current area formatted with preferred unit
  String get currentAreaFormatted {
    final area = currentArea;
    if (area == null) return '--';
    return _preferredUnit.formatArea(area);
  }

  /// Set preferred area unit
  void setPreferredUnit(AreaUnit unit) {
    _preferredUnit = unit;
    notifyListeners();
  }

  /// Set the selected shape
  void setShape(DrawShape shape) {
    _selectedShape = shape;
    notifyListeners();
  }

  /// Set the point size
  void setPointSize(double size) {
    _pointSize = size.clamp(0.5, 2.0);
    notifyListeners();
  }

  /// Set the drawing mode
  void setDrawingMode(DrawingMode mode) {
    _currentMode = mode;
    _clearCurrentDrawing();
    notifyListeners();
  }

  /// Set predefined shape
  void setPredefinedShape(PredefinedShape shape) {
    _selectedPredefinedShape = shape;
    _currentMode = DrawingMode.predefinedShape;
    _clearCurrentDrawing();
    notifyListeners();
  }

  /// Set polygon sides for regular polygon
  void setPolygonSides(int sides) {
    _polygonSides = sides.clamp(3, 12);
    if (_shapeCenter != null) {
      _updatePredefinedShapePreview();
    }
    notifyListeners();
  }

  /// Toggle map freeze state
  void toggleMapFreeze() {
    _isMapFrozen = !_isMapFrozen;
    notifyListeners();
  }

  /// Set shape center for predefined shapes
  void setShapeCenter(LatLngPoint center) {
    _shapeCenter = center;
    notifyListeners();
  }

  /// Set shape radius for predefined shapes
  void setShapeRadius(double radius) {
    _shapeRadius = radius;
    _updatePredefinedShapePreview(); // Generate the shape preview
    notifyListeners();
  }

  /// Set template crop type
  void setTemplateCropType(String? cropType) {
    _templateCropType = cropType;
    notifyListeners();
  }

  /// Save current state to history (public)
  void saveState() {
    _addToHistory();
  }

  /// Move shape by delta (in meters)
  void moveShape(double dxMeters, double dyMeters, {bool addToHistory = true}) {
    if (addToHistory) _addToHistory();

    // Calculate lat/lng delta
    // Approximate conversion:
    // 1 degree lat ~= 111,320 meters
    // 1 degree lng ~= 111,320 * cos(lat) meters

    final centerLat = _shapeCenter?.latitude ??
        (_currentPoints.isNotEmpty ? _currentPoints.first.latitude : 0);

    final latDelta = dyMeters / 111320.0;
    final lngDelta = dxMeters / (111320.0 * cos(centerLat * pi / 180.0));

    // For all predefined shapes, move center and regenerate
    if (_selectedPredefinedShape != null && _shapeCenter != null) {
      _shapeCenter = LatLngPoint(
        latitude: _shapeCenter!.latitude + latDelta,
        longitude: _shapeCenter!.longitude + lngDelta,
      );
      _updatePredefinedShapePreview(isPreview: !addToHistory);
    } else if (_currentPoints.isNotEmpty) {
      // Move all points for custom shape
      final newPoints = <LatLngPoint>[];
      for (final point in _currentPoints) {
        newPoints.add(LatLngPoint(
          latitude: point.latitude + latDelta,
          longitude: point.longitude + lngDelta,
        ));
      }
      _currentPoints.clear();
      _currentPoints.addAll(newPoints);
    }

    notifyListeners();
  }

  /// Scale shape by factor (e.g., 1.05 for 5% increase)
  void scaleShape(double scaleFactor, {bool addToHistory = true}) {
    if (addToHistory) _addToHistory();

    // For all predefined shapes, scale radius and regenerate
    if (_shapeRadius != null) {
      _shapeRadius = (_shapeRadius! * scaleFactor).clamp(5.0, 5000.0);
      // Also scale ellipse secondary radius if exists
      if (_selectedPredefinedShape == PredefinedShape.ellipse &&
          _ellipseSecondaryRadius != null) {
        _ellipseSecondaryRadius =
            (_ellipseSecondaryRadius! * scaleFactor).clamp(5.0, 5000.0);
      }
      _updatePredefinedShapePreview(isPreview: !addToHistory);
    }
    notifyListeners();
  }

  /// Rotate shape by degrees
  void rotateShape(double degrees, {bool addToHistory = true}) {
    if (addToHistory) _addToHistory();

    if (_selectedPredefinedShape != null) {
      _rotationAngle = (_rotationAngle + degrees) % 360;
      _updatePredefinedShapePreview(isPreview: !addToHistory);
    } else if (_currentPoints.isNotEmpty) {
      // Rotate custom shape around centroid
      final centroid = TurfService.calculateCentroid(_currentPoints);
      final rotatedPoints = _rotatePoints(_currentPoints, centroid, degrees);
      _currentPoints.clear();
      _currentPoints.addAll(rotatedPoints);
    }

    notifyListeners();
  }

  /// Finalize shape after manipulation (force high quality)
  void finalizeShape() {
    _updatePredefinedShapePreview(isPreview: false);
    notifyListeners();
  }

  /// Create a default preview for the selected predefined shape after setting the center.
  /// This provides an initial size so the shape appears without needing a second tap.
  void createDefaultPredefinedShapePreview() {
    if (_shapeCenter == null) return;
    switch (_selectedPredefinedShape) {
      case PredefinedShape.circle:
      case PredefinedShape.square:
        // Default radius of 50 meters if not set
        _shapeRadius ??= 50.0;
        _updatePredefinedShapePreview();
        break;
      case PredefinedShape.trapezoid:
        // Use radius-based calculation
        _shapeRadius ??= 50.0;
        _updatePredefinedShapePreview();
        break;
      case PredefinedShape.ellipse:
        // Use radius-based calculation
        _shapeRadius ??= 50.0;
        _ellipseSecondaryRadius ??= _shapeRadius! * 0.7;
        _updatePredefinedShapePreview();
        break;
      default:
        // No action for other shapes
        break;
    }
    notifyListeners();
  }

  /// Public wrapper to update shape preview (used after radius changes etc.)
  void updateShapePreview() {
    _updatePredefinedShapePreview();
    notifyListeners();
  }

  /// Add opposite corner to complete rectangle
  void addRectangleCorner(LatLngPoint corner) {
    if (_currentPoints.isEmpty) return;

    _addToHistory(); // Save state before modifying

    final firstCorner = _currentPoints.first;

    // Create rectangle from two opposite corners
    final minLat = firstCorner.latitude < corner.latitude
        ? firstCorner.latitude
        : corner.latitude;
    final maxLat = firstCorner.latitude > corner.latitude
        ? firstCorner.latitude
        : corner.latitude;
    final minLng = firstCorner.longitude < corner.longitude
        ? firstCorner.longitude
        : corner.longitude;
    final maxLng = firstCorner.longitude > corner.longitude
        ? firstCorner.longitude
        : corner.longitude;

    // Set rectangle corners in order (clockwise from top-left)
    _currentPoints.clear();
    _currentPoints.addAll([
      LatLngPoint(latitude: maxLat, longitude: minLng), // top-left
      LatLngPoint(latitude: maxLat, longitude: maxLng), // top-right
      LatLngPoint(latitude: minLat, longitude: maxLng), // bottom-right
      LatLngPoint(latitude: minLat, longitude: minLng), // bottom-left
    ]);

    // Calculate and store center for reference
    _shapeCenter = LatLngPoint(
      latitude: (minLat + maxLat) / 2,
      longitude: (minLng + maxLng) / 2,
    );

    notifyListeners();
  }

  /// Update specific corner of rectangle (for drag-based resizing)
  /// cornerIndex: 0=top-left, 1=top-right, 2=bottom-right, 3=bottom-left
  void updateRectangleCorner(int cornerIndex, LatLngPoint newPosition) {
    if (_currentPoints.length != 4) return;

    _addToHistory(); // Save state before modifying

    // Get current bounds
    final lats = _currentPoints.map((p) => p.latitude).toList();
    final lngs = _currentPoints.map((p) => p.longitude).toList();

    double minLat = lats.reduce((a, b) => a < b ? a : b);
    double maxLat = lats.reduce((a, b) => a > b ? a : b);
    double minLng = lngs.reduce((a, b) => a < b ? a : b);
    double maxLng = lngs.reduce((a, b) => a > b ? a : b);

    // Update bounds based on which corner is being dragged
    switch (cornerIndex) {
      case 0: // top-left
        maxLat = newPosition.latitude;
        minLng = newPosition.longitude;
        break;
      case 1: // top-right
        maxLat = newPosition.latitude;
        maxLng = newPosition.longitude;
        break;
      case 2: // bottom-right
        minLat = newPosition.latitude;
        maxLng = newPosition.longitude;
        break;
      case 3: // bottom-left
        minLat = newPosition.latitude;
        minLng = newPosition.longitude;
        break;
    }

    // Rebuild rectangle with new bounds
    _currentPoints.clear();
    _currentPoints.addAll([
      LatLngPoint(latitude: maxLat, longitude: minLng), // top-left
      LatLngPoint(latitude: maxLat, longitude: maxLng), // top-right
      LatLngPoint(latitude: minLat, longitude: maxLng), // bottom-right
      LatLngPoint(latitude: minLat, longitude: minLng), // bottom-left
    ]);

    // Update center
    _shapeCenter = LatLngPoint(
      latitude: (minLat + maxLat) / 2,
      longitude: (minLng + maxLng) / 2,
    );

    notifyListeners();
  }

  /// Start drawing mode
  void startDrawing({DrawShape? shape, double? size, DrawingMode? mode}) {
    _isDrawing = true;
    if (shape != null) _selectedShape = shape;
    if (size != null) _pointSize = size.clamp(0.5, 2.0);
    if (mode != null) _currentMode = mode;
    _rotationAngle = 0;
    _clearCurrentDrawing();
    _completedParcel = null;
    _error = null;

    // Initialize history
    _history.clear();
    _historyIndex = -1;
    _addToHistory();

    notifyListeners();
  }

  /// Add a point to the current polygon
  void addPoint(LatLngPoint point) {
    if (!_isDrawing) {
      _error = 'Drawing mode is not active';
      notifyListeners();
      return;
    }

    _addToHistory(); // Save state before adding point
    _currentPoints.add(point);
    _error = null;
    notifyListeners();
  }

  /// Remove the last point
  void removeLastPoint() {
    if (_currentPoints.isNotEmpty) {
      _addToHistory(); // Save state before removing point
      _currentPoints.removeLast();
      notifyListeners();
    }
  }

  /// Clear all points
  void clearPoints() {
    _addToHistory(); // Save state before clearing
    _currentPoints.clear();
    _error = null;
    notifyListeners();
  }

  /// Cancel drawing
  void cancelDrawing() {
    _isDrawing = false;
    _currentPoints.clear();
    _error = null;
    _history.clear();
    _historyIndex = -1;
    notifyListeners();
  }

  /// Complete the polygon and create a LandParcel
  Future<LandParcel?> completeDrawing({String? name, String? cropType}) async {
    if (!canComplete) {
      _error = 'يجب إضافة نقاط كافية لإكمال الرسم';
      notifyListeners();
      return null;
    }

    try {
      // Calculate centroid
      final centroid = TurfService.calculateCentroid(_currentPoints);

      // Calculate area (0 for freehand/lines)
      final area = selectedShape == DrawShape.freehand
          ? 0.0
          : TurfService.calculateArea(_currentPoints);

      // Create parcel
      final parcel = LandParcel(
        id: const Uuid().v4(),
        name: name ?? 'أرض ${DateTime.now().millisecondsSinceEpoch}',
        coordinates: List.from(_currentPoints),
        centroid: centroid,
        area: area,
        cropType: cropType ?? _templateCropType,
        createdAt: DateTime.now(),
        shape: _selectedShape,
        size: _pointSize,
      );

      _completedParcel = parcel;
      _isDrawing = false;
      _currentPoints.clear();
      _error = null;
      _history.clear();
      _historyIndex = -1;

      notifyListeners();
      return parcel;
    } catch (e) {
      _error = 'فشل في إكمال الرسم: $e';
      notifyListeners();
      return null;
    }
  }

  /// Get the total distance of the polygon perimeter
  double getPerimeter() {
    if (_currentPoints.length < 2) return 0;

    double totalDistance = 0;
    for (int i = 0; i < _currentPoints.length - 1; i++) {
      totalDistance += TurfService.calculateDistance(
        _currentPoints[i],
        _currentPoints[i + 1],
      );
    }

    // Add distance from last point to first (only for closed polygons, not freehand)
    if (selectedShape != DrawShape.freehand && _currentPoints.length >= 3) {
      totalDistance += TurfService.calculateDistance(
        _currentPoints.last,
        _currentPoints.first,
      );
    }

    return totalDistance;
  }

  /// Add current state to history
  void _addToHistory() {
    // If we are not at the end of history, remove future states
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    // Add current points to history
    // We need to create a deep copy of the points list
    _history.add(List<LatLngPoint>.from(_currentPoints));
    _historyIndex++;

    // Limit history size if needed (optional, e.g., 50 steps)
    if (_history.length > 50) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  /// Undo last action
  void undo() {
    if (!canUndo) return;

    _historyIndex--;
    _currentPoints.clear();
    _currentPoints.addAll(_history[_historyIndex]);
    notifyListeners();
  }

  /// Redo last undone action
  void redo() {
    if (!canRedo) return;

    _historyIndex++;
    _currentPoints.clear();
    _currentPoints.addAll(_history[_historyIndex]);
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    _isDrawing = false;
    _currentMode = DrawingMode.customPoints;
    _selectedShape = DrawShape.point;
    _pointSize = 1.0;
    _selectedPredefinedShape = null;
    _shapeCenter = null;
    _shapeRadius = null;
    _polygonSides = 5;
    _rotationAngle = 0;
    _currentPoints.clear();
    _completedParcel = null;
    _error = null;
    _templateCropType = null;
    _history.clear();
    _historyIndex = -1;
    notifyListeners();
  }

  /// Clear current drawing without resetting mode
  void _clearCurrentDrawing() {
    _currentPoints.clear();
    _shapeCenter = null;
    _shapeRadius = null;
  }

  /// Update predefined shape preview
  /// [isPreview] - if true, generates fewer points for better performance during drag
  void _updatePredefinedShapePreview({bool isPreview = false}) {
    if (_shapeCenter == null || _selectedPredefinedShape == null) return;

    _currentPoints.clear();

    switch (_selectedPredefinedShape!) {
      case PredefinedShape.circle:
        if (_shapeRadius != null) {
          _currentPoints.addAll(_calculateCirclePoints(
              _shapeCenter!, _shapeRadius!,
              points: isPreview ? 16 : 64 // Reduce points during drag
              ));
        }
        break;
      case PredefinedShape.square:
        if (_shapeRadius != null) {
          _currentPoints
              .addAll(_calculateSquarePoints(_shapeCenter!, _shapeRadius!));
        }
        break;

      case PredefinedShape.trapezoid:
        if (_shapeRadius != null) {
          _currentPoints.addAll(
            _calculateTrapezoidPoints(_shapeCenter!, _shapeRadius!),
          );
        }
        break;

      case PredefinedShape.ellipse:
        if (_shapeRadius != null) {
          // Secondary radius is 70% of primary (1.5:1 ratio approximately)
          final secondaryRadius =
              _ellipseSecondaryRadius ?? (_shapeRadius! * 0.7);
          _currentPoints.addAll(
            _calculateEllipsePoints(
                _shapeCenter!,
                _shapeRadius!, // Horizontal axis
                secondaryRadius, // Vertical axis
                points: isPreview ? 16 : 64 // Reduce points during drag
                ),
          );
        }
        break;
    }

    // Apply rotation if needed
    if (_rotationAngle != 0 && _currentPoints.isNotEmpty) {
      final rotatedPoints =
          _rotatePoints(_currentPoints, _shapeCenter!, _rotationAngle);
      _currentPoints.clear();
      _currentPoints.addAll(rotatedPoints);
    }
  }

  /// Calculate circle points using accurate geographic calculations
  List<LatLngPoint> _calculateCirclePoints(
      LatLngPoint center, double radiusMeters,
      {int points = 64}) {
    final List<LatLngPoint> circlePoints = [];

    for (int i = 0; i < points; i++) {
      final double angle = (i * 2 * pi) / points;

      // Accurate calculation using GeoCalculations
      final dx = radiusMeters * sin(angle);
      final dy = radiusMeters * cos(angle);

      final point = GeoCalculations.offsetPoint(
        center.latitude,
        center.longitude,
        dx,
        dy,
      );

      circlePoints.add(LatLngPoint(
        latitude: point.lat,
        longitude: point.lng,
      ));
    }

    return circlePoints;
  }

  /// Calculate square points using accurate geographic calculations
  List<LatLngPoint> _calculateSquarePoints(
      LatLngPoint center, double sideLength) {
    final double halfSide = sideLength / 2;

    // Calculate 4 corners using accurate offset
    final topLeft = GeoCalculations.offsetPoint(
      center.latitude,
      center.longitude,
      -halfSide,
      halfSide,
    );

    final topRight = GeoCalculations.offsetPoint(
      center.latitude,
      center.longitude,
      halfSide,
      halfSide,
    );

    final bottomRight = GeoCalculations.offsetPoint(
      center.latitude,
      center.longitude,
      halfSide,
      -halfSide,
    );

    final bottomLeft = GeoCalculations.offsetPoint(
      center.latitude,
      center.longitude,
      -halfSide,
      -halfSide,
    );

    return [
      LatLngPoint(latitude: topLeft.lat, longitude: topLeft.lng),
      LatLngPoint(latitude: topRight.lat, longitude: topRight.lng),
      LatLngPoint(latitude: bottomRight.lat, longitude: bottomRight.lng),
      LatLngPoint(latitude: bottomLeft.lat, longitude: bottomLeft.lng),
    ];
  }

  /// Calculate trapezoid points using accurate geographic calculations
  /// Bottom width = 2 × radius
  /// Top width = 1.5 × radius
  /// Height = radius
  List<LatLngPoint> _calculateTrapezoidPoints(
    LatLngPoint center,
    double radius,
  ) {
    final bottomWidth = radius * 2;
    final topWidth = radius * 1.5;
    final height = radius;

    final halfBottomWidth = bottomWidth / 2;
    final halfTopWidth = topWidth / 2;
    final halfHeight = height / 2;

    // Calculate 4 corners using accurate offset
    final bottomLeft = GeoCalculations.offsetPoint(
      center.latitude,
      center.longitude,
      -halfBottomWidth,
      -halfHeight,
    );

    final bottomRight = GeoCalculations.offsetPoint(
      center.latitude,
      center.longitude,
      halfBottomWidth,
      -halfHeight,
    );

    final topRight = GeoCalculations.offsetPoint(
      center.latitude,
      center.longitude,
      halfTopWidth,
      halfHeight,
    );

    final topLeft = GeoCalculations.offsetPoint(
      center.latitude,
      center.longitude,
      -halfTopWidth,
      halfHeight,
    );

    return [
      LatLngPoint(latitude: bottomLeft.lat, longitude: bottomLeft.lng),
      LatLngPoint(latitude: bottomRight.lat, longitude: bottomRight.lng),
      LatLngPoint(latitude: topRight.lat, longitude: topRight.lng),
      LatLngPoint(latitude: topLeft.lat, longitude: topLeft.lng),
    ];
  }

  /// Calculate ellipse points using accurate geographic calculations
  /// Creates an ellipse with specified horizontal and vertical radii
  /// Ratio is typically 1.5:1 (horizontal:vertical)
  List<LatLngPoint> _calculateEllipsePoints(
      LatLngPoint center,
      double radiusX, // Horizontal radius
      double radiusY, // Vertical radius
      {int points = 64}) {
    final List<LatLngPoint> ellipsePoints = [];

    for (int i = 0; i < points; i++) {
      final double angle = (i * 2 * pi) / points;

      // Calculate offset using parametric ellipse equation
      final dx = radiusX * sin(angle);
      final dy = radiusY * cos(angle);

      final point = GeoCalculations.offsetPoint(
        center.latitude,
        center.longitude,
        dx,
        dy,
      );

      ellipsePoints.add(LatLngPoint(
        latitude: point.lat,
        longitude: point.lng,
      ));
    }

    return ellipsePoints;
  }

  /// Rotate points around a pivot
  List<LatLngPoint> _rotatePoints(
      List<LatLngPoint> points, LatLngPoint pivot, double angleDegrees) {
    final double angleRad = angleDegrees * pi / 180.0;
    final double cosTheta = cos(angleRad);
    final double sinTheta = sin(angleRad);

    return points.map((point) {
      // Convert to meters relative to pivot (approximate)
      // 1 degree lat ~= 111,320 meters
      // 1 degree lng ~= 111,320 * cos(lat) meters
      const double latScale = 111320.0;
      final double lngScale = 111320.0 * cos(pivot.latitude * pi / 180.0);

      final double dy = (point.latitude - pivot.latitude) * latScale;
      final double dx = (point.longitude - pivot.longitude) * lngScale;

      // Rotate
      final double dxNew = dx * cosTheta - dy * sinTheta;
      final double dyNew = dx * sinTheta + dy * cosTheta;

      // Convert back to degrees
      return LatLngPoint(
        latitude: pivot.latitude + dyNew / latScale,
        longitude: pivot.longitude + dxNew / lngScale,
      );
    }).toList();
  }
}
