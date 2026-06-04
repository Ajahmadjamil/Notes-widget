import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';

class CustomLoading extends StatelessWidget {
  const CustomLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lottie.asset(
            //   Assets.imagesLoading,
            //   width: 150,
            //   height: 150,
            //   fit: BoxFit.contain,
            // ),
            const SizedBox(height: 16),
            Text("Please wait...", style: getSemiBoldStyle(color: AppColors.textColor, fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
