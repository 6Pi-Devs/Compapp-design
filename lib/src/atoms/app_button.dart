import 'dart:math' as math;

import 'package:compapp_design/src/atoms/app_icon.dart';
import 'package:compapp_design/src/models/app_icons.dart';
import 'package:compapp_design/src/tokens/app_motion.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_state_layers.dart';
import 'package:flutter/material.dart';

/// How a button looks and what it is for.
enum AppButtonVariant {
  /// The main action of a screen: primary fill.
  primary,

  /// A secondary action: surface fill and a line border.
  secondary,

  /// A quiet action with no fill, such as "Mark all as read".
  ghost,

  /// A destructive action only (deleting an account or data). Never for
  /// anything else: calm UI keeps red for destroying things.
  danger,
}

/// Drawn height of a button. The hit area is always at least 48.
enum AppButtonSize {
  /// 44 tall.
  md,

  /// 52 tall.
  lg,
}

/// A button on top of Material's filled, outlined and text buttons, which
/// `CompappTheme` styles.
///
/// [size] defaults to the size of the variant on the board: [AppButtonSize.lg]
/// for primary, secondary and danger, [AppButtonSize.md] for ghost. A null
/// [onPressed] disables the button.
///
/// While [loading] the button keeps its size, colors, element tree and
/// keyboard focus, and shows a spinner before the label. Pointer taps, Enter
/// and Space while focused, and the semantic tap action are all ignored. It
/// is still a button named by the label, with [loadingSemanticLabel] as its
/// value in a live region (Flutter has no busy flag). The spinner stands
/// still when the system asks to reduce motion.
///
/// [semanticLabel] replaces the label for assistive technology only.
/// [statesController] is Material's: holding `WidgetState.pressed` in it
/// renders the pressed look without a gesture, which stories and goldens use.
class AppButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size,
    this.icon,
    this.loading = false,
    this.semanticLabel,
    this.loadingSemanticLabel,
    this.statesController,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize? size;

  /// Optional icon before the label.
  final AppIcons? icon;
  final bool loading;
  final String? semanticLabel;

  /// Announced as the value of the button while [loading], for example
  /// "Loading".
  final String? loadingSemanticLabel;
  final WidgetStatesController? statesController;

  static void _ignore() {}

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolvedSize =
        size ??
        (variant == AppButtonVariant.ghost
            ? AppButtonSize.md
            : AppButtonSize.lg);
    final large = resolvedSize == AppButtonSize.lg;
    final glyph = large ? AppSizes.glyphLg : AppSizes.glyphMd;
    final solid =
        variant == AppButtonVariant.primary ||
        variant == AppButtonVariant.danger;
    final spinnerColor = switch (variant) {
      AppButtonVariant.primary => scheme.onPrimary,
      AppButtonVariant.danger => scheme.onError,
      AppButtonVariant.secondary || AppButtonVariant.ghost => scheme.primary,
    };

    final leading = loading
        ? _Spinner(
            size: glyph,
            ring: large ? AppSizes.spinnerLg : AppSizes.spinnerMd,
            color: spinnerColor,
            trackColor: solid
                ? spinnerColor.withValues(alpha: AppStateLayers.spinnerTrack)
                : scheme.surfaceContainerHigh,
          )
        : icon == null
        ? null
        : AppIcon(icon!, size: glyph);

    // The semantics live inside the button, so its node (and its focus)
    // stays the same in every state.
    final content = Semantics(
      label: semanticLabel,
      value: loading ? loadingSemanticLabel : null,
      liveRegion: loading,
      excludeSemantics: semanticLabel != null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    );

    final style = _style(scheme, resolvedSize);
    final effectiveOnPressed = loading ? _ignore : onPressed;
    final button = switch (variant) {
      AppButtonVariant.primary || AppButtonVariant.danger => FilledButton(
        onPressed: effectiveOnPressed,
        style: style,
        statesController: statesController,
        child: content,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: effectiveOnPressed,
        style: style,
        statesController: statesController,
        child: content,
      ),
      AppButtonVariant.ghost => TextButton(
        onPressed: effectiveOnPressed,
        style: style,
        statesController: statesController,
        child: content,
      ),
    };

    return IgnorePointer(ignoring: loading, child: button);
  }

  ButtonStyle _style(ColorScheme scheme, AppButtonSize resolvedSize) {
    final large = resolvedSize == AppButtonSize.lg;
    final height = large ? AppSizes.controlLg : AppSizes.controlMd;
    final radius = large ? AppRadius.md : AppRadius.sm;

    return ButtonStyle(
      // Pressed is a fill (below), so the ink overlay and the ripple of
      // Material would only double it.
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
      minimumSize: WidgetStatePropertyAll(Size(AppSizes.minDrawn, height)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => _background(scheme, states),
      ),
      foregroundColor: switch (variant) {
        AppButtonVariant.danger => WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? scheme.error
              : scheme.onError,
        ),
        AppButtonVariant.ghost => WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? scheme.onSurfaceVariant
              : states.contains(WidgetState.pressed)
              ? scheme.onSurface
              : scheme.primary,
        ),
        AppButtonVariant.primary || AppButtonVariant.secondary => null,
      },
    );
  }

  /// The fill of every state. Disabled wins over pressed, and pressed is the
  /// ink layer blended over the base fill.
  Color _background(ColorScheme scheme, Set<WidgetState> states) {
    final disabled = states.contains(WidgetState.disabled);
    final pressed = states.contains(WidgetState.pressed);
    Color pressedOver(Color fill, double alpha) =>
        Color.alphaBlend(scheme.onSurface.withValues(alpha: alpha), fill);

    return switch (variant) {
      AppButtonVariant.primary =>
        disabled
            ? scheme.surfaceContainerHigh
            : pressed
            ? pressedOver(scheme.primary, AppStateLayers.pressedPrimary)
            : scheme.primary,
      AppButtonVariant.secondary =>
        pressed && !disabled
            ? pressedOver(
                scheme.surfaceContainerLowest,
                AppStateLayers.pressedSecondary,
              )
            : scheme.surfaceContainerLowest,
      AppButtonVariant.ghost =>
        pressed && !disabled ? scheme.primaryContainer : Colors.transparent,
      AppButtonVariant.danger =>
        disabled
            ? scheme.errorContainer
            : pressed
            ? pressedOver(scheme.error, AppStateLayers.pressedDanger)
            : scheme.error,
    };
  }
}

class _Spinner extends StatefulWidget {
  const new({
    required this.size,
    required this.ring,
    required this.color,
    required this.trackColor,
  });

  /// The box the spinner takes, like the icon it replaces.
  final double size;

  /// Diameter of the ring drawn in the middle of the box.
  final double ring;
  final Color color;
  final Color trackColor;

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.spin,
  );
  late final Animation<double> _turns = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.spinCurve,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    (_turns as CurvedAnimation).dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RotationTransition(
        turns: _turns,
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _SpinnerPainter(
            widget.ring,
            widget.color,
            widget.trackColor,
          ),
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  const new(this.ring, this.color, this.trackColor);

  final double ring;
  final Color color;
  final Color trackColor;

  /// A quarter turn, starting at the top.
  static const double _sweep = math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = AppSizes.borderEmphasis;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: ring,
      height: ring,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawArc(rect, 0, 2 * math.pi, false, paint..color = trackColor)
      ..drawArc(rect, -math.pi / 2, _sweep, false, paint..color = color);
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) =>
      oldDelegate.ring != ring ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}
