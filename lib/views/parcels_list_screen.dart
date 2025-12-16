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
  final Function(LandParcel)? onNavigateToParcel;

  const ParcelsListScreen({super.key, this.onNavigateToParcel});

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
      elevation: 3,
      shadowColor: AppColors.primary.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _openParcelDetail(context, parcel),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and actions
              Row(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getShapeIcon(parcel),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parcel.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
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

                  // Delete button
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red[400],
                    tooltip: 'حذف',
                    onPressed: () => _confirmDelete(context, parcel, provider),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Information chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    icon: Icons.square_foot,
                    label: _formatArea(parcel.area),
                    color: Colors.blue,
                  ),
                  if (parcel.cropType != null)
                    _buildInfoChip(
                      icon: Icons.grass,
                      label: parcel.cropType!,
                      color: Colors.green,
                    ),
                  _buildInfoChip(
                    icon: Icons.location_on,
                    label: '${parcel.coordinates.length} نقاط',
                    color: Colors.orange,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // View on map button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _goToParcelOnMap(context, parcel),
                  icon: const Icon(Icons.map, size: 20),
                  label: const Text('عرض على الخريطة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
    // Navigate back to map screen
    Navigator.pop(context);

    // If callback is provided, use it to navigate to parcel
    if (widget.onNavigateToParcel != null) {
      widget.onNavigateToParcel!(parcel);
    }
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
