import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';

class CollabGlassToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool accent;

  const CollabGlassToolBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final iconColor = !enabled
        ? AppColors.textColor2.withValues(alpha: 0.35)
        : accent
            ? AppColors.selectedColor
            : AppColors.textColor;

    return Expanded(
      child: PressableScale(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent
                    ? AppColors.selectedColor.withValues(alpha: 0.14)
                    : AppColors.glassFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accent
                      ? AppColors.selectedColor.withValues(alpha: 0.35)
                      : AppColors.glassBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.selectedColor.withValues(
                      alpha: accent ? 0.12 : 0.04,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: getRegularStyle(
                fontSize: 11,
                color: enabled
                    ? AppColors.textColor2
                    : AppColors.textColor2.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
