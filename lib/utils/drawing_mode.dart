import 'package:hive/hive.dart';

part 'drawing_mode.g.dart';

/// Drawing mode for land parcels
@HiveType(typeId: 7)
enum DrawingMode {
  /// Draw predefined geometric shapes (circle, rectangle, etc.)
  @HiveField(0)
  predefinedShape,

  /// Draw custom polygon point-by-point
  @HiveField(1)
  customPoints,

  /// Draw freehand continuous line
  @HiveField(2)
  freehand,
}

/// Predefined geometric shapes
@HiveType(typeId: 8)
enum PredefinedShape {
  /// Circle - tap center and drag to set radius
  @HiveField(0)
  circle,

  /// Square - tap center with fixed size
  @HiveField(2)
  square,

  /// Trapezoid - most common shape in real farms
  @HiveField(4)
  trapezoid,

  /// Ellipse - for natural/organic shaped fields
  @HiveField(5)
  ellipse,
}

/// Extension for DrawingMode display names
extension DrawingModeExtension on DrawingMode {
  String get displayName {
    switch (this) {
      case DrawingMode.predefinedShape:
        return 'أشكال جاهزة';
      case DrawingMode.customPoints:
        return 'رسم مخصص';
      case DrawingMode.freehand:
        return 'رسم حر';
    }
  }

  String get description {
    switch (this) {
      case DrawingMode.predefinedShape:
        return 'اختر شكل جاهز (دائرة، مربع، مستطيل)';
      case DrawingMode.customPoints:
        return 'حدد النقاط واحدة تلو الأخرى';
      case DrawingMode.freehand:
        return 'ارسم بشكل حر على الخريطة';
    }
  }
}

/// Extension for PredefinedShape display names
extension PredefinedShapeExtension on PredefinedShape {
  String get displayName {
    switch (this) {
      case PredefinedShape.circle:
        return 'دائرة';
      case PredefinedShape.square:
        return 'مربع';
      case PredefinedShape.trapezoid:
        return 'شبه منحرف';
      case PredefinedShape.ellipse:
        return 'بيضاوي';
    }
  }

  String get icon {
    switch (this) {
      case PredefinedShape.circle:
        return '⭕';
      case PredefinedShape.square:
        return '◻';
      case PredefinedShape.trapezoid:
        return '⏢';
      case PredefinedShape.ellipse:
        return '⬭';
    }
  }

  String get instructions {
    switch (this) {
      case PredefinedShape.circle:
        return 'اضغط على المركز واسحب لتحديد نصف القطر';
      case PredefinedShape.square:
        return 'اضغط على المركز';
      case PredefinedShape.trapezoid:
        return 'اضغط على المركز ثم اسحب لتحديد الحجم';
      case PredefinedShape.ellipse:
        return 'اضغط على المركز ثم اسحب لضبط الحجم';
    }
  }
}

/// Agricultural area units for land measurement
@HiveType(typeId: 9)
enum AreaUnit {
  /// Square meters (m²)
  @HiveField(0)
  squareMeters,

  /// Donum (1000 m²) - Common in Syria, Jordan, Iraq
  @HiveField(1)
  donum,

  /// Hectare (10,000 m²) - International standard
  @HiveField(2)
  hectare,

  /// Feddan (4,200 m²) - Common in Egypt and Sudan
  @HiveField(3)
  feddan,
}

/// Extension for AreaUnit display and conversion
extension AreaUnitExtension on AreaUnit {
  /// Get display name in Arabic
  String get displayName {
    switch (this) {
      case AreaUnit.squareMeters:
        return 'م²';
      case AreaUnit.donum:
        return 'دونم';
      case AreaUnit.hectare:
        return 'هكتار';
      case AreaUnit.feddan:
        return 'فدان';
    }
  }

  /// Get full name in Arabic
  String get fullName {
    switch (this) {
      case AreaUnit.squareMeters:
        return 'متر مربع';
      case AreaUnit.donum:
        return 'دونم';
      case AreaUnit.hectare:
        return 'هكتار';
      case AreaUnit.feddan:
        return 'فدان';
    }
  }

  /// Convert from square meters to this unit
  double convertFromSquareMeters(double sqm) {
    switch (this) {
      case AreaUnit.squareMeters:
        return sqm;
      case AreaUnit.donum:
        return sqm / 1000.0;
      case AreaUnit.hectare:
        return sqm / 10000.0;
      case AreaUnit.feddan:
        return sqm / 4200.0;
    }
  }

  /// Convert from this unit to square meters
  double convertToSquareMeters(double value) {
    switch (this) {
      case AreaUnit.squareMeters:
        return value;
      case AreaUnit.donum:
        return value * 1000.0;
      case AreaUnit.hectare:
        return value * 10000.0;
      case AreaUnit.feddan:
        return value * 4200.0;
    }
  }

  /// Format area value with unit
  String formatArea(double areaSqm, {int decimals = 2}) {
    final converted = convertFromSquareMeters(areaSqm);
    return '${converted.toStringAsFixed(decimals)} $displayName';
  }
}
