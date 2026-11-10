import 'dart:math' as math;

import 'package:compapp_design/src/atoms/app_button.dart';
import 'package:compapp_design/src/models/app_icons.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A personal or home code on a dashed card, with a copy and a share button
/// under it.
///
/// The [code] is the text to show, already grouped by the app ("4829 1736"):
/// it wraps at the spaces, so each group has to fit the card, and it always
/// reads left to right, as a code is read. It is a string and the design
/// system does nothing with it: copying and sharing are the callbacks
/// [onCopy] and [onShare], and the app does the clipboard and the share sheet.
/// [copied] is the state the app sets after it copied: the copy button then
/// says [copiedLabel] and shows a check instead of the copy glyph, so it is
/// never told by color alone. The app owns how long it lasts.
///
/// The button changes its label without a word, so the app must announce the
/// copy too, for example with an `AppSnackbar`, which is a live region.
///
/// For assistive technology the code is one node named by [label] ("Your
/// personal code") whose value is the code spelled out character by character,
/// so "48291736" is not read as a number. The visible texts add nothing of
/// their own. The copy and share buttons are their own buttons, named by their
/// visible labels. Nothing is announced twice, and the card itself is not
/// interactive.
///
/// The dashed edge is decoration in the hairline color, not a control
/// boundary: the code and the buttons carry the meaning. The card grows with
/// large text, and nothing is clamped. The buttons share the width in two
/// equal halves while the longest word of each fits its half, and stack, each
/// as wide as the card, when one does not, so no word is cut. It needs a
/// bounded width and mirrors in right-to-left, with the copy button at the
/// start. It has no motion.
class CodeCard extends StatelessWidget {
  const new({
    required this.code,
    required this.label,
    required this.copyLabel,
    required this.copiedLabel,
    required this.shareLabel,
    required this.onCopy,
    required this.onShare,
    this.copied = false,
    super.key,
  }) : assert(code != '', 'The card needs a code'),
       assert(label != '', 'The code needs a spoken name'),
       assert(copyLabel != '', 'The copy button needs a label'),
       assert(copiedLabel != '', 'The copied state needs a label'),
       assert(shareLabel != '', 'The share button needs a label');

  final String code;

  /// The caption over the code, which also names it for assistive technology.
  final String label;
  final String copyLabel;
  final String copiedLabel;
  final String shareLabel;
  final bool copied;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  static const double _cardRadius = AppRadius.sm;
  static const double _cardPadding = AppSpacing.sm + AppSpacing.xs;
  static const double _gap = AppSpacing.sm + AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final card = Semantics(
      container: true,
      label: label,
      attributedValue: AttributedString(
        code,
        attributes: [
          SpellOutStringAttribute(range: TextRange(start: 0, end: code.length)),
        ],
      ),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: scheme.surfaceContainerLowest,
          shape: _DashedBorder(
            borderRadius: BorderRadius.circular(_cardRadius),
            side: BorderSide(
              color: scheme.outlineVariant,
              width: AppSizes.borderDashed,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: _cardPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              // A code is read left to right whatever the text direction is.
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  code,
                  key: const Key('account.code.value'),
                  textAlign: TextAlign.center,
                  style: AppTypography.code.copyWith(color: scheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Column(
      key: const Key('account.code'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        const SizedBox(height: _gap),
        _EqualPair(
          spacing: AppSpacing.sm,
          textDirection: Directionality.of(context),
          children: [
            AppButton(
              key: const Key('account.code.copy'),
              label: copied ? copiedLabel : copyLabel,
              icon: copied ? AppIcons.check : AppIcons.copy,
              variant: AppButtonVariant.secondary,
              onPressed: onCopy,
            ),
            AppButton(
              key: const Key('account.code.share'),
              label: shareLabel,
              icon: AppIcons.share,
              variant: AppButtonVariant.secondary,
              onPressed: onShare,
            ),
          ],
        ),
      ],
    );
  }
}

/// A rounded rectangle whose side is dashed. Material has no dashed border.
class _DashedBorder extends RoundedRectangleBorder {
  const new({super.borderRadius, super.side});

  @override
  _DashedBorder copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
  }) => _DashedBorder(
    side: side ?? this.side,
    borderRadius: borderRadius ?? this.borderRadius,
  );

  @override
  ShapeBorder scale(double t) =>
      _DashedBorder(side: side.scale(t), borderRadius: borderRadius * t);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    final outline = Path()
      ..addRRect(
        borderRadius
            .resolve(textDirection)
            .toRRect(rect)
            .deflate(side.width / 2),
      );
    final paint = Paint()
      ..color = side.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = side.width;
    final dash = side.width * AppSizes.dash;
    final period = dash + side.width * AppSizes.dashGap;
    for (final metric in outline.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += period) {
        canvas.drawPath(
          metric.extractPath(start, math.min(start + dash, metric.length)),
          paint,
        );
      }
    }
  }
}

