import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/drawing_provider.dart';
import '../../utils/colors.dart';
import '../../utils/drawing_mode.dart';

/// Floating controls for shape manipulation
class ShapeControls extends StatefulWidget {
  const ShapeControls({super.key});

  @override
  State<ShapeControls> createState() => _ShapeControlsState();
}

class _ShapeControlsState extends State<ShapeControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  Timer? _debounceTimer;
  Timer? _continuousTimer;
  bool _isVisible = true; // حالة الإظهار/الإخفاء

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    _continuousTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DrawingProvider>(
      builder: (context, drawing, _) {
        if (!drawing.isDrawing) return const SizedBox.shrink();

        final showSizeControls =
            drawing.currentMode == DrawingMode.predefinedShape &&
                drawing.shapeRadius != null;

        return Positioned(
          left: 16,
          bottom: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // زر الإخفاء/الإظهار
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _isVisible ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.primary,
                  ),
                  tooltip: _isVisible ? 'إخفاء التحكم' : 'إظهار التحكم',
                  onPressed: () {
                    setState(() {
                      _isVisible = !_isVisible;
                    });
                    HapticFeedback.lightImpact();
                  },
                ),
              ),

              const SizedBox(height: 8),

              // لوحة التحكم (قابلة للإخفاء)
              if (_isVisible)
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Size controls
                      if (showSizeControls) _buildSizeControls(drawing),

                      // Quick actions
                      const SizedBox(height: 12),
                      _buildQuickActions(drawing),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSizeControls(DrawingProvider drawing) {
    return SizedBox(
      width: 300, // Fixed width to prevent layout errors
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.straighten,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'الحجم',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${drawing.shapeRadius!.toStringAsFixed(0)} م',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Decrease button
                _buildSizeButton(
                  icon: Icons.remove,
                  onPressed: () => _adjustSize(drawing, -50),
                  onLongPress: () => _startContinuousAdjust(drawing, -50),
                  onLongPressEnd: _stopContinuousAdjust,
                ),
                const SizedBox(width: 8),
                // Slider
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.primary.withOpacity(0.2),
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withOpacity(0.1),
                      trackHeight: 4,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: drawing.shapeRadius!.clamp(10.0, 2000.0),
                      min: 10,
                      max: 2000,
                      onChanged: (value) => _onSliderChanged(value, drawing),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Increase button
                _buildSizeButton(
                  icon: Icons.add,
                  onPressed: () => _adjustSize(drawing, 50),
                  onLongPress: () => _startContinuousAdjust(drawing, 50),
                  onLongPressEnd: _stopContinuousAdjust,
                ),
              ],
            ),
            // Quick size presets
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPresetButton('50م', 50, drawing),
                _buildPresetButton('100م', 100, drawing),
                _buildPresetButton('250م', 250, drawing),
                _buildPresetButton('500م', 500, drawing),
                _buildPresetButton('1كم', 1000, drawing),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeButton({
    required IconData icon,
    required VoidCallback onPressed,
    required VoidCallback onLongPress,
    required VoidCallback onLongPressEnd,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress();
      },
      onLongPressEnd: (_) => onLongPressEnd(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildPresetButton(
      String label, double value, DrawingProvider drawing) {
    final isSelected = (drawing.shapeRadius! - value).abs() < 10;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        drawing.setShapeRadius(value);
        drawing.updateShapePreview();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(DrawingProvider drawing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scale up
          _buildQuickActionButton(
            icon: Icons.zoom_in,
            tooltip: 'تكبير 10%',
            onTap: () {
              HapticFeedback.lightImpact();
              drawing.scaleShape(1.1);
            },
          ),
          // Scale down
          _buildQuickActionButton(
            icon: Icons.zoom_out,
            tooltip: 'تصغير 10%',
            onTap: () {
              HapticFeedback.lightImpact();
              drawing.scaleShape(0.9);
            },
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),
          // Rotate left
          _buildQuickActionButton(
            icon: Icons.rotate_left,
            tooltip: 'تدوير 5° عكس عقارب الساعة',
            onTap: () {
              HapticFeedback.selectionClick();
              drawing.rotateShape(-5); // يسار = سالب
            },
          ),
          // Rotate right
          _buildQuickActionButton(
            icon: Icons.rotate_right,
            tooltip: 'تدوير 5° مع عقارب الساعة',
            onTap: () {
              HapticFeedback.selectionClick();
              drawing.rotateShape(5); // يمين = موجب
            },
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),
          // Center tip
          _buildQuickActionButton(
            icon: Icons.center_focus_strong,
            tooltip: 'توسيط',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('استخدم زر القفل لتعطيل الخريطة ثم حرك الشكل'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: Colors.grey[700]),
        ),
      ),
    );
  }

  void _adjustSize(DrawingProvider drawing, double delta) {
    final newRadius = (drawing.shapeRadius! + delta).clamp(10.0, 5000.0);
    drawing.setShapeRadius(newRadius);
    drawing.updateShapePreview();
  }

  void _startContinuousAdjust(DrawingProvider drawing, double delta) {
    _continuousTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _adjustSize(drawing, delta);
    });
  }

  void _stopContinuousAdjust() {
    _continuousTimer?.cancel();
    _continuousTimer = null;
  }

  void _onSliderChanged(double value, DrawingProvider drawing) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 50), () {
      drawing.setShapeRadius(value);
      drawing.updateShapePreview();
    });
  }
}
