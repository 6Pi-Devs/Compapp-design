import 'package:compapp_design/src/foundation/render_equal_pair.dart';
import 'package:flutter/widgets.dart';

/// Lays out two children as equal halves side by side, or one under the other
/// when the longest word of either does not fit its half. A `LayoutBuilder`
/// would do the same, but the golden harness measures intrinsic sizes, which it
/// cannot answer, so this render object does.
///
/// Further children, if any, are laid out and placed like the child of their
/// side (the third like the first, the fourth like the second, and so on), so a
/// widget that extends this one can draw extra layers over each side.
class EqualPair extends MultiChildRenderObjectWidget {
  const new({
    required this.spacing,
    required this.textDirection,
    required super.children,
    super.key,
  }) : assert(
         children.length >= 2,
         'EqualPair lays out two children, one per side: it got fewer.',
       );

  final double spacing;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderEqualPair(spacing, textDirection);

  @override
  void updateRenderObject(BuildContext context, RenderEqualPair renderObject) {
    renderObject
      ..spacing = spacing
      ..textDirection = textDirection;
  }
}
