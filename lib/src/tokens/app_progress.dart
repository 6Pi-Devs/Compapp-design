/// Numbers of the progress atoms (`progress.*`).
abstract final class AppProgress {
  /// Arc of an in-use ring with no known end, as a fraction of the circle
  /// (`progress.ring-sweep`).
  static const double ringSweep = 0.3;

  /// Lowest opacity of the arc while it breathes (`progress.ring-breathe`).
  static const double ringBreatheOpacity = 0.4;

  /// Every token by its JSON name, checked by the parity test.
  static const Map<String, double> values = {
    'ring-sweep': ringSweep,
    'ring-breathe': ringBreatheOpacity,
  };
}
