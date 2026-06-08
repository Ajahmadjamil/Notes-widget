import 'package:flutter/material.dart';

/// Identifiers for each cohesive app color preset.
enum AppThemeId {
  softCream,
  amberGlow,
  messagesLight,
  nordicSlate,
  androidDark,
}

extension AppThemeIdLabel on AppThemeId {
  String get displayName => switch (this) {
        AppThemeId.softCream => 'Soft Cream',
        AppThemeId.amberGlow => 'Amber Glow',
        AppThemeId.messagesLight => 'Messages Light',
        AppThemeId.nordicSlate => 'Nordic Slate',
        AppThemeId.androidDark => 'Android Dark',
      };

  static AppThemeId fromStorage(String? value) {
    const legacy = <String, AppThemeId>{
      'defaultTheme': AppThemeId.softCream,
      'sunnyYellow': AppThemeId.softCream,
      'vividOrange': AppThemeId.amberGlow,
      'androidLight': AppThemeId.messagesLight,
      'crimsonRush': AppThemeId.softCream,
      'royalViolet': AppThemeId.softCream,
      'whatsappDark': AppThemeId.androidDark,
      'googleDark': AppThemeId.androidDark,
      'oceanBreeze': AppThemeId.messagesLight,
      'neonHorizon': AppThemeId.nordicSlate,
    };
    if (value != null && legacy.containsKey(value)) {
      return legacy[value]!;
    }
    return AppThemeId.values.firstWhere(
      (id) => id.name == value,
      orElse: () => AppThemeId.softCream,
    );
  }
}

/// Semantic color tokens for a single cohesive theme.
class AppThemePalette {
  final String name;
  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color onBackground;
  final Color onPrimary;
  final Color previewPrimary;
  final Color previewSecondary;

  const AppThemePalette({
    required this.name,
    required this.brightness,
    required this.background,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.onBackground,
    required this.onPrimary,
    required this.previewPrimary,
    required this.previewSecondary,
  });

  Color get onSurfaceVariant => onBackground.withValues(alpha: 0.55);

  Color get cardColor => surface.withValues(
        alpha: brightness == Brightness.light ? 0.45 : 0.55,
      );

  Color get glassFill => surface.withValues(alpha: 0.28);

  Color get glassBorder => brightness == Brightness.light
      ? Colors.white.withValues(alpha: 0.45)
      : onBackground.withValues(alpha: 0.18);

  Color get glassFocusFill => surface.withValues(alpha: 0.18);

  Color get glassFocusBorder => primary.withValues(alpha: 0.22);

  Color get glassHighlightFill => surface.withValues(alpha: 0.22);

  Color get glassHighlightBorder => brightness == Brightness.light
      ? primary.withValues(alpha: 0.2)
      : primary.withValues(alpha: 0.4);

  Color get glassSelectedFill => primary.withValues(alpha: 0.75);

  Color get borderSubtle => onBackground.withValues(alpha: 0.12);

  Color get iconMuted => onBackground.withValues(alpha: 0.45);

  Color get statusBarInactive => onBackground.withValues(alpha: 0.3);

  Color get btnDisabled => onBackground.withValues(alpha: 0.25);

  Color get btnDisabledLight => onBackground.withValues(alpha: 0.3);

  Color get navInactive => onBackground.withValues(alpha: 0.4);

  Color get horizontalCardActive => primary.withValues(alpha: 0.12);

  Color get shimmerBase => brightness == Brightness.light
      ? surface.withValues(alpha: 0.5)
      : surface;

  Color get shimmerHighlight => brightness == Brightness.light
      ? Colors.white.withValues(alpha: 0.6)
      : background;
}

/// All preset palettes — high-contrast, no blue-tinted pairings.
abstract final class AppThemePalettes {
  static const softCream = AppThemePalette(
    name: 'Soft Cream',
    brightness: Brightness.light,
    background: Color(0xfffff8f0),
    surface: Color(0xfff5ede0),
    primary: Color(0xff6d4c41),
    secondary: Color(0xffefebe9),
    onBackground: Color(0xff3e2723),
    onPrimary: Color(0xffffffff),
    previewPrimary: Color(0xff6d4c41),
    previewSecondary: Color(0xfff5ede0),
  );

  static const amberGlow = AppThemePalette(
    name: 'Amber Glow',
    brightness: Brightness.light,
    background: Color(0xfffffcf5),
    surface: Color(0xfffff3d6),
    primary: Color(0xffbf360c),
    secondary: Color(0xffffcc80),
    onBackground: Color(0xff3e2723),
    onPrimary: Color(0xffffffff),
    previewPrimary: Color(0xffbf360c),
    previewSecondary: Color(0xffffcc80),
  );

  /// Google Messages light — white surfaces, green accent, no blue.
  static const messagesLight = AppThemePalette(
    name: 'Messages Light',
    brightness: Brightness.light,
    background: Color(0xffffffff),
    surface: Color(0xfff2f2f2),
    primary: Color(0xff188038),
    secondary: Color(0xffe8f5e9),
    onBackground: Color(0xff1c1c1c),
    onPrimary: Color(0xffffffff),
    previewPrimary: Color(0xff188038),
    previewSecondary: Color(0xffc8e6c9),
  );

  /// Neutral charcoal dark — warm gray accents, no blue/teal.
  static const nordicSlate = AppThemePalette(
    name: 'Nordic Slate',
    brightness: Brightness.dark,
    background: Color(0xff2b2b2b),
    surface: Color(0xff383838),
    primary: Color(0xffbcaaa4),
    secondary: Color(0xff424242),
    onBackground: Color(0xffeeeeee),
    onPrimary: Color(0xff212121),
    previewPrimary: Color(0xffbcaaa4),
    previewSecondary: Color(0xff424242),
  );

  /// Typical Android phone dark — #121212 surfaces, soft green accent.
  static const androidDark = AppThemePalette(
    name: 'Android Dark',
    brightness: Brightness.dark,
    background: Color(0xff121212),
    surface: Color(0xff1e1e1e),
    primary: Color(0xff81c784),
    secondary: Color(0xff2c2c2c),
    onBackground: Color(0xffe0e0e0),
    onPrimary: Color(0xff121212),
    previewPrimary: Color(0xff81c784),
    previewSecondary: Color(0xff2c2c2c),
  );

  static AppThemePalette forId(AppThemeId id) => switch (id) {
        AppThemeId.softCream => softCream,
        AppThemeId.amberGlow => amberGlow,
        AppThemeId.messagesLight => messagesLight,
        AppThemeId.nordicSlate => nordicSlate,
        AppThemeId.androidDark => androidDark,
      };

  static const errorRed = Color(0xffc62828);
  static const successGreen = Color(0xff2e7d32);
}
