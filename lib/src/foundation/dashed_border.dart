import 'package:compapp_design/src/foundation/dashed_outline.dart';
import 'package:flutter/painting.dart';

/// A rounded rectangle whose side is dashed. Material has no dashed border.
class DashedBorder extends RoundedRectangleBorder {
  const new({super.borderRadius, super.side});

  @override
  DashedBorder copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
  }) => DashedBorder(
    side: side ?? this.side,
    borderRadius: borderRadius ?? this.borderRadius,
  );

  @override
  ShapeBorder scale(double t) =>
      DashedBorder(side: side.scale(t), borderRadius: borderRadius * t);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    paintDashedOutline(
      canvas,
      borderRadius.resolve(textDirection).toRRect(rect).deflate(side.width / 2),
      color: side.color,
      width: side.width,
    );
  }
}
