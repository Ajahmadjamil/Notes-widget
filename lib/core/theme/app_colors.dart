import 'package:noteswidgetapp/core/theme/theme_service.dart';
import 'package:flutter/material.dart';

class AppColors {
  // Core palette
  static const Color bg = Color(0xffffefd6);
  static const Color container = Color(0xfff6d6a4);
  static const Color selected = Color(0xff4a1800);

  // Background
  static Color get bgColor => ThemeService.instance.isDarkMode ? bg : bg;

  static Color get containerColor =>
      ThemeService.instance.isDarkMode ? container : container;

  static Color get selectedColor =>
      ThemeService.instance.isDarkMode ? selected : selected;

  static Color get primaryColor =>
      ThemeService.instance.isDarkMode ? selected : selected;

  static Color get secondaryColor =>
      ThemeService.instance.isDarkMode ? container.withValues(alpha: 0.6) : container.withValues(alpha: 0.6);

  static Color get darkBgColor =>
      ThemeService.instance.isDarkMode ? selected : selected;

  static Color get cardColor =>
      ThemeService.instance.isDarkMode ? container.withValues(alpha: 0.5) : container.withValues(alpha: 0.45);

  static Color transparent = Colors.transparent;

  // Text
  static Color get textColor =>
      ThemeService.instance.isDarkMode ? selected : selected;

  static Color get textColor1 =>
      ThemeService.instance.isDarkMode ? Colors.white : Colors.white;

  static Color get textColor2 =>
      ThemeService.instance.isDarkMode ? selected.withValues(alpha: 0.55) : selected.withValues(alpha: 0.55);

  static Color get textColorRed =>
      ThemeService.instance.isDarkMode ? const Color(0xffC62828) : const Color(0xffC62828);

  static Color get textColorGreen =>
      ThemeService.instance.isDarkMode ? const Color(0xff2E7D32) : const Color(0xff2E7D32);

  static Color get textColorPrimary =>
      ThemeService.instance.isDarkMode ? selected : selected;

  // Text fields
  static Color get textFieldBorderColor =>
      ThemeService.instance.isDarkMode ? selected.withValues(alpha: 0.15) : selected.withValues(alpha: 0.15);

  static Color get textFieldBorderErrorColor =>
      ThemeService.instance.isDarkMode ? textColorRed : textColorRed;

  static Color get textFieldPlaceHolderColor =>
      ThemeService.instance.isDarkMode ? selected.withValues(alpha: 0.4) : selected.withValues(alpha: 0.4);

  static Color get textFieldTextColor =>
      ThemeService.instance.isDarkMode ? selected : selected;

  static Color get textFieldTextColor1 =>
      ThemeService.instance.isDarkMode ? Colors.white : Colors.white;

  static Color get textFieldHintColor =>
      ThemeService.instance.isDarkMode ? selected.withValues(alpha: 0.4) : selected.withValues(alpha: 0.4);

  static Color get textFieldBorderColorSlct =>
      ThemeService.instance.isDarkMode ? selected : selected;

  static Color get textFieldSelectedBg =>
      ThemeService.instance.isDarkMode ? container.withValues(alpha: 0.5) : container.withValues(alpha: 0.5);

  static Color get textFieldSelectedBorder =>
      ThemeService.instance.isDarkMode ? selected : selected;

  // Glass
  static Color get glassFill =>
      ThemeService.instance.isDarkMode ? container.withValues(alpha: 0.28) : container.withValues(alpha: 0.28);

  static Color get glassBorder =>
      ThemeService.instance.isDarkMode ? Colors.white.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.45);

  static Color get glassFocusFill =>
      ThemeService.instance.isDarkMode ? container.withValues(alpha: 0.18) : container.withValues(alpha: 0.18);

  static Color get glassFocusBorder =>
      ThemeService.instance.isDarkMode ? selected.withValues(alpha: 0.22) : selected.withValues(alpha: 0.22);

  static Color get glassHighlightFill =>
      ThemeService.instance.isDarkMode ? container.withValues(alpha: 0.22) : container.withValues(alpha: 0.22);

  static Color get glassHighlightBorder =>
      ThemeService.instance.isDarkMode ? selected.withValues(alpha: 0.2) : selected.withValues(alpha: 0.2);

  static Color get glassSelectedFill =>
      ThemeService.instance.isDarkMode ? selected.withValues(alpha: 0.75) : selected.withValues(alpha: 0.75);

  // Status bar
  static Color get statusBarActiveColor =>
      ThemeService.instance.isDarkMode ? selected : selected;

  static Color get statusBarInActiveColor =>
      ThemeService.instance.isDarkMode ? selected.withValues(alpha: 0.3) : selected.withValues(alpha: 0.3);

  // Icons
  static Color get iconColorBlack =>
      ThemeService.instance.isDarkMode ? selected : selected;

  static Color get iconColorWhite =>
      ThemeService.instance.isDarkMode ? Colors.white : Colors.white;

  static Color get iconColorGrey =>
      ThemeService.instance.isDarkMode ? selected.withValues(alpha: 0.45) : selected.withValues(alpha: 0.45);

  static Color get borderColor =>
      ThemeService.instance.isDarkMode ? selected.withValues(alpha: 0.12) : selected.withValues(alpha: 0.12);

  static Color get appBarColor =>
      ThemeService.instance.isDarkMode ? bgColor : bgColor;

  static Color get appBarTextColor =>
      ThemeService.instance.isDarkMode ? textColor : textColor;

  static Color get horizontalCardActiveBgColor =>
      ThemeService.instance.isDarkMode ? selected.withValues(alpha: 0.12) : selected.withValues(alpha: 0.12);

  // Buttons
  static Color get btnColorPrimary =>
      ThemeService.instance.isDarkMode ? selected : selected;

  static Color get btnColorSecondary =>
      ThemeService.instance.isDarkMode ? container.withValues(alpha: 0.6) : container.withValues(alpha: 0.6);

  static Color get btnColorLight =>
      ThemeService.instance.isDarkMode ? container.withValues(alpha: 0.4) : container.withValues(alpha: 0.4);

  static Color get btnDisabledColor =>
      ThemeService.instance.isDarkMode ? selected.withValues(alpha: 0.25) : selected.withValues(alpha: 0.25);

  static Color get btnColorRed =>
      ThemeService.instance.isDarkMode ? textColorRed : textColorRed;

  static Color get btnDisabledLightGreyColor =>
      ThemeService.instance.isDarkMode ? selected.withValues(alpha: 0.3) : selected.withValues(alpha: 0.3);

  static Color get btnLavenderColor =>
      ThemeService.instance.isDarkMode ? container.withValues(alpha: 0.5) : container.withValues(alpha: 0.5);

  // Navbar
  static Color get activeNavBarIconColor =>
      ThemeService.instance.isDarkMode ? selected : selected;

  static Color get inActiveNavBarIconColor =>
      ThemeService.instance.isDarkMode ? selected.withValues(alpha: 0.4) : selected.withValues(alpha: 0.4);

  // Shimmer
  static Color get shimmerBaseColor =>
      ThemeService.instance.isDarkMode ? container : container.withValues(alpha: 0.5);

  static Color get shimmerHighlightColor =>
      ThemeService.instance.isDarkMode ? bg : Colors.white.withValues(alpha: 0.6);
}
