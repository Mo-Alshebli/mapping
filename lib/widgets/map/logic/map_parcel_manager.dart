import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../models/land_parcel.dart';
import '../../../../services/turf_service.dart';
import '../../../../utils/colors.dart';
import 'map_annotation_manager.dart';

/// Manages parcel-related operations on the map
class MapParcelManager {
  final MapAnnotationManager _annotationManager;

  MapParcelManager(this._annotationManager);

  /// Add a single parcel to the map
  Future<void> addParcelToMap(LandParcel parcel) async {
    final polygonManager = _annotationManager.polygonManager;
    if (polygonManager == null) return;

    // Convert coordinates
    final positions = parcel.coordinates.map((coord) {
      return Position(coord.longitude, coord.latitude);
    }).toList();

    // Close the polygon
    if (positions.isNotEmpty && positions.first != positions.last) {
      positions.add(positions.first);
    }

    // Create polygon
    final options = PolygonAnnotationOptions(
      geometry: Polygon(coordinates: [positions]),
      fillColor: AppColors.polygonFill.value,
      fillOutlineColor: AppColors.polygonStroke.value,
    );

    await polygonManager.create(options);
  }

  /// Load a list of parcels onto the map
  Future<void> loadExistingParcels(List<LandParcel> parcels) async {
    for (final parcel in parcels) {
      await addParcelToMap(parcel);
    }
  }

  /// Find a parcel at a specific coordinate
  LandParcel? findParcelAtLatLng(LatLngPoint point, List<LandParcel> parcels) {
    for (final parcel in parcels) {
      if (parcel.coordinates.length >= 3 &&
          TurfService.isPointInPolygon(point, parcel.coordinates)) {
        return parcel;
      }
    }
    return null;
  }

  /// Build label widgets for parcels
  Future<List<Widget>> buildParcelLabels(
      List<LandParcel> parcels, MapboxMap? mapboxMap) async {
    if (mapboxMap == null) return [];

    final List<Widget> labels = [];

    for (final parcel in parcels) {
      try {
        final screen = await mapboxMap.pixelForCoordinate(
          Point(
            coordinates: Position(
              parcel.centroid.longitude,
              parcel.centroid.latitude,
            ),
          ),
        );

        labels.add(
          Positioned(
            left: screen.x - 50,
            top: screen.y + 10,
            child: IgnorePointer(
              child: Container(
                width: 100,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  parcel.name,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      } catch (_) {
        continue;
      }
    }

    return labels;
  }
}
