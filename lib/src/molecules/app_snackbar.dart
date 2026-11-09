import 'dart:math' as math;

import 'package:compapp_design/src/atoms/app_icon.dart';
import 'package:compapp_design/src/models/app_icons.dart';
import 'package:compapp_design/src/tokens/app_motion.dart';
import 'package:compapp_design/src/tokens/app_opacity.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_state_layers.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// What a snackbar reports. The tone changes the glyph and nothing else: there
/// is no danger color, because a failed request is not an alarm.
enum SnackTone {
  /// A check: something went through.
  info,

  /// A circled exclamation mark: something did not go through.
  error,
}

/// A short message on the inverse surface, with an optional action.
///
/// The bar renders the message and calls [onAction]. It keeps no timer: when
/// to show it, when to take it away (the auto-dismiss) and whether a second
/// message replaces the first belong to the app, which flips [visible].
///
/// [visible] drives the enter and exit: the bar slides up and fades in, and
/// slides down and fades out, over `AppMotion.snackbar`. When the system asks
/// to reduce motion the bar appears and disappears at once. After the exit it
/// takes no space and leaves the semantics and the focus order.
///
/// The tone is a glyph ([AppIcons.check] or [AppIcons.alert]) in the soft
/// primary color: color never carries the tone alone, and the message says
/// what happened in words.
///
/// For assistive technology the bar is a live region named by [message], so it
/// is announced once when it appears. The glyph and the text are excluded from
/// semantics, and the action is a focusable button named by [actionLabel],
/// after the message. The action is shown when [actionLabel] is a non-empty
/// string and a null [onAction] disables it. It is 44 drawn with a 48 hit
/// area and shows a focus ring in the light color of the bar.
///
/// The bar is at least 52 tall and grows when the text wraps with large text.
/// An action wider than a quarter of the bar (as Material's
/// `actionOverflowThreshold`) moves under the message, end-aligned, so the
/// message keeps its words whole at 2.0. A disabled action is drawn in a
/// dimmer light, and a pressed, hovered or focused one gets an overlay of the
/// soft primary. It mirrors in right-to-left text.
///
/// [message] is never empty.
class AppSnackbar extends StatefulWidget {
  const new({
    required this.message,
    this.tone = SnackTone.info,
    this.actionLabel,
    this.onAction,
    this.visible = true,
    super.key,
  }) : assert(message != '', 'A snackbar needs a message');

  final String message;
  final SnackTone tone;

  /// Text of the action. Null or empty leaves the action out.
  final String? actionLabel;

  /// Called by the action. Null disables it.
  final VoidCallback? onAction;

  /// Whether the bar is shown. Changing it plays the enter or the exit.
  final bool visible;

  @override
  State<AppSnackbar> createState() => _AppSnackbarState();
}

