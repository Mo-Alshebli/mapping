import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/land_parcel.dart';

/// Provider for managing location services
class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;
  bool _isLocationServiceEnabled = false;
  bool _hasPermission = false;

  // Getters
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;
  bool get hasPermission => _hasPermission;
  bool get hasLocation => _currentPosition != null;

  LatLngPoint? get currentLatLng {
    if (_currentPosition == null) return null;
    return LatLngPoint(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
    );
  }

  /// Initialize location service
  Future<void> initialize() async {
    await checkServiceStatus();
    if (_isLocationServiceEnabled) {
      await checkPermission();
    }
  }

  /// Check if location service is enabled
  Future<void> checkServiceStatus() async {
    try {
      _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      notifyListeners();
    } catch (e) {
      _error = 'فشل في التحقق من خدمة الموقع: $e';
      notifyListeners();
    }
  }

  /// Check location permission
  Future<void> checkPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      _hasPermission = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      notifyListeners();
    } catch (e) {
      _error = 'فشل في التحقق من صلاحيات الموقع: $e';
      notifyListeners();
    }
  }

  /// Request location permission
  Future<bool> requestPermission() async {
    try {
      // Check if service is enabled
      if (!_isLocationServiceEnabled) {
        _error = 'خدمة الموقع غير مفعلة. يرجى تفعيلها من الإعدادات.';
        notifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _error =
            'تم رفض صلاحيات الموقع نهائياً. يرجى تفعيلها من إعدادات التطبيق.';
        _hasPermission = false;
        notifyListeners();
        return false;
      }

      _hasPermission = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      _error = null;
      notifyListeners();
      return _hasPermission;
    } catch (e) {
      _error = 'فشل في طلب صلاحيات الموقع: $e';
      _hasPermission = false;
      notifyListeners();
      return false;
    }
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check service and permission
      await checkServiceStatus();
      if (!_isLocationServiceEnabled) {
        throw Exception('خدمة الموقع غير مفعلة');
      }

      if (!_hasPermission) {
        final granted = await requestPermission();
        if (!granted) {
          throw Exception('لم يتم منح صلاحيات الموقع');
        }
      }

      // Get position
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _isLoading = false;
      _error = null;
      notifyListeners();
      return _currentPosition;
    } catch (e) {
      _error = 'فشل في الحصول على الموقع الحالي: $e';
      _isLoading = false;
      _currentPosition = null;
      notifyListeners();
      return null;
    }
  }

  /// Calculate distance from current location to a point
  double? getDistanceToPoint(LatLngPoint point) {
    if (_currentPosition == null) return null;

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      point.latitude,
      point.longitude,
    );
  }

  /// Calculate distance from current location to a parcel
  double? getDistanceToParcel(LandParcel parcel) {
    return getDistanceToPoint(parcel.centroid);
  }

  /// Check if current location is inside a parcel
  bool isInsideParcel(LandParcel parcel) {
    if (_currentPosition == null) return false;

    // Use a simple point-in-polygon algorithm or Turf
    // For now, check if distance to centroid is less than some threshold
    final distance = getDistanceToParcel(parcel);
    if (distance == null) return false;

    // Rough estimation - should use proper point-in-polygon
    final avgRadius = (parcel.area / 3.14159).clamp(0, double.infinity);
    return distance <= avgRadius;
  }

  /// Open app settings
  Future<bool> openSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      _error = 'فشل في فتح الإعدادات: $e';
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset provider
  void reset() {
    _currentPosition = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
