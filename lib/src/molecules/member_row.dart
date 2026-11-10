import 'dart:math' as math;

import 'package:compapp_design/src/atoms/app_pebble.dart';
import 'package:compapp_design/src/atoms/app_status_dot.dart';
import 'package:compapp_design/src/models/member_status.dart';
import 'package:compapp_design/src/models/member_view.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A member of the home on one line: their pebble, their name with an optional
/// [subtitle] under it, and an optional [trailing] text with a status dot.
///
/// The row is one thing to assistive technology: a single node that reads
/// `member.semanticLabel`, then the [subtitle], then the [trailing] text. The
/// label names the member, so the visible name is left out of semantics, and
/// the pebble and the dot are decorative here. The row is not interactive.
/// The dot follows the member's status (primary at home, a hollow ring away,
/// none while invited) and only appears beside a [trailing] text, which is
/// what names the status for everyone: the dot is never the only cue.
///
/// The row is at least `AppSizes.row` tall and grows with large text, and
/// nothing is clamped. Beside the texts, the trailing text takes only the
/// width it needs, hugs the end edge and wraps within a third of the row. The
/// row has no divider or padding at its sides: the list around it owns both.
/// It reads in the text direction, so in right-to-left the pebble sits at the
/// right and the trailing text at the left. In a parent that does not bound
/// its width the row takes the width of its content on one line.
///
/// A name or a subtitle never breaks inside a word because of its neighbors.
/// When the longest word of the name or the subtitle does not fit beside the
/// pebble within two thirds of the row, or the longest word of the trailing
/// text does not fit within a third, the trailing text and its dot move under
/// the texts, and the texts take the width the pebble leaves, as the home bar
/// of `AppTopBar` does with its buttons. That happens at large text scales
/// and in narrow columns: at a scale of 1.0 in a phone column the row is laid
/// out as it always was. A small render object with intrinsic and dry layout
/// does it, not a `LayoutBuilder`, so the golden harness can measure the row.
/// The row keeps the baseline of the name, so it lines up in a baseline-aligned
/// `Row`.
///
/// One case is left: a word wider than the whole row, even after that. It
/// wraps by its letters, as any text does when a word is wider than its box,
/// so all of it stays visible at 200% as WCAG 1.4.4 asks. The name is never
/// cut with an ellipsis.
class MemberRow extends StatelessWidget {
  const new({required this.member, this.subtitle, this.trailing, super.key});

  final MemberView member;
  final String? subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = this.subtitle;
    final trailing = this.trailing;
    final hasSubtitle = subtitle != null && subtitle.isNotEmpty;
    final hasTrailing = trailing != null && trailing.isNotEmpty;

