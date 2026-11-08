import 'dart:math' as math;

import 'package:compapp_design/src/tokens/app_colors_context.dart';
import 'package:compapp_design/src/tokens/app_motion.dart';
import 'package:compapp_design/src/tokens/app_progress.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';

/// Colors of the ring: [busy] is the in-use amber on a soft amber track,
/// [primary] the green on a sunken track.
enum AppRingTone { busy, primary }

/// A progress ring.
///
/// With a [value] from 0 to 1 (clamped) it draws that part of the circle,
/// clockwise from the top, in every reading direction: a ring is a clock face,
/// not a line of text. With no [value] it is "in use, no known end": a
/// quarter-ish arc whose opacity breathes over `AppMotion.inUse`. The arc
/// stands still, at full opacity, when `MediaQuery.disableAnimations` is on.
/// It only shows how far along something is. It never turns red, and it says
/// nothing about who is behind.
///
/// A short [label] (a count such as "11") is drawn in the middle. The ring is
/// at least [size] square and grows with large text so the label stays inside
/// it, never shrinking the text.
///
/// [semanticLabel] is required but may be null. A label ("Chores") makes the
/// ring one node, with [semanticValue] ("11 of 15 done", required with a
/// [value]) as its value; the middle label and the drawing are excluded. Null
/// leaves the ring out of semantics, for a ring whose neighbouring text already
/// says what it is and how far (an in-use ring inside a labeled parent). Like
/// any semantic child the node merges into a parent that merges its children.
/// An in-use ring never exposes a [semanticValue].
///
/// A [value] that is not finite is shown as 0, and fails an assert in debug.
class AppProgressRing extends StatelessWidget {
  const new({
    required this.semanticLabel,
    this.value,
    this.tone = AppRingTone.primary,
    this.size = AppSizes.ring,
    this.label,
    this.semanticValue,
    super.key,
  }) : assert(
         value == null ||
             semanticLabel == null ||
             semanticLabel == '' ||
             semanticValue != null,
         'A ring with a value and a label needs a semanticValue',
       ),
       assert(
         // x - x is 0 for a finite number and NaN for NaN and infinity.
         value == null || value - value == 0,
         'The value must be finite',
       );

  /// How far along, from 0 to 1, or null when there is no known end.
  final double? value;
  final AppRingTone tone;

  /// The least side of the ring.
  final double size;

  /// Text in the middle of the ring.
  final String? label;
  final String? semanticLabel;
  final String? semanticValue;

  /// How much of the circle an arc covers, from 0 to 1: the [value] clamped,
  /// 0 for one that is not finite.
  @visibleForTesting
  static double sweepOf(double value) =>
      value.isFinite ? value.clamp(0.0, 1.0) : 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final (track, arc) = switch (tone) {
      AppRingTone.busy => (colors.busySoft, colors.busy),
      AppRingTone.primary => (scheme.surfaceContainerHigh, scheme.primary),
    };

    final text = label;
    var side = size;
    TextStyle? style;
    if (text != null && text.isNotEmpty) {
      style = AppTypography.ringLabel.copyWith(color: scheme.onSurface);
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      // The label is a box in a circle: its diagonal is the inner diameter.
      final diagonal = math.sqrt(
        painter.width * painter.width + painter.height * painter.height,
      );
      painter.dispose();
      side = math.max(
        size,
        diagonal + 2 * (AppSizes.ringStroke + AppSpacing.xs),
      );
    }

    final breathing = value == null;
    final known = value;
    final ring = SizedBox.square(
      dimension: side,
      child: _Ring(
        track: track,
        arc: arc,
        sweep: breathing ? AppProgress.ringSweep : sweepOf(known!),
        breathing: breathing,
        label: style == null ? null : Text(text!, style: style, maxLines: 1),
      ),
    );
    final spoken = semanticLabel;
    if (spoken == null || spoken.isEmpty) return ExcludeSemantics(child: ring);
    return Semantics(
      container: true,
      label: spoken,
      value: breathing ? null : semanticValue,
      excludeSemantics: true,
      child: ring,
    );
  }
}

class _Ring extends StatefulWidget {
  const new({
    required this.track,
    required this.arc,
    required this.sweep,
    required this.breathing,
    required this.label,
  });

  final Color track;
  final Color arc;

  /// The part of the circle the arc covers, from 0 to 1.
  final double sweep;
  final bool breathing;
  final Widget? label;

  @override
  State<_Ring> createState() => _RingState();
}

class _RingState extends State<_Ring> with TickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(_Ring oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final animate =
        widget.breathing && !MediaQuery.disableAnimationsOf(context);
    if (!animate) {
      _controller?.dispose();
      _controller = null;
      return;
    }
    final controller = _controller ??= AnimationController(
      vsync: this,
      duration: AppMotion.inUse,
    );
    if (!controller.isAnimating) controller.repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          // The breathing repaints only the ring, not the layer around it.
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _RingPainter(
                track: widget.track,
                arc: widget.arc,
                sweep: widget.sweep,
                breathe: _controller,
              ),
            ),
          ),
        ),
        ?widget.label,
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  new({
    required this.track,
    required this.arc,
    required this.sweep,
    required this.breathe,
  }) : super(repaint: breathe);

  final Color track;
  final Color arc;
  final double sweep;

  /// One period of the breathing, or null for an arc that stands still.
  final Animation<double>? breathe;

  /// Opacity of the arc: full at the start of the period, lowest in the
  /// middle, full again at the end, eased both ways.
  double get _opacity {
    final period = breathe?.value;
    if (period == null) return 1;
    final half = period < 0.5 ? period * 2 : (1 - period) * 2;
    return 1 -
        (1 - AppProgress.ringBreatheOpacity) *
            AppMotion.inUseCurve.transform(half);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = AppSizes.ringStroke;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = track);
    if (sweep <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * sweep,
      false,
      paint..color = arc.withValues(alpha: arc.a * _opacity),
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.track != track ||
      oldDelegate.arc != arc ||
      oldDelegate.sweep != sweep ||
      oldDelegate.breathe != breathe;
}
