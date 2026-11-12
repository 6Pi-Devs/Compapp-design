import 'dart:math' as math;

import 'package:compapp_design/src/atoms/app_button.dart';
import 'package:compapp_design/src/models/item_sheet_mode.dart';
import 'package:compapp_design/src/models/item_sheet_view.dart';
import 'package:compapp_design/src/models/item_usage.dart';
import 'package:compapp_design/src/molecules/member_row.dart';
import 'package:compapp_design/src/molecules/sheet_header.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_shadows.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// The bottom sheet of a shared item (the washer, the oven): a question about
/// it, the person using it, a line of explanation and the button that
/// confirms.
///
/// It composes [SheetHeader], [MemberRow] and [AppButton] on the sheet
/// surface (the sheet fill, top corners and the sheet shadow), and takes plain
/// data ([ItemSheetView]) and two callbacks: [onConfirm] when the button is
/// pressed and [onClose] by the close button or the Escape key. The view says
/// what is asked: [ItemSheetMode.start], [ItemSheetMode.finish],
/// [ItemSheetMode.nudge] and [ItemSheetMode.remind] confirm it, and
/// [ItemSheetMode.cooldown] shows the same button disabled while the message
/// says how long is left. The app owns the words, the person using the item
/// and the clock, and the route that shows the sheet.
///
/// The sheet is modal and meant for `showModalBottomSheet(isScrollControlled:
/// true, backgroundColor: Colors.transparent, ...)`: the sheet draws its own
/// surface, and `isScrollControlled` lets it use the height it needs. The
/// header stays pinned and the body (the person, the message and the button)
/// scrolls inside the sheet when the height is bounded, so at large text on a
/// short screen the button is reached by scrolling and nothing is clipped. When
/// the header alone would take more than half of a bounded height (the default
/// route, which caps a sheet at 9/16 of the screen, at 200% text), it stops
/// being pinned and scrolls together with the body, so the button is still
/// reached. With no bound on the height (a golden, a test) the sheet takes the
/// height of its content.
///
/// For assistive technology the title is a heading that names the route (the
/// route that shows the sheet is the route scope, so the title is not said
/// twice), and focus starts on the title: once the sheet has been laid out the
/// title takes focus (and, with a keyboard, its ring), so the next Tab reaches
/// the close button. Focus is asked for once, when the sheet opens: a new view
/// never takes it back (a new item id mounts the content again, and focus falls
/// back through the scope's history), and a new view that disables the
/// button while it has focus moves focus to the title instead of letting it
/// fall to the route (in directional navigation a disabled button can keep
/// focus, so a view that stays in cooldown leaves it alone).
///
/// [onClose] is called by the close button and by Escape while focus is inside
/// the sheet. The barrier, a drag down and the route's own dismiss action do
/// not reach it: the app must treat the pop result of the route as a close
/// too.
///
/// The usage is one merged node (the member's spoken label, then the
/// subtitle), the message a plain text and the button a button named by its
/// label. The button is the last child, so it keeps its element and focus when
/// the person or the message above it come and go.
///
/// It needs a bounded width, grows with large text instead of clipping, nothing
/// clamped, and mirrors in right-to-left. It has no motion of its own.
class ItemSheet extends StatefulWidget {
  const new({
    required this.view,
    required this.onConfirm,
    required this.onClose,
    super.key,
  });

  final ItemSheetView view;

  /// Called by the confirm button, which is disabled while the view waits.
  final VoidCallback onConfirm;

  /// Called by the close button and by Escape.
  final VoidCallback onClose;

  static const double _gap = AppSpacing.sm + AppSpacing.xs;

