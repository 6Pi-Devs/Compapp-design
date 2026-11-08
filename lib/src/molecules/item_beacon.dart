import 'package:compapp_design/src/atoms/app_icon.dart';
import 'package:compapp_design/src/atoms/app_progress_ring.dart';
import 'package:compapp_design/src/models/item_view.dart';
import 'package:compapp_design/src/tokens/app_colors_context.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';

/// A shared thing pinned to a room: its glyph, its name and a line of status,
/// as one tappable chip on top of Material's `OutlinedButton`, which
/// `CompappTheme` styles (surface fill, outline border, ink focus ring).
///
/// While the thing is [inUse] its glyph sits inside a breathing busy ring (an
/// `AppProgressRing` with no known end, which stands still when animations are
/// off) and the [statusLabel] ("34 min") is busy-colored. Free, the glyph sits
/// on a sunken tile and the [statusLabel] ("free") is muted. The ring and the
/// color are never the only cue: the status is always the text beside them.
/// It is calm on purpose: busy is amber, never a danger color, and the beacon
/// never says who is late.
///
/// The beacon is one button named by [semanticLabel] ("Washer, in use by
/// Carlos, 34 minutes"), which replaces the visible texts for assistive
/// technology, so the ring, the glyph and the texts add nothing of their own.
/// It is at least `AppSizes.minDrawn` (44) drawn and 48 to hit, and grows with
/// large text: the texts wrap, nothing is clamped. It mirrors in right-to-left
/// except the ring, which is a clock face.
class ItemBeacon extends StatelessWidget {
  const new({
    required this.item,
    required this.inUse,
    required this.statusLabel,
    required this.semanticLabel,
    required this.onTap,
    super.key,
  }) : assert(semanticLabel != '', 'The beacon needs a spoken label');

  final ItemView item;
  final bool inUse;

  /// The status line under the name: the time in use, or that it is free.
  final String statusLabel;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    final glyphColor = inUse ? colors.busy : scheme.onSurface;
    final leading = SizedBox.square(
      dimension: AppSizes.beacon,
      child: inUse
          ? Stack(
              alignment: Alignment.center,
              children: [
                const AppProgressRing(
                  semanticLabel: null,
                  tone: AppRingTone.busy,
                  size: AppSizes.beacon,
                ),
                AppIcon(item.icon, size: AppSizes.glyphMd, color: glyphColor),
              ],
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Center(
                child: AppIcon(
                  item.icon,
                  size: AppSizes.glyphMd,
                  color: glyphColor,
                ),
              ),
            ),
    );

    return OutlinedButton(
      key: Key('floorplan.item.${item.id}'),
      onPressed: onTap,
      style: const ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size.square(AppSizes.minDrawn)),
        padding: WidgetStatePropertyAll(
          EdgeInsetsDirectional.fromSTEB(
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
          ),
        ),
      ),
      child: Semantics(
        label: semanticLabel,
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: AppTypography.caption.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    statusLabel,
                    style: AppTypography.caption.copyWith(
                      color: inUse ? colors.busy : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
