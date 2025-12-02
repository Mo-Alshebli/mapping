import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'crop_statistics.g.dart';

@HiveType(typeId: 2)
class CropStatistics extends Equatable {
  @HiveField(0)
  final double healthPercentage; // Overall health percentage (0-100)

  @HiveField(1)
  final double moistureLevel; // Moisture level (0-100)

  @HiveField(2)
  final DateTime? lastIrrigationDate; // Last irrigation date

  @HiveField(3)
  final double ndviValue; // NDVI value (-1 to 1)

  @HiveField(4)
  final Map<String, double> distribution; // Health distribution
  // Example: {'healthy': 75.0, 'moderate': 20.0, 'poor': 5.0}

  @HiveField(5)
  final List<HistoricalData>? history; // Historical data

  /// Get historical data (alias for history)
  List<HistoricalData> get historicalData => history ?? [];

  const CropStatistics({
    required this.healthPercentage,
    required this.moistureLevel,
    this.lastIrrigationDate,
    required this.ndviValue,
    required this.distribution,
    this.history,
  });

  // Create from JSON (API response)
  factory CropStatistics.fromJson(Map<String, dynamic> json) {
    return CropStatistics(
      healthPercentage: (json['health_percentage'] as num).toDouble(),
      moistureLevel: (json['moisture_level'] as num).toDouble(),
      lastIrrigationDate: json['last_irrigation_date'] != null
          ? DateTime.parse(json['last_irrigation_date'])
          : null,
      ndviValue: (json['ndvi_value'] as num).toDouble(),
      distribution: Map<String, double>.from(
        json['distribution'].map((k, v) => MapEntry(k, (v as num).toDouble())),
      ),
      history: json['history'] != null
          ? (json['history'] as List)
              .map((h) => HistoricalData.fromJson(h))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'health_percentage': healthPercentage,
      'moisture_level': moistureLevel,
      'last_irrigation_date': lastIrrigationDate?.toIso8601String(),
      'ndvi_value': ndviValue,
      'distribution': distribution,
      'history': history?.map((h) => h.toJson()).toList(),
    };
  }

  // Get health status text
  String get healthStatus {
    if (healthPercentage >= 75) return 'ممتاز';
    if (healthPercentage >= 50) return 'جيد';
    if (healthPercentage >= 25) return 'متوسط';
    return 'ضعيف';
  }

  // Get days since last irrigation
  int? get daysSinceIrrigation {
    if (lastIrrigationDate == null) return null;
    return DateTime.now().difference(lastIrrigationDate!).inDays;
  }

  @override
  List<Object?> get props => [
        healthPercentage,
        moistureLevel,
        lastIrrigationDate,
        ndviValue,
        distribution,
        history,
      ];
}

@HiveType(typeId: 3)
class HistoricalData extends Equatable {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final double value;

  @HiveField(2)
  final String type; // 'health', 'moisture', 'ndvi'

  const HistoricalData({
    required this.date,
    required this.value,
    required this.type,
  });

  factory HistoricalData.fromJson(Map<String, dynamic> json) {
    return HistoricalData(
      date: DateTime.parse(json['date']),
      value: (json['value'] as num).toDouble(),
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'value': value,
      'type': type,
    };
  }

  /// Get NDVI value (alias for value when type is 'ndvi')
  double get ndviValue => value;

  @override
  List<Object?> get props => [date, value, type];
}
