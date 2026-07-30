import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final Color color;
  final Function()? onTap;
  final Widget? widget;
  TextStyle? style;
  double radius;
  bool isEnabled;
  final double height;

  CustomButton({
    super.key,
    required this.label,
    required this.color,
    this.widget,
    this.onTap,
    this.radius = 28,
    this.isEnabled = true,
    this.style,
    this.height = 48,
  });

  bool get _isPrimary =>
      color == AppColors.btnColorPrimary || color == AppColors.primaryColor;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isEnabled ? color : AppColors.btnDisabledColor;
    final textColor = _isPrimary || color == AppColors.btnDisabledLightGreyColor
        ? AppColors.textColor1
        : AppColors.textColor;

    return PressableScale(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        decoration: BoxDecoration(
          color: effectiveColor,
          borderRadius: BorderRadius.circular(radius),
          border: _isPrimary
              ? null
              : Border.all(color: AppColors.glassBorder),
          boxShadow: _isPrimary && isEnabled
              ? [
                  BoxShadow(
                    color: AppColors.selectedColor.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Material(
              color: AppColors.transparent,
              child: Material(
                color: AppColors.transparent,
                child: Text(
                  label,
                  style: style ?? getMediumStyle(fontSize: 14, color: textColor),
                ),
              ),
            ),
            if (widget != null)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: widget!,
              ),
          ],
        ),
      ),
    );
  }
}
