import 'dart:math' as math;

import 'package:compapp_design/src/atoms/app_button.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';

/// What a screen shows when it has nothing yet: a dashed floor plan motif, a
/// title, a body and an optional action.
///
/// The words are the app's: the state never blames anyone and says what the
/// screen is for or how to fill it ("Add the washer, the oven or anything the
/// house takes turns with"). Every string is a prop.
///
/// The action is the primary [AppButton] of the screen and shows only when
/// [actionLabel] is a non-empty string. A null [onAction] disables it.
///
/// For assistive technology the title and the body are one text node read
/// together, and the action is a button after it. The motif is decorative and
/// excluded. The content is centered and wraps with large text, so the state
/// grows instead of clipping: put it in a scrollable screen, as large text can
/// make it taller than the screen. In right-to-left text the rooms of the motif
/// mirror with the layout.
class AppEmptyState extends StatelessWidget {
  const new({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String body;

  /// Text of the action. Null or empty leaves the action out.
  final String? actionLabel;

  /// Called by the action. Null disables it.
  final VoidCallback? onAction;

  static const double _gap = AppSpacing.sm + AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final actionLabel = this.actionLabel;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ExcludeSemantics(
              child: _PlanMotif(key: Key('emptyState.motif')),
            ),
            const SizedBox(height: _gap),
            MergeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    key: const Key('emptyState.title'),
                    textAlign: TextAlign.center,
                    style: AppTypography.title.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: _gap),
                  Text(
                    body,
                    key: const Key('emptyState.body'),
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (actionLabel != null && actionLabel.isNotEmpty) ...[
              const SizedBox(height: _gap),
              AppButton(
                key: const Key('emptyState.action'),
                label: actionLabel,
                onPressed: onAction,
                size: AppButtonSize.md,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The dashed plan: a room outline holding three small rooms over one wide
/// and one small, like a floor plan seen from above.
class _PlanMotif extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    const gap = AppSpacing.xs;

    Widget room() => Expanded(
      child: _DashedBox(color: color, radius: AppRadius.xs),
    );

    return SizedBox(
      width: AppSizes.emptyMotifWidth,
      height: AppSizes.emptyMotifHeight,
      child: _DashedBox(
        color: color,
        radius: AppRadius.md,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    room(),
                    const SizedBox(width: gap),
                    room(),
                    const SizedBox(width: gap),
                    room(),
                  ],
                ),
              ),
              const SizedBox(height: gap),
              Expanded(
                // Two columns wide and a gap, like a grid cell that spans two.
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final column = (constraints.maxWidth - 2 * gap) / 3;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 2 * column + gap,
                          child: _DashedBox(color: color, radius: AppRadius.xs),
                        ),
                        const SizedBox(width: gap),
                        room(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A rounded rectangle with a dashed `border-dashed` outline.
class _DashedBox extends StatelessWidget {
  const new({required this.color, required this.radius, this.child});

  final Color color;
  final double radius;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedPainter(color, radius),
      child: child,
    );
  }
}

class _DashedPainter extends CustomPainter {
  const new(this.color, this.radius);

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const width = AppSizes.borderDashed;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ).deflate(width / 2),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    const dash = width * AppSizes.dash;
    const period = dash + width * AppSizes.dashGap;
    for (final metric in outline.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += period) {
        canvas.drawPath(
          metric.extractPath(start, math.min(start + dash, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
