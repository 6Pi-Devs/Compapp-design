import 'package:compapp_design/src/models/room_draw_room.dart';
import 'package:compapp_design/src/models/room_draw_status.dart';
import 'package:flutter/foundation.dart';

/// What a room draw board draws, as plain data: the draw ([drawId] and its
/// [status] in words, [statusLabel]), the [bedrooms] with who goes to each,
/// whether the person looking is the admin, and the words of the two buttons
/// and of the note a member reads instead of them.
///
/// The draw is the app's: the server chooses at random, the app hands over the
/// result already worded and the board never draws a lot. [drawId] keys the
/// result, so a new draw replaces it. [statusLabel] ("Waiting to be applied",
/// "Applied") is the visible name of the status, which is never told by a
/// color alone.
///
/// Only the admin draws and applies, so a member sees the result and
/// [readOnlyNote] ("Only Ana can draw again or apply the result"), required
/// while [isAdmin] is false (the board checks it in debug builds). The admin
/// sees [drawAgainLabel] and, while the draw is pending, [applyLabel].
@immutable
class RoomDrawView {
  const new({
    required this.drawId,
    required this.status,
    required this.statusLabel,
    required this.bedrooms,
    required this.drawAgainLabel,
    required this.applyLabel,
    this.isAdmin = false,
    this.readOnlyNote,
  }) : assert(drawId != '', 'A draw needs an id'),
       assert(statusLabel != '', 'The status needs a label'),
       assert(drawAgainLabel != '', 'The draw again button needs a label'),
       assert(applyLabel != '', 'The apply button needs a label'),
       assert(readOnlyNote != '', 'The note for a member cannot be empty');

  final String drawId;
  final RoomDrawStatus status;
  final String statusLabel;
  final List<RoomDrawRoom> bedrooms;
  final String drawAgainLabel;
  final String applyLabel;
  final bool isAdmin;
  final String? readOnlyNote;

  @override
  bool operator ==(Object other) =>
      other is RoomDrawView &&
      other.drawId == drawId &&
      other.status == status &&
      other.statusLabel == statusLabel &&
      listEquals(other.bedrooms, bedrooms) &&
      other.drawAgainLabel == drawAgainLabel &&
      other.applyLabel == applyLabel &&
      other.isAdmin == isAdmin &&
      other.readOnlyNote == readOnlyNote;

  @override
  int get hashCode => Object.hash(
    drawId,
    status,
    statusLabel,
    Object.hashAll(bedrooms),
    drawAgainLabel,
    applyLabel,
    isAdmin,
    readOnlyNote,
  );
}
