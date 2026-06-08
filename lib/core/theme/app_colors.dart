import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/theme/app_theme_palette.dart';
import 'package:noteswidgetapp/core/theme/theme_service.dart';

class AppColors {
  static AppThemePalette get _p => ThemeService.instance.palette;

  // Core palette (dynamic per theme)
  static Color get bg => _p.background;
  static Color get container => _p.surface;
  static Color get selected => _p.primary;

  // Background
  static Color get bgColor => _p.background;

  static Color get containerColor => _p.surface;

  static Color get selectedColor => _p.primary;

  static Color get primaryColor => _p.primary;

  static Color get secondaryColor => _p.secondary.withValues(alpha: 0.6);

  static Color get darkBgColor => _p.primary;

  static Color get cardColor => _p.cardColor;

  static Color transparent = Colors.transparent;

  // Text
  static Color get textColor => _p.onBackground;

  static Color get textColor1 => _p.onPrimary;

  static Color get textColor2 => _p.onSurfaceVariant;

  static Color get textColorRed => AppThemePalettes.errorRed;

  static Color get textColorGreen => AppThemePalettes.successGreen;

  static Color get textColorPrimary => _p.onBackground;

  // Text fields
  static Color get textFieldBorderColor => _p.onBackground.withValues(alpha: 0.15);

  static Color get textFieldBorderErrorColor => textColorRed;

  static Color get textFieldPlaceHolderColor =>
      _p.onBackground.withValues(alpha: 0.4);

  static Color get textFieldTextColor => _p.onBackground;

  static Color get textFieldTextColor1 => _p.onPrimary;

  static Color get textFieldHintColor => _p.onBackground.withValues(alpha: 0.4);

  static Color get textFieldBorderColorSlct => _p.primary;

  static Color get textFieldSelectedBg => _p.surface.withValues(alpha: 0.5);

  static Color get textFieldSelectedBorder => _p.primary;

  // Glass
  static Color get glassFill => _p.glassFill;

  static Color get glassBorder => _p.glassBorder;

  static Color get glassFocusFill => _p.glassFocusFill;

  static Color get glassFocusBorder => _p.glassFocusBorder;

  static Color get glassHighlightFill => _p.glassHighlightFill;

  static Color get glassHighlightBorder => _p.glassHighlightBorder;

  static Color get glassSelectedFill => _p.glassSelectedFill;

  // Status bar
  static Color get statusBarActiveColor => _p.primary;

  static Color get statusBarInActiveColor => _p.statusBarInactive;

  // Icons
  static Color get iconColorBlack => _p.onBackground;

  static Color get iconColorWhite => _p.onPrimary;

  static Color get iconColorGrey => _p.iconMuted;

  static Color get borderColor => _p.borderSubtle;

  static Color get appBarColor => _p.background;

  static Color get appBarTextColor => _p.onBackground;

  static Color get horizontalCardActiveBgColor => _p.horizontalCardActive;

  // Buttons
  static Color get btnColorPrimary => _p.primary;

  static Color get btnColorSecondary => _p.secondary.withValues(alpha: 0.6);

  static Color get btnColorLight => _p.surface.withValues(alpha: 0.4);

  static Color get btnDisabledColor => _p.btnDisabled;

  static Color get btnColorRed => textColorRed;

  static Color get btnDisabledLightGreyColor => _p.btnDisabledLight;

  static Color get btnLavenderColor => _p.surface.withValues(alpha: 0.5);

  // Navbar
  static Color get activeNavBarIconColor => _p.primary;

  static Color get inActiveNavBarIconColor => _p.navInactive;

  // Shimmer
  static Color get shimmerBaseColor => _p.shimmerBase;

  static Color get shimmerHighlightColor => _p.shimmerHighlight;
}
