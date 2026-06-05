import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';

/// Reusable glassmorphic container used across the app.
class AppContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool isSelected;
  final bool isHighlighted;
  final bool isFocused;
  final double borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enableGlass;
  final double blur;
  final AlignmentGeometry? alignment;

  const AppContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.isSelected = false,
    this.isHighlighted = false,
    this.isFocused = false,
    this.borderRadius = 24,
    this.onTap,
    this.onLongPress,
    this.enableGlass = true,
    this.blur = 12,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = isSelected
        ? AppColors.glassSelectedFill
        : isHighlighted
            ? AppColors.glassHighlightFill
            : isFocused
                ? AppColors.glassFocusFill
                : AppColors.glassFill;

    final borderColor = isSelected
        ? AppColors.selectedColor.withValues(alpha: 0.5)
        : isHighlighted
            ? AppColors.glassHighlightBorder
            : isFocused
                ? AppColors.glassFocusBorder
                : AppColors.glassBorder;

    Widget content = Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        color: enableGlass ? fillColor : (isSelected ? AppColors.selectedColor : AppColors.containerColor),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: isFocused ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.selectedColor.withValues(
              alpha: isSelected ? 0.18 : isHighlighted ? 0.05 : isFocused ? 0.06 : 0.08,
            ),
            blurRadius: isSelected ? 20 : isHighlighted ? 8 : isFocused ? 10 : 14,
            offset: Offset(0, isFocused || isHighlighted ? 3 : 6),
          ),
        ],
      ),
      child: child,
    );

    if (enableGlass) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null || onLongPress != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.selectedColor.withValues(alpha: 0.06),
          highlightColor: AppColors.selectedColor.withValues(alpha: 0.03),
          child: content,
        ),
      );
    }

    return content;
  }
}
