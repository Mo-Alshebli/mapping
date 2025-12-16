import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/land_parcel.dart';
import '../providers/drawing_provider.dart';
import '../providers/parcels_provider.dart';
import '../providers/map_state_provider.dart';
import '../providers/location_provider.dart';
import '../utils/constants.dart';
import '../utils/colors.dart';
import '../utils/draw_shape.dart';
import '../widgets/map/mapbox_view.dart';
import '../widgets/drawing/mode_selector.dart';
import '../widgets/drawing/drawing_toolbar.dart';
import '../widgets/drawing/area_display.dart';
import '../widgets/map/location_search_bar.dart';
import 'parcels_list_screen.dart';

/// Main map screen
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final GlobalKey<MapboxViewState> _mapboxKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize providers
    final parcelsProvider = context.read<ParcelsProvider>();
    final locationProvider = context.read<LocationProvider>();

    await Future.wait([
      parcelsProvider.initialize(),
      // تهيئة خدمة الموقع ثم محاولة الحصول على موقع المستخدم مباشرة
      locationProvider
          .initialize()
          .then((_) => locationProvider.getCurrentLocation()),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          // Map style toggle
          Consumer<MapStateProvider>(
            builder: (context, mapState, _) {
              return IconButton(
                icon: Icon(
                  mapState.isSatelliteView ? Icons.map : Icons.satellite,
                ),
                tooltip: mapState.isSatelliteView
                    ? 'عرض الخريطة'
                    : 'عرض الأقمار الصناعية',
                onPressed: () => mapState.toggleMapStyle(),
              );
            },
          ),

          // Current location
          Consumer<LocationProvider>(
            builder: (context, location, _) {
              return IconButton(
                icon: location.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.my_location),
                tooltip: 'موقعي الحالي',
                onPressed: location.isLoading ? null : _goToCurrentLocation,
              );
            },
          ),

          // Parcels list
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: AppStrings.myParcels,
            onPressed: _showParcelsList,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map view (placeholder - will implement with Mapbox)
          _buildMapPlaceholder(),

          // Drawing Toolbar
          DrawingToolbar(
            onComplete: () {
              final drawing = context.read<DrawingProvider>();
              _completeDrawing(drawing);
            },
          ),

          // Location Search Bar
          Consumer<DrawingProvider>(
            builder: (context, drawing, _) {
              // Hide search bar when drawing
              if (drawing.isDrawing) return const SizedBox.shrink();

              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LocationSearchBar(
                  onLocationSelected: (lat, lng) {
                    _mapboxKey.currentState?.moveCamera(
                      LatLngPoint(latitude: lat, longitude: lng),
                      zoom: 15,
                    );
                  },
                ),
              );
            },
          ),

          // Live Area Display (shows current area while drawing)
          const LiveAreaDisplay(),
        ],
      ),
      floatingActionButton: Consumer<DrawingProvider>(
        builder: (context, drawing, _) {
          if (drawing.isDrawing) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: _showDrawingModeSelector,
            icon: const Icon(Icons.edit_location),
            label: const Text('رسم قطعة أرض'),
            backgroundColor: AppColors.primary,
          );
        },
      ),
    );
  }

  /// Show drawing mode selector
  void _showDrawingModeSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DrawingModeSelector(),
    ).then((_) {
      // Mode selector now handles starting drawing for each mode
      // No additional action needed here
    });
  }

  Widget _buildMapPlaceholder() {
    // Using actual Mapbox map now
    return MapboxView(key: _mapboxKey);
  }

  Future<void> _completeDrawing(DrawingProvider drawing) async {
    // Show dialog to name the parcel
    final parcelName = await _showNameDialog();
    if (parcelName == null || !mounted) return;

    final parcel = await drawing.completeDrawing(name: parcelName);

    if (parcel != null && mounted) {
      // Add to parcels provider
      final parcelsProvider = context.read<ParcelsProvider>();
      await parcelsProvider.addParcel(parcel);
      await _mapboxKey.currentState?.addParcel(parcel);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إضافة الأرض: ${parcel.name}'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (drawing.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(drawing.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showNameDialog() async {
    final drawing = context.read<DrawingProvider>();
    // If we have a template crop type, use it in the name (e.g., "Wheat Field")
    // Otherwise use generic date-based name
    final defaultName = drawing.selectedPredefinedShape != null &&
            drawing.templateCropType != null
        ? 'حقل ${drawing.templateCropType}'
        : 'أرض ${DateTime.now().day}/${DateTime.now().month}';

    final controller = TextEditingController(
      text: defaultName,
    );

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اسم الأرض'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'الاسم',
            hintText: 'أدخل اسم الأرض',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, controller.text);
            },
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    final locationProvider = context.read<LocationProvider>();
    final position = await locationProvider.getCurrentLocation();

    if (position != null && mounted) {
      final mapState = context.read<MapStateProvider>();

      // Update state provider for consistency
      mapState.moveToLocation(
        LatLngPoint(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        zoom: 16,
      );

      // Move the actual map camera
      await _mapboxKey.currentState?.moveCamera(
        LatLngPoint(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        zoom: 16,
      );
    } else if (locationProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locationProvider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showParcelsList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParcelsListScreen(
          onNavigateToParcel: (parcel) {
            // Move camera to parcel when user clicks "View on Map"
            _mapboxKey.currentState?.moveCamera(
              parcel.centroid,
              zoom: 17,
            );
          },
        ),
      ),
    );
  }
}
