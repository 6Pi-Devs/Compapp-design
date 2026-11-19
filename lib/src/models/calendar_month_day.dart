import 'package:compapp_design/src/models/member_view.dart';
import 'package:flutter/foundation.dart';

/// One day of a calendar month grid, as plain data.
///
/// [date] is the all-day date as `YYYY-MM-DD` in the home's time zone, a
/// string and never a `DateTime`: the design system does no date maths. It is
/// the key of the day. [dayNumber] is the visible number of the cell ("14").
/// [semanticLabel] is the spoken name of the day, built by the app: the date,
/// whether it is today, who is away and the events of the day ("Saturday 14
/// November, today. Away: Luis, Ana. Visit, Marta"). It must contain
/// [dayNumber] (WCAG 2.5.3, label in name), because the day is a button and
/// it is all assistive technology hears of the cell: the pebbles and ribbons
/// drawn in it say nothing of their own.
///
/// [inMonth] is false for a day of the weeks around the month (the days that
/// fill the first and the last week): it is drawn muted, and still tappable.
/// [away] are the members away that day, in display order: the grid shows the
/// first one and a count of the rest.
@immutable
class CalendarMonthDay {
  const new({
    required this.date,
    required this.dayNumber,
    required this.semanticLabel,
    this.inMonth = true,
    this.away = const [],
  }) : assert(date != '', 'A day needs a date'),
       assert(dayNumber != '', 'A day needs a number'),
       assert(semanticLabel != '', 'A day needs a spoken label');

  final String date;
  final String dayNumber;
  final String semanticLabel;
  final bool inMonth;
  final List<MemberView> away;

  @override
  bool operator ==(Object other) =>
      other is CalendarMonthDay &&
      other.date == date &&
      other.dayNumber == dayNumber &&
      other.semanticLabel == semanticLabel &&
      other.inMonth == inMonth &&
      listEquals(other.away, away);

  @override
  int get hashCode => Object.hash(
    date,
    dayNumber,
    semanticLabel,
    inMonth,
    Object.hashAll(away),
  );
}
