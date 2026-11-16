import 'dart:ui' show Tristate;

import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/host.dart';
import '../helpers/painted_pixels.dart';
import '../helpers/word_breaks.dart';

const _dates = [
  '2026-11-01',
  '2026-11-02',
  '2026-11-03',
  '2026-11-04',
  '2026-11-05',
  '2026-11-06',
  '2026-11-07',
];

const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const _longWeekdays = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

const _weekdaysEs = ['dom', 'lun', 'mar', 'mié', 'jue', 'vie', 'sáb'];
const _longWeekdaysEs = [
  'domingo',
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
];

List<CalendarStripDay> _days({
  List<String> dates = _dates,
  bool spanish = false,
  String? today,
}) => [
  for (var i = 0; i < dates.length; i++)
    CalendarStripDay(
      date: dates[i],
      weekday: (spanish ? _weekdaysEs : _weekdays)[i],
      dayNumber: '${i + 1}',
      semanticLabel: spanish
          ? '${_longWeekdaysEs[i]} ${i + 1} de noviembre'
                '${dates[i] == today ? ', hoy' : ''}'
          : '${_longWeekdays[i]} ${i + 1} November'
                '${dates[i] == today ? ', today' : ''}',
    ),
];

CalendarStripEvent _event(
  String id,
  CalendarEventKind kind,
  String start,
  String end, {
  String? title,
  String? label,
}) {
  final shown = title ?? id;
  return CalendarStripEvent(
    event: CalendarEventView(id: id, kind: kind, title: shown),
    startDate: start,
    endDate: end,
    semanticLabel: label ?? '$shown, $start to $end',
  );
}

CalendarStripEvent get _absence => _event(
  'luis',
  CalendarEventKind.absence,
  '2026-11-01',
  '2026-11-06',
  title: 'Luis away · until Fri',
  label: 'Absence. Luis away · until Fri 6 Nov',
);

CalendarStripEvent get _visit => _event(
  'visit',
  CalendarEventKind.visit,
  '2026-11-04',
  '2026-11-04',
  title: 'Visit',
  label: 'Visit, Wed 4 Nov',
);

CalendarStripEvent get _overnight => _event(
  'night',
  CalendarEventKind.overnight,
  '2026-11-07',
  '2026-11-08',
  title: 'Overnight guest',
  label: 'Overnight guest, Sat 7 to Sun 8 Nov',
);

CalendarStripView _view({
  List<CalendarStripEvent>? events,
  String? today = '2026-11-01',
  bool spanish = false,
  List<String> dates = _dates,
}) => CalendarStripView(
  days: _days(dates: dates, spanish: spanish, today: today),
  events: events ?? [_absence, _visit, _overnight],
  today: today,
);

CalendarStrip _strip({
  CalendarStripView? view,
  ValueChanged<String>? onDayTap,
  ValueChanged<String>? onEventTap,
}) => CalendarStrip(
  view: view ?? _view(),
  onDayTap: onDayTap ?? (_) {},
  onEventTap: onEventTap ?? (_) {},
);

Finder _day(String date) => find.byKey(Key('calendar.day.$date'));
Finder _row(String id) => find.byKey(Key('calendar.event.$id'));
Finder _piece(String id, String date) =>
    find.byKey(Key('calendar.ribbon.$id.$date'));
Finder get _stripFinder => find.byKey(const Key('calendar.strip'));
Finder get _eventList => find.byKey(const Key('calendar.events'));

/// The ribbon inside the piece of [id] on [date].
EventRibbon _ribbon(WidgetTester tester, String id, String date) =>
    tester.widget<EventRibbon>(
      find.descendant(of: _piece(id, date), matching: find.byType(EventRibbon)),
    );

/// A widget test on a surface tall enough for the whole strip: it is not a
/// scrollable, and at large text it is tall.
void _widgets(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (tester) async {
    tester.view
      ..physicalSize = const Size(800, 8000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await body(tester);
  });
}

List<SemanticsNode> _children(SemanticsNode node) {
  final children = <SemanticsNode>[];
  node.visitChildren((child) {
    children.add(child);
    return true;
  });
  return children;
}

