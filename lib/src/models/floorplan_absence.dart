import 'package:compapp_design/src/models/member_view.dart';
import 'package:flutter/foundation.dart';

/// A member who is out, as the away tray of the plan draws them: their pebble
/// and a short [label] beside it ("until Fri").
///
/// The app owns every word and every date. The spoken name of the button is the
/// member's own `semanticLabel` followed by the [label], so the label is said
/// in the same words it is shown in (WCAG 2.5.3, label in name).
@immutable
class FloorplanAbsence {
  const new({required this.member, this.label});

  final MemberView member;
  final String? label;

  @override
  bool operator ==(Object other) =>
      other is FloorplanAbsence &&
      other.member == member &&
      other.label == label;

  @override
  int get hashCode => Object.hash(member, label);
}
