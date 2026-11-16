import 'package:compapp_design/src/models/floorplan_absence.dart';
import 'package:compapp_design/src/models/floorplan_room.dart';
import 'package:flutter/foundation.dart';

/// What a floor plan map draws, as plain data: the [rooms], the members who are
/// out ([absences]) and the words around them.
///
/// The board lists FloorplanView(rooms, members, items, usages, absences, meId,
/// now). The design system keeps no clock and no snapshot: the app works out
/// who is where, which items are in use and for how long, and hands over rooms
/// that are already worded (see [FloorplanRoom]). [awayLabel] is the visible
/// heading of the away tray ("Away"), which shows only while there are
/// [absences]. [emptyTitle] and [emptyBody] are what the map says when no room
/// is drawn, which must never blame anyone, and [loadingLabel] is the spoken
/// name of the map while it [loading] (the map then draws nothing else).
///
/// The ids of the rooms, of the items across all the rooms and of the absent
/// members are the keys of what they draw, so each must be unique.
@immutable
class FloorplanView {
  const new({
    required this.rooms,
    required this.awayLabel,
    required this.emptyTitle,
    required this.emptyBody,
    required this.loadingLabel,
    this.absences = const [],
    this.loading = false,
  }) : assert(awayLabel != '', 'The away tray needs a heading'),
       assert(emptyTitle != '', 'The empty state needs a title'),
       assert(emptyBody != '', 'The empty state needs a body'),
       assert(loadingLabel != '', 'The loading state needs a spoken label');

  final List<FloorplanRoom> rooms;
  final List<FloorplanAbsence> absences;
  final String awayLabel;
  final String emptyTitle;
  final String emptyBody;
  final String loadingLabel;
  final bool loading;

  /// The rooms that are drawn: the ones that are not archived, in the order the
  /// app gave them (the order of creation).
  List<FloorplanRoom> get visibleRooms => [
    for (final room in rooms)
      if (!room.archived) room,
  ];

  @override
  bool operator ==(Object other) =>
      other is FloorplanView &&
      listEquals(other.rooms, rooms) &&
      listEquals(other.absences, absences) &&
      other.awayLabel == awayLabel &&
      other.emptyTitle == emptyTitle &&
      other.emptyBody == emptyBody &&
      other.loadingLabel == loadingLabel &&
      other.loading == loading;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(rooms),
    Object.hashAll(absences),
    awayLabel,
    emptyTitle,
    emptyBody,
    loadingLabel,
    loading,
  );
}
