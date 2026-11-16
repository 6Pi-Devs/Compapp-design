import 'dart:math' as math;

import 'package:flutter/rendering.dart';

class _EqualPairParentData extends ContainerBoxParentData<RenderBox>;

/// How a pair is laid out for some constraints.
class _PairPlan {
  const new({
    required this.size,
    required this.childConstraints,
    required this.stacked,
  });

  final Size size;
  final BoxConstraints childConstraints;
  final bool stacked;
}

/// The render object of `EqualPair`.
class RenderEqualPair extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _EqualPairParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _EqualPairParentData> {
  new(double spacing, TextDirection textDirection)
    : _spacing = spacing,
      _textDirection = textDirection;

  double _spacing;
  double get spacing => _spacing;
  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox get first => firstChild!;
  RenderBox get second => childAfter(first)!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _EqualPairParentData) {
      child.parentData = _EqualPairParentData();
    }
  }

  _PairPlan _plan(BoxConstraints constraints) {
    final maxWidth = constraints.maxWidth;
    final half = (maxWidth - _spacing) / 2;
    final sideBySide =
        !maxWidth.isFinite ||
        (first.getMinIntrinsicWidth(double.infinity) <= half &&
            second.getMinIntrinsicWidth(double.infinity) <= half);

    if (!sideBySide) {
      final loose = BoxConstraints(
        minWidth: maxWidth,
        maxWidth: maxWidth,
        maxHeight: constraints.maxHeight,
      );
      final heights = [
        first.getDryLayout(loose).height,
        second.getDryLayout(loose).height,
      ];
      return _PairPlan(
        size: constraints.constrain(
          Size(maxWidth, heights[0] + _spacing + heights[1]),
        ),
        childConstraints: loose,
        stacked: true,
      );
    }

    final width = maxWidth.isFinite
        ? half
        : math.max(
            first.getMaxIntrinsicWidth(double.infinity),
            second.getMaxIntrinsicWidth(double.infinity),
          );
    final tightWidth = BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: constraints.maxHeight,
    );
    final height = math.max(
      first.getDryLayout(tightWidth).height,
      second.getDryLayout(tightWidth).height,
    );
    return _PairPlan(
      size: constraints.constrain(Size(2 * width + _spacing, height)),
      childConstraints: BoxConstraints.tightFor(width: width, height: height),
      stacked: false,
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    first.getMinIntrinsicWidth(height),
    second.getMinIntrinsicWidth(height),
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      2 *
          math.max(
            first.getMaxIntrinsicWidth(height),
            second.getMaxIntrinsicWidth(height),
          ) +
      _spacing;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _plan(BoxConstraints(maxWidth: width)).size.height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) => _plan(constraints).size;

  @override
  void performLayout() {
    final plan = _plan(constraints);
    size = plan.size;
    final children = getChildrenAsList();
    for (final child in children.take(2)) {
      child.layout(plan.childConstraints, parentUsesSize: true);
    }
    for (final (index, child) in children.indexed) {
      final side = index % 2;
      if (index >= 2) {
        child.layout(BoxConstraints.tight(children[side].size));
      }
      final Offset offset;
      if (plan.stacked) {
        offset = Offset(0, side == 0 ? 0 : first.size.height + _spacing);
      } else {
        final slot = _textDirection == TextDirection.ltr ? side : 1 - side;
        offset = Offset(slot * (children[side].size.width + _spacing), 0);
      }
      (child.parentData! as _EqualPairParentData).offset = offset;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
