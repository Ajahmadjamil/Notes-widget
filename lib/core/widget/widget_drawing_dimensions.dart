/// Shared note handwriting pad matches the home widget: full width, 2 launcher rows.
class WidgetDrawingDimensions {
  WidgetDrawingDimensions._();

  /// Standard 4-cell widget width on Android launchers (76dp per cell).
  static const double referenceWidthDp = 304;

  /// Two launcher rows (70dp each).
  static const double referenceHeightDp = 140;

  static const double aspectRatio = referenceWidthDp / referenceHeightDp;

  /// Logical canvas height for a given pad width (same proportions as the widget).
  static double heightForWidth(double width) => width / aspectRatio;

  /// Pixel dimensions used when rendering the widget PNG (2× for sharpness).
  static ({int width, int height}) renderPixelsForWidth(double logicalWidth) {
    final logicalHeight = heightForWidth(logicalWidth);
    return (
      width: (logicalWidth * 2).round(),
      height: (logicalHeight * 2).round(),
    );
  }
}
