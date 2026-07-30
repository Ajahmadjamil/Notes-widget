import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/shared/widgets/custom_button.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';

/// Glassmorphic confirmation dialog matching the app theme.
class GlassConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData? icon;
  final Color? confirmColor;

  const GlassConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Yes',
    this.cancelLabel = 'No',
    this.icon,
    this.confirmColor,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Yes',
    String cancelLabel = 'No',
    IconData? icon,
    Color? confirmColor,
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: AppColors.secondaryColor.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return GlassConfirmDialog(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          icon: icon,
          confirmColor: confirmColor,
        );
      },
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeSlideIn(
        slideOffset: 16,
        duration: const Duration(milliseconds: 280),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: AppContainer(
            borderRadius: 28,
            blur: 22,
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.selectedColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.selectedColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.selectedColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Material(
                  color: AppColors.transparent,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: getSemiBoldStyle(
                      fontSize: 20,
                      color: AppColors.textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                color: AppColors.transparent,child:  Text(
                  message,
                  textAlign: TextAlign.center,
                  style: getRegularStyle(
                    fontSize: 14,
                    color: AppColors.textColor2,
                  ).copyWith(height: 1.4),
                )),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        label: cancelLabel,
                        color: AppColors.btnColorLight,
                        style: getMediumStyle(
                          fontSize: 14,
                          color: AppColors.textColor,
                        ),
                        onTap: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        label: confirmLabel,
                        color: confirmColor ?? AppColors.primaryColor,
                        onTap: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
