import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';

/// Half-width divider placed below the editor title field.
class EditorTitleDivider extends StatelessWidget {
  const EditorTitleDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final halfWidth = MediaQuery.sizeOf(context).width * 0.5;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        width: halfWidth,
        height: 1.2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1),
          gradient: LinearGradient(
            colors: [
              AppColors.selectedColor.withValues(alpha: 0.35),
              AppColors.selectedColor.withValues(alpha: 0.08),
            ],
          ),
        ),
      ),
    );
  }
}
