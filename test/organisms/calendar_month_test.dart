import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/host.dart';

/// Two weeks, Monday 26 October to Sunday 8 November 2026.
const _dates = [
  '2026-10-26',
  '2026-10-27',
  '2026-10-28',
  '2026-10-29',
  '2026-10-30',
  '2026-10-31',
  '2026-11-01',
  '2026-11-02',
  '2026-11-03',
  '2026-11-04',
  '2026-11-05',
  '2026-11-06',
  '2026-11-07',
  '2026-11-08',
];

const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

const _today = '2026-11-03';

MemberView _member(int joinOrder, String initials) => MemberView(
  id: 'm$joinOrder',
  name: 'Member $joinOrder',
  initials: initials,
  joinOrder: joinOrder,
  semanticLabel: 'Member $joinOrder, away',
);

String _number(String date) => '${int.parse(date.substring(8))}';

String _label(String date) => 'Day ${_number(date)}';

List<CalendarMonthDay> _days({Map<String, List<MemberView>> away = const {}}) =>
    [
      for (final date in _dates)
        CalendarMonthDay(
          date: date,
          dayNumber: _number(date),
          semanticLabel: _label(date),
          inMonth: date.startsWith('2026-11'),
          away: away[date] ?? const [],
        ),
    ];

CalendarStripEvent _event(
  String id,
  CalendarEventKind kind,
  String start,
  String end,
) => CalendarStripEvent(
  event: CalendarEventView(id: id, kind: kind, title: id),
  startDate: start,
  endDate: end,
  semanticLabel: id,
);

CalendarMonthView _view({
  List<CalendarStripEvent> events = const [],
  Map<String, List<MemberView>> away = const {},
  String? today = _today,
  String? selected,
  List<String> weekdays = _weekdays,
  List<CalendarMonthDay>? days,
}) => CalendarMonthView(
  weekdays: weekdays,
  days: days ?? _days(away: away),
  events: events,
  today: today,
  selected: selected,
);

CalendarMonth _month({
  CalendarMonthView? view,
  ValueChanged<String>? onDayTap,
  bool disabled = false,
}) => CalendarMonth(
  view: view ?? _view(),
  onDayTap: disabled ? null : (onDayTap ?? (_) {}),
);

Finder _day(String date) => find.byKey(Key('calendar.day.$date'));
Finder _piece(String id, String date) =>
    find.byKey(Key('calendar.ribbon.$id.$date'));
Finder _more(String date) => find.byKey(Key('calendar.more.$date'));
Finder _away(String date) => find.byKey(Key('calendar.away.$date'));

EventRibbon _ribbon(WidgetTester tester, String id, String date) =>
    tester.widget<EventRibbon>(
      find.descendant(of: _piece(id, date), matching: find.byType(EventRibbon)),
    );

ButtonStyle _style(WidgetTester tester, String date) =>
    tester.widget<TextButton>(_day(date)).style!;

Text _numberText(WidgetTester tester, String date) => tester.widget<Text>(
  find.descendant(of: _day(date), matching: find.text(_number(date))),
);

/// A widget test on a surface tall enough for the whole grid.
void _widgets(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (tester) async {
    tester.view
      ..physicalSize = const Size(800, 4000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await body(tester);
  });
}

final Map<String, List<MemberView>> _fiveAway = {
  '2026-11-04': [
    _member(2, 'MW'),
    _member(0, 'A'),
    _member(1, 'L'),
    _member(3, 'C'),
    _member(4, 'S'),
  ],
};

final List<CalendarStripEvent> _kinds = [
  _event('away', CalendarEventKind.absence, '2026-11-02', '2026-11-03'),
  _event('visit', CalendarEventKind.visit, '2026-11-04', '2026-11-04'),
  _event('night', CalendarEventKind.overnight, '2026-11-05', '2026-11-06'),
  _event('other', CalendarEventKind.other, '2026-11-07', '2026-11-07'),
];

