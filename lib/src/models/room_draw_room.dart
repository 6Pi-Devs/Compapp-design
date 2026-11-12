import 'package:compapp_design/src/models/member_view.dart';
import 'package:compapp_design/src/models/room_view.dart';
import 'package:flutter/foundation.dart';

/// A bedroom in the result of a room draw, as plain data: the [room], the
/// [members] that go there (a group that shared a bedroom goes together, and
/// none means the bedroom stays free), the [caption] under them ("from Bedroom
/// 3", "Stays free") and the whole spoken description of the bedroom.
///
/// [semanticLabel] ("Bedroom 1: Carlos, from Bedroom 3") must contain the
/// visible name and the visible caption (WCAG 2.5.3, label in name): the board
/// checks it in debug builds, since a const constructor cannot. The app words
/// it because it names the room, the people and where they come from.
@immutable
class RoomDrawRoom {
  const new({
    required this.room,
    required this.caption,
    required this.semanticLabel,
    this.members = const [],
  }) : assert(caption != '', 'A bedroom of the draw needs a caption'),
       assert(
         semanticLabel != '',
         'A bedroom of the draw needs a spoken label',
       );

  final RoomView room;
  final String caption;
  final String semanticLabel;
  final List<MemberView> members;

  @override
  bool operator ==(Object other) =>
      other is RoomDrawRoom &&
      other.room == room &&
      other.caption == caption &&
      other.semanticLabel == semanticLabel &&
      listEquals(other.members, members);

  @override
  int get hashCode =>
      Object.hash(room, caption, semanticLabel, Object.hashAll(members));
}
