import 'package:hive/hive.dart';

part 'draw_shape.g.dart';

/// Enum for different drawing shapes on the map
@HiveType(typeId: 6)
enum DrawShape {
  /// Standard point marker
  @HiveField(0)
  point,

  /// Circle marker
  @HiveField(1)
  circle,

  /// Square marker
  @HiveField(2)
  square,

  /// Star marker
  @HiveField(3)
  star,

  /// Freehand drawing (polyline/polygon)
  @HiveField(4)
  freehand,
}

/// Extension on DrawShape for display names
extension DrawShapeExtension on DrawShape {
  /// Get Arabic display name for the shape
  String get displayName {
    switch (this) {
      case DrawShape.point:
        return 'نقطة';
      case DrawShape.circle:
        return 'دائرة';
      case DrawShape.square:
        return 'مربع';
      case DrawShape.star:
        return 'نجمة';
      case DrawShape.freehand:
        return 'رسم حر';
    }
  }

  /// Get icon name for Mapbox
  String get iconName {
    switch (this) {
      case DrawShape.point:
        return 'marker-15';
      case DrawShape.circle:
        return 'circle-15';
      case DrawShape.square:
        return 'square-15';
      case DrawShape.star:
        return 'star-15';
      case DrawShape.freehand:
        return 'marker-15'; // Freehand uses lines, not icons
    }
  }
}