    final pebble = AppPebble(
      initials: member.initials,
      joinOrder: member.joinOrder,
      semanticLabel: member.semanticLabel,
      status: switch (member.status) {
        MemberStatus.home => AppPebbleStatus.home,
        MemberStatus.away => AppPebbleStatus.away,
        MemberStatus.invited => AppPebbleStatus.invited,
      },
      isYou: member.isYou,
      isAdmin: member.isAdmin,
    );
    final dot = switch (member.status) {
      MemberStatus.home => AppDotStatus.home,
      MemberStatus.away => AppDotStatus.away,
      MemberStatus.invited => null,
    };
    final name = member.name;
    const caption = AppTypography.caption;
    // The height of the first line of the trailing text, which grows with the
    // text scale: the dot sits on its middle when the trailing text is stacked.
    final dotLine =
        MediaQuery.textScalerOf(context).scale(caption.fontSize!) *
        caption.height!;
    return MergeSemantics(
      key: Key('member.${member.id}'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.row),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: _MemberRowLayout(
            textDirection: Directionality.of(context),
            // The label of the member is the spoken name of the row, so the
            // pebble's own node is replaced by a plain one.
            leading: Semantics(
              label: member.semanticLabel,
              child: ExcludeSemantics(child: pebble),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Text(
                    name,
                    style: AppTypography.labelLg.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                if (hasSubtitle)
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            dot: hasTrailing && dot != null ? AppStatusDot(status: dot) : null,
            dotLine: dotLine,
            trailing: hasTrailing
                ? Text(
                    trailing,
                    style: AppTypography.caption.copyWith(
                      color: scheme.onSurface,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

enum _Slot { leading, body, dot, trailing }

/// Lays out the pebble, the texts, the status dot and the optional trailing
/// text of the row.
///
/// Beside each other, the pebble and the texts take up to two thirds of the
/// width (all of it without a trailing text) at the start edge and the dot and
/// the trailing text up to a third, less [AppSpacing.sm], at the end edge,
/// each centered vertically, the dot on the whole text. When the longest word
/// of the texts or of the trailing text does not fit like that, the dot and the
/// trailing text go under the texts, the dot on the middle of the first line
/// ([dotLine] is its height).
class _MemberRowLayout
    extends SlottedMultiChildRenderObjectWidget<_Slot, RenderBox> {
  const new({
    required this.leading,
    required this.body,
    required this.dot,
    required this.trailing,
    required this.dotLine,
    required this.textDirection,
  });

  final Widget leading;
  final Widget body;
  final Widget? dot;
  final Widget? trailing;
  final double dotLine;
  final TextDirection textDirection;

  @override
  Iterable<_Slot> get slots => _Slot.values;

  @override
  Widget? childForSlot(_Slot slot) => switch (slot) {
    _Slot.leading => leading,
    _Slot.body => body,
    _Slot.dot => dot,
    _Slot.trailing => trailing,
  };

  @override
  SlottedContainerRenderObjectMixin<_Slot, RenderBox> createRenderObject(
    BuildContext context,
  ) => _RenderMemberRowLayout(textDirection: textDirection, dotLine: dotLine);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMemberRowLayout renderObject,
  ) {
    renderObject
      ..textDirection = textDirection
      ..dotLine = dotLine;
  }
}

typedef _Plan = ({
  Size size,
  bool stacked,
  Size leading,
  Size body,
  double bodyMax,
  Size? dot,
  Size? trailing,
});

typedef _Offsets = ({
  Offset leading,
  Offset body,
  Offset? dot,
  Offset? trailing,
});

class _RenderMemberRowLayout extends RenderBox
    with SlottedContainerRenderObjectMixin<_Slot, RenderBox> {
  new({required this._textDirection, required this._dotLine});

  static const double _gap = AppSpacing.md;

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  double _dotLine;
  double get dotLine => _dotLine;
  set dotLine(double value) {
    if (_dotLine == value) return;
    _dotLine = value;
    markNeedsLayout();
  }

  RenderBox get _leading => childForSlot(_Slot.leading)!;
  RenderBox get _body => childForSlot(_Slot.body)!;
  RenderBox? get _dot => childForSlot(_Slot.dot);
  RenderBox? get _trailing => childForSlot(_Slot.trailing);

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) child.parentData = BoxParentData();
  }

  /// The room the dot and its gap take before the trailing text.
  double get _dotRoom => _dot == null
      ? 0
      : _dot!.getMaxIntrinsicWidth(double.infinity) + AppSpacing.sm;

  /// Works out every size and whether the trailing text goes under the texts.
  /// [layoutChild] lays children out for real or only measures them, so
  /// layout and dry layout cannot disagree.
  _Plan _plan(BoxConstraints constraints, ChildLayouter layoutChild) {
    final leading = _leading;
    final body = _body;
    final trailing = _trailing;
    final bounded = constraints.hasBoundedWidth;
    final width = constraints.maxWidth;
    final dotRoom = _dotRoom;

    // The pebble and the texts may take two parts of the row and the trailing
    // text one.
    final groupMax = trailing == null || !bounded ? width : width / 3 * 2;
    final trailingMax = bounded
        ? math.max<double>(0, width / 3 - AppSpacing.sm)
        : double.infinity;

    final leadingSize = layoutChild(
      leading,
      BoxConstraints(maxWidth: groupMax),
    );
    final besideMax = math.max<double>(0, groupMax - leadingSize.width - _gap);

    final stacked =
        trailing != null &&
        bounded &&
        (body.getMinIntrinsicWidth(double.infinity) > besideMax ||
            dotRoom + trailing.getMinIntrinsicWidth(double.infinity) >
                trailingMax);

    final dot = _dot;
    final dotSize = dot == null
        ? null
        : layoutChild(dot, const BoxConstraints());

    if (stacked) {
      final textsMax = math.max<double>(0, width - leadingSize.width - _gap);
      final bodySize = layoutChild(body, BoxConstraints(maxWidth: textsMax));
      final trailingSize = layoutChild(
        trailing,
        BoxConstraints(maxWidth: math.max<double>(0, textsMax - dotRoom)),
      );
      final group = _groupHeight(dotSize, trailingSize, stacked: true);
      final height =
          math.max(leadingSize.height, bodySize.height) + AppSpacing.xs + group;
      return (
        size: constraints.constrain(Size(width, height)),
        stacked: true,
        leading: leadingSize,
        body: bodySize,
        bodyMax: textsMax,
        dot: dotSize,
        trailing: trailingSize,
      );
    }

    final bodySize = layoutChild(body, BoxConstraints(maxWidth: besideMax));
    final trailingSize = trailing == null
        ? null
        : layoutChild(
            trailing,
            BoxConstraints(
              maxWidth: math.max<double>(0, trailingMax - dotRoom),
            ),
          );
    final double height = math.max(
      math.max(leadingSize.height, bodySize.height),
      trailingSize == null
          ? 0
          : _groupHeight(dotSize, trailingSize, stacked: false),
    );
    final natural =
        leadingSize.width +
        _gap +
        bodySize.width +
        (trailingSize == null
            ? 0
            : AppSpacing.sm + dotRoom + trailingSize.width);
    return (
      size: constraints.constrain(Size(bounded ? width : natural, height)),
      stacked: false,
      leading: leadingSize,
      body: bodySize,
      bodyMax: besideMax,
      dot: dotSize,
      trailing: trailingSize,
    );
  }

  /// The height of the dot and the trailing text together. Stacked, the dot is
  /// on the first line and may hang below a text of one short line.
  double _groupHeight(Size? dot, Size trailing, {required bool stacked}) {
    if (dot == null) return trailing.height;
    final dotBottom = stacked ? _dotTop(dot) + dot.height : dot.height;
    return math.max(trailing.height, dotBottom);
  }

  double _dotTop(Size dot) => math.max<double>(0, (dotLine - dot.height) / 2);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _plan(constraints, ChildLayoutHelper.dryLayoutChild).size;

  /// Where each child goes, from the start edge of the row in the reading
  /// direction (mirrored in right-to-left by [performLayout]).
  _Offsets _offsets(_Plan plan) {
    final height = plan.size.height;
    final top = math.max(plan.leading.height, plan.body.height);
    final textsStart = plan.leading.width + _gap;
    final trailing = plan.trailing;
    final dot = plan.dot;
    final dotRoom = _dotRoom;
    if (plan.stacked) {
      final group = _groupHeight(dot, trailing!, stacked: true);
      final block = top + AppSpacing.xs + group;
      final y = (height - block) / 2;
      final groupTop = y + top + AppSpacing.xs;
      return (
        leading: Offset(0, y + (top - plan.leading.height) / 2),
        body: Offset(textsStart, y + (top - plan.body.height) / 2),
        dot: dot == null ? null : Offset(textsStart, groupTop + _dotTop(dot)),
        trailing: Offset(textsStart + dotRoom, groupTop),
      );
    }
    Offset? dotOffset;
    Offset? trailingOffset;
    if (trailing != null) {
      final group = _groupHeight(dot, trailing, stacked: false);
      final groupStart = plan.size.width - dotRoom - trailing.width;
      final groupTop = (height - group) / 2;
      trailingOffset = Offset(
        groupStart + dotRoom,
        groupTop + (group - trailing.height) / 2,
      );
      if (dot != null) {
        dotOffset = Offset(groupStart, groupTop + (group - dot.height) / 2);
      }
    }
    return (
      leading: Offset(0, (height - plan.leading.height) / 2),
      body: Offset(textsStart, (height - plan.body.height) / 2),
      dot: dotOffset,
      trailing: trailingOffset,
    );
  }

  @override
  void performLayout() {
    final plan = _plan(constraints, ChildLayoutHelper.layoutChild);
    size = plan.size;
    final offsets = _offsets(plan);
    final rtl = textDirection == TextDirection.rtl;

    void place(RenderBox child, Offset offset) {
      final left = rtl ? size.width - offset.dx - child.size.width : offset.dx;
      (child.parentData! as BoxParentData).offset = Offset(left, offset.dy);
    }

    place(_leading, offsets.leading);
    place(_body, offsets.body);
    if (offsets.dot != null) place(_dot!, offsets.dot!);
    if (offsets.trailing != null) place(_trailing!, offsets.trailing!);
  }

  // The row keeps the baseline of the name, like the texts of a Row would,
  // not the one of the pebble.
  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final distance = _body.getDistanceToActualBaseline(baseline);
    if (distance == null) return null;
    return distance + (_body.parentData! as BoxParentData).offset.dy;
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final plan = _plan(constraints, ChildLayoutHelper.dryLayoutChild);
    final distance = _body.getDryBaseline(
      BoxConstraints(maxWidth: plan.bodyMax),
      baseline,
    );
    if (distance == null) return null;
    return distance + _offsets(plan).body.dy;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    // The narrowest that cuts no word: the trailing text stacked.
    final texts = _body.getMinIntrinsicWidth(double.infinity);
    final under = _trailing == null
        ? 0
        : _dotRoom + _trailing!.getMinIntrinsicWidth(double.infinity);
    return _leading.getMinIntrinsicWidth(double.infinity) +
        _gap +
        math.max(texts, under);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final trailing = _trailing;
    return _leading.getMaxIntrinsicWidth(double.infinity) +
        _gap +
        _body.getMaxIntrinsicWidth(double.infinity) +
        (trailing == null
            ? 0
            : AppSpacing.sm +
                  _dotRoom +
                  trailing.getMaxIntrinsicWidth(double.infinity));
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      computeDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in children) {
      context.paintChild(
        child,
        offset + (child.parentData! as BoxParentData).offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in children.toList().reversed) {
      final hit = result.addWithPaintOffset(
        offset: (child.parentData! as BoxParentData).offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}
