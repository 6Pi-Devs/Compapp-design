import 'dart:math' as math;

import 'package:compapp_design/src/atoms/app_icon.dart';
import 'package:compapp_design/src/models/app_icons.dart';
import 'package:compapp_design/src/tokens/app_colors_context.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';

/// Side of a pebble. The number is the side in logical pixels.
enum AppPebbleSize {
  s28(AppSizes.pebbleXs, AppTypography.pebbleXs, AppTypography.pebbleXsPair),
  s36(AppSizes.pebbleSm, AppTypography.pebbleSm, AppTypography.pebbleSm),
  s44(AppSizes.pebbleMd, AppTypography.pebbleMd, AppTypography.pebbleMd),
  s56(AppSizes.pebbleLg, AppTypography.pebbleLg, AppTypography.pebbleLg),
  s72(AppSizes.pebbleXl, AppTypography.pebbleXl, AppTypography.pebbleXl);

  new(this.side, this.initialsStyle, this.pairStyle);

  final double side;

  /// The font token of one initial at this size (the board size).
  final TextStyle initialsStyle;

  /// The font token of two initials. Only s28 reduces it, so "MW" fits.
  final TextStyle pairStyle;

  /// The font token for [initials]: one letter keeps the board size, two use
  /// [pairStyle].
  TextStyle styleFor(String initials) =>
      initials.characters.length > 1 ? pairStyle : initialsStyle;

  /// Whether the pebble draws the away and admin badges: from s44 up. Below
  /// that the badges would cover the initials, so s28 and s36 draw the plain
  /// pebble and leave away and admin to the semantic label and the text
  /// nearby.
  bool get hasBadges => side >= AppSizes.pebbleMd;
}

/// Where a member is. [home] adds nothing to the pebble: only [away] (a moon
/// badge) and [invited] (a dashed outline, no fill) are drawn.
enum AppPebbleStatus { home, away, invited }

/// A person: their initials on a colored pebble.
///
/// The color comes from [joinOrder] through `AppColors.pebbleAt`. Pass a
/// stable join sequence (the order in which members joined the home), never a
/// list index: an index shifts every color after a member who leaves.
///
/// Status and role are drawn as shapes: [AppPebbleStatus.away] is a moon
/// badge, [AppPebbleStatus.invited] a dashed outline without fill, [isAdmin] a
/// key badge and [isYou] a solid 2 px ring. When [isYou] and
/// [AppPebbleStatus.invited] meet, the solid ring wins over the dashed one.
///
/// The ring of a filled pebble is inset by its own width and drawn in the dark
/// `AppColors.onPebble`: the pebble colors are pastel in both themes while the
/// ink turns light in dark mode, so an ink border at the edge would vanish
/// against the fill. An invited pebble has no fill, so its ring sits at the
/// edge in ink.
///
/// The pebble is always a square. At text scale 1 it is exactly [size], for
/// every state and for one or two initials up to "MW": the font tokens are
/// sized so the font's whole ascent and descent, accents and descenders
/// included, stay inside the ring band with a gap. Wider pairs ("WW", "ÆW") do
/// not fit the two smallest sizes at a readable font size, so there the pebble
/// grows by a pixel or two instead of shrinking the text. With larger text it
/// grows, from the scaled text alone and without a jump, never shrinking the
/// initials: the side is the larger of [size] and what the text needs.
///
/// From s44 up the side also reserves room for the two badge squares, in every
/// state, so pebbles of one size stay equal in a row. The clearance is the
/// text line box, whose height is the capital height: capitals are never
/// covered by a badge, at any text scale. On s44 and up a badge may cover the
/// tip of an accent or a descender on two-letter initials ("MÁ" under the key,
/// "Wg" under the moon): that is accepted, so the pebbles keep their exact
/// sizes. The ring is different: the whole ascent and descent of the font stay
/// inside its band.
///
/// The away and admin badges render only from s44 up (see
/// [AppPebbleSize.hasBadges]). On s28 and s36 away and admin are not drawn:
/// say them in [semanticLabel] and in the text next to the pebble.
///
/// The status badge hangs at the bottom trailing corner, like the board. The
/// admin key hangs at the top trailing corner: the board draws it at the
/// bottom too, which would put it on top of the status badge. Both hang
/// `AppSizes.pebbleBadgeOffset` (4) outside the pebble and mirror in
/// right-to-left. A row of pebbles needs at least `AppSpacing.xs` between them
/// and no clipping parent, or the badges are cut off or touch the neighbor.
///
/// [semanticLabel] is the whole spoken description ("Ana, you, admin") and
/// must not be empty: the pebble is one image node and everything drawn in it
/// is excluded. It has `container: true`, so it is a node of its own under a
/// parent that does not merge. Under a parent that merges its children (a
/// `MergeSemantics` row, as a member row will be) it merges into that node, as
/// every semantic child does, and its label joins the row's.
class AppPebble extends StatelessWidget {
  const new({
    required this.initials,
    required this.joinOrder,
    required this.semanticLabel,
    this.size = AppPebbleSize.s44,
    this.status = AppPebbleStatus.home,
    this.isYou = false,
    this.isAdmin = false,
    super.key,
  }) : assert(semanticLabel != '', 'The pebble needs a spoken label');

  final String initials;

  /// Position of the member in the home, which picks the pebble color.
  final int joinOrder;
  final String semanticLabel;
  final AppPebbleSize size;
  final AppPebbleStatus status;
  final bool isYou;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final invited = status == AppPebbleStatus.invited;
    final away = status == AppPebbleStatus.away;

