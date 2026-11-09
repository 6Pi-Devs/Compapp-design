import 'dart:math' as math;

import 'package:compapp_design/src/atoms/app_icon.dart';
import 'package:compapp_design/src/atoms/app_pebble.dart';
import 'package:compapp_design/src/models/app_icons.dart';
import 'package:compapp_design/src/models/member_status.dart';
import 'package:compapp_design/src/models/member_view.dart';
import 'package:compapp_design/src/models/room_tile_state.dart';
import 'package:compapp_design/src/models/room_view.dart';
import 'package:compapp_design/src/tokens/app_colors_context.dart';
import 'package:compapp_design/src/tokens/app_decor.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';

/// A room of the home on the plan: its name, a [caption] under it, the
/// [beacons] pinned at the bottom start and the [occupants] as pebbles at the
/// bottom end of the same line while both fit. When they do not fit on one
/// line the pebbles wrap under the beacons and start there, because a wrapped
/// line has nothing to push them to the end.
///
/// The look follows [state], and the text of [caption] always says it too
/// ("home", "occupied, 12 min", "away", "free"), so the look is never the only
/// cue. [RoomTileState.home] is a primary-soft wall with a presence-home
/// edge and a soft glow, [RoomTileState.occupied] an in-use amber wall with a
/// lock beside the name, [RoomTileState.away] a sunken wall with a muted
/// caption, and [RoomTileState.free] an empty surface with a dashed outline.
/// The glow, the hairline edges and the dashed outline are decoration in the
/// hairline color: the tile is not interactive, so no edge is a control
/// boundary, and the caption and the lock carry the state. Busy is amber,
/// never a danger color.
///
/// The tile is not interactive. It is one node for assistive technology, named
/// by [semanticLabel] ("Bathroom, occupied by Carlos, 12 minutes"): the name,
/// the caption, the lock and the pebbles add nothing of their own. The
/// [beacons] are not part of that node: each stays its own button, a child of
/// the tile, so they are announced and focused one by one. A beacon is any
/// widget (an `ItemBeacon`): a molecule cannot import another one, so the
/// organism that composes them passes them in.
///
/// Not here yet, left to the organisms that need them: an `onTap` (the
/// `FloorplanMap` tile is tappable, and a tappable tile around buttons needs
/// its own semantics design), and the `archived` and `draw` states of the
/// contract (`RoomDrawBoard` draws the tile in its draw form).
///
/// It fills the height it is given and otherwise takes the height of its
/// content. A row of the plan is a least height (about 100): it grows with the
/// text scale, so the plan gives the tile the height of its tallest content
/// and not a fixed one. The beacons and the pebbles share a line while they
/// fit (a beacon and one pebble fit a cell 170 wide) and wrap onto more lines
/// when they do not; a beacon cannot shrink below its glyph. It mirrors in
/// right-to-left.
class RoomTile extends StatelessWidget {
  const new({
    required this.room,
    required this.state,
    required this.caption,
    required this.semanticLabel,
    this.occupants = const [],
    this.beacons = const [],
    super.key,
  }) : assert(semanticLabel != '', 'The tile needs a spoken label');

  final RoomView room;
  final RoomTileState state;

  /// The line under the name, which says the state in words.
  final String caption;
  final String semanticLabel;

  /// Who is in the room now, drawn as small pebbles.
  final List<MemberView> occupants;

  /// The things pinned to the room.
  final List<Widget> beacons;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    const edge = AppDecor.roomEdge;

    final (fill, border, captionColor, shadows) = switch (state) {
      RoomTileState.home => (
        scheme.primaryContainer,
        colors.presenceHome,
        scheme.onSurface,
        [
          BoxShadow(
            color: colors.presenceHome.withValues(alpha: edge),
            spreadRadius: AppSpacing.xs,
          ),
        ],
      ),
      RoomTileState.away => (
        scheme.surfaceContainerHigh,
        scheme.outlineVariant,
        scheme.onSurfaceVariant,
        const <BoxShadow>[],
      ),
      RoomTileState.occupied => (
        colors.busySoft,
        colors.busy.withValues(alpha: edge),
        scheme.onSurface,
        const <BoxShadow>[],
      ),
      RoomTileState.free => (
        scheme.surfaceContainerLowest,
        scheme.outlineVariant,
        scheme.onSurfaceVariant,
        const <BoxShadow>[],
      ),
    };
    final side = BorderSide(color: border, width: AppSizes.borderRoom);
    const radius = BorderRadius.all(Radius.circular(AppRadius.md));
    final ShapeBorder shape = state == RoomTileState.free
        ? _DashedBorder(borderRadius: radius, side: side)
        : RoundedRectangleBorder(borderRadius: radius, side: side);

    final header = ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  room.name,
                  style: AppTypography.label.copyWith(color: scheme.onSurface),
                ),
              ),
              if (state == RoomTileState.occupied) ...[
                const SizedBox(width: AppSpacing.xs),
                AppIcon(
                  AppIcons.occupied,
                  size: AppSizes.glyphMd,
                  color: colors.busy,
                ),
              ],
            ],
          ),
          Text(
            caption,
            style: AppTypography.caption.copyWith(color: captionColor),
          ),
        ],
      ),
    );

    final pebbles = occupants.isEmpty
        ? null
        : ExcludeSemantics(
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              alignment: WrapAlignment.end,
              children: [
                for (final member in occupants)
                  AppPebble(
                    key: Key('roomTile.pebble.${member.id}'),
                    initials: member.initials,
                    joinOrder: member.joinOrder,
                    semanticLabel: member.semanticLabel,
                    size: AppPebbleSize.s36,
                    status: switch (member.status) {
                      MemberStatus.home => AppPebbleStatus.home,
                      MemberStatus.away => AppPebbleStatus.away,
                      MemberStatus.invited => AppPebbleStatus.invited,
                    },
                    isYou: member.isYou,
                    isAdmin: member.isAdmin,
                  ),
              ],
            ),
          );
    final pinned = beacons.isEmpty
        ? null
        : Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: beacons,
          );
    // One Wrap puts the beacons at the start and the pebbles at the end of a
    // line while both fit, and wraps the pebbles under the beacons when they
    // do not. A Wrap measures its intrinsic sizes, which the golden harness
    // needs, and a beacon cannot shrink below its glyph.
    final footer = (pinned == null && pebbles == null)
        ? null
        : Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            alignment: pinned != null && pebbles != null
                ? WrapAlignment.spaceBetween
                : pebbles != null
                ? WrapAlignment.end
                : WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [?pinned, ?pebbles],
          );

    return Semantics(
      key: Key('floorplan.room.${room.id}'),
      container: true,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: fill,
          shape: shape,
          shadows: shadows,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [header, ?footer],
          ),
        ),
      ),
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
