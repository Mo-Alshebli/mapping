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
import '../utils/drawing_mode.dart';
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
          // Map settings
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'إعدادات الخريطة',
            onPressed: _showMapSettings,
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
      // After mode selected, start drawing
      final drawing = context.read<DrawingProvider>();
      final requiresShapeSelection =
          drawing.currentMode == DrawingMode.predefinedShape &&
              drawing.selectedPredefinedShape == null;

      if (!requiresShapeSelection) {
        _startDrawingWithMode();
      }
    });
  }

  /// Start drawing with selected mode
  void _startDrawingWithMode() {
    final drawing = context.read<DrawingProvider>();
    drawing.startDrawing();

    String message = 'اضغط على الخريطة لتحديد النقاط';

    if (drawing.currentMode == DrawingMode.predefinedShape) {
      message = drawing.selectedPredefinedShape?.instructions ?? message;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    // Using actual Mapbox map now
    return MapboxView(key: _mapboxKey);
  }

  void _showMapSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(sheetContext).padding.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'إعدادات الخريطة',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Consumer<MapStateProvider>(
                  builder: (context, mapState, _) {
                    return Column(
                      children: [
                        SwitchListTile(
                          value: mapState.isSatelliteView,
                          title: const Text('عرض الأقمار الصناعية'),
                          subtitle:
                              const Text('تبديل بين خريطة الأقمار والشوارع'),
                          onChanged: (_) => mapState.toggleMapStyle(),
                        ),
                        SwitchListTile(
                          value: mapState.showNDVILayers,
                          title: const Text('طبقات NDVI'),
                          subtitle: const Text('عرض صحة المحاصيل على الخريطة'),
                          onChanged: (_) => mapState.toggleNDVILayers(),
                        ),
                        SwitchListTile(
                          value: mapState.showLabels,
                          title: const Text('إظهار العلامات'),
                          subtitle:
                              const Text('إظهار أسماء الحقول على الخريطة'),
                          onChanged: (_) => mapState.toggleLabels(),
                        ),
                        SwitchListTile(
                          value: mapState.showCharts,
                          title: const Text('إظهار الرسوم'),
                          subtitle: const Text(
                              'إظهار المؤشرات فوق قطع الأراضي المحفوظة'),
                          onChanged: (_) => mapState.toggleCharts(),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.refresh),
                          title: const Text('إعادة تعيين الكاميرا'),
                          subtitle: const Text('العودة إلى الموقع الافتراضي'),
                          onTap: () {
                            mapState.reset();
                            Navigator.pop(sheetContext);
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Consumer<LocationProvider>(
                  builder: (context, location, _) {
                    return ListTile(
                      leading: const Icon(Icons.my_location),
                      title: const Text('الانتقال إلى موقعي'),
                      subtitle: const Text('يحتاج تفعيل خدمة الموقع'),
                      onTap: location.isLoading
                          ? null
                          : () async {
                              await _goToCurrentLocation();
                              if (context.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                    );
                  },
                ),
                Consumer<DrawingProvider>(
                  builder: (context, drawing, _) {
                    return ListTile(
                      leading: const Icon(Icons.layers_clear),
                      title: const Text('مسح الرسم الحالي'),
                      onTap: () {
                        drawing.reset();
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم إلغاء وضع الرسم'),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _showDrawingModeSelector();
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('ابدأ الرسم الآن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
        builder: (context) => const ParcelsListScreen(),
      ),
    );
  }
}
