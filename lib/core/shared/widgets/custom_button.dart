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

  CustomButton({
    super.key,
    required this.label,
    required this.color,
    this.widget,
    this.onTap,
    this.radius = 8,
    this.isEnabled = true,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: color,
          // border: Border.all(
          //   color: AppColors.textFieldBorderColor,
          //   width: 1,
          // ),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style:
                  style ??
                  getMediumStyle(
                    fontSize: 14,
                    color: color == AppColors.btnColorPrimary || color == AppColors.btnDisabledLightGreyColor
                        ? AppColors.textColor1
                        : AppColors.textColorPrimary,
                  ),
            ),
            widget == null
                ? Container()
                : Container(
                    child: Padding(padding: const EdgeInsets.fromLTRB(5, 2, 0, 0), child: widget),
                  ),
          ],
        ),
      ),
    );
  }
}