class _AppSnackbarState extends State<AppSnackbar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.snackbar,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.snackbarCurve,
  );
  bool _first = true;

  /// Half the height of the bar: how far it slides.
  static const Offset _hidden = Offset(0, 0.5);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (_first) {
      _first = false;
      if (widget.visible) {
        reduced ? _controller.value = 1 : _controller.forward();
      }
    } else if (reduced) {
      _controller.value = widget.visible ? 1 : 0;
    }
  }

  @override
  void didUpdateWidget(AppSnackbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = widget.visible ? 1 : 0;
    } else if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isDismissed && !widget.visible) {
          return const SizedBox.shrink();
        }
        final bar = _Bar(
          message: widget.message,
          tone: widget.tone,
          actionLabel: widget.actionLabel,
          onAction: widget.onAction,
        );
        final shown = widget.visible;
        return ExcludeSemantics(
          excluding: !shown,
          child: IgnorePointer(
            ignoring: !shown,
            child: ExcludeFocus(
              excluding: !shown,
              child: FadeTransition(
                opacity: _curve,
                child: SlideTransition(
                  position: Tween(
                    begin: _hidden,
                    end: Offset.zero,
                  ).animate(_curve),
                  child: bar,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const new({
    required this.message,
    required this.tone,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final SnackTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  static const double _gap = AppSpacing.sm + AppSpacing.xs;

  /// The share of the bar the action may take beside the message. A wider
  /// action goes on a line of its own under the message, so the message keeps
  /// its words whole. It is the default of Material's
  /// `SnackBarThemeData.actionOverflowThreshold`.
  static const double _actionOverflowThreshold = 0.25;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = actionLabel;
    final hasAction = label != null && label.isNotEmpty;

    final icon = ExcludeSemantics(
      child: AppIcon(
        switch (tone) {
          SnackTone.info => AppIcons.check,
          SnackTone.error => AppIcons.alert,
        },
        key: const Key('snackbar.icon'),
        size: AppSizes.glyphLg,
        color: scheme.inversePrimary,
      ),
    );
    final text = Padding(
      padding: const EdgeInsets.symmetric(vertical: _gap),
      child: ExcludeSemantics(
        child: Text(
          message,
          key: const Key('snackbar.message'),
          style: AppTypography.body.copyWith(color: scheme.onInverseSurface),
        ),
      ),
    );
    final action = hasAction ? _action(scheme, label) : null;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      liveRegion: true,
      label: message,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.controlLg),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: AppSpacing.md,
              end: hasAction ? AppSpacing.sm : AppSpacing.md,
            ),
            child: _ActionFlow(
              gap: _gap,
              stackedBottom: AppSpacing.xs,
              actionOverflowThreshold: _actionOverflowThreshold,
              message: Row(
                children: [
                  icon,
                  const SizedBox(width: _gap),
                  Expanded(child: text),
                ],
              ),
              action: action,
            ),
          ),
        ),
      ),
    );
  }

  Widget _action(ColorScheme scheme, String label) {
    return TextButton(
      key: const Key('snackbar.action'),
      onPressed: onAction,
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? scheme.onInverseSurface.withValues(
                  alpha: AppOpacity.disabledInverseLabel,
                )
              : scheme.inversePrimary,
        ),
        // The overlay is made of the soft primary the label is drawn in, not
        // of the page primary, so it shows on the bar.
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return scheme.inversePrimary.withValues(
              alpha: AppStateLayers.pressedPrimary,
            );
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return scheme.inversePrimary.withValues(
              alpha: AppStateLayers.pressedSecondary,
            );
          }
          return null;
        }),
        side: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? BorderSide(
                  color: scheme.onInverseSurface,
                  width: AppSizes.borderEmphasis,
                  strokeAlign: BorderSide.strokeAlignOutside,
                )
              : null,
        ),
      ),
      child: Text(label),
    );
  }
}

enum _Slot { message, action }

