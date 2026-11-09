/// Opacities of content drawn on a surface (`opacity.*`), not layers of a
/// widget state.
abstract final class AppOpacity {
  /// A label drawn on the inverse surface, such as a snackbar action, when its
  /// control is disabled (`opacity.disabled-inverse-label`). It keeps 4.5:1 in
  /// both themes.
  static const double disabledInverseLabel = 0.65;

  /// Every token by its JSON name, checked by the parity test.
  static const Map<String, double> values = {
    'disabled-inverse-label': disabledInverseLabel,
  };
}
