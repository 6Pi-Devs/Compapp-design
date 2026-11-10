import 'package:compapp_design/src/foundation/dashed_outline.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:flutter/rendering.dart';

/// Paints a dashed rounded outline just inside the box it is given, for a box
/// that has no shape of its own to carry a `DashedBorder`.
class DashedOutlinePainter extends CustomPainter {
  const new({
    required this.color,
    required this.radius,
    this.width = AppSizes.borderDashed,
  });

  final Color color;
  final double radius;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    paintDashedOutline(
      canvas,
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(radius),
      ).deflate(width / 2),
      color: color,
      width: width,
    );
  }

  @override
  bool shouldRepaint(DashedOutlinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.width != width;
}