    final outline = switch ((invited, isYou)) {
      (true, false) => _Outline(
        color: scheme.onSurfaceVariant,
        width: AppSizes.borderDashed,
        dashed: true,
      ),
      (true, true) => _Outline(
        color: scheme.onSurface,
        width: AppSizes.borderEmphasis,
      ),
      (false, true) => _Outline(
        color: colors.onPebble,
        width: AppSizes.borderEmphasis,
        inset: AppSizes.borderEmphasis,
      ),
      (false, false) => null,
    };

    // The side: the nominal one, or what the scaled initials need. The text
    // line box must clear the badge squares of both trailing corners (reserved
    // from s44 up in every state, so equal pebbles stay equal), and the font's
    // whole ascent and descent must stay inside the ring band and a gap: the
    // line box can be shorter than the font's envelope, and accents and
    // descenders live in the difference.
    final textStyle = size.styleFor(initials);
    final textScaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    TextPainter layout(TextStyle style) => TextPainter(
      text: TextSpan(text: initials, style: style),
      textDirection: direction,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final boxed = layout(textStyle);
    final natural = layout(
      TextStyle(
        fontFamily: textStyle.fontFamily,
        fontSize: textStyle.fontSize,
        fontWeight: textStyle.fontWeight,
        fontVariations: textStyle.fontVariations,
        fontFeatures: textStyle.fontFeatures,
        letterSpacing: textStyle.letterSpacing,
      ),
    );
    final boxedLine = boxed.computeLineMetrics();
    final naturalLine = natural.computeLineMetrics();
    final reach = boxedLine.isEmpty || naturalLine.isEmpty
        ? 0.0
        : math.max(
            naturalLine.first.ascent - boxedLine.first.ascent,
            naturalLine.first.descent - boxedLine.first.descent,
          );
    final textWidth = boxed.width;
    final textHeight = boxed.height;
    boxed.dispose();
    natural.dispose();
    final showAway = away && size.hasBadges;
    final showAdmin = isAdmin && size.hasBadges;
    final badgeRoom = size.hasBadges
        ? textHeight + 2 * (AppSizes.pebbleBadge - AppSizes.pebbleBadgeOffset)
        : 0.0;
    final side = math.max(
      math.max(size.side, badgeRoom),
      math.max(
        textWidth + 2 * AppSpacing.xs,
        textHeight + 2 * (AppSpacing.xs + math.max(0, reach)),
      ),
    );

    final face = SizedBox.square(
      dimension: side,
      child: CustomPaint(
        foregroundPainter: outline == null
            ? null
            : _OutlinePainter(outline, AppRadius.pebble(side)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: invited ? null : colors.pebbleAt(joinOrder),
            borderRadius: AppRadius.pebble(side),
          ),
          child: Center(
            child: Text(
              initials,
              style: textStyle.copyWith(
                color: invited ? scheme.onSurfaceVariant : colors.onPebble,
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      image: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          face,
          if (showAway)
            PositionedDirectional(
              end: -AppSizes.pebbleBadgeOffset,
              bottom: -AppSizes.pebbleBadgeOffset,
              child: _Badge(
                key: const Key('pebble.badge.away'),
                icon: AppIcons.away,
                fill: colors.presenceAway,
                glyph: colors.onPresenceAway,
              ),
            ),
          if (showAdmin)
            PositionedDirectional(
              end: -AppSizes.pebbleBadgeOffset,
              top: -AppSizes.pebbleBadgeOffset,
              child: _Badge(
                key: const Key('pebble.badge.admin'),
                icon: AppIcons.adminKey,
                fill: scheme.inverseSurface,
                glyph: scheme.onInverseSurface,
              ),
            ),
        ],
      ),
    );
  }
}

/// A small rounded square with a glyph, cut out of the pebble by a ring in the
/// card color.
class _Badge extends StatelessWidget {
  const new({
    required this.icon,
    required this.fill,
    required this.glyph,
    super.key,
  });

  final AppIcons icon;
  final Color fill;
  final Color glyph;

  @override
  Widget build(BuildContext context) {
    const side = AppSizes.pebbleBadge;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadius.pebble(side),
        border: Border.all(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          width: AppSizes.borderEmphasis,
        ),
      ),
      child: SizedBox.square(
        dimension: side,
        child: Center(
          child: AppIcon(icon, size: AppSizes.pebbleBadgeGlyph, color: glyph),
        ),
      ),
    );
  }
}

/// The ring of a pebble: its [color] and [width], solid or [dashed], drawn
/// [inset] from the edge.
class _Outline {
  const new({
    required this.color,
    required this.width,
    this.inset = 0,
    this.dashed = false,
  });

  final Color color;
  final double width;
  final double inset;
  final bool dashed;
}

class _OutlinePainter extends CustomPainter {
  const new(this.outline, this.radius);

  final _Outline outline;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final width = outline.width;
    final ring = radius
        .toRRect(Offset.zero & size)
        .deflate(outline.inset + width / 2);
    final paint = Paint()
      ..color = outline.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    if (!outline.dashed) {
      canvas.drawRRect(ring, paint);
      return;
    }
    final dash = width * AppSizes.dash;
    final period = dash + width * AppSizes.dashGap;
    for (final metric in (Path()..addRRect(ring)).computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += period) {
        canvas.drawPath(
          metric.extractPath(start, math.min(start + dash, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_OutlinePainter oldDelegate) =>
      oldDelegate.outline.color != outline.color ||
      oldDelegate.outline.width != outline.width ||
      oldDelegate.outline.inset != outline.inset ||
      oldDelegate.outline.dashed != outline.dashed ||
      oldDelegate.radius != radius;
}
