import 'package:turf/helpers.dart';
import 'package:turf/turf.dart' as turf;
import 'package:geolocator/geolocator.dart' as geo;
import '../models/land_parcel.dart';

/// Service for geometric operations using Turf library
class TurfService {
  /// Calculate the centroid (center point) of a polygon
  static LatLngPoint calculateCentroid(List<LatLngPoint> coordinates) {
    if (coordinates.isEmpty) {
      throw ArgumentError('Coordinates list cannot be empty');
    }

    // Convert to Turf Position format
    final positions =
        coordinates.map((c) => Position(c.longitude, c.latitude)).toList();

    // Close the polygon if not closed
    if (positions.first != positions.last) {
      positions.add(positions.first);
    }

    // Create polygon
    final polygon = Polygon(coordinates: [positions]);

    // Calculate centroid
    final centerPoint = turf.center(
      FeatureCollection(features: [Feature(geometry: polygon)]),
    );

    final coords = centerPoint.geometry as Point;

    return LatLngPoint(
      latitude: coords.coordinates.lat.toDouble(),
      longitude: coords.coordinates.lng.toDouble(),
    );
  }

  /// Calculate the area of a polygon in square meters
  static double calculateArea(List<LatLngPoint> coordinates) {
    if (coordinates.length < 3) {
      throw ArgumentError('Polygon must have at least 3 points');
    }

    // Convert to Turf Position format
    final positions =
        coordinates.map((c) => Position(c.longitude, c.latitude)).toList();

    // Close the polygon if not closed
    if (positions.first != positions.last) {
      positions.add(positions.first);
    }

    // Create polygon
    final polygon = Polygon(coordinates: [positions]);

    // Calculate area in square meters
    final areaValue = turf.area(Feature(geometry: polygon));
    return areaValue?.toDouble() ?? 0.0;
  }

  /// Convert list of coordinates to GeoJSON Polygon
  static Map<String, dynamic> toGeoJSONPolygon(List<LatLngPoint> coordinates) {
    final positions =
        coordinates.map((c) => [c.longitude, c.latitude]).toList();

    // Close the polygon
    if (coordinates.first != coordinates.last) {
      positions.add([coordinates.first.longitude, coordinates.first.latitude]);
    }

    return {
      'type': 'Polygon',
      'coordinates': [positions],
    };
  }

  /// Check if a point is inside a polygon
  static bool isPointInPolygon(LatLngPoint point, List<LatLngPoint> polygon) {
    final pt = Point(coordinates: Position(point.longitude, point.latitude));

    final positions =
        polygon.map((c) => Position(c.longitude, c.latitude)).toList();

    if (positions.first != positions.last) {
      positions.add(positions.first);
    }

    final poly = Polygon(coordinates: [positions]);

    // booleanPointInPolygon expects Position and GeoJSONObject (Polygon)
    return turf.booleanPointInPolygon(
      pt.coordinates, // Pass Position directly
      poly, // Pass Polygon directly
    );
  }

  /// Calculate the distance between two points in meters
  static double calculateDistance(LatLngPoint from, LatLngPoint to) {
    return geo.Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }
}
