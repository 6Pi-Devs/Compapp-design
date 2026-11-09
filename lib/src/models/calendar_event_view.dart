import 'package:compapp_design/src/models/calendar_event_kind.dart';
import 'package:flutter/foundation.dart';

/// A calendar event of the home, as the design system draws it.
///
/// Plain immutable data owned by this package. [id] is the stable event id
/// that widget keys are built from. [title] is the text to show on the
/// ribbon, already localized by the app ("Absence · Luis away"). The app owns
/// the dates: the design system does no date maths and only draws how the
/// event sits in the days it is given.
@immutable
class CalendarEventView {
  const new({required this.id, required this.kind, required this.title});

  final String id;
  final CalendarEventKind kind;
  final String title;

  @override
  bool operator ==(Object other) =>
      other is CalendarEventView &&
      other.id == id &&
      other.kind == kind &&
      other.title == title;

  @override
  int get hashCode => Object.hash(id, kind, title);
}
