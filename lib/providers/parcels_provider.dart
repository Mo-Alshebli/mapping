import 'package:flutter/material.dart';
import '../models/land_parcel.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

/// Provider for managing land parcels
class ParcelsProvider extends ChangeNotifier {
  List<LandParcel> _parcels = [];
  LandParcel? _selectedParcel;
  bool _isLoading = false;
  String? _error;

  final ApiService _apiService;

  ParcelsProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // Getters
  List<LandParcel> get parcels => List.unmodifiable(_parcels);
  LandParcel? get selectedParcel => _selectedParcel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get parcelsCount => _parcels.length;
  bool get hasParcels => _parcels.isNotEmpty;

  /// Initialize and load parcels from storage
  /// Initialize and load parcels from storage
  Future<void> initialize() async {
    // Schedule the entire initialization to run after the current frame
    // This prevents "setState during build" errors regardless of when initialize() is called
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _isLoading = true;
      _error = null;
      notifyListeners();

      try {
        _parcels = await StorageService.loadParcels();
        _isLoading = false;
        notifyListeners();
      } catch (e) {
        _error = 'فشل في تحميل الأراضي: $e';
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  /// Add a new parcel
  Future<void> addParcel(LandParcel parcel) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Add to list
      _parcels.add(parcel);

      // Save to storage
      await StorageService.saveParcel(parcel);

      // Fetch data from server (optional - can fail silently)
      _fetchParcelDataInBackground(parcel);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'فشل في إضافة الأرض: $e';
      _parcels.remove(parcel);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch parcel data from server in background
  Future<void> _fetchParcelDataInBackground(LandParcel parcel) async {
    try {
      final response = await _apiService.analyzeParcel(parcel);

      // Update parcel with server data
      final updatedParcel = parcel.copyWith(
        ndviLayer: response.ndviLayer,
        statistics: response.statistics,
        lastUpdated: DateTime.now(),
      );

      await updateParcel(updatedParcel);
    } catch (e) {
      // Fail silently - parcel is already saved locally
      debugPrint('Failed to fetch parcel data from server: $e');
    }
  }

  /// Update an existing parcel
  Future<void> updateParcel(LandParcel parcel) async {
    try {
      final index = _parcels.indexWhere((p) => p.id == parcel.id);
      if (index != -1) {
        _parcels[index] = parcel;
        await StorageService.updateParcel(parcel);

        // Update selected parcel if it's the same one
        if (_selectedParcel?.id == parcel.id) {
          _selectedParcel = parcel;
        }

        notifyListeners();
      }
    } catch (e) {
      _error = 'فشل في تحديث الأرض: $e';
      notifyListeners();
    }
  }

  /// Delete a parcel
  Future<void> deleteParcel(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _parcels.removeWhere((p) => p.id == id);
      await StorageService.deleteParcel(id);

      if (_selectedParcel?.id == id) {
        _selectedParcel = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'فشل في حذف الأرض: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a parcel
  void selectParcel(String id) {
    _selectedParcel = _parcels.firstWhere(
      (p) => p.id == id,
      orElse: () => _parcels.first,
    );
    notifyListeners();
  }

  /// Deselect current parcel
  void deselectParcel() {
    _selectedParcel = null;
    notifyListeners();
  }

  /// Search parcels by name
  List<LandParcel> searchByName(String query) {
    if (query.isEmpty) return _parcels;

    return _parcels
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Filter parcels by crop type
  List<LandParcel> filterByCropType(String? cropType) {
    if (cropType == null || cropType.isEmpty) return _parcels;

    return _parcels.where((p) => p.cropType == cropType).toList();
  }

  /// Get all unique crop types
  List<String> getAllCropTypes() {
    final cropTypes = _parcels
        .where((p) => p.cropType != null)
        .map((p) => p.cropType!)
        .toSet()
        .toList();
    cropTypes.sort();
    return cropTypes;
  }

  /// Get total area of all parcels
  double getTotalArea() {
    return _parcels.fold(0.0, (sum, parcel) => sum + parcel.area);
  }

  /// Get parcels sorted by area
  List<LandParcel> getSortedByArea({bool descending = true}) {
    final sorted = List<LandParcel>.from(_parcels);
    sorted.sort((a, b) =>
        descending ? b.area.compareTo(a.area) : a.area.compareTo(b.area));
    return sorted;
  }

  /// Get parcels sorted by health
  List<LandParcel> getSortedByHealth({bool descending = true}) {
    final withHealth = _parcels.where((p) => p.statistics != null).toList();
    withHealth.sort((a, b) => descending
        ? b.statistics!.healthPercentage
            .compareTo(a.statistics!.healthPercentage)
        : a.statistics!.healthPercentage
            .compareTo(b.statistics!.healthPercentage));
    return withHealth;
  }

  /// Refresh parcel data from server
  Future<void> refreshParcelData(String id) async {
    final parcel = _parcels.firstWhere((p) => p.id == id);
    await _fetchParcelDataInBackground(parcel);
  }

  /// Clear all error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
