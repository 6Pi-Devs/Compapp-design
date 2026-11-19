import 'package:compapp_design/compapp_design.dart';
import 'package:flutter_test/flutter_test.dart';

const _ana = MemberView(
  id: 'ana',
  name: 'Ana',
  initials: 'A',
  joinOrder: 0,
  semanticLabel: 'Ana, away',
);

CalendarMonthDay _day({
  String date = '2026-11-02',
  String dayNumber = '2',
  String label = 'Monday 2 November',
  bool inMonth = true,
  List<MemberView> away = const [],
}) => CalendarMonthDay(
  date: date,
  dayNumber: dayNumber,
  semanticLabel: label,
  inMonth: inMonth,
  away: away,
);

const _event = CalendarStripEvent(
  event: CalendarEventView(
    id: 'e',
    kind: CalendarEventKind.visit,
    title: 'Visit',
  ),
  startDate: '2026-11-02',
  endDate: '2026-11-02',
  semanticLabel: 'Visit',
);

CalendarMonthView _view({
  List<String> weekdays = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
  List<CalendarMonthDay>? days,
  List<CalendarStripEvent> events = const [_event],
  String? today = '2026-11-02',
  String? selected,
}) => CalendarMonthView(
  weekdays: weekdays,
  days: days ?? [_day()],
  events: events,
  today: today,
  selected: selected,
);

void main() {
  group('CalendarMonthDay', () {
    test('is in the month with nobody away by default', () {
      final day = _day();
      expect(day.inMonth, isTrue);
      expect(day.away, isEmpty);
    });

    test('two days with the same data are equal and hash alike', () {
      expect(_day(away: [_ana]), _day(away: [_ana]));
      expect(_day(away: [_ana]).hashCode, _day(away: [_ana]).hashCode);
    });

    test('every field takes part in equality', () {
      for (final other in [
        _day(date: '2026-11-03'),
        _day(dayNumber: '3'),
        _day(label: 'Other'),
        _day(inMonth: false),
        _day(away: [_ana]),
      ]) {
        expect(other, isNot(_day()));
      }
    });

    test('needs a date, a number and a spoken label', () {
      expect(() => _day(date: ''), throwsAssertionError);
      expect(() => _day(dayNumber: ''), throwsAssertionError);
      expect(() => _day(label: ''), throwsAssertionError);
    });
  });

  group('CalendarMonthView', () {
    test('two views with the same data are equal and hash alike', () {
      expect(_view(), _view());
      expect(_view().hashCode, _view().hashCode);
    });

    test('every field takes part in equality', () {
      for (final other in [
        _view(weekdays: const ['L', 'M', 'X', 'J', 'V', 'S', 'D']),
        _view(days: [_day(date: '2026-11-09')]),
        _view(events: const []),
        _view(today: null),
        _view(selected: '2026-11-02'),
      ]) {
        expect(other, isNot(_view()));
      }
    });

    test('today and the selected day are a date or null, never empty', () {
      expect(() => _view(today: ''), throwsAssertionError);
      expect(() => _view(selected: ''), throwsAssertionError);
    });
  });
}
