import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/drawing_provider.dart';
import '../../utils/drawing_mode.dart';
import '../../utils/colors.dart';

/// Bottom sheet for selecting drawing mode
class DrawingModeSelector extends StatelessWidget {
  const DrawingModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_location_alt,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'اختر نمط الرسم',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'حدد الطريقة التي تريد رسم قطعة الأرض بها',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Drawing modes as cards
          ...DrawingMode.values.map((mode) => _buildModeCard(context, mode)),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildModeCard(BuildContext context, DrawingMode mode) {
    final drawingProvider = context.watch<DrawingProvider>();
    final isSelected = drawingProvider.currentMode == mode;

    IconData icon;
    Color color;
    String tip;

    switch (mode) {
      case DrawingMode.predefinedShape:
        icon = Icons.category;
        color = Colors.blue;
        tip = 'الأسهل والأسرع';
        break;
      case DrawingMode.customPoints:
        icon = Icons.timeline;
        color = Colors.purple;
        tip = 'للأشكال المعقدة';
        break;
      case DrawingMode.freehand:
        icon = Icons.gesture;
        color = Colors.teal;
        tip = 'للرسم الحر';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            drawingProvider.setDrawingMode(mode);
            Navigator.pop(context);

            // If predefined shape mode, show shape selector
            if (mode == DrawingMode.predefinedShape) {
              _showShapeSelector(context);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? color : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(isSelected ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            mode.displayName,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? color : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tip,
                              style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mode.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow or check
                Icon(
                  isSelected ? Icons.check_circle : Icons.arrow_forward_ios,
                  color: isSelected ? color : Colors.grey[400],
                  size: isSelected ? 24 : 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showShapeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ShapeSelectorPanel(),
    );
  }
}

/// Bottom sheet for selecting predefined shape
class ShapeSelectorPanel extends StatelessWidget {
  const ShapeSelectorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.category, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'اختر الشكل',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على الشكل المطلوب لبدء الرسم',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Shapes grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            physics: const NeverScrollableScrollPhysics(),
            children: PredefinedShape.values
                .map((shape) => _buildShapeCard(context, shape))
                .toList(),
          ),

          const SizedBox(height: 16),

          // Tips
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    color: Colors.blue[700], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'نصيحة: بعد الرسم يمكنك تحريك الشكل وتغيير حجمه',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildShapeCard(BuildContext context, PredefinedShape shape) {
    final drawingProvider = context.watch<DrawingProvider>();
    final isSelected = drawingProvider.selectedPredefinedShape == shape;

    Color color;
    IconData icon;

    switch (shape) {
      case PredefinedShape.circle:
        color = Colors.green;
        icon = Icons.circle_outlined;
        break;
      case PredefinedShape.square:
        color = Colors.orange;
        icon = Icons.square_outlined;
        break;
      case PredefinedShape.trapezoid:
        color = Colors.brown;
        icon = Icons.crop_landscape_outlined;
        break;
      case PredefinedShape.ellipse:
        color = Colors.indigo;
        icon = Icons.egg_outlined;
        break;
    }

    return Material(
      color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          // اختر الشكل، ثم ابدأ وضع الرسم مباشرة
          drawingProvider.setPredefinedShape(shape);
          drawingProvider.startDrawing();
          Navigator.pop(context);

          // Show instructions
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(shape.instructions)),
                ],
              ),
              duration: const Duration(seconds: 3),
              backgroundColor: color,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),

              // Name
              Text(
                shape.displayName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              // Short instruction
              Text(
                _getShortInstruction(shape),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getShortInstruction(PredefinedShape shape) {
    switch (shape) {
      case PredefinedShape.circle:
        return 'نقرة واحدة + سحب';
      case PredefinedShape.square:
        return 'نقرة واحدة + سحب';
      case PredefinedShape.trapezoid:
        return 'نقرة واحدة + سحب';
      case PredefinedShape.ellipse:
        return 'نقرة واحدة + سحب';
    }
  }
}
