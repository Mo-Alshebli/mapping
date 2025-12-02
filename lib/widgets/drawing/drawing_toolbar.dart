import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/drawing_provider.dart';
import '../../utils/colors.dart';

/// Toolbar for drawing actions (Undo, Redo, Complete, Cancel)
class DrawingToolbar extends StatelessWidget {
  final VoidCallback onComplete;

  const DrawingToolbar({
    super.key,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DrawingProvider>(
      builder: (context, drawing, _) {
        if (!drawing.isDrawing) return const SizedBox.shrink();

        // canComplete now handles predefined shapes correctly
        final canComplete = drawing.canComplete;

        return Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Cancel
                _buildToolbarButton(
                  context,
                  icon: Icons.close,
                  label: 'إلغاء',
                  color: Colors.red,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    drawing.reset();
                  },
                ),

                _buildDivider(),

                // Undo
                _buildToolbarButton(
                  context,
                  icon: Icons.undo,
                  label: 'تراجع',
                  color: Colors.orange,
                  enabled: drawing.canUndo,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    drawing.undo();
                  },
                ),

                // Redo
                _buildToolbarButton(
                  context,
                  icon: Icons.redo,
                  label: 'إعادة',
                  color: Colors.blue,
                  enabled: drawing.canRedo,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    drawing.redo();
                  },
                ),

                _buildDivider(),

                // Lock/Unlock Map
                _buildToolbarButton(
                  context,
                  icon: drawing.isMapFrozen ? Icons.lock : Icons.lock_open,
                  label: drawing.isMapFrozen ? 'مقفل' : 'مفتوح',
                  color: drawing.isMapFrozen ? Colors.orange : Colors.green,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    drawing.toggleMapFreeze();

                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          drawing.isMapFrozen
                              ? 'الخريطة مقفلة - اسحب لتحريك الشكل'
                              : 'الخريطة مفتوحة - يمكنك التنقل',
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

                _buildDivider(),

                // Complete
                _buildToolbarButton(
                  context,
                  icon: Icons.check,
                  label: 'حفظ',
                  color: AppColors.primary,
                  enabled: canComplete,
                  isPrimary: canComplete,
                  onTap: canComplete
                      ? () {
                          HapticFeedback.heavyImpact();
                          onComplete();
                        }
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolbarButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    bool enabled = true,
    bool isPrimary = false,
    VoidCallback? onTap,
  }) {
    final effectiveColor = enabled ? color : Colors.grey[400]!;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: isPrimary
              ? BoxDecoration(
                  color: effectiveColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: effectiveColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : effectiveColor,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : effectiveColor,
                  fontSize: 11,
                  fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey[200],
    );
  }
}
