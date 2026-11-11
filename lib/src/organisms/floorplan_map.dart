import 'dart:math' as math;

import 'package:compapp_design/src/atoms/app_icon.dart';
import 'package:compapp_design/src/atoms/app_pebble.dart';
import 'package:compapp_design/src/atoms/app_progress_ring.dart';
import 'package:compapp_design/src/foundation/dashed_border.dart';
import 'package:compapp_design/src/models/app_icons.dart';
import 'package:compapp_design/src/models/floorplan_absence.dart';
import 'package:compapp_design/src/models/floorplan_room.dart';
import 'package:compapp_design/src/models/floorplan_room_kind.dart';
import 'package:compapp_design/src/models/floorplan_view.dart';
import 'package:compapp_design/src/models/member_status.dart';
import 'package:compapp_design/src/molecules/app_empty_state.dart';
import 'package:compapp_design/src/molecules/item_beacon.dart';
import 'package:compapp_design/src/molecules/room_tile.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// The home drawn as a calm plan: its rooms as tiles (bedrooms in the top and
/// bottom rows, common areas in the middle, in the order the app gives them),
/// the things of the house pinned to their rooms as beacons, and the members
/// who are out in a tray under the plan.
///
/// It composes [RoomTile], [ItemBeacon], `AppPebble`, `AppIcon` and the away
/// tray, which is private here: the board draws it as part of the map (it owns
/// the key `floorplan.awayTray`), and an organism may not import another one.
/// It takes plain data ([FloorplanView]) and three callbacks: [onRoomTap] with
/// the id of the room, [onItemTap] with the id of the item and [onMemberTap]
/// with the id of the member in the tray. The app does the clock and the
/// snapshot: it hands over rooms that are already worded, and the map keeps
/// rooms, items and members by their ids.
///
/// The plan is derived, never stored: there are no coordinates. Bedrooms are
/// split between a top and a bottom section and the common areas fill the one
/// between them. A section has rows of at most three tiles that share the width
/// equally, and a row never holds more tiles than leave each one the width of
/// its longest word (and 48): at large text or in a narrow column the tiles
/// move to rows of two and then one, so no word of a room is cut. A row is as
/// tall as its tallest tile and at least `AppSizes.rowTall`, and the tiles
/// of a row are as tall as the row. Archived rooms are not drawn. A small
/// render object with intrinsic and dry layout does it, not a `LayoutBuilder`,
/// so the golden harness can measure the map.
///
/// Each room is one button node of the list that the plan is, named by the
/// spoken label of the room ("Ana's room, Ana is home, 3 hours"), and each
/// beacon inside it stays its own button. The members of the tray are buttons
/// too, named by the spoken label of the member and the words beside the
/// pebble. The state of a room is said by its caption and its spoken label,
/// never by its color alone, and a member in the tray by words and a moon.
///
/// While [FloorplanView.loading] the map draws a ring named by the loading
/// label and nothing else. With no room to draw it says the empty state, and
/// the tray is not drawn.
///
/// It is a plain column that takes its height from its content and needs a
/// bounded width: put it in the scrollable of the screen. It grows with large
/// text instead of clipping, never clamps the text scale and mirrors in
/// right-to-left. The focus rings are drawn outside the shapes, so a parent
/// that clips needs `AppSizes.borderEmphasis` of room around it. The gap
/// between tiles (8) holds the ring of one (2) and the glow of its neighbor
/// (4) side by side, so no tile paints over another one's ring and nothing has
/// to paint last. Motion is only the breathing ring of an item in use, which
/// stands still when animations are off.
class FloorplanMap extends StatelessWidget {
  const new({
    required this.view,
    required this.onRoomTap,
    required this.onItemTap,
    required this.onMemberTap,
    super.key,
  });

  final FloorplanView view;

  /// Called with the id of the tapped room.
  final ValueChanged<String> onRoomTap;

  /// Called with the id of the tapped item.
  final ValueChanged<String> onItemTap;

  /// Called with the id of the tapped member of the away tray.
  final ValueChanged<String> onMemberTap;

  /// The most tiles of a row.
  static const int _maxPerRow = 3;

  @override
  Widget build(BuildContext context) {
    final rooms = view.visibleRooms;
    assert(_unique([for (final r in rooms) r.room.id]), 'Room ids are keys');
    assert(
      _unique([
        for (final r in rooms)
          for (final i in r.items) i.item.id,
      ]),
      'Item ids are keys, across every room',
    );
    assert(
      _unique([for (final a in view.absences) a.member.id]),
      'Member ids are keys',
    );
    assert(
      rooms.every((r) => r.semanticLabel.contains(r.room.name)),
      'The spoken label of a room contains its visible name (label in name)',
    );
    assert(
      rooms.every(
        (r) => r.items.every((i) => i.semanticLabel.contains(i.item.name)),
      ),
      'The spoken label of an item contains its visible name (label in name)',
    );

    final Widget content;
    if (view.loading) {
      content = Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(child: AppProgressRing(semanticLabel: view.loadingLabel)),
      );
    } else if (rooms.isEmpty) {
      content = AppEmptyState(title: view.emptyTitle, body: view.emptyBody);
    } else {
      content = _Plan(
        view: view,
        rooms: rooms,
        onRoomTap: onRoomTap,
        onItemTap: onItemTap,
        onMemberTap: onMemberTap,
      );
    }
    return Semantics(
      key: const Key('floorplan.map'),
      container: true,
      explicitChildNodes: true,
      child: content,
    );
  }

  static bool _unique(List<String> ids) => ids.length == ids.toSet().length;
}

