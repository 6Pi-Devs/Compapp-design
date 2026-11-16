import 'dart:math' as math;

import 'package:compapp_design/src/atoms/app_icon.dart';
import 'package:compapp_design/src/atoms/app_pebble.dart';
import 'package:compapp_design/src/foundation/dashed_border.dart';
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
import 'package:compapp_design/src/tokens/app_state_layers.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/foundation.dart';
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
/// The tile is one node for assistive technology, named by [semanticLabel]
/// ("Bathroom, occupied by Carlos, 12 minutes"): the name, the caption, the
/// lock and the pebbles add nothing of their own. The [beacons] are not part of
/// that node: each stays its own button, a child of the tile, so they are
/// announced and focused one by one. A beacon is any widget (an `ItemBeacon`):
/// a molecule cannot import another one, so the organism that composes them
/// passes them in.
///
/// With an [onTap] the tile is also a button: the node says so, it takes the
/// focus (Enter and Space activate it) and a press shows the surface state
/// layer over the wall. A beacon inside it keeps its own tap: a touch on the
/// beacon never reaches the tile. Focus is the house ring, 2 px of ink drawn
/// outside the shape, so a parent that clips needs `AppSizes.borderEmphasis`
/// of room around the tile, and a neighbor that paints after it must not cover
/// it. A press that starts on a beacon is the beacon's: the tile shows no
/// press layer for it, from the first moment to the release. Without [onTap]
/// the tile is plain: no button, no focus, no state layer. Going from no
/// [onTap] to one, or back, remounts the tile (and so drops its focus), because
/// the plain tile is a different widget; keep it non-null for the life of a
/// screen.
///
/// With [draw] the tile takes its draw form, the one of a bedroom in the
/// result of a room draw: the name alone on top, and at the bottom the pebbles
/// of the people who go there at the start of the line with the [caption]
/// ("from Bedroom 3", "Stays free") beside them, wrapping under them when the
/// line is full. The look still follows [state] (a bedroom with people is
/// `home`, one that stays empty is `free`), and the caption says it in words.
/// The draw form has no beacons. Without [draw] the tile is exactly as it was.
///
/// Not here: the `archived` state of the contract, which the board does not
/// draw.
///
/// It fills the height it is given and otherwise takes the height of its
/// content. A row of the plan is a least height (`FloorplanMap` uses
/// `AppSizes.rowTall`, 72): it grows with the text scale, so the plan gives the
/// tile the height of its tallest content and not a fixed one. The beacons and
/// the pebbles share a line while they fit (a beacon and one pebble fit a cell
/// 170 wide) and wrap onto more lines when they do not; a beacon cannot shrink
/// below its glyph. It mirrors in right-to-left.
class RoomTile extends StatelessWidget {
  const new({
    required this.room,
    required this.state,
    required this.caption,
    required this.semanticLabel,
    this.occupants = const [],
    this.beacons = const [],
    this.onTap,
    this.draw = false,
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

  /// Called by a tap, Enter or Space on the tile itself. Null leaves the tile
  /// plain.
  final VoidCallback? onTap;

  /// Draws the tile in its draw form: the caption sits at the bottom, beside
  /// the pebbles, instead of under the name.
  final bool draw;

  @override
  Widget build(BuildContext context) {
    assert(!draw || beacons.isEmpty, 'The draw form of a tile has no beacons');
    assert(
      !draw || semanticLabel.contains(room.name),
      'The spoken label of a draw tile contains its visible name (label in '
      'name)',
    );
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
        ? DashedBorder(borderRadius: radius, side: side)
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
          if (!draw)
            Text(
              caption,
              style: AppTypography.caption.copyWith(color: captionColor),
            ),
        ],
      ),
    );

    Widget pebble(MemberView member) => AppPebble(
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
    );

    final pebbles = occupants.isEmpty
        ? null
        : ExcludeSemantics(
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              alignment: WrapAlignment.end,
              children: [for (final member in occupants) pebble(member)],
            ),
          );
    final pinned = beacons.isEmpty
        ? null
        : Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final beacon in beacons)
                if (this.onTap == null)
                  beacon
                else
                  // Keyed like its beacon (wrapped), so a beacon that keeps
                  // its key keeps its element and focus when earlier ones go.
                  _BeaconGuard(
                    key: beacon.key == null ? null : ValueKey(beacon.key),
                    child: beacon,
                  ),
            ],
          );
    // One Wrap puts the beacons at the start and the pebbles at the end of a
    // line while both fit, and wraps the pebbles under the beacons when they
    // do not. A Wrap measures its intrinsic sizes, which the golden harness
    // needs, and a beacon cannot shrink below its glyph.
    // The draw form puts the pebbles at the start of the line and the caption
    // beside them, as one Wrap, so the caption drops under the pebbles when
    // the line is full and no word is cut.
    final footer = draw
        ? ExcludeSemantics(
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final member in occupants) pebble(member),
                Text(
                  caption,
                  style: AppTypography.caption.copyWith(color: captionColor),
                ),
              ],
            ),
          )
        : (pinned == null && pebbles == null)
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

    final wall = DecoratedBox(
      decoration: ShapeDecoration(color: fill, shape: shape, shadows: shadows),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [header, ?footer],
        ),
      ),
    );

    final key = Key('floorplan.room.${room.id}');
    final onTap = this.onTap;
    if (onTap != null) {
      return _TappableTile(
        key: key,
        label: semanticLabel,
        onTap: onTap,
        child: wall,
      );
    }
    return Semantics(
      key: key,
      container: true,
      label: semanticLabel,
      child: wall,
    );
  }
}

