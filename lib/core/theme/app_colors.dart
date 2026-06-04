import 'package:noteswidgetapp/core/theme/theme_service.dart';
import 'package:flutter/material.dart';

class AppColors {
  // Background
  static Color get bgColor => ThemeService.instance.isDarkMode ? const Color(0xffE4E9F5) : const Color(0xffE4E9F5);

  static Color get primaryColor => ThemeService.instance.isDarkMode ? const Color(0xff604BE8) : const Color(0xff604BE8);

  static Color get secondaryColor =>
      ThemeService.instance.isDarkMode ? const Color(0xffdbd7f6) : const Color(0xffdbd7f6);

  static Color get darkBgColor => ThemeService.instance.isDarkMode ? const Color(0xff302D3D) : const Color(0xff302D3D);

  static Color get cardColor =>
      ThemeService.instance.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  static Color transparent = Colors.transparent;
  //text color
  static Color get textColor =>
      ThemeService.instance.isDarkMode ? Colors.white : const Color(0xff302D3D);

  static Color get textColor1 => ThemeService.instance.isDarkMode ? Colors.white : Colors.white;

  static Color get textColor2 => ThemeService.instance.isDarkMode ? const Color(0xff969DB6) : const Color(0xff969DB6);

  static Color get textColorRed => ThemeService.instance.isDarkMode ? Colors.red : Colors.red;

  static Color get textColorGreen =>
      ThemeService.instance.isDarkMode ? const Color(0xff00BE4E) : const Color(0xff00BE4E);

  static Color get textColorPrimary => ThemeService.instance.isDarkMode ? primaryColor : primaryColor;

  // textFields color
  static Color get textFieldBorderColor =>
      ThemeService.instance.isDarkMode ? const Color(0xffDCDCDC) : const Color(0xffDCDCDC);

  static Color get textFieldBorderErrorColor => ThemeService.instance.isDarkMode ? Colors.red : Colors.red;

  static Color get textFieldPlaceHolderColor =>
      ThemeService.instance.isDarkMode ? const Color(0xffB6B7B7) : const Color(0xffB6B7B7);

  static Color get textFieldTextColor =>
      ThemeService.instance.isDarkMode ? const Color(0xff302D3D) : const Color(0xff302D3D);

  static Color get textFieldTextColor1 => ThemeService.instance.isDarkMode ? Colors.white : Colors.white;

  static Color get textFieldHintColor =>
      ThemeService.instance.isDarkMode ? const Color(0xff969DB6) : const Color(0xff969DB6);

  static Color get textFieldBorderColorSlct => ThemeService.instance.isDarkMode ? primaryColor : primaryColor;

  // btn Colors if selected
  static Color get textFieldSelectedBg => ThemeService.instance.isDarkMode
      ? const Color(0xff604BE8).withOpacity(0.2)
      : const Color(0xff604BE8).withOpacity(0.2);

  static Color get textFieldSelectedBorder => ThemeService.instance.isDarkMode ? primaryColor : primaryColor;

  // status bar
  static Color get statusBarActiveColor =>
      ThemeService.instance.isDarkMode ? const Color(0xff35363a) : const Color(0xff35363a);

  static Color get statusBarInActiveColor =>
      ThemeService.instance.isDarkMode ? Colors.grey.withOpacity(.7) : Colors.grey.withOpacity(.7);

  // icons
  static Color get iconColorBlack => ThemeService.instance.isDarkMode ? Colors.black : Colors.black;

  static Color get iconColorWhite => ThemeService.instance.isDarkMode ? Colors.white : Colors.white;

  static Color get iconColorGrey =>
      ThemeService.instance.isDarkMode ? const Color(0xff969DB6) : const Color(0xff969DB6);

  static Color get borderColor => ThemeService.instance.isDarkMode ? const Color(0xffD1D3D7) : const Color(0xffD1D3D7);

  static Color get appBarColor => ThemeService.instance.isDarkMode ? bgColor : bgColor;

  static Color get appBarTextColor => ThemeService.instance.isDarkMode ? textColor : textColor;

  static Color get horizontalCardActiveBgColor => ThemeService.instance.isDarkMode
      ? const Color(0xff604BE8).withOpacity(0.1)
      : const Color(0xff604BE8).withOpacity(0.1);

  // Buttons
  static Color get btnColorPrimary => ThemeService.instance.isDarkMode ? primaryColor : primaryColor;

  static Color get btnColorSecondary => ThemeService.instance.isDarkMode
      ? const Color(0xff604BE8).withOpacity(0.2)
      : const Color(0xff604BE8).withOpacity(0.2);

  static Color get btnColorLight => ThemeService.instance.isDarkMode
      ? const Color(0xff604BE8).withOpacity(0.1)
      : const Color(0xff604BE8).withOpacity(0.1);

  static Color get btnDisabledColor => ThemeService.instance.isDarkMode
      ? const Color(0xff604BE8).withOpacity(0.1)
      : const Color(0xff604BE8).withOpacity(0.1);

  static Color get btnColorRed => ThemeService.instance.isDarkMode ? const Color(0xffff0000) : const Color(0xffff0000);

  static Color get btnDisabledLightGreyColor =>
      ThemeService.instance.isDarkMode ? const Color(0xffABB1C5) : const Color(0xffABB1C5);

  static Color get btnLavenderColor =>
      ThemeService.instance.isDarkMode ? const Color(0xffebe8f8) : const Color(0xffebe8f8);

  // navbar colors
  static Color get activeNavBarIconColor => ThemeService.instance.isDarkMode ? primaryColor : primaryColor;

  static Color get inActiveNavBarIconColor =>
      ThemeService.instance.isDarkMode ? const Color(0xff969DB6) : const Color(0xff969DB6);

  // Shimmer
  static Color get shimmerBaseColor => ThemeService.instance.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;

  static Color get shimmerHighlightColor => ThemeService.instance.isDarkMode ? Colors.grey[500]! : Colors.grey[100]!;
}
