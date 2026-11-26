import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Gives its child at least [minWidth] of width, even when its parent is
/// narrower: the child is centered and spills over the sides, so the node of a
/// button in a narrow column is still a full tap target. It takes the width
/// and the intrinsic widths of the column, not of the wider child.
class Widen extends SingleChildRenderObjectWidget {
  const new({required this.minWidth, required super.child, super.key});

  final double minWidth;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderWiden(minWidth);

  @override
  void updateRenderObject(BuildContext context, RenderWiden renderObject) {
    renderObject.minWidth = minWidth;
  }
}

/// The render object of [Widen].
class RenderWiden extends RenderShiftedBox {
  new(this._minWidth) : super(null);

  double _minWidth;
  double get minWidth => _minWidth;
  set minWidth(double value) {
    if (value == _minWidth) return;
    _minWidth = value;
    markNeedsLayout();
  }

  BoxConstraints _childConstraints(BoxConstraints constraints) {
    if (!constraints.hasBoundedWidth) return constraints.loosen();
    final width = math.max(_minWidth, constraints.maxWidth);
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: constraints.maxHeight,
    );
  }

  Size _sizeFor(BoxConstraints constraints, Size child) =>
      constraints.constrain(
        Size(
          constraints.hasBoundedWidth ? constraints.maxWidth : child.width,
          child.height,
        ),
      );

  @override
  double computeMinIntrinsicWidth(double height) =>
      child?.getMinIntrinsicWidth(height) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      child?.getMaxIntrinsicWidth(height) ?? 0;

  @override
  double computeMinIntrinsicHeight(double width) =>
      child?.getMinIntrinsicHeight(math.max(_minWidth, width)) ?? 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      child?.getMaxIntrinsicHeight(math.max(_minWidth, width)) ?? 0;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    return _sizeFor(
      constraints,
      child.getDryLayout(_childConstraints(constraints)),
    );
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_childConstraints(constraints), parentUsesSize: true);
    size = _sizeFor(constraints, child.size);
    (child.parentData! as BoxParentData).offset = Offset(
      (size.width - child.size.width) / 2,
      0,
    );
  }
}
