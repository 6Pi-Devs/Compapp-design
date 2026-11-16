import 'package:compapp_design/src/models/room_view.dart';
import 'package:flutter/foundation.dart';

/// A room that was archived, as the editor lists it: its name, the optional
/// line under it ("Archived 3 Mar") and the spoken name of its restore button.
///
/// [restoreLabel] names the room it restores ("Restore Office"), so the button
/// says which room it acts on. Archived rooms are not deleted, so they stay in
/// the list and still count toward the limit of rooms of the home; restoring
/// one does not change that count.
@immutable
class RoomEditorArchivedRoom {
  const new({required this.room, required this.restoreLabel, this.subtitle})
    : assert(restoreLabel != '', 'The restore button needs a spoken label');

  final RoomView room;
  final String restoreLabel;
  final String? subtitle;

  @override
  bool operator ==(Object other) =>
      other is RoomEditorArchivedRoom &&
      other.room == room &&
      other.restoreLabel == restoreLabel &&
      other.subtitle == subtitle;

  @override
  int get hashCode => Object.hash(room, restoreLabel, subtitle);
}
