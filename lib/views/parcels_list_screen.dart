import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/land_parcel.dart';
import '../providers/parcels_provider.dart';
import '../providers/map_state_provider.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import 'parcel_detail_screen.dart';

/// Screen for managing land parcels (list, search, delete)
class ParcelsListScreen extends StatefulWidget {
  const ParcelsListScreen({super.key});

  @override
  State<ParcelsListScreen> createState() => _ParcelsListScreenState();
}

class _ParcelsListScreenState extends State<ParcelsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCropType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myParcels),
        actions: [
          // Filter by crop type
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'تصفية حسب المحصول',
            onSelected: (value) {
              setState(() {
                _selectedCropType = value;
              });
            },
            itemBuilder: (context) {
              final parcelsProvider = context.read<ParcelsProvider>();
              final cropTypes = parcelsProvider.getAllCropTypes();
              return [
                const PopupMenuItem<String?>(
                  value: null,
                  child: Text('الكل'),
                ),
                ...cropTypes.map((type) => PopupMenuItem<String?>(
                      value: type,
                      child: Text(type),
                    )),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'البحث عن أرض...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Stats summary
          Consumer<ParcelsProvider>(
            builder: (context, provider, _) {
              final totalArea = provider.getTotalArea();
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.7)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.landscape,
                      label: 'عدد الأراضي',
                      value: '${provider.parcelsCount}',
                    ),
                    _buildStatItem(
                      icon: Icons.square_foot,
                      label: 'المساحة الكلية',
                      value: _formatArea(totalArea),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Parcels list
          Expanded(
            child: Consumer<ParcelsProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          provider.error!,
                          style: TextStyle(color: Colors.red[700]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.initialize(),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }

                // Apply filters
                var parcels = provider.parcels;
                if (_searchQuery.isNotEmpty) {
                  parcels = provider.searchByName(_searchQuery);
                }
                if (_selectedCropType != null) {
                  parcels = parcels
                      .where((p) => p.cropType == _selectedCropType)
                      .toList();
                }

                if (parcels.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.landscape_outlined,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _selectedCropType != null
                              ? 'لا توجد نتائج'
                              : 'لا توجد أراضي مسجلة',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ابدأ برسم قطعة أرض جديدة',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: parcels.length,
                  itemBuilder: (context, index) {
                    final parcel = parcels[index];
                    return _buildParcelCard(context, parcel, provider);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildParcelCard(
    BuildContext context,
    LandParcel parcel,
    ParcelsProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openParcelDetail(context, parcel),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon/Shape indicator
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getShapeIcon(parcel),
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parcel.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.square_foot,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          _formatArea(parcel.area),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (parcel.cropType != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.grass, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            parcel.cropType!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(parcel.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Column(
                children: [
                  // Go to map
                  IconButton(
                    icon: const Icon(Icons.map_outlined),
                    color: AppColors.primary,
                    tooltip: 'عرض على الخريطة',
                    onPressed: () => _goToParcelOnMap(context, parcel),
                  ),
                  // Delete
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red[400],
                    tooltip: 'حذف',
                    onPressed: () => _confirmDelete(context, parcel, provider),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getShapeIcon(LandParcel parcel) {
    if (parcel.shape == null) return Icons.crop_square;
    switch (parcel.shape!) {
      case _:
        return Icons.crop_square;
    }
  }

  String _formatArea(double areaInSqMeters) {
    if (areaInSqMeters >= 10000) {
      return '${(areaInSqMeters / 10000).toStringAsFixed(2)} هكتار';
    }
    return '${areaInSqMeters.toStringAsFixed(0)} م²';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _openParcelDetail(BuildContext context, LandParcel parcel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParcelDetailScreen(parcel: parcel),
      ),
    );
  }

  void _goToParcelOnMap(BuildContext context, LandParcel parcel) {
    final mapState = context.read<MapStateProvider>();
    mapState.focusOnParcel(parcel);
    Navigator.pop(context); // Return to map
  }

  void _confirmDelete(
    BuildContext context,
    LandParcel parcel,
    ParcelsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الأرض'),
        content: Text('هل أنت متأكد من حذف "${parcel.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteParcel(parcel.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم حذف "${parcel.name}"'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}





