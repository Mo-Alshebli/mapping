import 'package:flutter/foundation.dart';
import '../models/land_parcel.dart';

/// Provider for managing map state
class MapStateProvider extends ChangeNotifier {
  LatLngPoint _center = const LatLngPoint(
    latitude: 24.7136, // Riyadh
    longitude: 46.6753,
  );

  double _zoom = 13.0;
  bool _isSatelliteView = true;
  bool _showNDVILayers = true;
  bool _showCharts = true;
  bool _showLabels = true;
  String? _selectedParcelId;

  // Getters
  LatLngPoint get center => _center;
  double get zoom => _zoom;
  bool get isSatelliteView => _isSatelliteView;
  bool get showNDVILayers => _showNDVILayers;
  bool get showCharts => _showCharts;
  bool get showLabels => _showLabels;
  String? get selectedParcelId => _selectedParcelId;

  /// Move map to a specific location
  void moveToLocation(LatLngPoint location, {double? zoom}) {
    _center = location;
    if (zoom != null) {
      _zoom = zoom;
    }
    notifyListeners();
  }

  /// Update zoom level
  void setZoom(double zoom) {
    _zoom = zoom.clamp(3.0, 20.0);
    notifyListeners();
  }

  /// Zoom in
  void zoomIn() {
    setZoom(_zoom + 1);
  }

  /// Zoom out
  void zoomOut() {
    setZoom(_zoom - 1);
  }

  /// Toggle between satellite and street view
  void toggleMapStyle() {
    _isSatelliteView = !_isSatelliteView;
    notifyListeners();
  }

  /// Set map style
  void setMapStyle(bool isSatellite) {
    _isSatelliteView = isSatellite;
    notifyListeners();
  }

  /// Toggle NDVI layers visibility
  void toggleNDVILayers() {
    _showNDVILayers = !_showNDVILayers;
    notifyListeners();
  }

  /// Toggle charts visibility
  void toggleCharts() {
    _showCharts = !_showCharts;
    notifyListeners();
  }

  /// Toggle labels visibility
  void toggleLabels() {
    _showLabels = !_showLabels;
    notifyListeners();
  }

  /// Set NDVI layers visibility
  void setNDVILayersVisibility(bool visible) {
    _showNDVILayers = visible;
    notifyListeners();
  }

  /// Set charts visibility
  void setChartsVisibility(bool visible) {
    _showCharts = visible;
    notifyListeners();
  }

  /// Set labels visibility
  void setLabelsVisibility(bool visible) {
    _showLabels = visible;
    notifyListeners();
  }

  /// Focus on a specific parcel
  void focusOnParcel(LandParcel parcel) {
    _center = parcel.centroid;
    _zoom = 16.0;
    _selectedParcelId = parcel.id;
    notifyListeners();
  }

  /// Select parcel on map
  void selectParcel(String parcelId) {
    _selectedParcelId = parcelId;
    notifyListeners();
  }

  /// Deselect parcel
  void deselectParcel() {
    _selectedParcelId = null;
    notifyListeners();
  }

  /// Reset map to default state
  void reset() {
    _center = const LatLngPoint(latitude: 24.7136, longitude: 46.6753);
    _zoom = 13.0;
    _isSatelliteView = true;
    _showNDVILayers = true;
    _showCharts = true;
    _showLabels = true;
    _selectedParcelId = null;
    notifyListeners();
  }
}
