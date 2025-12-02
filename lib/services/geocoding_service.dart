import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/mapbox_config.dart';
import '../models/land_parcel.dart';

/// Location search result
class LocationSearchResult {
  final String name;
  final String address;
  final LatLngPoint coordinates;

  LocationSearchResult({
    required this.name,
    required this.address,
    required this.coordinates,
  });

  factory LocationSearchResult.fromJson(Map<String, dynamic> json) {
    final center = json['center'] as List;
    return LocationSearchResult(
      name: json['text'] ?? '',
      address: json['place_name'] ?? '',
      coordinates: LatLngPoint(
        latitude: center[1],
        longitude: center[0],
      ),
    );
  }
}

/// Service for geocoding (location search) using Mapbox API
class GeocodingService {
  /// Search for locations by query string
  static Future<List<LocationSearchResult>> searchLocation(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        '${MapboxConfig.geocodingApiUrl}/$encodedQuery.json?access_token=${MapboxConfig.accessToken}&limit=5&language=ar',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;

        return features
            .map((feature) => LocationSearchResult.fromJson(feature))
            .toList();
      } else {
        throw Exception('Failed to search location: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching location: $e');
    }
  }
}
