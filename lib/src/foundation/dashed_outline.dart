import 'dart:math' as math;

import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:flutter/painting.dart';

/// Strokes [outline] as dashes on [canvas]: a dash is [AppSizes.dash] and a gap
/// [AppSizes.dashGap] times [width], so the pattern scales with the stroke.
///
/// [outline] is the path of the stroke centre, so a caller that wants the
/// stroke inside its box deflates the box by half of [width] first.
void paintDashedOutline(
  Canvas canvas,
  RRect outline, {
  required Color color,
  required double width,
}) {
  final path = Path()..addRRect(outline);
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width;
  final dash = width * AppSizes.dash;
  final period = dash + width * AppSizes.dashGap;
  for (final metric in path.computeMetrics()) {
    for (var start = 0.0; start < metric.length; start += period) {
      canvas.drawPath(
        metric.extractPath(start, math.min(start + dash, metric.length)),
        paint,
      );
    }
  }
}
