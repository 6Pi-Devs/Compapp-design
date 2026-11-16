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

  /// While the border animates it stays dashed: the inherited `lerpFrom` would
  /// hand back a solid [RoundedRectangleBorder].
  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is RoundedRectangleBorder) {
      return DashedBorder(
        side: BorderSide.lerp(a.side, side, t),
        borderRadius: BorderRadiusGeometry.lerp(
          a.borderRadius,
          borderRadius,
          t,
        )!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is RoundedRectangleBorder) {
      return DashedBorder(
        side: BorderSide.lerp(side, b.side, t),
        borderRadius: BorderRadiusGeometry.lerp(
          borderRadius,
          b.borderRadius,
          t,
        )!,
      );
    }
    return super.lerpTo(b, t);
  }

  /// Draws nothing for a side with no style or no width (a zero width is
  /// Flutter's hairline, which a dash pattern cannot scale from). The stroke
  /// follows [BorderSide.strokeAlign]: inside the box, centred on its edge or
  /// outside it.
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width <= 0) return;
    paintDashedOutline(
      canvas,
      borderRadius
          .resolve(textDirection)
          .toRRect(rect)
          .deflate(-side.strokeAlign * side.width / 2),
      color: side.color,
      width: side.width,
    );
  }
}
