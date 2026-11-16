import 'package:flutter/foundation.dart';

/// One day of a calendar strip, as plain data.
///
/// [date] is the all-day date as `YYYY-MM-DD` in the home's time zone, a
/// string and never a `DateTime`: the app owns the calendar and the design
/// system does no date maths. It is the key of the day. [weekday] and
/// [dayNumber] are the visible texts of the cell ("Sun", "1"), already
/// localized: keep the weekday short, a word that does not fit the cell moves
/// the strip onto two rows. [semanticLabel] is the spoken name of the day
/// ("Sunday 1 November, today"), which must contain both visible texts in the
/// same words (WCAG 2.5.3, label in name) and says whether it is today.
@immutable
class CalendarStripDay {
  const new({
    required this.date,
    required this.weekday,
    required this.dayNumber,
    required this.semanticLabel,
  }) : assert(date != '', 'A day needs a date'),
       assert(weekday != '', 'A day needs a weekday'),
       assert(dayNumber != '', 'A day needs a number'),
       assert(semanticLabel != '', 'A day needs a spoken label');

  final String date;
  final String weekday;
  final String dayNumber;
  final String semanticLabel;

  @override
  bool operator ==(Object other) =>
      other is CalendarStripDay &&
      other.date == date &&
      other.weekday == weekday &&
      other.dayNumber == dayNumber &&
      other.semanticLabel == semanticLabel;

  @override
  int get hashCode => Object.hash(date, weekday, dayNumber, semanticLabel);
}
