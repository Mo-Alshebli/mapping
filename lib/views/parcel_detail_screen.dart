import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/land_parcel.dart';
import '../providers/parcels_provider.dart';
import '../providers/map_state_provider.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/charts/health_gauge.dart';
import '../widgets/charts/ndvi_chart.dart';

/// Screen for viewing and editing parcel details
class ParcelDetailScreen extends StatefulWidget {
  final LandParcel parcel;

  const ParcelDetailScreen({super.key, required this.parcel});

  @override
  State<ParcelDetailScreen> createState() => _ParcelDetailScreenState();
}

class _ParcelDetailScreenState extends State<ParcelDetailScreen> {
  late LandParcel _parcel;
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _cropTypeController;

  @override
  void initState() {
    super.initState();
    _parcel = widget.parcel;
    _nameController = TextEditingController(text: _parcel.name);
    _cropTypeController = TextEditingController(text: _parcel.cropType ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cropTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل الأرض' : _parcel.name),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'تعديل',
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'إلغاء',
              onPressed: () => setState(() {
                _isEditing = false;
                _nameController.text = _parcel.name;
                _cropTypeController.text = _parcel.cropType ?? '';
              }),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Basic Info Card
            _buildInfoCard(),

            const SizedBox(height: 16),

            // Area & Perimeter Card
            _buildMeasurementsCard(),

            const SizedBox(height: 16),

            // Health Statistics (if available)
            if (_parcel.statistics != null) ...[
              _buildHealthCard(),
              const SizedBox(height: 16),
            ],

            // NDVI Chart (if available)
            if (_parcel.ndviLayer != null) ...[
              _buildNDVICard(),
              const SizedBox(height: 16),
            ],

            // Coordinates Card
            _buildCoordinatesCard(),

            const SizedBox(height: 16),

            // Actions
            _buildActionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.info_outline, 'معلومات الأرض'),
            const Divider(height: 24),

            // Name
            if (_isEditing)
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الأرض',
                  border: OutlineInputBorder(),
                ),
              )
            else
              _buildInfoRow('الاسم', _parcel.name),

            const SizedBox(height: 12),

            // Crop Type
            if (_isEditing)
              TextField(
                controller: _cropTypeController,
                decoration: const InputDecoration(
                  labelText: 'نوع المحصول',
                  border: OutlineInputBorder(),
                  hintText: 'مثال: قمح، نخيل، خضروات...',
                ),
              )
            else
              _buildInfoRow('المحصول', _parcel.cropType ?? 'غير محدد'),

            const SizedBox(height: 12),

            // Dates
            _buildInfoRow(
              'تاريخ الإنشاء',
              DateFormat('yyyy/MM/dd - HH:mm').format(_parcel.createdAt),
            ),
            if (_parcel.lastUpdated != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                'آخر تحديث',
                DateFormat('yyyy/MM/dd - HH:mm').format(_parcel.lastUpdated!),
              ),
            ],

            // Save button when editing
            if (_isEditing) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveChanges,
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ التغييرات'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.straighten, 'القياسات'),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementTile(
                    icon: Icons.square_foot,
                    label: 'المساحة',
                    value: _formatArea(_parcel.area),
                    subValue:
                        '${_parcel.areaInHectares.toStringAsFixed(3)} هكتار',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMeasurementTile(
                    icon: Icons.timeline,
                    label: 'عدد النقاط',
                    value: '${_parcel.coordinates.length}',
                    subValue: 'نقطة',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard() {
    final stats = _parcel.statistics!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.health_and_safety, 'صحة المحصول',
                color: Colors.green),
            const Divider(height: 24),
            Center(
              child: HealthGauge(
                healthPercentage: stats.healthPercentage,
                size: 150,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHealthStat('NDVI', stats.ndviValue.toStringAsFixed(2)),
                _buildHealthStat(
                    'الرطوبة', '${stats.moistureLevel.toStringAsFixed(0)}%'),
                _buildHealthStat('الحالة', stats.healthStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNDVICard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.show_chart, 'مؤشر NDVI',
                color: Colors.teal),
            const Divider(height: 24),
            SizedBox(
              height: 200,
              child: NDVIChart(
                historicalData: _parcel.statistics?.historicalData ?? [],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinatesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.location_on, 'الإحداثيات'),
            const Divider(height: 24),

            // Center point
            _buildInfoRow(
              'المركز',
              '${_parcel.centroid.latitude.toStringAsFixed(6)}, ${_parcel.centroid.longitude.toStringAsFixed(6)}',
            ),

            const SizedBox(height: 12),

            // Expandable coordinates list
            ExpansionTile(
              title: Text('نقاط المضلع (${_parcel.coordinates.length})'),
              tilePadding: EdgeInsets.zero,
              children: _parcel.coordinates.asMap().entries.map((entry) {
                final index = entry.key;
                final coord = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${coord.latitude.toStringAsFixed(6)}, ${coord.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader(Icons.settings, 'الإجراءات'),
            const Divider(height: 24),

            // Go to map
            OutlinedButton.icon(
              onPressed: _goToMap,
              icon: const Icon(Icons.map),
              label: const Text('عرض على الخريطة'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Refresh data
            OutlinedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث البيانات'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Delete
            OutlinedButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_forever),
              label: const Text('حذف الأرض'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: color ?? AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementTile({
    required IconData icon,
    required String label,
    required String value,
    required String subValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subValue,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatArea(double areaInSqMeters) {
    if (areaInSqMeters >= 10000) {
      return '${(areaInSqMeters / 10000).toStringAsFixed(2)} هكتار';
    }
    return '${areaInSqMeters.toStringAsFixed(0)} م²';
  }

  void _saveChanges() async {
    final provider = context.read<ParcelsProvider>();
    final updatedParcel = _parcel.copyWith(
      name: _nameController.text.trim(),
      cropType: _cropTypeController.text.trim().isEmpty
          ? null
          : _cropTypeController.text.trim(),
      lastUpdated: DateTime.now(),
    );

    await provider.updateParcel(updatedParcel);

    setState(() {
      _parcel = updatedParcel;
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ التغييرات'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _goToMap() {
    final mapState = context.read<MapStateProvider>();
    mapState.focusOnParcel(_parcel);
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _refreshData() async {
    final provider = context.read<ParcelsProvider>();
    await provider.refreshParcelData(_parcel.id);

    // Reload parcel data
    final updatedParcel = provider.parcels.firstWhere(
      (p) => p.id == _parcel.id,
      orElse: () => _parcel,
    );

    setState(() {
      _parcel = updatedParcel;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث البيانات'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الأرض'),
        content: Text(
            'هل أنت متأكد من حذف "${_parcel.name}"؟\nهذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<ParcelsProvider>();
              await provider.deleteParcel(_parcel.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to list
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم حذف "${_parcel.name}"'),
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
