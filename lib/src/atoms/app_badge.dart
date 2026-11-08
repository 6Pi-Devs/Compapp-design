import 'dart:math' as math;

import 'package:compapp_design/src/tokens/app_colors_context.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';

/// The fill of a badge. There is no danger tone: a badge counts or labels, it
/// never alarms.
enum AppBadgeTone {
  /// Solid primary with on-primary text.
  primary,

  /// Soft in-use fill with ink text.
  busy,

  /// Soft primary fill with ink text.
  soft,
}

/// A count or a short label on a small colored shape.
///
/// [AppBadge.count] is a pill that is at least 18 square, shows the number up
/// to [maxCount] and `99+` beyond it, in primary by default. A negative count
/// is shown as 0. The badge renders "0" when it is given 0: callers hide it
/// instead when there is nothing to count.
/// [AppBadge.label] is a rounded rectangle around a short text, soft by
/// default. Both grow with large text and never shrink it.
///
/// Neither fill is the information: the number or the label is, in text that
/// reaches 4.5:1 on its fill.
///
/// For assistive technology the visible text is read as it is. Pass
/// [semanticLabel] to say more than the number ("3 unread"): the badge is then
/// one labeled node and its text is excluded. Like every semantic child, the
/// badge merges into a parent that merges its children: inside a
/// `MergeSemantics` around the badge and what it badges, the parent reads
/// "Activity" and "3 unread" as one label (or "Activity" and "3" without a
/// [semanticLabel]). Under a parent that does not merge it is a node of its
/// own beside the parent's.
class AppBadge extends StatelessWidget {
  const new count(
    int this.count, {
    this.tone = AppBadgeTone.primary,
    this.semanticLabel,
    super.key,
  }) : assert(count >= 0, 'A count cannot be negative'),
       label = null;

  const new label(
    String this.label, {
    this.tone = AppBadgeTone.soft,
    this.semanticLabel,
    super.key,
  }) : count = null;

  /// The largest number shown as it is. Beyond it the badge shows
  /// `maxCount+`.
  static const int maxCount = 99;

  /// The text of a count: the number, `99+` past [maxCount], 0 below zero.
  @visibleForTesting
  static String countText(int count) =>
      count > maxCount ? '$maxCount+' : '${math.max(0, count)}';

  final int? count;
  final String? label;
  final AppBadgeTone tone;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (fill, ink) = switch (tone) {
      AppBadgeTone.primary => (scheme.primary, scheme.onPrimary),
      AppBadgeTone.busy => (context.appColors.busySoft, scheme.onSurface),
      AppBadgeTone.soft => (scheme.primaryContainer, scheme.onSurface),
    };

    final count = this.count;
    final Widget badge;
    if (count != null) {
      badge = DecoratedBox(
        decoration: ShapeDecoration(color: fill, shape: const StadiumBorder()),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSizes.badgeCount,
            minHeight: AppSizes.badgeCount,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.badgeCountPadding,
              ),
              child: Text(
                countText(count),
                style: AppTypography.badgeCount.copyWith(color: ink),
                textDirection: TextDirection.ltr,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ),
        ),
      );
    } else {
      badge = DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppSizes.badgeLabelRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            label!,
            style: AppTypography.badgeLabel.copyWith(color: ink),
          ),
        ),
      );
    }

    final spoken = semanticLabel;
    if (spoken == null || spoken.isEmpty) return badge;
    return Semantics(
      container: true,
      label: spoken,
      excludeSemantics: true,
      child: badge,
    );
  }
}
