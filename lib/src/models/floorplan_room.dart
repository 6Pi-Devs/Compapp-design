import 'package:compapp_design/src/models/floorplan_item.dart';
import 'package:compapp_design/src/models/floorplan_room_kind.dart';
import 'package:compapp_design/src/models/member_view.dart';
import 'package:compapp_design/src/models/room_tile_state.dart';
import 'package:compapp_design/src/models/room_view.dart';
import 'package:flutter/foundation.dart';

/// A room of the plan, as plain data: the [room], where it goes ([kind]), how
/// it looks ([state]), what it says and who and what is in it.
///
/// [caption] is the line under the name that says the state in words ("Home ·
/// 3 h", "In use · 12 min") and [semanticLabel] the spoken name of the whole
/// tile ("Ana's room, Ana is home, 3 hours"), which must contain the visible
/// name of the room in the same words (WCAG 2.5.3, label in name). The
/// [occupants] are drawn as pebbles in the tile and [items] are pinned to it as
/// beacons. An [archived] room is not drawn. The app owns every word, every
/// duration and the order of creation.
@immutable
class FloorplanRoom {
  const new({
    required this.room,
    required this.kind,
    required this.state,
    required this.caption,
    required this.semanticLabel,
    this.occupants = const [],
    this.items = const [],
    this.archived = false,
  }) : assert(caption != '', 'A room says its state in words'),
       assert(semanticLabel != '', 'A room needs a spoken label');

  final RoomView room;
  final FloorplanRoomKind kind;
  final RoomTileState state;
  final String caption;
  final String semanticLabel;
  final List<MemberView> occupants;
  final List<FloorplanItem> items;
  final bool archived;

  @override
  bool operator ==(Object other) =>
      other is FloorplanRoom &&
      other.room == room &&
      other.kind == kind &&
      other.state == state &&
      other.caption == caption &&
      other.semanticLabel == semanticLabel &&
      listEquals(other.occupants, occupants) &&
      listEquals(other.items, items) &&
      other.archived == archived;

  @override
  int get hashCode => Object.hash(
    room,
    kind,
    state,
    caption,
    semanticLabel,
    Object.hashAll(occupants),
    Object.hashAll(items),
    archived,
  );
}
