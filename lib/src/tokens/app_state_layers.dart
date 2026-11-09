/// Opacities of the ink or foreground drawn over a fill for a widget state
/// (`state-layer.*`).
abstract final class AppStateLayers {
  /// Ink over a primary fill when pressed.
  static const double pressedPrimary = 0.12;

  /// Ink over a surface fill when pressed. A control on the inverse surface
  /// (the action of a snackbar) reuses it for hover and focus, over its own
  /// soft primary.
  static const double pressedSecondary = 0.08;

  /// Ink over a danger fill when pressed.
  static const double pressedDanger = 0.16;

  /// Track of a spinner drawn on a solid fill.
  static const double spinnerTrack = 0.35;

  /// Every token by its JSON name, checked by the parity test.
  static const Map<String, double> values = {
    'pressed-primary': pressedPrimary,
    'pressed-secondary': pressedSecondary,
    'pressed-danger': pressedDanger,
    'spinner-track': spinnerTrack,
  };
}
