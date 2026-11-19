import 'package:compapp_design/src/models/calendar_month_day.dart';
import 'package:compapp_design/src/models/calendar_strip_event.dart';
import 'package:flutter/foundation.dart';

/// What a calendar month grid draws, as plain data.
///
/// [weekdays] are the seven narrow labels of the header, in display order
/// ("M", "T", ...), already localized. [days] are whole weeks in order, so
/// their number is a multiple of seven, and their dates are unique. [events]
/// are drawn as ribbons over the days they cover; an event that starts before
/// the first day or ends after the last is clipped to the grid, with a flat
/// edge where it goes on. Their ids must be unique. [today] and [selected] are
/// `YYYY-MM-DD` strings like the dates of the days, `null` when none of the
/// days is today or selected.
///
/// A const constructor cannot read the length of a list, so `CalendarMonth`
/// asserts the seven weekdays and the whole weeks.
@immutable
class CalendarMonthView {
  const new({
    required this.weekdays,
    required this.days,
    required this.events,
    this.today,
    this.selected,
  }) : assert(today != '', 'Today is a date or null'),
       assert(selected != '', 'The selected day is a date or null');

  final List<String> weekdays;
  final List<CalendarMonthDay> days;
  final List<CalendarStripEvent> events;
  final String? today;
  final String? selected;

  @override
  bool operator ==(Object other) =>
      other is CalendarMonthView &&
      listEquals(other.weekdays, weekdays) &&
      listEquals(other.days, days) &&
      listEquals(other.events, events) &&
      other.today == today &&
      other.selected == selected;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(weekdays),
    Object.hashAll(days),
    Object.hashAll(events),
    today,
    selected,
  );
}
