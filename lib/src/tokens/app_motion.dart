import 'package:flutter/animation.dart';

abstract final class AppMotion {
  static const Duration presence = Duration(milliseconds: 600);
  static const Curve presenceCurve = Curves.easeOut;

  /// Period of the repeating "in use" breathing animation.
  static const Duration inUse = Duration(milliseconds: 4000);
  static const Curve inUseCurve = Curves.easeInOut;

  /// Durations by JSON name, compared against the JSON by the parity test.
  static const Map<String, Duration> values = {
    'presence': presence,
    'in-use': inUse,
  };

  /// Curves by JSON name, compared against the JSON by the parity test.
  static const Map<String, Curve> curves = {
    'presence': presenceCurve,
    'in-use': inUseCurve,
  };
}
