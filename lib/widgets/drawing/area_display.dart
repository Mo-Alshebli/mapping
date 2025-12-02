import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/drawing_provider.dart';
import '../../utils/colors.dart';
import '../../utils/drawing_mode.dart';

/// Live area display widget with unit conversion
/// Compact and collapsible version
class LiveAreaDisplay extends StatefulWidget {
  const LiveAreaDisplay({super.key});

  @override
  State<LiveAreaDisplay> createState() => _LiveAreaDisplayState();
}

class _LiveAreaDisplayState extends State<LiveAreaDisplay> {
  bool _isExpanded = false; // مطوية بشكل افتراضي

  @override
  Widget build(BuildContext context) {
    return Consumer<DrawingProvider>(
      builder: (context, drawing, _) {
        // Only show when drawing and has enough points
        if (!drawing.isDrawing || drawing.currentArea == null) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 16,
          right: 16,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              constraints: BoxConstraints(
                maxWidth: _isExpanded ? 160 : 100,
              ),
              padding: EdgeInsets.all(_isExpanded ? 10 : 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header مع أيقونة
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.area_chart,
                        color: AppColors.primary,
                        size: _isExpanded ? 16 : 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'المساحة',
                        style: TextStyle(
                          fontSize: _isExpanded ? 11 : 10,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Main area display
                  Text(
                    drawing.currentAreaFormatted,
                    style: TextStyle(
                      fontSize: _isExpanded ? 18 : 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.right,
                  ),

                  // Area in other units (only when expanded)
                  if (_isExpanded) ...[
                    const SizedBox(height: 6),
                    const Divider(height: 1),
                    const SizedBox(height: 6),
                    _buildUnitRow(AreaUnit.squareMeters, drawing, context),
                    _buildUnitRow(AreaUnit.donum, drawing, context),
                    _buildUnitRow(AreaUnit.hectare, drawing, context),
                    _buildUnitRow(AreaUnit.feddan, drawing, context),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnitRow(
    AreaUnit unit,
    DrawingProvider drawing,
    BuildContext context,
  ) {
    final area = drawing.currentArea ?? 0;
    final converted = unit.convertFromSquareMeters(area);
    final isSelected = drawing.preferredUnit == unit;

    return GestureDetector(
      onTap: () => drawing.setPreferredUnit(unit),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        margin: const EdgeInsets.only(bottom: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${converted.toStringAsFixed(2)} ${unit.displayName}',
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? AppColors.primary : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 3),
              const Icon(
                Icons.check_circle,
                size: 12,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