void main() {
  final themes = [('light', CompappTheme.light), ('dark', CompappTheme.dark)];

  group('content', () {
    _widgets('draws the seven days in order, each with its weekday and its '
        'number', (tester) async {
      await tester.pumpWidget(host(_strip()));

      final lefts = [
        for (final date in _dates) tester.getTopLeft(_day(date)).dx,
      ];
      expect(lefts, [...lefts]..sort());
      for (var i = 0; i < 7; i++) {
        expect(
          find.descendant(
            of: _day(_dates[i]),
            matching: find.text(_weekdays[i]),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: _day(_dates[i]), matching: find.text('${i + 1}')),
          findsOneWidget,
        );
      }
    });

    _widgets('has its keys', (tester) async {
      await tester.pumpWidget(host(_strip()));

      for (final key in [
        'calendar.strip',
        'calendar.events',
        'calendar.day.2026-11-01',
        'calendar.day.2026-11-07',
        'calendar.event.luis',
        'calendar.event.visit',
        'calendar.event.night',
        'calendar.ribbon.luis.2026-11-01',
        'calendar.ribbon.visit.2026-11-04',
        'calendar.ribbon.night.2026-11-07',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget, reason: key);
      }
    });

    _widgets('draws an event on each day it covers, and on no other', (
      tester,
    ) async {
      await tester.pumpWidget(host(_strip()));

      for (final (id, covered) in [
        ('luis', _dates.sublist(0, 6)),
        ('visit', ['2026-11-04']),
        ('night', ['2026-11-07']),
      ]) {
        for (final date in _dates) {
          expect(
            _piece(id, date),
            covered.contains(date) ? findsOneWidget : findsNothing,
            reason: '$id on $date',
          );
        }
      }
    });

    _widgets('keeps a flat edge where an event goes on, and none where it '
        'starts or ends', (tester) async {
      await tester.pumpWidget(host(_strip()));

      List<(bool, bool)> edges(String id, List<String> dates) => [
        for (final date in dates)
          (
            _ribbon(tester, id, date).continuesBefore,
            _ribbon(tester, id, date).continuesAfter,
          ),
      ];
      expect(edges('luis', _dates.sublist(0, 6)), [
        (false, true),
        (true, true),
        (true, true),
        (true, true),
        (true, true),
        (true, false),
      ]);
      expect(edges('visit', ['2026-11-04']), [(false, false)]);
      expect(edges('night', ['2026-11-07']), [
        (false, true),
      ], reason: 'it goes on past the week');
    });

    _widgets('an event that began before the week has a flat start', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _strip(
            view: _view(
              events: [
                _event(
                  'long',
                  CalendarEventKind.absence,
                  '2026-10-28',
                  '2026-11-02',
                ),
              ],
            ),
          ),
        ),
      );

      expect(_ribbon(tester, 'long', '2026-11-01').continuesBefore, isTrue);
      expect(_ribbon(tester, 'long', '2026-11-02').continuesAfter, isFalse);
      expect(_piece('long', '2026-11-03'), findsNothing);
    });

    _widgets('leaves out an event that touches none of the days', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _strip(
            view: _view(
              events: [
                _event(
                  'past',
                  CalendarEventKind.visit,
                  '2026-10-20',
                  '2026-10-21',
                ),
                _event(
                  'later',
                  CalendarEventKind.visit,
                  '2026-11-09',
                  '2026-11-09',
                ),
              ],
            ),
          ),
        ),
      );

      expect(_row('past'), findsNothing);
      expect(_row('later'), findsNothing);
      expect(_eventList, findsNothing);
    });

    _widgets('places each event in the first row it does not overlap', (
      tester,
    ) async {
      await tester.pumpWidget(host(_strip()));

      double top(String id, String date) =>
          tester.getTopLeft(_piece(id, date)).dy;
      expect(top('luis', '2026-11-01'), top('luis', '2026-11-06'));
      expect(
        top('visit', '2026-11-04'),
        greaterThan(top('luis', '2026-11-04')),
        reason: 'it overlaps the absence: second row',
      );
      expect(
        top('night', '2026-11-07'),
        top('luis', '2026-11-01'),
        reason: 'it does not overlap the absence: first row',
      );
    });

    _widgets('lists the events, each with its whole title, in the order '
        'given', (tester) async {
      await tester.pumpWidget(host(_strip()));

      expect(
        find.descendant(
          of: _row('luis'),
          matching: find.text('Luis away · until Fri'),
        ),
        findsOneWidget,
      );
      final tops = [
        for (final id in ['luis', 'visit', 'night'])
          tester.getTopLeft(_row(id)).dy,
      ];
      expect(tops, [...tops]..sort());
      expect(
        tester.getTopLeft(_row('luis')).dy,
        greaterThan(tester.getBottomLeft(_day('2026-11-01')).dy),
        reason: 'under the days',
      );
    });

    _widgets('an empty week is the seven days alone', (tester) async {
      await tester.pumpWidget(host(_strip(view: _view(events: const []))));

      expect(find.byType(EventRibbon), findsNothing);
      expect(_eventList, findsNothing);
      expect(find.byType(TextButton), findsNWidgets(7));
    });

    _widgets('an invalid view is a mistake the debug build reports', (
      tester,
    ) async {
      for (final view in [
        CalendarStripView(days: _days().sublist(0, 6), events: const []),
        _view(dates: [..._dates.sublist(0, 6), '2026-11-06']),
        _view(events: [_visit, _visit]),
        _view(
          events: [
            _event('back', CalendarEventKind.visit, '2026-11-05', '2026-11-03'),
          ],
        ),
      ]) {
        await tester.pumpWidget(host(_strip(view: view)));
        expect(tester.takeException(), isAssertionError);
      }
    });

    _widgets('a spoken label that lacks the visible text is reported (label '
        'in name)', (tester) async {
      await tester.pumpWidget(
        host(
          _strip(
            view: CalendarStripView(
              days: [
                ..._days().sublist(0, 6),
                const CalendarStripDay(
                  date: '2026-11-07',
                  weekday: 'Sat',
                  dayNumber: '7',
                  semanticLabel: 'The seventh',
                ),
              ],
              events: const [],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isAssertionError);

      await tester.pumpWidget(
        host(
          _strip(
            view: _view(
              events: [
                _event(
                  'luis',
                  CalendarEventKind.absence,
                  '2026-11-01',
                  '2026-11-06',
                  title: 'Luis away',
                  label: 'Absence of a flatmate',
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });

    test('the models need their words and compare by value', () {
      expect(
        () => CalendarStripDay(
          date: '',
          weekday: 'Sun',
          dayNumber: '1',
          semanticLabel: 'Sunday 1',
        ),
        throwsAssertionError,
      );
      expect(
        () => CalendarStripEvent(
          event: const CalendarEventView(
            id: 'a',
            kind: CalendarEventKind.visit,
            title: 'A',
          ),
          startDate: '2026-11-01',
          endDate: '2026-11-01',
          semanticLabel: '',
        ),
        throwsAssertionError,
      );
      expect(_view(), _view());
      expect(_view().hashCode, _view().hashCode);
      expect(_view(), isNot(_view(today: '2026-11-02')));
      expect(_view(), isNot(_view(events: const [])));
    });
  });

  group('callbacks', () {
    _widgets('a tap on a day calls onDayTap with its date', (tester) async {
      final taps = <String>[];
      await tester.pumpWidget(host(_strip(onDayTap: taps.add)));

      await tester.tap(_day('2026-11-03'));
      await tester.tap(_day('2026-11-07'));

      expect(taps, ['2026-11-03', '2026-11-07']);
    });

    _widgets('a tap on an event row calls onEventTap with its id', (
      tester,
    ) async {
      final taps = <String>[];
      await tester.pumpWidget(host(_strip(onEventTap: taps.add)));

      await tester.tap(_row('visit'));
      await tester.tap(_row('luis'));

      expect(taps, ['visit', 'luis']);
    });

    _widgets('the ribbons of the band are not buttons', (tester) async {
      final days = <String>[];
      final events = <String>[];
      await tester.pumpWidget(
        host(_strip(onDayTap: days.add, onEventTap: events.add)),
      );

      await tester.tap(_piece('luis', '2026-11-03'), warnIfMissed: false);

      expect(events, isEmpty);
      expect(days, isEmpty);
    });

    for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
      _widgets(
        'a focused day takes ${key.keyLabel.isEmpty ? 'Space' : key.keyLabel}',
        (tester) async {
          final taps = <String>[];
          await tester.pumpWidget(host(_strip(onDayTap: taps.add)));

          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.sendKeyEvent(key);

          expect(taps, ['2026-11-02']);
        },
      );
    }

    _widgets('the semantic tap action does the same as a tap', (tester) async {
      final handle = tester.ensureSemantics();
      final days = <String>[];
      final events = <String>[];
      await tester.pumpWidget(
        host(_strip(onDayTap: days.add, onEventTap: events.add)),
      );

      tester.semantics.tap(find.semantics.byLabel(RegExp('^Tuesday 3')));
      tester.semantics.tap(find.semantics.byLabel('Visit, Wed 4 Nov').last);

      expect(days, ['2026-11-03']);
      expect(events, ['visit']);
      handle.dispose();
    });
  });

  group('semantics', () {
    _widgets('a day is one button that reads the day, then its events', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_strip()));

      SemanticsData data(String date) =>
          tester.getSemantics(_day(date)).getSemanticsData();
      expect(
        data('2026-11-01').label,
        'Sunday 1 November, today\nAbsence. Luis away · until Fri 6 Nov',
      );
      expect(
        data('2026-11-04').label,
        'Wednesday 4 November\nAbsence. Luis away · until Fri 6 Nov\n'
        'Visit, Wed 4 Nov',
      );
      expect(data('2026-11-07').label, contains('Overnight guest'));
      for (final date in _dates) {
        expect(data(date).flagsCollection.isButton, isTrue, reason: date);
        expect(data(date).flagsCollection.isEnabled, Tristate.isTrue);
        expect(data(date).hasAction(SemanticsAction.tap), isTrue);
      }
      handle.dispose();
    });

    _widgets('a day without events reads only the day', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_strip(view: _view(events: const []))));

      expect(
        tester.getSemantics(_day('2026-11-02')).getSemanticsData().label,
        'Monday 2 November',
      );
      handle.dispose();
    });

    _widgets('the visible weekday and number add nothing of their own', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_strip(view: _view(events: const []))));

      expect(semanticsLabels(tester), [
        for (var i = 0; i < 7; i++)
          '${_longWeekdays[i]} ${i + 1} November${i == 0 ? ', today' : ''}',
      ]);
      handle.dispose();
    });

    _widgets('the events are a list of buttons, and the ribbons say '
        'nothing', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_strip()));

      final roles = {
        for (final node in semanticsNodes(tester))
          node.id: node.getSemanticsData().role,
      };
      expect(roles.values.where((r) => r == SemanticsRole.list), hasLength(1));
      expect(
        roles.values.where((r) => r == SemanticsRole.listItem),
        hasLength(3),
      );
      final list = tester.getSemantics(_eventList);
      final items = _children(list);
      expect(items, hasLength(3));
      expect(
        [
          for (final item in items)
            for (final child in _children(item)) child.label,
        ],
        [
          'Absence. Luis away · until Fri 6 Nov',
          'Visit, Wed 4 Nov',
          'Overnight guest, Sat 7 to Sun 8 Nov',
        ],
      );
      for (final item in items) {
        final button = _children(item).single.getSemanticsData();
        expect(button.flagsCollection.isButton, isTrue);
        expect(button.hasAction(SemanticsAction.tap), isTrue);
      }
      // 7 days, then the three events, nothing for the ribbons.
      expect(semanticsLabels(tester), hasLength(10));
      handle.dispose();
    });

    _widgets('reads in the order of the screen', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_strip()));

      final labels = semanticsLabels(tester);
      expect(labels.first, startsWith('Sunday 1 November'));
      expect(labels[6], startsWith('Saturday 7 November'));
      expect(labels[7], 'Absence. Luis away · until Fri 6 Nov');
      handle.dispose();
    });

    _widgets('today is told by the spoken label and the filled cell, and '
        'only one day', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          _strip(
            view: _view(today: '2026-11-03', events: const []),
          ),
        ),
      );

      final spoken = [
        for (final date in _dates)
          if (tester
              .getSemantics(_day(date))
              .getSemanticsData()
              .label
              .contains('today'))
            date,
      ];
      expect(spoken, ['2026-11-03']);
      handle.dispose();
    });

    _widgets('a week without today highlights nobody', (tester) async {
      await tester.pumpWidget(
        host(_strip(view: _view(today: null, events: const []))),
      );
      final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));

      for (final date in _dates) {
        final cell = tester.getRect(_day(date)).shift(-boundary);
        final pixels = await paintedPixels(
          tester,
          hostBoundaryKey,
          region: Rect.fromLTWH(cell.left + 8, cell.top + 22, 4, 4),
        );
        expect(
          countPixels(pixels, CompappTheme.light.colorScheme.primary),
          0,
          reason: date,
        );
      }
    });
  });

  group('look', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;

      _widgets('today is the primary fill and the others have none ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            _strip(view: _view(events: const [])),
            theme: theme,
          ),
        );
        final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));

        Future<List<Color>> corner(String date) async {
          final cell = tester.getRect(_day(date)).shift(-boundary);
          return await paintedPixels(
            tester,
            hostBoundaryKey,
            region: Rect.fromLTWH(cell.left + 8, cell.top + 22, 4, 4),
          );
        }

        final today = await corner('2026-11-01');
        expect(countPixels(today, scheme.primary), today.length);
        expect(countPixels(await corner('2026-11-02'), scheme.primary), 0);
        for (final text in ['Sun', '1']) {
          final style = tester
              .widget<Text>(
                find.descendant(
                  of: _day('2026-11-01'),
                  matching: find.text(text),
                ),
              )
              .style!;
          expect(style.color, scheme.onPrimary, reason: text);
        }
      });

      _widgets('the weekday is muted ink and the number is ink ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            _strip(view: _view(events: const [])),
            theme: theme,
          ),
        );

        Color? color(String text) => tester
            .widget<Text>(
              find.descendant(
                of: _day('2026-11-02'),
                matching: find.text(text),
              ),
            )
            .style
            ?.color;
        expect(color('Mon'), scheme.onSurfaceVariant);
        expect(color('2'), scheme.onSurface);
      });

      _widgets('the card is the surface with a hairline edge, and the '
          'dividers are the line color ($name)', (tester) async {
        await tester.pumpWidget(host(_strip(), theme: theme));

        final card = tester.widget<DecoratedBox>(
          find
              .descendant(of: _stripFinder, matching: find.byType(DecoratedBox))
              .first,
        );
        final decoration = card.decoration as BoxDecoration;
        expect(decoration.color, scheme.surfaceContainerLowest);
        expect((decoration.border! as Border).top.color, scheme.outlineVariant);
        final dividers = tester
            .widgetList<SizedBox>(
              find.descendant(
                of: _stripFinder,
                matching: find.byType(SizedBox),
              ),
            )
            .where((box) => box.height == AppSizes.hairline);
        expect(
          dividers,
          hasLength(3),
          reason: 'under the days and between rows',
        );
        for (final divider in dividers) {
          expect((divider.child! as ColoredBox).color, scheme.outlineVariant);
        }
      });

      _widgets('each kind of ribbon is drawn with its fill and its glyph, '
          'the absence quiet ($name)', (tester) async {
        final colors = theme.extension<AppColors>()!;
        await tester.pumpWidget(host(_strip(), theme: theme));
        final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));

        for (final (id, date, fill) in [
          ('luis', '2026-11-02', scheme.surfaceContainerHigh),
          ('visit', '2026-11-04', colors.pebbleSky),
          ('night', '2026-11-07', colors.pebbleApricot),
        ]) {
          final rect = tester.getRect(_piece(id, date)).shift(-boundary);
          final pixels = await paintedPixels(
            tester,
            hostBoundaryKey,
            region: rect,
          );
          expect(
            countPixels(pixels, fill),
            greaterThan(rect.width * rect.height ~/ 2),
            reason: '$id: the fill',
          );
          expect(
            find.descendant(
              of: _piece(id, date),
              matching: find.byType(AppIcon),
            ),
            findsOneWidget,
            reason: '$id: the glyph tells the kind, not the color',
          );
        }
        expect(
          [
            for (final id in ['luis', 'visit', 'night'])
              tester
                  .widget<AppIcon>(
                    find.descendant(
                      of: _piece(
                        id,
                        id == 'luis'
                            ? '2026-11-02'
                            : (id == 'visit' ? '2026-11-04' : '2026-11-07'),
                      ),
                      matching: find.byType(AppIcon),
                    ),
                  )
                  .icon,
          ],
          [AppIcons.away, AppIcons.visit, AppIcons.bed],
        );
      });

      _widgets('a focused day draws an ink ring outside its shape ($name)', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            _strip(view: _view(events: const [])),
            theme: theme,
          ),
        );
        final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));
        Future<int> ink() async {
          final cell = tester.getRect(_day('2026-11-04')).shift(-boundary);
          final ring = await paintedPixels(
            tester,
            hostBoundaryKey,
            region: Rect.fromLTWH(
              cell.left + 12,
              cell.top - AppSizes.borderEmphasis,
              cell.width - 24,
              AppSizes.borderEmphasis,
            ),
          );
          return countPixels(ring, scheme.onSurface);
        }

        expect(await ink(), 0);
        for (var i = 0; i < 4; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        }
        await tester.pumpAndSettle();
        expect(
          await ink(),
          greaterThan(0),
          reason: 'the 2 px ink ring is above the cell',
        );
      });

      test('the texts and the ring keep their contrast ($name)', () {
        expectContrast(
          {
            'today': (scheme.onPrimary, scheme.primary),
            'weekday': (scheme.onSurfaceVariant, scheme.surfaceContainerLowest),
            'number': (scheme.onSurface, scheme.surfaceContainerLowest),
            'title': (scheme.onSurface, scheme.surfaceContainerLowest),
          },
          minimum: 4.5,
          reason: 'the calendar strip ($name)',
        );
        expectContrast(
          {'focus ring': (scheme.onSurface, scheme.surfaceContainerLowest)},
          minimum: 3,
          reason: 'the focus ring of the calendar strip ($name)',
        );
      });
    }

    _widgets('has no danger color and no motion', (tester) async {
      await tester.pumpWidget(host(_strip()));
      final scheme = CompappTheme.light.colorScheme;

      final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));
      final all = await paintedPixels(
        tester,
        hostBoundaryKey,
        region: tester.getRect(_stripFinder).shift(-boundary),
      );
      expect(countPixels(all, scheme.error), 0);
      expect(countPixels(all, scheme.errorContainer), 0);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('large text and narrow columns', () {
    setUpAll(loadBundledFonts);

    const longTitle = 'Invitada a dormir de María de los Ángeles';
    CalendarStripView longView() => CalendarStripView(
      days: _days(spanish: true, today: '2026-11-01'),
      events: [
        _event(
          'luis',
          CalendarEventKind.absence,
          '2026-11-01',
          '2026-11-06',
          title: 'Luis fuera · hasta el viernes 6 de noviembre',
        ),
        _event(
          'visit',
          CalendarEventKind.visit,
          '2026-11-04',
          '2026-11-04',
          title: 'Visita de Marta',
        ),
        _event(
          'night',
          CalendarEventKind.overnight,
          '2026-11-07',
          '2026-11-08',
          title: longTitle,
        ),
      ],
      today: '2026-11-01',
    );

    for (final width in [320.0, 360.0]) {
      for (final scale in [1.0, 1.3, 1.5, 2.0]) {
        for (final direction in TextDirection.values) {
          _widgets('width $width, ${scale}x, ${direction.name}: no overflow, '
              'nothing clipped, no word cut, every title whole', (
            tester,
          ) async {
            await tester.pumpWidget(
              host(
                _strip(view: longView()),
                width: width,
                textScale: scale,
                direction: direction,
              ),
            );

            final reason = 'at $width, ${scale}x, ${direction.name}';
            expect(tester.takeException(), isNull, reason: reason);
            final strip = tester.getRect(_stripFinder);
            expect(strip.width, width, reason: reason);
            for (final date in _dates) {
              final rect = tester.getRect(_day(date));
              expect(rect.height, greaterThan(AppSizes.minTarget - 0.01));
              expect(
                rect.width,
                greaterThan(AppSizes.minTarget - 0.01),
                reason: '$date is a full tap target, $reason',
              );
              expect(rect.top, greaterThanOrEqualTo(strip.top));
              expect(rect.bottom, lessThanOrEqualTo(strip.bottom));
              for (final text in [
                _weekdaysEs[_dates.indexOf(date)],
                '${_dates.indexOf(date) + 1}',
              ]) {
                final finder = find.descendant(
                  of: _day(date),
                  matching: find.text(text),
                );
                expectNoMidWordBreaks(tester, finder, reason: reason);
                final label = tester.getRect(finder);
                expect(
                  label.left,
                  greaterThanOrEqualTo(rect.left - 0.5),
                  reason: '$text inside its button, $reason',
                );
                expect(label.right, lessThanOrEqualTo(rect.right + 0.5));
              }
            }
            for (final id in ['luis', 'visit', 'night']) {
              final row = tester.getRect(_row(id));
              expect(row.left, greaterThanOrEqualTo(strip.left));
              expect(row.right, lessThanOrEqualTo(strip.right));
              expect(row.height, greaterThanOrEqualTo(AppSizes.row));
              final title = find.descendant(
                of: _row(id),
                matching: find.byType(Text),
              );
              expectNoMidWordBreaks(tester, title, reason: reason);
              final text = tester.widget<Text>(title);
              expect(text.overflow, isNull, reason: 'no ellipsis, $reason');
              expect(text.maxLines, isNull);
            }
          });
        }
      }
    }

    _widgets('the week is one row in a phone column, at 1.0 and 1.5', (
      tester,
    ) async {
      for (final scale in [1.0, 1.5]) {
        await tester.pumpWidget(
          host(_strip(view: longView()), textScale: scale),
        );
        expect(
          {for (final date in _dates) tester.getTopLeft(_day(date)).dy}.length,
          1,
          reason: 'at ${scale}x',
        );
      }
    });

    _widgets('the days move to two rows of four and three when a weekday '
        'does not fit its column, with their ribbons', (tester) async {
      await tester.pumpWidget(host(_strip(view: longView()), textScale: 2));

      final tops = [
        for (final date in _dates) tester.getTopLeft(_day(date)).dy,
      ];
      expect(tops.sublist(0, 4).toSet(), hasLength(1));
      expect(tops.sublist(4).toSet(), hasLength(1));
      expect(tops[4], greaterThan(tops[0]));
      // The ribbons follow their day.
      expect(
        tester.getTopLeft(_piece('luis', '2026-11-05')).dy,
        greaterThan(tester.getBottomLeft(_day('2026-11-05')).dy - 1),
      );
      expect(
        tester.getTopLeft(_piece('luis', '2026-11-01')).dy,
        lessThan(tops[4]),
      );
      expect(tester.takeException(), isNull);
    });

    _widgets('a long weekday moves the days to rows at 1.0, and a week of '
        'full names is still whole', (tester) async {
      final view = CalendarStripView(
        days: [
          for (var i = 0; i < 7; i++)
            CalendarStripDay(
              date: _dates[i],
              weekday: _longWeekdaysEs[i],
              dayNumber: '${i + 1}',
              semanticLabel: '${_longWeekdaysEs[i]} ${i + 1}',
            ),
        ],
        events: const [],
      );
      await tester.pumpWidget(host(_strip(view: view), textScale: 1.3));

      expect(tester.takeException(), isNull);
      final rows = {
        for (final date in _dates) tester.getTopLeft(_day(date)).dy,
      };
      expect(rows.length, greaterThan(1));
      for (var i = 0; i < 7; i++) {
        expectNoMidWordBreaks(
          tester,
          find.descendant(
            of: _day(_dates[i]),
            matching: find.text(_longWeekdaysEs[i]),
          ),
        );
      }
    });

    _widgets('a column is never narrower than 44 and a day button is 48, '
        'overlapping its neighbors by a few pixels at most', (tester) async {
      await tester.pumpWidget(host(_strip(view: longView())));

      final first = tester.getRect(_day(_dates[0]));
      final second = tester.getRect(_day(_dates[1]));
      expect(first.width, closeTo(AppSizes.minTarget, 0.01));
      expect(second.left - first.left, greaterThanOrEqualTo(AppSizes.minDrawn));
      expect(first.right - second.left, lessThanOrEqualTo(4));
    });

    _widgets('mirrors in right-to-left: the first day at the right, the flat '
        'edges swap sides', (tester) async {
      await tester.pumpWidget(
        host(_strip(view: longView()), direction: TextDirection.rtl),
      );

      final lefts = [
        for (final date in _dates) tester.getTopLeft(_day(date)).dx,
      ];
      expect(lefts, [...lefts]..sort((a, b) => b.compareTo(a)));
      final strip = tester.getRect(_stripFinder);
      expect(
        tester.getRect(_day(_dates[0])).center.dx,
        greaterThan(strip.center.dx),
      );
      // The first piece of the absence has its round end at the right.
      final piece = tester.getRect(_piece('luis', '2026-11-01'));
      final ribbon = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: _piece('luis', '2026-11-01'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final radius = (ribbon.decoration as BoxDecoration).borderRadius!.resolve(
        TextDirection.rtl,
      );
      expect(radius.topRight.x, greaterThan(0));
      expect(radius.topLeft.x, 0);
      expect(piece.right, lessThanOrEqualTo(strip.right));
    });

    _widgets('text is scaled, never clamped, and the strip grows', (
      tester,
    ) async {
      await tester.pumpWidget(host(_strip(view: longView())));
      final base = tester.getSize(_stripFinder).height;
      final baseTitle = tester
          .getSize(
            find.descendant(of: _row('visit'), matching: find.byType(Text)),
          )
          .height;

      await tester.pumpWidget(host(_strip(view: longView()), textScale: 2));

      expect(tester.getSize(_stripFinder).height, greaterThan(base));
      expect(
        tester
            .getSize(
              find.descendant(of: _row('visit'), matching: find.byType(Text)),
            )
            .height,
        greaterThanOrEqualTo(baseTitle * 2 - 1),
      );
    });

    _widgets('in a column too narrow for 7 times 44 the days wrap too', (
      tester,
    ) async {
      await tester.pumpWidget(host(_strip(view: longView()), width: 280));

      expect(tester.takeException(), isNull);
      expect({for (final d in _dates) tester.getTopLeft(_day(d)).dy}.length, 2);
    });

    _widgets('takes the width of its content and fits when unbounded', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CompappTheme.light,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: IntrinsicWidth(child: _strip(view: longView())),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(_stripFinder).width, greaterThan(300));
    });
  });

  group('identity and focus across updates', () {
    _widgets('the days are keyed by date: a week that rolls keeps the '
        'element and the focus of a day', (tester) async {
      await tester.pumpWidget(host(_strip(view: _view(events: const []))));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      final focused = FocusManager.instance.primaryFocus;
      final element = tester.element(_day('2026-11-03'));
      expect(focused, isNotNull);
      expect(
        find.descendant(
          of: _day('2026-11-03'),
          matching: find.byWidgetPredicate((w) => w is Focus),
        ),
        findsWidgets,
      );

      final rolled = [..._dates.sublist(1), '2026-11-08'];
      await tester.pumpWidget(
        host(
          _strip(
            view: _view(dates: rolled, events: const []),
          ),
        ),
      );

      expect(_day('2026-11-01'), findsNothing);
      expect(tester.element(_day('2026-11-03')), same(element));
      expect(FocusManager.instance.primaryFocus, same(focused));
      expect(
        tester.getTopLeft(_day('2026-11-03')).dx,
        lessThan(tester.getTopLeft(_day('2026-11-04')).dx),
      );
    });

    _widgets('an event appearing or leaving keeps the focus and the node of '
        'a day and of another event', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_strip(view: _view(events: [_visit]))));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      final focused = FocusManager.instance.primaryFocus;
      final day = tester.element(_day('2026-11-05'));
      final visit = tester.element(_row('visit'));
      final visitNode = tester.getSemantics(_row('visit')).id;

      await tester.pumpWidget(host(_strip()));

      expect(FocusManager.instance.primaryFocus, same(focused));
      expect(tester.element(_day('2026-11-05')), same(day));
      expect(tester.element(_row('visit')), same(visit));
      expect(tester.getSemantics(_row('visit')).id, visitNode);

      await tester.pumpWidget(host(_strip(view: _view(events: [_visit]))));

      expect(FocusManager.instance.primaryFocus, same(focused));
      expect(tester.element(_row('visit')), same(visit));
      handle.dispose();
    });

    _widgets('the events are keyed by id, not by position', (tester) async {
      await tester.pumpWidget(
        host(_strip(view: _view(events: [_visit, _overnight]))),
      );
      final visit = tester.element(_row('visit'));
      final night = tester.element(_row('night'));

      await tester.pumpWidget(
        host(_strip(view: _view(events: [_overnight, _visit]))),
      );

      expect(
        tester.getTopLeft(_row('night')).dy,
        lessThan(tester.getTopLeft(_row('visit')).dy),
      );
      expect(tester.element(_row('visit')), same(visit));
      expect(tester.element(_row('night')), same(night));
    });

    _widgets('a focused event row keeps focus when a day wraps to a second '
        'row', (tester) async {
      await tester.pumpWidget(host(_strip(view: _view(events: [_visit]))));
      for (var i = 0; i < 8; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      }
      final focused = FocusManager.instance.primaryFocus;
      expect(focused, isNotNull);

      await tester.pumpWidget(
        host(_strip(view: _view(events: [_visit])), textScale: 2),
      );

      expect(FocusManager.instance.primaryFocus, same(focused));
    });
  });

  group('the touch area', () {
    _widgets('is the column: a tap inside the column of a day fires that day, '
        'and the node of 48 does not take the taps of its neighbor', (
      tester,
    ) async {
      final taps = <String>[];
      await tester.pumpWidget(host(_strip(onDayTap: taps.add)));

      final strip = tester.getRect(_stripFinder);
      const inset = AppSpacing.xs + AppSizes.hairline;
      final column = (strip.width - 2 * inset) / 7;
      final edge = strip.left + inset + column;
      final y = tester.getCenter(_day('2026-11-01')).dy;
      expect(
        tester.getRect(_day('2026-11-01')).right,
        greaterThan(edge),
        reason: 'the node of day 1 spills over the column of day 2',
      );

      await tester.tapAt(Offset(edge - 1, y));
      await tester.tapAt(Offset(edge + 1, y));

      expect(taps, ['2026-11-01', '2026-11-02']);
    });
  });

  group('lanes', () {
    _widgets('two one day events on the same date get different lanes, and '
        'both are drawn', (tester) async {
      await tester.pumpWidget(
        host(
          _strip(
            view: _view(
              events: [
                _event(
                  'a',
                  CalendarEventKind.visit,
                  '2026-11-02',
                  '2026-11-02',
                ),
                _event(
                  'b',
                  CalendarEventKind.other,
                  '2026-11-02',
                  '2026-11-02',
                ),
              ],
            ),
          ),
        ),
      );

      expect(_piece('a', '2026-11-02'), findsOneWidget);
      expect(_piece('b', '2026-11-02'), findsOneWidget);
      expect(
        tester.getTopLeft(_piece('b', '2026-11-02')).dy,
        greaterThan(tester.getTopLeft(_piece('a', '2026-11-02')).dy),
      );
    });

    _widgets('events that share only their edge day get different lanes', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _strip(
            view: _view(
              events: [
                _event(
                  'a',
                  CalendarEventKind.visit,
                  '2026-11-01',
                  '2026-11-04',
                ),
                _event(
                  'b',
                  CalendarEventKind.other,
                  '2026-11-04',
                  '2026-11-06',
                ),
              ],
            ),
          ),
        ),
      );

      for (final date in _dates.sublist(0, 4)) {
        expect(_piece('a', date), findsOneWidget, reason: date);
      }
      for (final date in _dates.sublist(3, 6)) {
        expect(_piece('b', date), findsOneWidget, reason: date);
      }
      expect(
        tester.getTopLeft(_piece('b', '2026-11-04')).dy,
        greaterThan(tester.getTopLeft(_piece('a', '2026-11-04')).dy),
      );
    });

    _widgets('events that touch without sharing a day stay in one lane', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _strip(
            view: _view(
              events: [
                _event(
                  'a',
                  CalendarEventKind.visit,
                  '2026-11-01',
                  '2026-11-03',
                ),
                _event(
                  'b',
                  CalendarEventKind.other,
                  '2026-11-04',
                  '2026-11-06',
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        tester.getTopLeft(_piece('b', '2026-11-04')).dy,
        tester.getTopLeft(_piece('a', '2026-11-03')).dy,
      );
    });
  });

  group('the focus ring beside a filled day', () {
    Future<void> focusDay(WidgetTester tester, String date) async {
      for (var i = 0; i < 20; i++) {
        final context = FocusManager.instance.primaryFocus?.context;
        if (context?.findAncestorWidgetOfExactType<TextButton>()?.key ==
            Key('calendar.day.$date')) {
          await tester.pumpAndSettle();
          return;
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      fail('focus never reached $date');
    }

    for (final direction in TextDirection.values) {
      for (final focused in ['2026-11-03', '2026-11-05']) {
        _widgets('draws its ring on all four sides next to today, '
            '$focused, ${direction.name}', (tester) async {
          final ink = CompappTheme.light.colorScheme.onSurface;
          await tester.pumpWidget(
            host(
              _strip(
                view: _view(today: '2026-11-04', events: const []),
              ),
              direction: direction,
            ),
          );
          await focusDay(tester, focused);

          final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));
          final r = tester.getRect(_day(focused)).shift(-boundary);
          const w = AppSizes.borderEmphasis;
          final sides = {
            'top': Rect.fromLTWH(r.left + 12, r.top - w, r.width - 24, w),
            'bottom': Rect.fromLTWH(r.left + 12, r.bottom, r.width - 24, w),
            'left': Rect.fromLTWH(r.left - w, r.top + 12, w, r.height - 24),
            'right': Rect.fromLTWH(r.right, r.top + 12, w, r.height - 24),
          };
          for (final MapEntry(key: side, value: region) in sides.entries) {
            final pixels = await paintedPixels(
              tester,
              hostBoundaryKey,
              region: region,
            );
            expect(
              countPixels(pixels, ink),
              greaterThan(0),
              reason: 'the $side of the ring of $focused',
            );
          }
        });
      }
    }

    _widgets('only the column with focus paints last, and none does when '
        'nothing is focused', (tester) async {
      await tester.pumpWidget(host(_strip(view: _view(events: const []))));
      final columns = tester.renderObject(
        find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_EqualColumns',
        ),
      ) as RenderBox;
      List<bool> flags() {
        final result = <bool>[];
        columns.visitChildren((child) {
          result.add((child.parentData! as dynamic).paintLast as bool);
        });
        return result;
      }

      expect(flags(), List.filled(7, false));

      await focusDay(tester, '2026-11-03');
      expect(flags(), [false, false, true, false, false, false, false]);

      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pumpAndSettle();
      expect(flags(), List.filled(7, false));
    });
  });

  group('motion', () {
    _widgets('has none of its own', (tester) async {
      await tester.pumpWidget(host(_strip()));

      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
