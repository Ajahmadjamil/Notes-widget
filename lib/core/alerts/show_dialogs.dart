import 'package:noteswidgetapp/core/shared/widgets/custom_button.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:flutter/material.dart';

class Dialogs {
  static Future<bool> showConfirmationDialog({
    required BuildContext context,
    String? title,
    String? message,
    String? lottieAsset,
    String negativeLabel = "No",
    String positiveLabel = "Yes",
    Widget? positiveLabelWidget, // ✅ make it optional
    Color? positiveColor,
    Color? negativeColor,
    Future<void> Function()? onConfirm,
    Future<void> Function()? onCancel,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final isLandscape = MediaQuery.of(dialogContext).orientation == Orientation.landscape;
        final dialogWidth = isLandscape
            ? MediaQuery.of(dialogContext).size.width * 0.5
            : MediaQuery.of(dialogContext).size.width;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogWidth),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.textFieldBorderColor),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (lottieAsset != null) ...[
                    // Lottie.asset(lottieAsset, width: 150, height: 150, fit: BoxFit.contain),
                    const SizedBox(height: 24),
                  ],
                  if (title != null)
                    Text(
                      title,
                      style: getMediumStyle(color: AppColors.textColor, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                  if (message != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: getRegularStyle(color: AppColors.textColor2, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          child: CustomButton(
                            onTap: () async {
                              if (onCancel != null) await onCancel();
                              Navigator.of(dialogContext).pop(false);
                            },
                            label: negativeLabel,
                            color: negativeColor ?? Colors.grey.shade300,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Material(
                          child: CustomButton(
                            onTap: () async {
                              if (onConfirm != null) {
                                await onConfirm(); // 👈 wait for API
                              }
                              // only close dialog AFTER confirm work is done
                              Navigator.of(dialogContext).pop(true);
                            },
                            color: positiveColor ?? AppColors.btnColorPrimary,
                            label: positiveLabel,
                            widget:
                                positiveLabelWidget ??
                                Text(positiveLabel, style: getMediumStyle(color: Colors.white, fontSize: 16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((value) => value ?? false);
  }

  static Future<bool> showInfoDialog({
    required BuildContext context,
    required String lottieAsset,
    required String title,
    String okLabel = "OK",
    Color? okColor,
    Future<void> Function()? onOk,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final isLandscape = MediaQuery.of(dialogContext).orientation == Orientation.landscape;
        final dialogWidth = isLandscape
            ? MediaQuery.of(dialogContext).size.width * 0.5
            : MediaQuery.of(dialogContext).size.width;

        // ✅ Auto close after 3 seconds
        Future.delayed(const Duration(seconds: 3), () async {
          if (Navigator.of(dialogContext).canPop()) {
            if (onOk != null) await onOk();
            Navigator.of(dialogContext).pop(true);
          }
        });

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogWidth),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.textFieldBorderColor),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ Lottie animation
                  // Lottie.asset(lottieAsset, width: 150, height: 150, fit: BoxFit.contain),
                  const SizedBox(height: 24),

                  // ✅ Title
                  Text(
                    title,
                    style: getMediumStyle(color: AppColors.textColor, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // ✅ OK button
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      child: CustomButton(
                        onTap: () async {
                          if (onOk != null) await onOk();
                          Navigator.of(dialogContext).pop(true);
                        },
                        color: okColor ?? AppColors.btnColorPrimary,
                        label: okLabel,
                        widget: Text(okLabel, style: getMediumStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((value) => value ?? false);
  }
}
