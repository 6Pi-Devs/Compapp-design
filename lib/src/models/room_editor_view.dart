import 'package:compapp_design/src/models/room_editor_archived_room.dart';
import 'package:compapp_design/src/models/room_editor_room.dart';
import 'package:flutter/foundation.dart';

/// What a room editor draws, as plain data: the [bedrooms] and the
/// [commonAreas] the admin can edit and the [archived] rooms, each list with
/// its heading, and the visible words of the two buttons that are not per
/// room.
///
/// [addLabel] is the visible label of the button that adds a room and
/// [assignLabel] the one of the button that opens the members a bedroom can
/// take. When the home cannot take another room the app passes the reason in
/// [limitMessage] ("The home has 30 rooms, archived ones included"): the add
/// button is then disabled and the message is shown under the bedrooms
/// heading. [archivedTitle] is required while there are archived rooms.
///
/// The ids of the rooms are the keys of their rows, so a room must be in one
/// list only.
@immutable
class RoomEditorView {
  const new({
    required this.bedroomsTitle,
    required this.commonAreasTitle,
    required this.addLabel,
    required this.assignLabel,
    required this.bedrooms,
    required this.commonAreas,
    this.archivedTitle,
    this.archived = const [],
    this.limitMessage,
  }) : assert(addLabel != '', 'The add button needs a label'),
       assert(assignLabel != '', 'The assign button needs a label');

  final String bedroomsTitle;
  final String commonAreasTitle;
  final String addLabel;
  final String assignLabel;
  final List<RoomEditorRoom> bedrooms;
  final List<RoomEditorRoom> commonAreas;
  final String? archivedTitle;
  final List<RoomEditorArchivedRoom> archived;
  final String? limitMessage;

  @override
  bool operator ==(Object other) =>
      other is RoomEditorView &&
      other.bedroomsTitle == bedroomsTitle &&
      other.commonAreasTitle == commonAreasTitle &&
      other.addLabel == addLabel &&
      other.assignLabel == assignLabel &&
      listEquals(other.bedrooms, bedrooms) &&
      listEquals(other.commonAreas, commonAreas) &&
      other.archivedTitle == archivedTitle &&
      listEquals(other.archived, archived) &&
      other.limitMessage == limitMessage;

  @override
  int get hashCode => Object.hash(
    bedroomsTitle,
    commonAreasTitle,
    addLabel,
    assignLabel,
    Object.hashAll(bedrooms),
    Object.hashAll(commonAreas),
    archivedTitle,
    Object.hashAll(archived),
    limitMessage,
  );
}
