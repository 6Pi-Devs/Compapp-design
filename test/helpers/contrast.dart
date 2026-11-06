import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG contrast ratio of two opaque colors.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Fails when any pair is below [minimum]. A pair is `(foreground,
/// background)` under a readable name, so the failure says which one.
void expectContrast(
  Map<String, (Color, Color)> pairs, {
  required double minimum,
  required String reason,
}) {
  final failing = [
    for (final MapEntry(key: name, value: (a, b)) in pairs.entries)
      if (contrastRatio(a, b) < minimum)
        '$name: ${contrastRatio(a, b).toStringAsFixed(2)}',
  ];
  expect(failing, isEmpty, reason: 'below $minimum:1 in $reason');
}
