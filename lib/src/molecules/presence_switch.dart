import 'dart:math' as math;

import 'package:compapp_design/src/atoms/app_icon.dart';
import 'package:compapp_design/src/models/app_icons.dart';
import 'package:compapp_design/src/models/presence.dart';
import 'package:compapp_design/src/tokens/app_colors_context.dart';
import 'package:compapp_design/src/tokens/app_motion.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// The "I'm home / I'm out" switch: two buttons in a sunken track and a filled
/// thumb under the selected one, like a light switch.
///
/// The thumb is primary at [Presence.home] and the away color at
/// [Presence.away], and it slides from one side to the other. Each side has its
/// glyph (a sun, a moon) and its label, and the selected one is the only one
/// with a fill, so the state is never told by color alone: the thumb has 3:1
/// against the track, and the group says which side is checked.
///
/// While the thumb slides, every label and glyph is drawn twice: in the muted
/// ink on the track, where the thumb is not, and in the color that reads on the
/// thumb, where it is, clipped to the thumb's rectangle of that frame. Every
/// pixel therefore has the right color for what is under it on every frame, as
/// in an iOS segmented control, and no color is ever blended between the two.
/// At rest each side is drawn once.
///
/// For assistive technology it is a group named by [semanticLabel] ("Your
/// presence") with two toggle buttons, [homeLabel] and [awayLabel], one of
/// them checked. The glyphs and the second drawing add nothing. Each side is
/// focusable with the ink ring and activated by tap, Enter and Space. Choosing
/// the selected side does nothing, and [onChanged] is only called with the
/// other one.
///
/// The track has a hairline border in `outline`, which keeps 3:1 against the
/// page and a card (the sunken fill alone does not).
///
/// The track is at least `AppSizes.presenceControl` tall and both sides grow
/// together with large text: the labels wrap by word and nothing is clamped.
/// The sides share the width equally while the longest word of each fits its
/// half, and when one does not they stack, each as wide as the track, so no
/// word is ever cut; the thumb then slides down or up. It needs a bounded width
/// and mirrors in right-to-left, with the home side at the start. The thumb
/// slides over `AppMotion.presence`, or jumps when the system asks to reduce
/// motion.
class PresenceSwitch extends StatelessWidget {
  const new({
    required this.value,
    required this.onChanged,
    required this.homeLabel,
    required this.awayLabel,
    required this.semanticLabel,
    super.key,
  }) : assert(homeLabel != '', 'The home side needs a label'),
       assert(awayLabel != '', 'The away side needs a label'),
       assert(semanticLabel != '', 'The group needs a spoken label');

  final Presence value;
  final ValueChanged<Presence> onChanged;
  final String homeLabel;
  final String awayLabel;
  final String semanticLabel;

  static const double _inset = AppSpacing.xs;
  static const double _sideHeight =
      AppSizes.presenceControl - 2 * (_inset + AppSizes.hairline);
  static const double _trackRadius = AppRadius.md;
  static const double _sideRadius = _trackRadius - _inset - AppSizes.hairline;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final target = value == Presence.away ? 1.0 : 0.0;