/// Lays out two children as equal halves side by side, or one under the other
/// when the longest word of either does not fit its half. A `LayoutBuilder`
/// would do the same, but the golden harness measures intrinsic sizes, which it
/// cannot answer, so this render object does.
class _EqualPair extends MultiChildRenderObjectWidget {
  const new({
    required this.spacing,
    required this.textDirection,
    required super.children,
  });

  final double spacing;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderEqualPair(spacing, textDirection);

  @override
  void updateRenderObject(BuildContext context, _RenderEqualPair renderObject) {
    renderObject
      ..spacing = spacing
      ..textDirection = textDirection;
  }
}

class _PairParentData extends ContainerBoxParentData<RenderBox>;

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

class _RenderEqualPair extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _PairParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _PairParentData> {
  new(this._spacing, this._textDirection);

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

  RenderBox get _first => firstChild!;
  RenderBox get _second => childAfter(_first)!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _PairParentData) {
      child.parentData = _PairParentData();
    }
  }

  _PairPlan _plan(BoxConstraints constraints) {
    final maxWidth = constraints.maxWidth;
    final half = (maxWidth - _spacing) / 2;
    final sideBySide =
        !maxWidth.isFinite ||
        (_first.getMinIntrinsicWidth(double.infinity) <= half &&
            _second.getMinIntrinsicWidth(double.infinity) <= half);

    if (!sideBySide) {
      final loose = BoxConstraints(
        minWidth: maxWidth,
        maxWidth: maxWidth,
        maxHeight: constraints.maxHeight,
      );
      final heights = [
        _first.getDryLayout(loose).height,
        _second.getDryLayout(loose).height,
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
            _first.getMaxIntrinsicWidth(double.infinity),
            _second.getMaxIntrinsicWidth(double.infinity),
          );
    final tightWidth = BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: constraints.maxHeight,
    );
    final height = math.max(
      _first.getDryLayout(tightWidth).height,
      _second.getDryLayout(tightWidth).height,
    );
    return _PairPlan(
      size: constraints.constrain(Size(2 * width + _spacing, height)),
      childConstraints: BoxConstraints.tightFor(width: width, height: height),
      stacked: false,
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _first.getMinIntrinsicWidth(height),
    _second.getMinIntrinsicWidth(height),
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      2 *
          math.max(
            _first.getMaxIntrinsicWidth(height),
            _second.getMaxIntrinsicWidth(height),
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
    final children = [_first, _second];
    for (final child in children) {
      child.layout(plan.childConstraints, parentUsesSize: true);
    }
    for (final (index, child) in children.indexed) {
      final Offset offset;
      if (plan.stacked) {
        offset = Offset(0, index == 0 ? 0 : _first.size.height + _spacing);
      } else {
        final slot = _textDirection == TextDirection.ltr ? index : 1 - index;
        offset = Offset(slot * (child.size.width + _spacing), 0);
      }
      (child.parentData! as _PairParentData).offset = offset;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
