import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'crop_statistics.dart';
import 'ndvi_layer.dart';
import '../utils/draw_shape.dart';

part 'land_parcel.g.dart';

@HiveType(typeId: 0)
class LandParcel extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<LatLngPoint> coordinates; // Polygon points

  @HiveField(3)
  final LatLngPoint centroid; // Center point for chart display

  @HiveField(4)
  final double area; // Area in square meters

  @HiveField(5)
  final String? cropType; // Type of crop

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime? lastUpdated;

  @HiveField(8)
  final CropStatistics? statistics; // Crop health statistics

  @HiveField(9)
  final NDVILayer? ndviLayer; // NDVI overlay layer

  @HiveField(10)
  final DrawShape? shape; // Shape type for rendering

  @HiveField(11)
  final double? size; // Marker size multiplier

  const LandParcel({
    required this.id,
    required this.name,
    required this.coordinates,
    required this.centroid,
    required this.area,
    this.cropType,
    required this.createdAt,
    this.lastUpdated,
    this.statistics,
    this.ndviLayer,
    this.shape,
    this.size,
  });

  // Convert to GeoJSON format for API
  Map<String, dynamic> toGeoJSON() {
    return {
      'type': 'Feature',
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          coordinates.map((c) => [c.longitude, c.latitude]).toList(),
        ],
      },
      'properties': {
        'id': id,
        'name': name,
        'cropType': cropType,
        'area': area,
        'createdAt': createdAt.toIso8601String(),
        'shape': (shape ?? DrawShape.point).name,
        'size': size ?? 1.0,
      },
    };
  }

  // Get area in hectares
  double get areaInHectares => area / 10000;

  // Get area in acres
  double get areaInAcres => area / 4046.86;

  // Copy with updated fields
  LandParcel copyWith({
    String? id,
    String? name,
    List<LatLngPoint>? coordinates,
    LatLngPoint? centroid,
    double? area,
    String? cropType,
    DateTime? createdAt,
    DateTime? lastUpdated,
    CropStatistics? statistics,
    NDVILayer? ndviLayer,
    DrawShape? shape,
    double? size,
  }) {
    return LandParcel(
      id: id ?? this.id,
      name: name ?? this.name,
      coordinates: coordinates ?? this.coordinates,
      centroid: centroid ?? this.centroid,
      area: area ?? this.area,
      cropType: cropType ?? this.cropType,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      statistics: statistics ?? this.statistics,
      ndviLayer: ndviLayer ?? this.ndviLayer,
      shape: shape ?? this.shape,
      size: size ?? this.size,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        coordinates,
        centroid,
        area,
        cropType,
        createdAt,
        lastUpdated,
        statistics,
        ndviLayer,
        shape,
        size,
      ];
}

// Simple LatLng wrapper for Hive
@HiveType(typeId: 1)
class LatLngPoint extends Equatable {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  const LatLngPoint({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}
