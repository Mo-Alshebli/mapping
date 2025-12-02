import 'package:hive_flutter/hive_flutter.dart';
import 'package:mapping/utils/draw_shape.dart';
import 'package:mapping/utils/drawing_mode.dart';
import '../models/land_parcel.dart';
import '../models/crop_statistics.dart';
import '../models/ndvi_layer.dart';

/// Service for local storage using Hive
class StorageService {
  static const String _parcelsBox = 'parcels';
  static const String _versionBox = 'version';
  static const int _currentVersion = 2; // Increment this when schema changes
  static bool _isInitialized = false;

  /// Initialize Hive and register adapters
  static Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Check if migration is needed
    await _checkAndMigrate();

    // Register adapters (must be registered before opening boxes)
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LandParcelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(LatLngPointAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CropStatisticsAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(HistoricalDataAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(NDVILayerAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(NDVIBoundsAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(DrawShapeAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(DrawingModeAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(PredefinedShapeAdapter());
    }

    // Open boxes
    await Hive.openBox<LandParcel>(_parcelsBox);

    _isInitialized = true;
  }

  /// Check version and migrate if needed
  static Future<void> _checkAndMigrate() async {
    try {
      final versionBox = await Hive.openBox<int>(_versionBox);
      final storedVersion = versionBox.get('version', defaultValue: 0);

      if (storedVersion != _currentVersion) {
        // Version mismatch - clear old data
        await Hive.deleteBoxFromDisk(_parcelsBox);
        await versionBox.put('version', _currentVersion);
      }
    } catch (e) {
      // If any error occurs, clear everything and start fresh
      await Hive.deleteBoxFromDisk(_parcelsBox);
      await Hive.deleteBoxFromDisk(_versionBox);
      final versionBox = await Hive.openBox<int>(_versionBox);
      await versionBox.put('version', _currentVersion);
    }
  }

  /// Save a single parcel
  static Future<void> saveParcel(LandParcel parcel) async {
    final box = Hive.box<LandParcel>(_parcelsBox);
    await box.put(parcel.id, parcel);
  }

  /// Save multiple parcels
  static Future<void> saveParcels(List<LandParcel> parcels) async {
    final box = Hive.box<LandParcel>(_parcelsBox);
    final Map<String, LandParcel> parcelsMap = {};
    for (var parcel in parcels) {
      parcelsMap[parcel.id] = parcel;
    }
    await box.putAll(parcelsMap);
  }

  /// Load all parcels
  static Future<List<LandParcel>> loadParcels() async {
    final box = Hive.box<LandParcel>(_parcelsBox);
    return box.values.toList();
  }

  /// Load a single parcel by ID
  static Future<LandParcel?> loadParcel(String id) async {
    final box = Hive.box<LandParcel>(_parcelsBox);
    return box.get(id);
  }

  /// Delete a parcel
  static Future<void> deleteParcel(String id) async {
    final box = Hive.box<LandParcel>(_parcelsBox);
    await box.delete(id);
  }

  /// Delete all parcels
  static Future<void> deleteAllParcels() async {
    final box = Hive.box<LandParcel>(_parcelsBox);
    await box.clear();
  }

  /// Check if a parcel exists
  static Future<bool> parcelExists(String id) async {
    final box = Hive.box<LandParcel>(_parcelsBox);
    return box.containsKey(id);
  }

  /// Get the number of parcels
  static Future<int> getParcelsCount() async {
    final box = Hive.box<LandParcel>(_parcelsBox);
    return box.length;
  }

  /// Update a parcel
  static Future<void> updateParcel(LandParcel parcel) async {
    final box = Hive.box<LandParcel>(_parcelsBox);
    if (box.containsKey(parcel.id)) {
      await box.put(parcel.id, parcel);
    } else {
      throw Exception('Parcel not found: ${parcel.id}');
    }
  }

  /// Search parcels by name
  static Future<List<LandParcel>> searchParcelsByName(String query) async {
    final box = Hive.box<LandParcel>(_parcelsBox);
    return box.values
        .where(
            (parcel) => parcel.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Filter parcels by crop type
  static Future<List<LandParcel>> filterParcelsByCropType(
      String cropType) async {
    final box = Hive.box<LandParcel>(_parcelsBox);
    return box.values.where((parcel) => parcel.cropType == cropType).toList();
  }

  /// Close all boxes and cleanup
  static Future<void> dispose() async {
    await Hive.close();
    _isInitialized = false;
  }
}
