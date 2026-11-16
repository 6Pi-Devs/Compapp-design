import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// The two children of a [HeaderBody].
enum HeaderBodySlot { header, body }

/// A header over a body, scrolled by [offset] only when the header is too tall
/// to pin.
///
/// The header takes the height it needs and the body the rest of a bounded
/// height, so a body that scrolls scrolls within it (a sheet, a form page).
/// When the header alone is taller than half of a bounded height, both take
/// their own height and the whole scrolls by [offset], so the body is never
/// left with nothing.
/// Without a bound on the height it is a column, which a flex child of a column
/// is not (it asserts) and which the golden harness measures with intrinsic
/// sizes.
class HeaderBody
    extends SlottedMultiChildRenderObjectWidget<HeaderBodySlot, RenderBox> {
  const new({
    required this.offset,
    required this.header,
    required this.body,
    super.key,
  });

  final ViewportOffset offset;
  final Widget header;
  final Widget body;

  @override
  Iterable<HeaderBodySlot> get slots => HeaderBodySlot.values;

  @override
  Widget? childForSlot(HeaderBodySlot slot) => switch (slot) {
    HeaderBodySlot.header => header,
    HeaderBodySlot.body => body,
  };

  @override
  SlottedContainerRenderObjectMixin<HeaderBodySlot, RenderBox>
  createRenderObject(BuildContext context) => RenderHeaderBody(offset);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderHeaderBody renderObject,
  ) {
    renderObject.offset = offset;
  }
}

typedef _HeaderBodyLayout = ({Size header, Size body, bool together});

class RenderHeaderBody extends RenderBox
    with SlottedContainerRenderObjectMixin<HeaderBodySlot, RenderBox>
    implements RenderAbstractViewport {
  new(this._offset);

  ViewportOffset _offset;
  double _maxExtent = 0;

  ViewportOffset get offset => _offset;

  set offset(ViewportOffset value) {
    if (value == _offset) return;
    if (attached) _offset.removeListener(markNeedsPaint);
    _offset = value;
    if (attached) _offset.addListener(markNeedsPaint);
    markNeedsLayout();
  }

  RenderBox get _header => childForSlot(HeaderBodySlot.header)!;
  RenderBox get _body => childForSlot(HeaderBodySlot.body)!;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _offset.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) child.parentData = BoxParentData();
  }

  /// The two sizes: the header at its own height, then the body given what the
  /// header leaves of a bounded height, or its own height when the header is
  /// taller than half of it.
  _HeaderBodyLayout _layout(BoxConstraints constraints, ChildLayouter layout) {
    final width = constraints.maxWidth;
    final header = layout(
      _header,
      BoxConstraints(minWidth: width, maxWidth: width),
    );
    final together =
        constraints.hasBoundedHeight &&
        header.height > constraints.maxHeight / 2;
    final room = constraints.hasBoundedHeight && !together
        ? math.max<double>(0, constraints.maxHeight - header.height)
        : double.infinity;
    final body = layout(
      _body,
      BoxConstraints(minWidth: width, maxWidth: width, maxHeight: room),
    );
    return (header: header, body: body, together: together);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final sizes = _layout(constraints, ChildLayoutHelper.dryLayoutChild);
    return constraints.constrain(
      Size(constraints.maxWidth, sizes.header.height + sizes.body.height),
    );
  }

  @override
  void performLayout() {
    final sizes = _layout(constraints, ChildLayoutHelper.layoutChild);
    final content = sizes.header.height + sizes.body.height;
    (_header.parentData! as BoxParentData).offset = Offset.zero;
    (_body.parentData! as BoxParentData).offset = Offset(
      0,
      sizes.header.height,
    );
    size = constraints.constrain(Size(constraints.maxWidth, content));
    _maxExtent = math.max<double>(0, content - size.height);
    _offset
      ..applyViewportDimension(size.height)
      ..applyContentDimensions(0, _maxExtent);
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _header.getMinIntrinsicWidth(height),
    _body.getMinIntrinsicWidth(height),
  );

  @override
  double computeMaxIntrinsicWidth(double height) => math.max(
    _header.getMaxIntrinsicWidth(height),
    _body.getMaxIntrinsicWidth(height),
  );

  @override
  double computeMinIntrinsicHeight(double width) =>
      _header.getMinIntrinsicHeight(width) + _body.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _header.getMaxIntrinsicHeight(width) + _body.getMaxIntrinsicHeight(width);

  double get _scrolled => _offset.hasPixels ? _offset.pixels : 0;

  Offset _childOffset(RenderBox child) =>
      (child.parentData! as BoxParentData).offset - Offset(0, _scrolled);

  @override
  void paint(PaintingContext context, Offset offset) {
    context.pushClipRect(needsCompositing, offset, Offset.zero & size, (
      context,
      offset,
    ) {
      for (final child in [_header, _body]) {
        context.paintChild(child, offset + _childOffset(child));
      }
    });
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final offset = _childOffset(child);
    transform.translateByDouble(offset.dx, offset.dy, 0, 1);
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) => Offset.zero & size;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in [_body, _header]) {
      final hit = result.addWithPaintOffset(
        offset: _childOffset(child),
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }

  @override
  RevealedOffset getOffsetToReveal(
    RenderObject target,
    double alignment, {
    Rect? rect,
    Axis? axis,
  }) {
    final pixels = _scrolled;
    if (axis == Axis.horizontal) {
      return RevealedOffset(offset: pixels, rect: rect ?? target.paintBounds);
    }
    final bounds = MatrixUtils.transformRect(
      target.getTransformTo(this),
      rect ?? target.paintBounds,
    );
    final to = (pixels + bounds.top - (size.height - bounds.height) * alignment)
        .clamp(0, _maxExtent)
        .toDouble();
    return RevealedOffset(
      offset: to,
      rect: bounds.shift(Offset(0, pixels - to)),
    );
  }

  @override
  void showOnScreen({
    RenderObject? descendant,
    Rect? rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    if (!_offset.allowImplicitScrolling) {
      return super.showOnScreen(
        descendant: descendant,
        rect: rect,
        duration: duration,
        curve: curve,
      );
    }
    final newRect = RenderViewportBase.showInViewport(
      descendant: descendant,
      viewport: this,
      offset: _offset,
      rect: rect,
      duration: duration,
      curve: curve,
    );
    super.showOnScreen(rect: newRect, duration: duration, curve: curve);
  }
}
