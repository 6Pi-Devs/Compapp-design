import 'package:flutter/painting.dart';

abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;

  /// Fraction of the pebble size used as its corner radius.
  static const double pebbleFraction = 0.3;

  /// Every token by its JSON name, checked by the parity test.
  static const Map<String, double> values = {
    'xs': xs,
    'sm': sm,
    'md': md,
    'lg': lg,
    'pebble': pebbleFraction,
  };

  static BorderRadius pebble(double size) =>
      BorderRadius.circular(size * pebbleFraction);
}