/// What a button of the away tray says: the member, then the words beside the
/// pebble.
String _spoken(FloorplanAbsence absence) {
  final label = absence.label;
  return [
    absence.member.semanticLabel,
    if (label != null && label.isNotEmpty) label,
  ].join('\n');
}

/// The card with the plan and the tray.
class _Plan extends StatelessWidget {
  const new({
    required this.view,
    required this.rooms,
    required this.onRoomTap,
    required this.onItemTap,
    required this.onMemberTap,
  });

  final FloorplanView view;
  final List<FloorplanRoom> rooms;
  final ValueChanged<String> onRoomTap;
  final ValueChanged<String> onItemTap;
  final ValueChanged<String> onMemberTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final bedrooms = [
      for (final r in rooms)
        if (r.kind == FloorplanRoomKind.bedroom) r,
    ];
    final common = [
      for (final r in rooms)
        if (r.kind == FloorplanRoomKind.common) r,
    ];
    final top = (bedrooms.length + 1) ~/ 2;
    final sections = [
      for (final section in [
        bedrooms.sublist(0, top),
        common,
        bedrooms.sublist(top),
      ])
        if (section.isNotEmpty) section,
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.sm,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Semantics(
                  container: true,
                  explicitChildNodes: true,
                  role: SemanticsRole.list,
                  child: _PlanLayout(
                    sections: [for (final s in sections) s.length],
                    textDirection: Directionality.of(context),
                    children: [
                      for (final section in sections)
                        for (final room in section)
                          Semantics(
                            key: ValueKey(room.room.id),
                            container: true,
                            explicitChildNodes: true,
                            role: SemanticsRole.listItem,
                            child: _tile(room),
                          ),
                    ],
                  ),
                ),
              ),
            ),
            if (view.absences.isNotEmpty)
              _AwayTray(
                heading: view.awayLabel,
                absences: view.absences,
                onMemberTap: onMemberTap,
              ),
          ],
        ),
      ),
    );
  }

  Widget _tile(FloorplanRoom room) {
    return RoomTile(
      room: room.room,
      state: room.state,
      caption: room.caption,
      semanticLabel: room.semanticLabel,
      occupants: room.occupants,
      onTap: () => onRoomTap(room.room.id),
      beacons: [
        for (final entry in room.items)
          ItemBeacon(
            key: ValueKey(entry.item.id),
            item: entry.item,
            inUse: entry.inUse,
            statusLabel: entry.statusLabel,
            semanticLabel: entry.semanticLabel,
            onTap: () => onItemTap(entry.item.id),
          ),
      ],
    );
  }
}

/// The members who are out: a moon and the heading, then one button for each,
/// in a dashed outline in the hairline color (decoration, the buttons are the
/// controls). The buttons wrap onto more lines when they do not fit.
class _AwayTray extends StatelessWidget {
  const new({
    required this.heading,
    required this.absences,
    required this.onMemberTap,
  });

