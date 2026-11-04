import 'package:flutter/painting.dart';

abstract final class AppShadows {
  /// `elevation.sheet`: ink at 18%, in both themes.
  static const List<BoxShadow> sheet = [
    BoxShadow(
      color: Color.fromRGBO(28, 43, 34, 0.18),
      offset: Offset(0, -8),
      blurRadius: 32,
    ),
  ];

  /// Every token by its JSON name, checked by the parity test.
  static const Map<String, List<BoxShadow>> values = {'sheet': sheet};
}
