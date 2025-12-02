class MapboxConfig {
  // Mapbox Public Access Token (for map display) - pk. token
  // Get it from: https://account.mapbox.com/access-tokens/
  static const String accessToken =
      'pk.eyJ1IjoibW9hbHNoZWJseSIsImEiOiJjbWliZzZlcW4xMGw0MmxzZTJidnBuZjliIn0.2e53_wHIZ-66o2VQ6fmPLw';

  // Mapbox Style URLs
  static const String satelliteStreets =
      'mapbox://styles/mapbox/satellite-streets-v12';
  static const String satellite = 'mapbox://styles/mapbox/satellite-v9';
  static const String streets = 'mapbox://styles/mapbox/streets-v12';
  static const String outdoors = 'mapbox://styles/mapbox/outdoors-v12';

  // Default Camera Position (Riyadh, Saudi Arabia)
  static const double defaultLatitude = 24.7136;
  static const double defaultLongitude = 46.6753;
  static const double defaultZoom = 13.0;

  // Map Bounds
  static const double minZoom = 3.0;
  static const double maxZoom = 20.0;

  // Geocoding API
  static const String geocodingApiUrl =
      'https://api.mapbox.com/geocoding/v5/mapbox.places';
}