  final String heading;
  final List<FloorplanAbsence> absences;
  final ValueChanged<String> onMemberTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      key: const Key('floorplan.awayTray'),
      container: true,
      explicitChildNodes: true,
      label: heading,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: DashedBorder(
            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.sm)),
            side: BorderSide(
              color: scheme.outlineVariant,
              width: AppSizes.borderRoom,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      AppIcons.away,
                      size: AppSizes.glyphLg,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        heading,
                        style: AppTypography.label.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              for (final absence in absences)
                _AbsentMember(
                  key: ValueKey(absence.member.id),
                  absence: absence,
                  onTap: () => onMemberTap(absence.member.id),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One member of the tray: the pebble and the words beside it, as one button
/// at least 48 tall and wide.
class _AbsentMember extends StatelessWidget {
  const new({required this.absence, required this.onTap, super.key});

  final FloorplanAbsence absence;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final member = absence.member;
    final label = absence.label;
    return TextButton(
      key: Key('floorplan.member.${member.id}'),
      onPressed: onTap,
      style: const ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size.square(AppSizes.minTarget)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
          ),
        ),
      ),
      child: Semantics(
        label: _spoken(absence),
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppPebble(
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
            if (label != null && label.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lays the tiles out in sections of rows: [sections] says how many tiles each
/// section takes from the children, in order.
class _PlanLayout extends MultiChildRenderObjectWidget {
  const new({
    required this.sections,
    required this.textDirection,
    required super.children,
  });

  final List<int> sections;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPlanLayout(sections: sections, textDirection: textDirection);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPlanLayout renderObject,
  ) {
    renderObject
      ..sections = sections
      ..textDirection = textDirection;
  }
}

class _PlanParentData extends ContainerBoxParentData<RenderBox>;

typedef _Arrangement = ({
  Size size,
  List<List<RenderBox>> rows,
  List<double> rowHeights,
  double cellWidth,
});

class _RenderPlanLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _PlanParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _PlanParentData> {
  new({required this._sections, required this._textDirection});

  static const double _gap = AppSpacing.sm;

  List<int> _sections;
  List<int> get sections => _sections;
  set sections(List<int> value) {
    if (listEquals(value, _sections)) return;
    _sections = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _PlanParentData) {
      child.parentData = _PlanParentData();
    }
  }

  List<RenderBox> get _children => getChildrenAsList();

  /// The rows of every section. In a bounded width a row takes as many tiles as
  /// leave each the least width of its section (its longest word, and 48), at
  /// most [FloorplanMap._maxPerRow], and the tiles of the section are spread
  /// over the fewest rows that hold them, as evenly as possible.
  List<List<RenderBox>> _rowsFor(double? width) {
    final children = _children;
    final rows = <List<RenderBox>>[];
    var start = 0;
    for (final count in _sections) {
      final section = children.sublist(start, start + count);
      start += count;
      var perRow = math.min(FloorplanMap._maxPerRow, count);
      if (width != null) {
        var need = AppSizes.minTarget;
        for (final child in section) {
          need = math.max(need, child.getMinIntrinsicWidth(double.infinity));
        }
        final fit = ((width + _gap) / (need + _gap)).floor();
        perRow = math.max(1, math.min(perRow, fit));
      }
      final rowCount = (count / perRow).ceil();
      final base = count ~/ rowCount;
      final extra = count % rowCount;
      var from = 0;
      for (var row = 0; row < rowCount; row++) {
        final size = base + (row < extra ? 1 : 0);
        rows.add(section.sublist(from, from + size));
        from += size;
      }
    }
    return rows;
  }

  _Arrangement _arrange(BoxConstraints constraints) {
    final bounded = constraints.hasBoundedWidth;
    final rows = _rowsFor(bounded ? constraints.maxWidth : null);
    if (rows.isEmpty) {
      return (
        size: constraints.smallest,
        rows: rows,
        rowHeights: const [],
        cellWidth: 0,
      );
    }
    // Unbounded, every tile is as wide as the widest one wants to be.
    var natural = 0.0;
    if (!bounded) {
      for (final child in _children) {
        natural = math.max(
          natural,
          child.getMaxIntrinsicWidth(double.infinity),
        );
      }
    }
    final rowHeights = <double>[];
    for (final row in rows) {
      final width = bounded
          ? (constraints.maxWidth - _gap * (row.length - 1)) / row.length
          : natural;
      var height = AppSizes.rowTall;
      for (final child in row) {
        height = math.max(
          height,
          child.getDryLayout(BoxConstraints.tightFor(width: width)).height,
        );
      }
      rowHeights.add(height);
    }
    final width = bounded
        ? constraints.maxWidth
        : rows
              .map((r) => r.length * natural + _gap * (r.length - 1))
              .reduce(math.max);
    final height =
        rowHeights.fold<double>(0, (sum, h) => sum + h) +
        _gap * (rows.length - 1);
    return (
      size: constraints.constrain(Size(width, height)),
      rows: rows,
      rowHeights: rowHeights,
      cellWidth: natural,
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    var need = AppSizes.minTarget;
    for (final child in _children) {
      need = math.max(need, child.getMinIntrinsicWidth(double.infinity));
    }
    return need;
  }

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _arrange(const BoxConstraints()).size.width;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _arrange(BoxConstraints(maxWidth: width)).size.height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _arrange(constraints).size;

  @override
  void performLayout() {
    final plan = _arrange(constraints);
    size = plan.size;
    final bounded = constraints.hasBoundedWidth;
    final rtl = _textDirection == TextDirection.rtl;
    var top = 0.0;
    for (var r = 0; r < plan.rows.length; r++) {
      final row = plan.rows[r];
      final width = bounded
          ? (size.width - _gap * (row.length - 1)) / row.length
          : plan.cellWidth;
      for (var i = 0; i < row.length; i++) {
        final child = row[i]
          ..layout(
            BoxConstraints.tightFor(width: width, height: plan.rowHeights[r]),
            parentUsesSize: true,
          );
        final x = i * (width + _gap);
        (child.parentData! as _PlanParentData).offset = Offset(
          rtl ? size.width - x - width : x,
          top,
        );
      }
      top += plan.rowHeights[r] + _gap;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
