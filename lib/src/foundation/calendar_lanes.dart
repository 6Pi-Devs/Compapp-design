import 'package:compapp_design/src/models/calendar_strip_event.dart';

/// An event placed in a row of days: the first and the last index of the days
/// it covers and the lane (row of the ribbon band) it sits in.
class CalendarLanePlacement {
  const new(this.event, this.first, this.last, this.lane);

  final CalendarStripEvent event;
  final int first;
  final int last;
  final int lane;

  /// Whether the event covers the day at [index].
  bool covers(int index) => index >= first && index <= last;

  /// Whether the event goes on before the day at [index]: it covers the day
  /// before it, or it starts before the first of [dates].
  bool continuesBefore(int index, List<String> dates) =>
      index > first || event.startDate.compareTo(dates.first) < 0;

  /// Whether the event goes on after the day at [index]: it covers the day
  /// after it, or it ends after the last of [dates].
  bool continuesAfter(int index, List<String> dates) =>
      index < last || event.endDate.compareTo(dates.last) > 0;
}

/// Places [events] over a row of days given by their `YYYY-MM-DD` [dates], in
/// order. Dates are compared as strings, which order like the dates they
/// spell: no date maths.
///
/// An event is clipped to the days it touches and put in the first lane where
/// it overlaps no event placed before it, in the order of [events]. An event
/// that touches none of the days is left out.
List<CalendarLanePlacement> placeCalendarLanes(
  List<String> dates,
  List<CalendarStripEvent> events,
) {
  final placed = <CalendarLanePlacement>[];
  final lanes = <List<CalendarLanePlacement>>[];
  for (final event in events) {
    var first = -1;
    var last = -1;
    for (var i = 0; i < dates.length; i++) {
      final date = dates[i];
      if (date.compareTo(event.startDate) >= 0 &&
          date.compareTo(event.endDate) <= 0) {
        if (first < 0) first = i;
        last = i;
      }
    }
    if (first < 0) continue;
    var lane = 0;
    while (lane < lanes.length &&
        lanes[lane].any((p) => p.first <= last && first <= p.last)) {
      lane++;
    }
    if (lane == lanes.length) lanes.add([]);
    final item = CalendarLanePlacement(event, first, last, lane);
    lanes[lane].add(item);
    placed.add(item);
  }
  return placed;
}
