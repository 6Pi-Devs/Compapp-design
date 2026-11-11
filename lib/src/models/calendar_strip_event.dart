import 'package:compapp_design/src/models/calendar_event_view.dart';
import 'package:flutter/foundation.dart';

/// An event of a calendar strip: the [event] a ribbon draws, the days it
/// covers and its spoken label.
///
/// [startDate] and [endDate] are the first and the last day of the event, both
/// included, as `YYYY-MM-DD` strings in the home's time zone. They may lie
/// outside the days the strip shows: the strip compares the strings (which
/// order like the dates they spell) and draws the part that is inside, with a
/// flat edge where the event goes on. [semanticLabel] is the app's spoken
/// description ("Absence, Luis, until Fri 6 Nov"). It must contain the visible
/// title of the event in the same words (WCAG 2.5.3, label in name), because
/// the event is a button.
@immutable
class CalendarStripEvent {
  const new({
    required this.event,
    required this.startDate,
    required this.endDate,
    required this.semanticLabel,
  }) : assert(startDate != '', 'An event needs a first day'),
       assert(endDate != '', 'An event needs a last day'),
       assert(semanticLabel != '', 'An event needs a spoken label');

  final CalendarEventView event;
  final String startDate;
  final String endDate;
  final String semanticLabel;

  @override
  bool operator ==(Object other) =>
      other is CalendarStripEvent &&
      other.event == event &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.semanticLabel == semanticLabel;

  @override
  int get hashCode => Object.hash(event, startDate, endDate, semanticLabel);
}
