import 'package:compapp_design/src/models/member_view.dart';
import 'package:compapp_design/src/models/room_assign_option.dart';
import 'package:compapp_design/src/models/room_view.dart';
import 'package:flutter/foundation.dart';

/// A room the admin can edit, as plain data: the [room], the line under its
/// name ([subtitle], "Ana · 1 of 1 bed"), who sleeps there ([occupants], drawn
/// as pebbles, empty for a common area) and the spoken names of its buttons.
///
/// [editLabel] and [archiveLabel] name the two icon buttons ("Edit Bedroom
/// 1", "Archive Kitchen"), so each one says which room it acts on. The app
/// words them, as it words everything.
///
/// [assignOptions] are the members that can be moved into this bedroom, none
/// when it is full or is not a bedroom: the room then has no assign button.
/// [assignLabel] is required while there are options (the editor checks it in
/// debug builds, since a const constructor cannot).
///
/// Archive is always enabled: the backend refuses to archive a bedroom someone
/// sleeps in, and the app tells the admin why when it answers.
@immutable
class RoomEditorRoom {
  const new({
    required this.room,
    required this.editLabel,
    required this.archiveLabel,
    this.assignLabel,
    this.subtitle,
    this.occupants = const [],
    this.assignOptions = const [],
  }) : assert(editLabel != '', 'The edit button needs a spoken label'),
       assert(archiveLabel != '', 'The archive button needs a spoken label'),
       assert(assignLabel != '', 'The assign button needs a spoken label');

  final RoomView room;
  final String editLabel;
  final String archiveLabel;

  /// Spoken name of the button that opens the list of [assignOptions], which
  /// must contain the visible label of the editor ("Assign" in "Assign
  /// someone to Bedroom 1"). Null when there are no options.
  final String? assignLabel;
  final String? subtitle;
  final List<MemberView> occupants;
  final List<RoomAssignOption> assignOptions;

  @override
  bool operator ==(Object other) =>
      other is RoomEditorRoom &&
      other.room == room &&
      other.editLabel == editLabel &&
      other.archiveLabel == archiveLabel &&
      other.assignLabel == assignLabel &&
      other.subtitle == subtitle &&
      listEquals(other.occupants, occupants) &&
      listEquals(other.assignOptions, assignOptions);

  @override
  int get hashCode => Object.hash(
    room,
    editLabel,
    archiveLabel,
    assignLabel,
    subtitle,
    Object.hashAll(occupants),
    Object.hashAll(assignOptions),
  );
}