/// The node, the focus, the activation and the focus and press layers of a
/// tile with an `onTap`. The node holds the label, the button role and the tap,
/// and the beacons are children of it.
class _TappableTile extends StatefulWidget {
  const new({
    required this.label,
    required this.onTap,
    required this.child,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_TappableTile> createState() => _TappableTileState();
}

class _TappableTileState extends State<_TappableTile> {
  final _focus = FocusNode(debugLabel: 'RoomTile');
  bool _hasFocus = false;
  bool _showRing = false;
  bool _pressed = false;
  int _beaconPointers = 0;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_update);
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    _focus
      ..removeListener(_update)
      ..dispose();
    super.dispose();
  }

  void _onHighlightMode(FocusHighlightMode mode) => _update();

  /// The ring is for the tile that holds the primary focus, not for one whose
  /// beacon does, and only while the person is using a keyboard.
  void _update() {
    final hasFocus = _focus.hasPrimaryFocus;
    final showRing =
        hasFocus &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (hasFocus == _hasFocus && showRing == _showRing) return;
    setState(() {
      _hasFocus = hasFocus;
      _showRing = showRing;
    });
  }

  /// A pointer is down inside a beacon: the press is the beacon's, and the
  /// tile shows no layer for it (Material's `markChildInkResponsePressed`).
  void _beaconPointer({required bool down}) {
    _beaconPointers = math.max(0, _beaconPointers + (down ? 1 : -1));
    if (down) _setPressed(false);
  }

  void _setPressed(bool pressed) {
    final value = pressed && _beaconPointers == 0;
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      container: true,
      label: widget.label,
      button: true,
      focusable: true,
      focused: _hasFocus,
      onTap: widget.onTap,
      // Screen-reader focus moves the input focus, except on iOS where
      // VoiceOver keeps its own.
      onFocus: defaultTargetPlatform == TargetPlatform.iOS
          ? null
          : _focus.requestFocus,
      child: _BeaconScope(
        state: this,
        child: Actions(
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap();
                return null;
              },
            ),
          },
          child: Focus(
            focusNode: _focus,
            includeSemantics: false,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: widget.onTap,
              onTapDown: (_) => _setPressed(true),
              onTapUp: (_) => _setPressed(false),
              onTapCancel: () => _setPressed(false),
              child: CustomPaint(
                foregroundPainter: _TileStatePainter(
                  ring: _showRing,
                  pressed: _pressed,
                  ink: ink,
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lets the beacons of a tile tell it that a pointer is down on them.
class _BeaconScope extends InheritedWidget {
  const new({required this.state, required super.child});

  final _TappableTileState state;

  @override
  bool updateShouldNotify(_BeaconScope old) => false;
}

/// Tells the tile that a pointer is down inside the beacon it wraps, from the
/// first moment, so the tile does not show its press layer for it.
class _BeaconGuard extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final state = context.getInheritedWidgetOfExactType<_BeaconScope>()?.state;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => state?._beaconPointer(down: true),
      onPointerUp: (_) => state?._beaconPointer(down: false),
      onPointerCancel: (_) => state?._beaconPointer(down: false),
      child: child,
    );
  }
}

/// The press layer inside the wall and the focus ring outside it.
class _TileStatePainter extends CustomPainter {
  const new({required this.ring, required this.pressed, required this.ink});

  final bool ring;
  final bool pressed;
  final Color ink;

  static const _radius = Radius.circular(AppRadius.md);

  @override
  void paint(Canvas canvas, Size size) {
    final wall = RRect.fromRectAndRadius(Offset.zero & size, _radius);
    if (pressed) {
      canvas.drawRRect(
        wall,
        Paint()..color = ink.withValues(alpha: AppStateLayers.pressedSecondary),
      );
    }
    if (ring) {
      // A stroke is centered on its path: the wall inflated by half the width
      // puts all of the ring outside the wall.
      canvas.drawRRect(
        wall.inflate(AppSizes.borderEmphasis / 2),
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppSizes.borderEmphasis,
      );
    }
  }

  @override
  bool shouldRepaint(_TileStatePainter old) =>
      old.ring != ring || old.pressed != pressed || old.ink != ink;
}
