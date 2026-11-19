import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design/src/foundation/calendar_lanes.dart';
import 'package:flutter_test/flutter_test.dart';

const _dates = [
  '2026-11-02',
  '2026-11-03',
  '2026-11-04',
  '2026-11-05',
  '2026-11-06',
  '2026-11-07',
  '2026-11-08',
];

CalendarStripEvent _event(String id, String start, String end) =>
    CalendarStripEvent(
      event: CalendarEventView(
        id: id,
        kind: CalendarEventKind.other,
        title: id,
      ),
      startDate: start,
      endDate: end,
      semanticLabel: id,
    );

void main() {
  test('clips an event to the days it touches', () {
    final placed = placeCalendarLanes(_dates, [
      _event('a', '2026-11-04', '2026-11-05'),
      _event('b', '2026-10-30', '2026-11-03'),
      _event('c', '2026-11-07', '2026-11-20'),
    ]);

    expect(
      [for (final p in placed) (p.first, p.last)],
      [(2, 3), (0, 1), (5, 6)],
    );
  });

  test('leaves out an event that touches none of the days', () {
    final placed = placeCalendarLanes(_dates, [
      _event('before', '2026-10-01', '2026-11-01'),
      _event('after', '2026-11-09', '2026-11-10'),
    ]);

    expect(placed, isEmpty);
  });

  test('puts an event in the first lane it does not overlap, in order', () {
    final placed = placeCalendarLanes(_dates, [
      _event('a', '2026-11-02', '2026-11-04'),
      _event('b', '2026-11-04', '2026-11-05'),
      _event('c', '2026-11-05', '2026-11-06'),
      _event('d', '2026-11-03', '2026-11-05'),
    ]);

    expect(
      {for (final p in placed) p.event.event.id: p.lane},
      {'a': 0, 'b': 1, 'c': 0, 'd': 2},
    );
  });

  test('covers the days from its first to its last', () {
    final placed = placeCalendarLanes(_dates, [
      _event('a', '2026-11-03', '2026-11-05'),
    ]).single;

    expect(
      [for (var i = 0; i < 7; i++) placed.covers(i)],
      [false, true, true, true, false, false, false],
    );
  });

  test('goes on before and after where it covers the next day or passes the '
      'edge of the days', () {
    final inside = placeCalendarLanes(_dates, [
      _event('a', '2026-11-03', '2026-11-05'),
    ]).single;
    final across = placeCalendarLanes(_dates, [
      _event('b', '2026-10-30', '2026-11-12'),
    ]).single;

    expect(inside.continuesBefore(1, _dates), isFalse);
    expect(inside.continuesBefore(2, _dates), isTrue);
    expect(inside.continuesAfter(3, _dates), isFalse);
    expect(inside.continuesAfter(2, _dates), isTrue);
    expect(across.continuesBefore(0, _dates), isTrue);
    expect(across.continuesAfter(6, _dates), isTrue);
  });
}
