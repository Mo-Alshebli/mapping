import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'ndvi_layer.g.dart';

@HiveType(typeId: 4)
class NDVILayer extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String overlayUrl; // URL to the NDVI image overlay

  @HiveField(2)
  final NDVIBounds bounds; // Geographic bounds of the overlay

  @HiveField(3)
  final double opacity; // Opacity (0.0 - 1.0)

  @HiveField(4)
  final bool isVisible; // Visibility toggle

  @HiveField(5)
  final DateTime captureDate; // Date when satellite image was captured

  @HiveField(6)
  final String? source; // Source of the data (e.g., 'Sentinel-2', 'Landsat')

  const NDVILayer({
    required this.id,
    required this.overlayUrl,
    required this.bounds,
    this.opacity = 0.7,
    this.isVisible = true,
    required this.captureDate,
    this.source,
  });

  // Create from JSON (API response)
  factory NDVILayer.fromJson(Map<String, dynamic> json) {
    return NDVILayer(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      overlayUrl: json['overlay_url'] ?? json['url'],
      bounds: NDVIBounds.fromJson(json['bounds']),
      opacity:
          json['opacity'] != null ? (json['opacity'] as num).toDouble() : 0.7,
      isVisible: json['is_visible'] ?? true,
      captureDate: json['capture_date'] != null
          ? DateTime.parse(json['capture_date'])
          : DateTime.now(),
      source: json['source'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'overlay_url': overlayUrl,
      'bounds': bounds.toJson(),
      'opacity': opacity,
      'is_visible': isVisible,
      'capture_date': captureDate.toIso8601String(),
      'source': source,
    };
  }

  // Copy with updated fields
  NDVILayer copyWith({
    String? id,
    String? overlayUrl,
    NDVIBounds? bounds,
    double? opacity,
    bool? isVisible,
    DateTime? captureDate,
    String? source,
  }) {
    return NDVILayer(
      id: id ?? this.id,
      overlayUrl: overlayUrl ?? this.overlayUrl,
      bounds: bounds ?? this.bounds,
      opacity: opacity ?? this.opacity,
      isVisible: isVisible ?? this.isVisible,
      captureDate: captureDate ?? this.captureDate,
      source: source ?? this.source,
    );
  }

  @override
  List<Object?> get props => [
        id,
        overlayUrl,
        bounds,
        opacity,
        isVisible,
        captureDate,
        source,
      ];
}

@HiveType(typeId: 5)
class NDVIBounds extends Equatable {
  @HiveField(0)
  final double north;

  @HiveField(1)
  final double south;

  @HiveField(2)
  final double east;

  @HiveField(3)
  final double west;

  const NDVIBounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  factory NDVIBounds.fromJson(Map<String, dynamic> json) {
    return NDVIBounds(
      north: (json['north'] as num).toDouble(),
      south: (json['south'] as num).toDouble(),
      east: (json['east'] as num).toDouble(),
      west: (json['west'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'north': north,
      'south': south,
      'east': east,
      'west': west,
    };
  }

  @override
  List<Object?> get props => [north, south, east, west];
}
