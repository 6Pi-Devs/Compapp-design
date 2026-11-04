import 'package:compapp_design/src/models/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:path_parsing/path_parsing.dart';

/// A stroke glyph of the [AppIcons] set.
///
/// Like Material's `Icon`, [size] and [color] come from the prop, then from the
/// ambient [IconTheme] (24 by default, which also supplies the opacity). The
/// glyph is centered in a square of that size, drawn at the scale of the grid
/// (or of the largest square the parent leaves it), and mirrored in
/// right-to-left text when the glyph is directional.
///
/// The icon is decorative and excluded from semantics unless [semanticLabel]
/// is a non-empty string, which exposes it as an image with that label, in a
/// node of its own so it does not merge into an ancestor button.
class AppIcon extends StatelessWidget {
  const new(this.icon, {this.size, this.color, this.semanticLabel, super.key});

  final AppIcons icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final dimension = size ?? iconTheme.size!;
    // IconTheme.of is concrete, so its size and color are never null.
    final base = color ?? iconTheme.color!;
    final resolvedColor = base.withValues(
      alpha: base.a * (iconTheme.opacity ?? 1),
    );

    Widget glyph = CustomPaint(
      size: Size.square(dimension),
      painter: _GlyphPainter(icon, resolvedColor),
    );
    if (icon.matchTextDirection &&
        Directionality.of(context) == TextDirection.rtl) {
      glyph = Transform.flip(flipX: true, child: glyph);
    }
    glyph = SizedBox.square(
      dimension: dimension,
      child: Center(child: glyph),
    );

    final label = semanticLabel;
    if (label == null || label.isEmpty) return ExcludeSemantics(child: glyph);
    return Semantics(container: true, image: true, label: label, child: glyph);
  }
}

class _GlyphPainter extends CustomPainter {
  const new(this.icon, this.color);

  final AppIcons icon;
  final Color color;

  static final Map<AppIcons, Path> _paths = {};

  static Path _pathOf(AppIcons icon) => _paths.putIfAbsent(icon, () {
    final builder = _PathBuilder();
    writeSvgPathDataToPath(icon.pathData, builder);
    return builder.path;
  });

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final scale = side / AppIcons.gridSize;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppIcons.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..translate((size.width - side) / 2, (size.height - side) / 2)
      ..scale(scale)
      ..drawPath(_pathOf(icon), paint);
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.icon != icon || oldDelegate.color != color;
}

class _PathBuilder implements PathProxy {
  final Path path = Path();

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}
