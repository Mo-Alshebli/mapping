import 'dart:math' as math;
import '../utils/drawing_mode.dart';

/// Template for predefined agricultural shapes
class ShapeTemplate {
  /// Display name of the template
  final String name;

  /// The geometric shape type
  final PredefinedShape shapeType;

  /// Type of crop (optional)
  final String? cropType;

  /// Estimated radius/size parameter in meters
  final double estimatedRadius;

  const ShapeTemplate({
    required this.name,
    required this.shapeType,
    this.cropType,
    required this.estimatedRadius,
  });

  /// Format the estimated area of this template
  String formatArea(AreaUnit unit) {
    double areaSqm = 0;

    switch (shapeType) {
      case PredefinedShape.circle:
        areaSqm = math.pi * estimatedRadius * estimatedRadius;
        break;
      case PredefinedShape.square:
        // In drawing_provider, square uses radius as side length
        areaSqm = estimatedRadius * estimatedRadius;
        break;
      case PredefinedShape.trapezoid:
        // Bottom=2r, Top=1.5r, Height=r
        // Area = ((2r + 1.5r)/2) * r = 1.75 * r^2
        areaSqm = 1.75 * estimatedRadius * estimatedRadius;
        break;
      case PredefinedShape.ellipse:
        // Major=r, Minor=0.7r
        // Area = pi * a * b
        areaSqm = math.pi * estimatedRadius * (estimatedRadius * 0.7);
        break;
    }

    return unit.formatArea(areaSqm);
  }

  /// Default templates list
  static List<ShapeTemplate> get defaultTemplates => [
        const ShapeTemplate(
          name: 'حقل قمح دائري',
          shapeType: PredefinedShape.circle,
          cropType: 'قمح',
          estimatedRadius: 100,
        ),
        const ShapeTemplate(
          name: 'حقل ذرة مربع',
          shapeType: PredefinedShape.square,
          cropType: 'ذرة',
          estimatedRadius: 100,
        ),
        const ShapeTemplate(
          name: 'حقل خضروات',
          shapeType: PredefinedShape.trapezoid,
          cropType: 'خضروات',
          estimatedRadius: 50,
        ),
        const ShapeTemplate(
          name: 'أرض بيضاوية',
          shapeType: PredefinedShape.ellipse,
          cropType: 'أعلاف',
          estimatedRadius: 120,
        ),
      ];
}
