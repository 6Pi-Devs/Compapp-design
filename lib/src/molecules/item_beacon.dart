import 'package:compapp_design/src/atoms/app_icon.dart';
import 'package:compapp_design/src/atoms/app_progress_ring.dart';
import 'package:compapp_design/src/models/app_icons.dart';
import 'package:compapp_design/src/models/item_status.dart';
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
/// The [status] says who has it. [ItemStatus.free]: the glyph sits on a
/// sunken tile and the [statusLabel] ("free") is muted. [ItemStatus.mine] and
/// [ItemStatus.others]: the glyph sits inside a breathing busy ring (an
/// `AppProgressRing` with no known end, which stands still when animations are
/// off) and the [statusLabel] ("34 min") is busy-colored. The two used states
/// differ by a small glyph before the status text, a check for mine and a lock
/// for others, so color is never the only cue; the status is also always the
/// text beside them. It is calm on purpose: busy is amber, never a danger
/// color, and the beacon never says who is late.
///
/// While [busy] (an action started from the beacon is running) the ring is a
/// primary-colored one around the glyph, whatever the status, and the beacon
/// keeps its size, its element tree and its keyboard focus. Taps, long
/// presses, Enter and Space, and the semantic actions are all ignored. It is
/// still a button named by [semanticLabel], with [busySemanticLabel] as its
/// value in a live region (Flutter has no busy flag).
///
/// [onTap] is the main action. [onLongPress] is an optional secondary one
/// (it is also a semantic long press action).
///
/// The beacon is one button named by [semanticLabel] ("Washer, in use by
/// Carlos, 34 minutes"), which replaces the visible texts for assistive
/// technology, so the ring, the glyphs and the texts add nothing of their own.
/// It is at least `AppSizes.minDrawn` (44) drawn and 48 to hit, and grows with
/// large text: the texts wrap, nothing is clamped. It mirrors in right-to-left
/// except the ring, which is a clock face.
class ItemBeacon extends StatelessWidget {
  const new({
    required this.item,
    required this.status,
    required this.statusLabel,
    required this.semanticLabel,
    required this.onTap,
    this.onLongPress,
    this.busy = false,
    this.busySemanticLabel,
    super.key,
  }) : assert(semanticLabel != '', 'The beacon needs a spoken label');

  final ItemView item;

  /// Who has the item: nobody, the person, or someone else.
  final ItemStatus status;

  /// The status line under the name: the time in use, or that it is free.
  final String statusLabel;
  final String semanticLabel;
  final VoidCallback onTap;

  /// An optional secondary action. Null: a long press does nothing.
  final VoidCallback? onLongPress;

  /// An action started from the beacon is running: it shows a ring and
  /// ignores every activation.
  final bool busy;

  /// Announced as the value of the beacon while [busy], for example
  /// "Updating".
  final String? busySemanticLabel;

  static void _ignore() {}

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    final used = status != ItemStatus.free;
    final glyphColor = used ? colors.busy : scheme.onSurface;
    final statusColor = used ? colors.busy : scheme.onSurfaceVariant;
    final marker = switch (status) {
      ItemStatus.free => null,
      ItemStatus.mine => AppIcons.check,
      ItemStatus.others => AppIcons.occupied,
    };
    final leading = SizedBox.square(
      dimension: AppSizes.beacon,
      child: used || busy
          ? Stack(
              alignment: Alignment.center,
              children: [
                AppProgressRing(
                  semanticLabel: null,
                  tone: busy ? AppRingTone.primary : AppRingTone.busy,
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

    final button = OutlinedButton(
      key: Key('floorplan.item.${item.id}'),
      onPressed: busy ? _ignore : onTap,
      onLongPress: busy && onLongPress != null ? _ignore : onLongPress,
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
        value: busy ? busySemanticLabel : null,
        liveRegion: busy,
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (marker != null) ...[
                        AppIcon(
                          marker,
                          size: AppSizes.glyphMd,
                          color: statusColor,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Flexible(
                        child: Text(
                          statusLabel,
                          style: AppTypography.caption.copyWith(
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return IgnorePointer(ignoring: busy, child: button);
  }
}
