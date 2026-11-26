import 'package:compapp_design/src/models/calendar_event_kind.dart';
import 'package:flutter/foundation.dart';

/// One entry of a calendar legend: a [kind] of event and the [label] that
/// names it, already localized by the app ("Absence").
@immutable
class CalendarLegendEntry {
  const new({required this.kind, required this.label})
    : assert(label != '', 'A legend entry needs a label');

  final CalendarEventKind kind;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is CalendarLegendEntry &&
      other.kind == kind &&
      other.label == label;

  @override
  int get hashCode => Object.hash(kind, label);
}
