import 'package:compapp_design/src/models/member_view.dart';
import 'package:flutter/foundation.dart';

/// One member in a group of a presence panel: the [member] and the two texts
/// of their row, the [subtitle] under the name and the [trailing] text at the
/// end ("since 5 h", "until Fri").
///
/// The app owns every string and every date, so a row that says how long
/// someone has been home is already worded when it gets here.
@immutable
class PresenceEntry {
  const new({required this.member, this.subtitle, this.trailing});

  final MemberView member;
  final String? subtitle;
  final String? trailing;

  @override
  bool operator ==(Object other) =>
      other is PresenceEntry &&
      other.member == member &&
      other.subtitle == subtitle &&
      other.trailing == trailing;

  @override
  int get hashCode => Object.hash(member, subtitle, trailing);
}