    return Semantics(
      key: const Key('presence.switch'),
      container: true,
      role: SemanticsRole.radioGroup,
      label: semanticLabel,
      child: CustomPaint(
        painter: _TrackPainter(
          fill: scheme.surfaceContainerHigh,
          border: scheme.outline,
          radius: _trackRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.all(_inset + AppSizes.hairline),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: target),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppMotion.presence,
            curve: AppMotion.presenceCurve,
            builder: (context, position, _) {
              final moving = position != target;
              final labels = {
                Presence.home: homeLabel,
                Presence.away: awayLabel,
              };
              return _ThumbPair(
                spacing: _inset,
                textDirection: Directionality.of(context),
                position: position,
                homeFill: scheme.primary,
                awayFill: colors.presenceAway,
                radius: _sideRadius,
                children: [
                  for (final side in Presence.values)
                    _Shell(
                      side: side,
                      label: labels[side]!,
                      selected: value == side,
                      hideFace: moving,
                      onChosen: () => onChanged(side),
                    ),
                  if (moving) ...[
                    for (final side in Presence.values)
                      _Overlay(
                        face: _Face(
                          side: side,
                          label: labels[side]!,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    for (final side in Presence.values)
                      _Overlay(
                        face: _Face(
                          side: side,
                          label: labels[side]!,
                          color: switch (side) {
                            Presence.home => scheme.onPrimary,
                            Presence.away => colors.onPresenceAway,
                          },
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The sunken track and its hairline border.
class _TrackPainter extends CustomPainter {
  const new({required this.fill, required this.border, required this.radius});

  final Color fill;
  final Color border;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas
      ..drawRRect(shape, Paint()..color = fill)
      ..drawRRect(
        shape.deflate(AppSizes.hairline / 2),
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppSizes.hairline,
      );
  }

  @override
  bool shouldRepaint(_TrackPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.border != border ||
      oldDelegate.radius != radius;
}

/// The glyph and the label of one side in one [color].
class _Face extends StatelessWidget {
  const new({required this.side, required this.label, required this.color});

  final Presence side;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = switch (side) {
      Presence.home => AppIcons.home,
      Presence.away => AppIcons.away,
    };
    // Self-contained: the same style in the button and in the second drawing,
    // whatever text style is around the switch (a line limit, an italic, an
    // underline), so the label never changes while the thumb slides.
    return DefaultTextStyle(
      style: AppTypography.labelLg,
      textAlign: TextAlign.center,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(icon, size: AppSizes.glyphLg, color: color),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.labelLg.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The button of one side. It draws its face in the color that reads on what is
/// under it at rest (the on-color of the thumb when selected, the muted ink
/// when not) and none while the thumb slides, when the overlays draw it.
class _Shell extends StatelessWidget {
  const new({
    required this.side,
    required this.label,
    required this.selected,
    required this.hideFace,
    required this.onChosen,
  });

  final Presence side;
  final String label;
  final bool selected;
  final bool hideFace;
  final VoidCallback onChosen;

  static void _keep() {}

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final onThumb = switch (side) {
      Presence.home => scheme.onPrimary,
      Presence.away => colors.onPresenceAway,
    };

    return TextButton(
      key: Key('presence.switch.${side.name}'),
      // Choosing the side that is already selected does nothing, but it stays
      // a focusable, enabled button that says it is checked.
      onPressed: selected ? _keep : onChosen,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size.fromHeight(PresenceSwitch._sideHeight),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(PresenceSwitch._sideRadius),
            ),
          ),
        ),
        foregroundColor: WidgetStatePropertyAll(scheme.onSurfaceVariant),
      ),
      child: Semantics(
        label: label,
        checked: selected,
        inMutuallyExclusiveGroup: true,
        excludeSemantics: true,
        child: Visibility(
          visible: !hideFace,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: _Face(
            side: side,
            label: label,
            color: selected ? onThumb : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// A second drawing of a face, laid out like the button under it. It takes no
/// pointer, no focus and no semantics: the button is the only control.
class _Overlay extends StatelessWidget {
  const new({required this.face});

  final Widget face;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(child: Center(child: face)),
    );
  }
}

/// Lays out two sides as equal halves side by side, or one under the other when
/// the longest word of either does not fit its half, and paints the thumb under
/// the selected one. A `LayoutBuilder` would do the same, but the golden
/// harness measures intrinsic sizes, which it cannot answer, so this render
/// object does.
///
/// The children are the two buttons, and while the thumb slides four more, in
/// this order: the muted face of each side, then its face on the thumb. They
/// get the size and place of the button of their side. The muted ones are
/// clipped to what is outside the thumb and the others to the thumb.
class _ThumbPair extends MultiChildRenderObjectWidget {
  const new({
    required this.spacing,
    required this.textDirection,
    required this.position,
    required this.homeFill,
    required this.awayFill,
    required this.radius,
    required super.children,
  });

  final double spacing;
  final TextDirection textDirection;

  /// Where the thumb is, from 0 (under the first side) to 1 (under the second).
  final double position;
  final Color homeFill;
  final Color awayFill;
  final double radius;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderThumbPair(
    spacing,
    textDirection,
    position,
    homeFill,
    awayFill,
    radius,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderThumbPair renderObject) {
    renderObject
      ..spacing = spacing
      ..textDirection = textDirection
      ..position = position
      ..homeFill = homeFill
      ..awayFill = awayFill
      ..radius = radius;
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

class _RenderThumbPair extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _PairParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _PairParentData> {
  new(
    this._spacing,
    this._textDirection,
    this._position,
    this._homeFill,
    this._awayFill,
    this._radius,
  );

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

  double _position;
  double get position => _position;
  set position(double value) {
    if (value == _position) return;
    _position = value;
    markNeedsPaint();
  }

  Color _homeFill;
  Color get homeFill => _homeFill;
  set homeFill(Color value) {
    if (value == _homeFill) return;
    _homeFill = value;
    markNeedsPaint();
  }

  Color _awayFill;
  Color get awayFill => _awayFill;
  set awayFill(Color value) {
    if (value == _awayFill) return;
    _awayFill = value;
    markNeedsPaint();
  }

  double _radius;
  double get radius => _radius;
  set radius(double value) {
    if (value == _radius) return;
    _radius = value;
    markNeedsPaint();
  }

  /// The two buttons, which decide the size of the pair.
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
        offset = Offset(0, side == 0 ? 0 : _first.size.height + _spacing);
      } else {
        final slot = _textDirection == TextDirection.ltr ? side : 1 - side;
        offset = Offset(slot * (children[side].size.width + _spacing), 0);
      }
      (child.parentData! as _PairParentData).offset = offset;
    }
  }

  Rect _sideRect(RenderBox side) =>
      (side.parentData! as _PairParentData).offset & side.size;

  @override
  void paint(PaintingContext context, Offset offset) {
    final children = getChildrenAsList();
    final bounds = Offset.zero & size;
    final thumb = RRect.fromRectAndRadius(
      Rect.lerp(_sideRect(_first), _sideRect(_second), _position)!,
      Radius.circular(_radius),
    );
    context.canvas.drawRRect(
      thumb.shift(offset),
      Paint()..color = Color.lerp(_homeFill, _awayFill, _position)!,
    );

    void paintAll(
      PaintingContext inner,
      Offset origin,
      Iterable<RenderBox> of,
    ) {
      for (final child in of) {
        inner.paintChild(
          child,
          (child.parentData! as _PairParentData).offset + origin,
        );
      }
    }

    paintAll(context, offset, children.take(2));
    if (children.length <= 2) return;

    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(bounds),
      Path()..addRRect(thumb),
    );
    context
      ..pushClipPath(
        needsCompositing,
        offset,
        bounds,
        outside,
        (inner, origin) => paintAll(inner, origin, children.sublist(2, 4)),
      )
      ..pushClipRRect(
        needsCompositing,
        offset,
        bounds,
        thumb,
        (inner, origin) => paintAll(inner, origin, children.sublist(4)),
      );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