  @override
  State<ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<ItemSheet> {
  final FocusNode _title = FocusNode(debugLabel: 'ItemSheet.title');

  /// Holds no focus of its own: it only tells whether the confirm button has
  /// it, so the sheet can move it before the button is disabled.
  final FocusNode _confirm = FocusNode(
    debugLabel: 'ItemSheet.confirm',
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void initState() {
    super.initState();
    _focusTitleAfterLayout();
  }

  /// Asks for focus on the title once, after this frame. A sheet that is gone
  /// by then has disposed the node, which must not be asked for focus.
  void _focusTitleAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _title.requestFocus();
    });
  }

  @override
  void didUpdateWidget(ItemSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    final waits = widget.view.mode == ItemSheetMode.cooldown;
    if (waits &&
        oldWidget.view.mode != ItemSheetMode.cooldown &&
        _confirm.hasFocus) {
      // A disabled button cannot hold focus (except in directional
      // navigation), and focus would fall to the route: take it to the title
      // first. Only when the wait starts: each tick of it is a new view.
      _title.requestFocus();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final scheme = Theme.of(context).colorScheme;
    final usage = view.usage;
    final message = view.message;

    final padding = MediaQuery.paddingOf(context);
    assert(
      usage == null ||
          !usage.member.isYou ||
          view.mode == ItemSheetMode.start ||
          view.mode == ItemSheetMode.finish,
      'Nobody nudges or reminds themselves',
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
      },
      child: Semantics(
        key: Key('itemSheet.${view.item.id}'),
        container: true,
        explicitChildNodes: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
            boxShadow: AppShadows.sheet,
          ),
          child: Scrollable(
            viewportBuilder: (context, position) => _HeaderBody(
              offset: position,
              header: SheetHeader(
                title: view.title,
                onClose: widget.onClose,
                closeLabel: view.closeLabel,
                titleFocusNode: _title,
                namesRoute: true,
              ),
              body: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.md + padding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  spacing: ItemSheet._gap,
                  children: [
                    if (usage != null) _Usage(usage),
                    if (message != null && message.isNotEmpty)
                      Text(
                        message,
                        key: const Key('itemSheet.message'),
                        style: AppTypography.body.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    Focus(
                      focusNode: _confirm,
                      includeSemantics: false,
                      child: AppButton(
                        key: const Key('itemSheet.confirm'),
                        label: view.confirmLabel,
                        onPressed: view.mode == ItemSheetMode.cooldown
                            ? null
                            : widget.onConfirm,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The person using the item, on a sunken card.
class _Usage extends StatelessWidget {
  const new(this.usage);

  final ItemUsage usage;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ItemSheet._gap),
        child: MemberRow(member: usage.member, subtitle: usage.subtitle),
      ),
    );
  }
}

enum _Slot { header, body }

/// A header over a body, scrolled by [offset] only when the header is too tall
/// to pin.
///
/// The header takes the height it needs and the body the rest of a bounded
/// height, so a body that scrolls scrolls within the sheet. When the header
/// alone is taller than half of a bounded height, both take their own height
/// and the whole scrolls by [offset], so the body is never left with nothing.
/// Without a bound on the height it is a column, which a flex child of a column
/// is not (it asserts) and which the golden harness measures with intrinsic
/// sizes.
class _HeaderBody
    extends SlottedMultiChildRenderObjectWidget<_Slot, RenderBox> {
  const new({required this.offset, required this.header, required this.body});

  final ViewportOffset offset;
  final Widget header;
  final Widget body;

  @override
  Iterable<_Slot> get slots => _Slot.values;

  @override
  Widget? childForSlot(_Slot slot) => switch (slot) {
    _Slot.header => header,
    _Slot.body => body,
  };

  @override
  SlottedContainerRenderObjectMixin<_Slot, RenderBox> createRenderObject(
    BuildContext context,
  ) => _RenderHeaderBody(offset);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderHeaderBody renderObject,
  ) {
    renderObject.offset = offset;
  }
}

typedef _Layout = ({Size header, Size body, bool together});

class _RenderHeaderBody extends RenderBox
    with SlottedContainerRenderObjectMixin<_Slot, RenderBox>
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

  RenderBox get _header => childForSlot(_Slot.header)!;
  RenderBox get _body => childForSlot(_Slot.body)!;

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
  _Layout _layout(BoxConstraints constraints, ChildLayouter layout) {
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
