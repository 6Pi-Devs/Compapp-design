import 'package:compapp_design/src/models/presence_broadcast.dart';
import 'package:compapp_design/src/models/presence_group.dart';
import 'package:flutter/foundation.dart';

/// What a presence panel draws, as plain data: who is [home], who is [away],
/// who is [invited] and has not joined yet (left out when null), and the
/// [broadcast] that asks the home who is in.
///
/// The ids of the members are the keys of the rows, so a member must be in one
/// group only.
@immutable
class PresenceView {
  const new({
    required this.home,
    required this.away,
    required this.broadcast,
    this.invited,
  });

  final PresenceGroup home;
  final PresenceGroup away;
  final PresenceGroup? invited;
  final PresenceBroadcast broadcast;

  @override
  bool operator ==(Object other) =>
      other is PresenceView &&
      other.home == home &&
      other.away == away &&
      other.invited == invited &&
      other.broadcast == broadcast;

  @override
  int get hashCode => Object.hash(home, away, invited, broadcast);
}
