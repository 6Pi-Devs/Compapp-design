import 'package:compapp_design/src/models/calendar_strip_day.dart';
import 'package:compapp_design/src/models/calendar_strip_event.dart';
import 'package:flutter/foundation.dart';

/// What a calendar strip draws, as plain data: the seven [days] (the rolling
/// week from today, in order), the [events] that touch them and which of the
/// days is [today].
///
/// [today] is a `YYYY-MM-DD` string like the dates of the days, `null` when
/// none of the days is today. The ids of the events are the keys of their
/// rows, so they must be unique, and the dates of the days must be unique and
/// in order. The design system keeps no calendar and no clock: the app
/// decides the days, the events and the words.
@immutable
class CalendarStripView {
  const new({required this.days, required this.events, this.today});

  final List<CalendarStripDay> days;
  final List<CalendarStripEvent> events;
  final String? today;

  @override
  bool operator ==(Object other) =>
      other is CalendarStripView &&
      listEquals(other.days, days) &&
      listEquals(other.events, events) &&
      other.today == today;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(days), Object.hashAll(events), today);
}