const Map<CalendarEventKind, AppIcons> _glyphs = {
  CalendarEventKind.visit: AppIcons.visit,
  CalendarEventKind.overnight: AppIcons.bed,
  CalendarEventKind.absence: AppIcons.away,
  CalendarEventKind.other: AppIcons.calendar,
};

void main() {
  final themes = [('light', CompappTheme.light), ('dark', CompappTheme.dark)];

  group('content', () {
    _widgets('draws the weekdays and every day in order, a row per week', (
      tester,
    ) async {
      await tester.pumpWidget(host(_month()));

      expect(find.text('M'), findsOneWidget);
      expect(find.text('T'), findsNWidgets(2));
      for (final week in [_dates.sublist(0, 7), _dates.sublist(7)]) {
        final lefts = [for (final d in week) tester.getTopLeft(_day(d)).dx];
        expect(lefts, [...lefts]..sort());
        final tops = {for (final d in week) tester.getTopLeft(_day(d)).dy};
        expect(tops, hasLength(1));
      }
      expect(
        tester.getTopLeft(_day(_dates[7])).dy,
        greaterThan(tester.getTopLeft(_day(_dates[0])).dy),
      );
      for (final date in _dates) {
        expect(
          find.descendant(of: _day(date), matching: find.text(_number(date))),
          findsOneWidget,
        );
      }
    });

    _widgets('has its keys', (tester) async {
      await tester.pumpWidget(
        host(
          _month(
            view: _view(events: _kinds, away: _fiveAway),
          ),
        ),
      );

      for (final key in [
        'calendar.month',
        'calendar.week.2026-10-26',
        'calendar.week.2026-11-02',
        'calendar.day.2026-11-04',
        'calendar.away.2026-11-04',
        'calendar.away.2026-11-04.m2',
        'calendar.ribbon.visit.2026-11-04',
        'event.visit',
      ]) {
        expect(find.byKey(Key(key)), findsWidgets, reason: key);
      }
    });

    _widgets('draws each kind of event with the glyph of its kind', (
      tester,
    ) async {
      await tester.pumpWidget(host(_month(view: _view(events: _kinds))));

      for (final event in _kinds) {
        final ribbon = _ribbon(tester, event.event.id, event.startDate);
        expect(ribbon.compact, isTrue);
        expect(ribbon.event.kind, event.event.kind);
        final icon = tester.widget<AppIcon>(
          find.descendant(
            of: _piece(event.event.id, event.startDate),
            matching: find.byType(AppIcon),
          ),
        );
        expect(icon.icon, _glyphs[event.event.kind]);
      }
    });

    _widgets('shows the first member away as a small pebble of their color, '
        'and +N for the others', (tester) async {
      await tester.pumpWidget(host(_month(view: _view(away: _fiveAway))));

      final pebble = tester.widget<AppPebble>(
        find.descendant(
          of: _away('2026-11-04'),
          matching: find.byType(AppPebble),
        ),
      );
      expect(pebble.initials, 'MW');
      expect(pebble.joinOrder, 2);
      expect(pebble.size, AppPebbleSize.s28);
      expect(
        find.descendant(of: _away('2026-11-04'), matching: find.text('+4')),
        findsOneWidget,
      );
      expect(find.byType(AppPebble), findsOneWidget);
    });

    _widgets('one member away shows the pebble alone, without a count', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _month(
            view: _view(
              away: {
                '2026-11-04': [_member(1, 'L')],
              },
            ),
          ),
        ),
      );

      expect(find.byType(AppPebble), findsOneWidget);
      expect(find.textContaining('+'), findsNothing);
    });

    _widgets('a week with nothing has no row for who is away, nor lanes', (
      tester,
    ) async {
      await tester.pumpWidget(host(_month()));

      expect(find.byType(AppPebble), findsNothing);
      expect(find.byType(EventRibbon), findsNothing);
    });
  });

  group('lanes', () {
    final crowded = [
      _event('a', CalendarEventKind.visit, '2026-11-04', '2026-11-04'),
      _event('b', CalendarEventKind.other, '2026-11-03', '2026-11-05'),
      _event('c', CalendarEventKind.overnight, '2026-11-04', '2026-11-05'),
      _event('d', CalendarEventKind.absence, '2026-11-04', '2026-11-04'),
    ];

    _widgets('shows two lanes and +N on each day with events left out', (
      tester,
    ) async {
      await tester.pumpWidget(host(_month(view: _view(events: crowded))));

      expect(_piece('a', '2026-11-04'), findsOneWidget);
      expect(_piece('b', '2026-11-04'), findsOneWidget);
      expect(_piece('c', '2026-11-04'), findsNothing);
      expect(_piece('d', '2026-11-04'), findsNothing);
      expect(
        find.descendant(of: _more('2026-11-04'), matching: find.text('+2')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _more('2026-11-05'), matching: find.text('+1')),
        findsOneWidget,
      );
      expect(_more('2026-11-03'), findsNothing);
      expect(CalendarMonth.maxLanes, 2);
    });

    _widgets('places events per week, in the first lane they fit', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _month(
            view: _view(
              events: [
                _event(
                  'a',
                  CalendarEventKind.visit,
                  '2026-11-02',
                  '2026-11-03',
                ),
                _event(
                  'b',
                  CalendarEventKind.other,
                  '2026-11-03',
                  '2026-11-04',
                ),
                _event(
                  'c',
                  CalendarEventKind.visit,
                  '2026-11-05',
                  '2026-11-05',
                ),
              ],
            ),
          ),
        ),
      );

      final top = tester.getTopLeft(_piece('a', '2026-11-02')).dy;
      expect(tester.getTopLeft(_piece('c', '2026-11-05')).dy, top);
      expect(tester.getTopLeft(_piece('b', '2026-11-03')).dy, greaterThan(top));
    });

    _widgets('a multi-day event joins across its days and keeps a flat edge '
        'at the ends of the weeks and of the grid', (tester) async {
      await tester.pumpWidget(
        host(
          _month(
            view: _view(
              events: [
                _event(
                  'trip',
                  CalendarEventKind.absence,
                  '2026-10-30',
                  '2026-11-03',
                ),
                _event(
                  'early',
                  CalendarEventKind.other,
                  '2026-10-20',
                  '2026-10-26',
                ),
                _event(
                  'late',
                  CalendarEventKind.visit,
                  '2026-11-08',
                  '2026-11-20',
                ),
              ],
            ),
          ),
        ),
      );

      (bool, bool) edges(String id, String date) {
        final ribbon = _ribbon(tester, id, date);
        return (ribbon.continuesBefore, ribbon.continuesAfter);
      }

      expect(edges('trip', '2026-10-30'), (false, true));
      expect(edges('trip', '2026-10-31'), (true, true));
      expect(edges('trip', '2026-11-01'), (true, true));
      expect(edges('trip', '2026-11-02'), (true, true));
      expect(edges('trip', '2026-11-03'), (true, false));
      expect(edges('early', '2026-10-26'), (true, false));
      expect(edges('late', '2026-11-08'), (false, true));
      // The pieces of one week touch: the event reads as one range.
      expect(
        tester.getTopRight(_piece('trip', '2026-10-30')).dx,
        moreOrLessEquals(tester.getTopLeft(_piece('trip', '2026-10-31')).dx),
      );
    });
  });

  group('callbacks', () {
    _widgets('a tap on the number, on who is away or on a ribbon reports the '
        'date of the day', (tester) async {
      final taps = <String>[];
      await tester.pumpWidget(
        host(
          _month(
            view: _view(events: _kinds, away: _fiveAway),
            onDayTap: taps.add,
          ),
        ),
      );

      await tester.tap(_day('2026-11-04'));
      await tester.tap(find.byType(AppPebble));
      await tester.tap(_piece('night', '2026-11-06'));
      expect(taps, ['2026-11-04', '2026-11-04', '2026-11-06']);
    });

    _widgets('a day outside the month still takes taps', (tester) async {
      final taps = <String>[];
      await tester.pumpWidget(host(_month(onDayTap: taps.add)));

      await tester.tap(_day('2026-10-27'));
      expect(taps, ['2026-10-27']);
    });

    _widgets('a null onDayTap disables the days', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(_month(view: _view(away: _fiveAway), disabled: true)),
      );

      expect(tester.widget<TextButton>(_day('2026-11-04')).onPressed, isNull);
      await tester.tap(find.byType(AppPebble));
      expect(tester.takeException(), isNull);
      expect(
        tester.getSemantics(_day('2026-11-04')),
        isSemantics(
          label: _label('2026-11-04'),
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasSelectedState: true,
          isSelected: false,
        ),
      );
      handle.dispose();
    });
  });

  group('semantics', () {
    _widgets('each day is one button named by its label, with a selected '
        'state; nothing else says anything', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          _month(
            view: _view(
              events: _kinds,
              away: _fiveAway,
              selected: '2026-11-05',
            ),
          ),
        ),
      );

      expect(semanticsLabels(tester), [for (final d in _dates) _label(d)]);
      for (final date in _dates) {
        expect(
          tester.getSemantics(_day(date)),
          isSemantics(
            label: _label(date),
            isButton: true,
            isFocusable: true,
            hasEnabledState: true,
            isEnabled: true,
            hasSelectedState: true,
            isSelected: date == '2026-11-05',
            hasTapAction: true,
            hasFocusAction: true,
          ),
          reason: date,
        );
      }
      handle.dispose();
    });

    _widgets('the button of a day is at least the least target', (
      tester,
    ) async {
      await tester.pumpWidget(host(_month()));

      for (final date in _dates) {
        final size = tester.getSize(_day(date));
        expect(size.width, greaterThanOrEqualTo(AppSizes.minTarget));
        expect(size.height, greaterThanOrEqualTo(AppSizes.minTarget));
      }
    });
  });

  group('look', () {
    for (final (name, theme) in themes) {
      _widgets('today is filled, the selected day ringed on a soft fill, a '
          'day outside the month muted ($name)', (tester) async {
        await tester.pumpWidget(
          host(
            _month(view: _view(selected: '2026-11-05')),
            theme: theme,
          ),
        );
        final scheme = theme.colorScheme;

        final today = _style(tester, _today);
        expect(today.backgroundColor!.resolve({}), scheme.primary);
        expect(today.side!.resolve({}), BorderSide.none);
        expect(_numberText(tester, _today).style!.color, scheme.onPrimary);

        final selected = _style(tester, '2026-11-05');
        expect(selected.backgroundColor!.resolve({}), scheme.primaryContainer);
        expect(selected.side!.resolve({})!.color, scheme.onSurface);
        expect(selected.side!.resolve({})!.width, AppSizes.borderEmphasis);

        final plain = _style(tester, '2026-11-06');
        expect(plain.backgroundColor!.resolve({}), Colors.transparent);
        expect(
          _numberText(tester, '2026-11-06').style!.color,
          scheme.onSurface,
        );
        expect(
          _numberText(tester, '2026-10-27').style!.color,
          scheme.onSurfaceVariant,
        );

        expectContrast(
          {
            'today': (scheme.onPrimary, scheme.primary),
            'selected': (scheme.onSurface, scheme.primaryContainer),
            'day': (scheme.onSurface, scheme.surfaceContainerLowest),
            'outside': (scheme.onSurfaceVariant, scheme.surfaceContainerLowest),
          },
          minimum: 4.5,
          reason: name,
        );
      });
    }

    _widgets('today that is selected keeps its fill and gets the ring', (
      tester,
    ) async {
      await tester.pumpWidget(host(_month(view: _view(selected: _today))));
      final scheme = CompappTheme.light.colorScheme;

      final style = _style(tester, _today);
      expect(style.backgroundColor!.resolve({}), scheme.primary);
      expect(style.side!.resolve({})!.color, scheme.onSurface);
    });

    for (final (name, theme) in themes) {
      _widgets('builds in the $name theme with every marker', (tester) async {
        await tester.pumpWidget(
          host(
            _month(
              view: _view(events: _kinds, away: _fiveAway),
            ),
            theme: theme,
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(EventRibbon), findsWidgets);
      });
    }
  });

  group('large text and narrow columns', () {
    for (final scale in [1.0, 2.0]) {
      _widgets('fits 320 wide at text scale $scale with five away, two '
          'initials and crowded lanes, without overflow', (tester) async {
        await loadBundledFonts();
        await tester.pumpWidget(
          host(
            _month(
              view: _view(
                away: _fiveAway,
                events: [
                  ..._kinds,
                  _event(
                    'x',
                    CalendarEventKind.visit,
                    '2026-11-04',
                    '2026-11-04',
                  ),
                  _event(
                    'y',
                    CalendarEventKind.other,
                    '2026-11-04',
                    '2026-11-04',
                  ),
                ],
              ),
            ),
            textScale: scale,
          ),
        );

        expect(tester.takeException(), isNull);
        final grid = tester.getRect(find.byType(CalendarMonth));
        expect(grid.width, hostWidth);
        // Who is away stays inside its column.
        final column = (grid.width - 2 * AppSpacing.xs) / 7;
        final away = tester.getRect(_away('2026-11-04'));
        expect(away.width, lessThanOrEqualTo(column + 0.01));
        expect(
          tester.getRect(find.text('+4')).right,
          lessThanOrEqualTo(away.right + 0.01),
        );
        expect(_more('2026-11-04'), findsOneWidget);
      });
    }

    _widgets('can be measured by intrinsic sizing, as the goldens do', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _month(
            view: _view(events: _kinds, away: _fiveAway),
          ),
        ),
      );
      final box = tester.renderObject<RenderBox>(find.byType(CalendarMonth));

      expect(box.getMinIntrinsicHeight(hostWidth), box.size.height);
      expect(
        box.getDryLayout(const BoxConstraints.tightFor(width: hostWidth)),
        box.size,
      );
    });
  });

  group('right to left', () {
    _widgets('mirrors the columns: the first weekday at the right', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _month(view: _view(events: _kinds)),
          direction: TextDirection.rtl,
        ),
      );

      expect(
        tester.getCenter(_day(_dates[7])).dx,
        greaterThan(tester.getCenter(_day(_dates[8])).dx),
      );
      expect(
        tester.getCenter(_piece('away', '2026-11-02')).dx,
        greaterThan(tester.getCenter(_piece('away', '2026-11-03')).dx),
      );
      final ribbon = _ribbon(tester, 'away', '2026-11-02');
      expect(ribbon.continuesAfter, isTrue);
    });
  });

  group('asserts', () {
    final cases = <String, CalendarMonthView>{
      'seven weekdays': _view(weekdays: _weekdays.sublist(1)),
      'whole weeks': _view(days: _days().sublist(1)),
      'some days': _view(days: const []),
      'dates in order': _view(days: _days().reversed.toList()),
      'unique event ids': _view(
        events: [
          _event('a', CalendarEventKind.visit, '2026-11-02', '2026-11-02'),
          _event('a', CalendarEventKind.visit, '2026-11-03', '2026-11-03'),
        ],
      ),
      'no event ends before it starts': _view(
        events: [
          _event('a', CalendarEventKind.visit, '2026-11-03', '2026-11-02'),
        ],
      ),
      'a label that says the number': _view(
        days: [
          for (final day in _days())
            CalendarMonthDay(
              date: day.date,
              dayNumber: day.dayNumber,
              semanticLabel: 'A day',
            ),
        ],
      ),
    };
    for (final MapEntry(key: name, value: view) in cases.entries) {
      _widgets('asserts $name', (tester) async {
        await tester.pumpWidget(host(_month(view: view)));
        expect(tester.takeException(), isAssertionError);
      });
    }
  });
}
