import 'package:compapp_design/src/models/member_view.dart';
import 'package:flutter/foundation.dart';

/// A member that can be moved into a bedroom, as the editor offers them.
///
/// [semanticLabel] is the whole spoken name of the button ("Move Carlos to
/// Bedroom 1") and must contain the visible name of the [member] (WCAG 2.5.3,
/// label in name). The app words it because it names both the member and the
/// room.
@immutable
class RoomAssignOption {
  const new({required this.member, required this.semanticLabel})
    : assert(semanticLabel != '', 'An option needs a spoken label');

  final MemberView member;
  final String semanticLabel;

  @override
  bool operator ==(Object other) =>
      other is RoomAssignOption &&
      other.member == member &&
      other.semanticLabel == semanticLabel;

  @override
  int get hashCode => Object.hash(member, semanticLabel);
}
