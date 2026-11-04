abstract final class AppSizes {
  /// Smallest hit area of an interactive element (`target.min`). Passes
  /// `androidTapTargetGuideline`.
  static const double minTarget = 48;

  /// Smallest drawn size of an interactive element (`target.min` drawn).
  static const double minDrawn = 44;

  /// Width of a flat border (`elevation.flat`).
  static const double hairline = 1;

  /// Every token by its JSON name, checked by the parity test.
  static const Map<String, double> values = {
    'target.min': minTarget,
    'target.min.drawn': minDrawn,
    'elevation.flat.width': hairline,
  };
}
