import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2E7D32); // Green for agriculture
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF4CAF50);

  // Secondary Colors
  static const Color secondary = Color(0xFF0288D1); // Blue
  static const Color secondaryDark = Color(0xFF01579B);
  static const Color secondaryLight = Color(0xFF03A9F4);

  // Health Colors
  static const Color healthGood = Color(0xFF4CAF50); // Green
  static const Color healthModerate = Color(0xFFFF9800); // Orange
  static const Color healthPoor = Color(0xFFF44336); // Red

  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFFFFFFF);

  // Drawing Colors
  static const Color drawingLine = Color(0xFF2196F3);
  static const Color drawingPoint = Color(0xFFFF5722);
  static const Color polygonFill = Color(0x404CAF50);
  static const Color polygonStroke = Color(0xFF4CAF50);

  // NDVI Colors (for visualization)
  static const Color ndviHigh = Color(0xFF00FF00);
  static const Color ndviMedium = Color(0xFFFFFF00);
  static const Color ndviLow = Color(0xFFFF0000);

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFFF44336),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
  ];
}