/// Lays out the message and the action. The action goes beside the message,
/// unless it is wider than [actionOverflowThreshold] of the width: then it goes
/// under the message, at the end. It is a render object of its own because a
/// `LayoutBuilder` cannot give intrinsic sizes, which a bar inside a `Table` or
/// an `IntrinsicHeight` needs.
class _ActionFlow
    extends SlottedMultiChildRenderObjectWidget<_Slot, RenderBox> {
  const new({
    required this.message,
    required this.action,
    required this.gap,
    required this.stackedBottom,
    required this.actionOverflowThreshold,
  });

  final Widget message;
  final Widget? action;
  final double gap;

  /// Room under an action that sits on its own line.
  final double stackedBottom;
  final double actionOverflowThreshold;

  @override
  Iterable<_Slot> get slots => _Slot.values;

  @override
  Widget? childForSlot(_Slot slot) => switch (slot) {
    _Slot.message => message,
    _Slot.action => action,
  };

  @override
  _RenderActionFlow createRenderObject(BuildContext context) {
    return _RenderActionFlow(
      gap,
      stackedBottom,
      actionOverflowThreshold,
      Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderActionFlow renderObject,
  ) {
    renderObject
      ..gap = gap
      ..stackedBottom = stackedBottom
      ..actionOverflowThreshold = actionOverflowThreshold
      ..textDirection = Directionality.of(context);
  }
}

class _RenderActionFlow extends RenderBox
    with SlottedContainerRenderObjectMixin<_Slot, RenderBox> {
  new(
    this._gap,
    this._stackedBottom,
    this._actionOverflowThreshold,
    this._textDirection,
  );

  double _gap;
  double get gap => _gap;
  set gap(double value) {
    if (_gap == value) return;
    _gap = value;
    markNeedsLayout();
  }

  double _stackedBottom;
  double get stackedBottom => _stackedBottom;
  set stackedBottom(double value) {
    if (_stackedBottom == value) return;
    _stackedBottom = value;
    markNeedsLayout();
  }

  double _actionOverflowThreshold;
  double get actionOverflowThreshold => _actionOverflowThreshold;
  set actionOverflowThreshold(double value) {
    if (_actionOverflowThreshold == value) return;
    _actionOverflowThreshold = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox get _message => childForSlot(_Slot.message)!;
  RenderBox? get _action => childForSlot(_Slot.action);

  /// The width this box takes: what it is given, or what it needs when the
  /// width is unbounded.
  double _width(BoxConstraints constraints) {
    if (constraints.hasBoundedWidth) return constraints.maxWidth;
    final action = _action;
    return _message.getMaxIntrinsicWidth(double.infinity) +
        (action == null
            ? 0
            : _gap + action.getMaxIntrinsicWidth(double.infinity));
  }

  _Plan _plan(BoxConstraints constraints) {
    final width = _width(constraints);
    final action = _action;
    final actionSize = action?.getDryLayout(BoxConstraints(maxWidth: width));
    final stacked =
        actionSize != null &&
        actionSize.width > width * _actionOverflowThreshold;
    final messageWidth = actionSize == null || stacked
        ? width
        : width - actionSize.width - _gap;
    final messageSize = _message.getDryLayout(
      BoxConstraints.tightFor(width: math.max(0, messageWidth)),
    );
    final height = actionSize == null
        ? messageSize.height
        : stacked
        ? messageSize.height + actionSize.height + _stackedBottom
        : math.max(messageSize.height, actionSize.height);
    return _Plan(
      size: constraints.constrain(Size(width, height)),
      stacked: stacked,
      messageSize: messageSize,
      actionSize: actionSize,
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => _plan(constraints).size;

  @override
  void performLayout() {
    final plan = _plan(constraints);
    size = plan.size;
    _message.layout(
      BoxConstraints.tight(plan.messageSize),
      parentUsesSize: true,
    );
    final action = _action;
    final actionSize = plan.actionSize;
    final rtl = _textDirection == TextDirection.rtl;
    double atStart(double width) => rtl ? size.width - width : 0;
    double atEnd(double width) => rtl ? 0 : size.width - width;

    (_message.parentData! as BoxParentData).offset = Offset(
      atStart(plan.messageSize.width),
      plan.stacked ? 0 : (size.height - plan.messageSize.height) / 2,
    );
    if (action != null && actionSize != null) {
      action.layout(BoxConstraints.tight(actionSize), parentUsesSize: true);
      (action.parentData! as BoxParentData).offset = Offset(
        atEnd(actionSize.width),
        plan.stacked
            ? plan.messageSize.height
            : (size.height - actionSize.height) / 2,
      );
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _message.getMinIntrinsicWidth(height),
    _action?.getMinIntrinsicWidth(height) ?? 0,
  );

  @override
  double computeMaxIntrinsicWidth(double height) {
    final action = _action;
    return _message.getMaxIntrinsicWidth(height) +
        (action == null ? 0 : _gap + action.getMaxIntrinsicWidth(height));
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _plan(BoxConstraints(maxWidth: width)).size.height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) => null;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in [?_action, _message]) {
      final offset = (child.parentData! as BoxParentData).offset;
      final hit = result.addWithPaintOffset(
        offset: offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in [_message, ?_action]) {
      context.paintChild(
        child,
        offset + (child.parentData! as BoxParentData).offset,
      );
    }
  }
}

class _Plan {
  const new({
    required this.size,
    required this.stacked,
    required this.messageSize,
    required this.actionSize,
  });

  final Size size;
  final bool stacked;
  final Size messageSize;
  final Size? actionSize;
}
