import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:flutter/material.dart';

class CustomLoading extends StatelessWidget {
  const CustomLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppContainer(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.selectedColor,
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: AppColors.transparent,
              child: Text(
                'Please wait...',
                style: getSemiBoldStyle(color: AppColors.textColor, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
