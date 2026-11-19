import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// The Monday the grid of November 2026 starts on.
final _gridStart = DateTime.utc(2026, 10, 26);

/// Six weeks: the whole of November 2026 with the days around it.
const _gridDays = 42;

/// Today in the stories, 19 November 2026, as an index of the grid.
const _todayIndex = 24;

/// The selected day of the selected story, 11 November 2026.
const _selectedIndex = 16;

/// The day the members are away together, 17 November 2026.
const _busyIndex = 22;

/// The members of the sample home, in join order.
const _members = [
  ('ana', 'Ana', 'A'),
  ('luis', 'Luis', 'L'),
  ('marta', 'Marta', 'M'),
  ('carlos', 'Carlos', 'C'),
  ('sofia', 'Sofía', 'S'),
  ('pablo', 'Pablo', 'P'),
];

/// The states of the grid.
enum _MonthState {
  defaultState('default'),
  selectedDay('selected-day'),
  manyAway('many-away'),
  denseEvents('dense-events');

  new(this.id);

  final String id;
}

/// One use case per state: the month with a few events of every kind, the
/// same with a day selected, five members away on one day, and a week with
/// more events than lanes. Nothing moves, so no motion is frozen.
WidgetbookComponent buildCalendarMonth() {
  return WidgetbookComponent(
    name: 'CalendarMonth',
    useCases: [
      _playground(),
      for (final state in _MonthState.values)
        WidgetbookUseCase(
          name: 'month-${state.id}',
          builder: (context) => barFrame(
            child: CalendarMonth(
              view: switch (state) {
                _MonthState.defaultState => _view(context),
                _MonthState.selectedDay => _view(
                  context,
                  selectedIndex: _selectedIndex,
                ),
                _MonthState.manyAway => _view(context, awayTogether: 5),
                _MonthState.denseEvents => _view(context, dense: true),
              },
              onDayTap: _ignore,
            ),
          ),
        ),
    ],
  );
}

void _ignore(String value) {}

String _date(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

DateTime _at(int index) => _gridStart.add(Duration(days: index));

List<String> _weekdays(BuildContext context) =>
    context.sample(en: 'M T W T F S S', es: 'L M X J V S D').split(' ');

String _weekdayName(BuildContext context, int weekday) {
  const en = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const es = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];
  return context.sample(en: en[weekday - 1], es: es[weekday - 1]);
}

String _monthName(BuildContext context, int month) {
  const en = ['October', 'November', 'December'];
  const es = ['octubre', 'noviembre', 'diciembre'];
  return context.sample(en: en[month - 10], es: es[month - 10]);
}

MemberView _member(BuildContext context, int index) {
  final (id, name, initials) = _members[index];
  return MemberView(
    id: id,
    name: name,
    initials: initials,
    joinOrder: index,
    semanticLabel: context.sample(en: '$name, away', es: '$name, fuera'),
    status: MemberStatus.away,
  );
}

/// An absence of the member at [member], from the day at [first] to the day
/// at [last] of the grid (either may lie outside it).
(CalendarStripEvent, int) _absence(
  BuildContext context,
  int member,
  int first,
  int last,
) {
  final name = _members[member].$2;
  final title = context.sample(en: '$name away', es: '$name fuera');
  return (
    CalendarStripEvent(
      event: CalendarEventView(
        id: 'away-${_members[member].$1}-$first',
        kind: CalendarEventKind.absence,
        title: title,
      ),
      startDate: _date(_at(first)),
      endDate: _date(_at(last)),
      semanticLabel: context.sample(
        en: 'Absence. $title',
        es: 'Ausencia. $title',
      ),
    ),
    member,
  );
}

CalendarStripEvent _event(
  BuildContext context,
  String id,
  CalendarEventKind kind,
  int first,
  int last, {
  required String en,
  required String es,
}) {
  final title = context.sample(en: en, es: es);
  return CalendarStripEvent(
    event: CalendarEventView(id: id, kind: kind, title: title),
    startDate: _date(_at(first)),
    endDate: _date(_at(last)),
    semanticLabel: title,
  );
}

/// The sample events: an absence that starts before the grid, one over a
/// week, one across two weeks, and a visit, an overnight stay and a cleaning
/// day, of which [events] keeps the first ones. [awayTogether] members are
/// away on the busy day, and [dense] adds a week with more events than lanes.
List<(CalendarStripEvent, int?)> _events(
  BuildContext context, {
  int awayTogether = 0,
  bool dense = false,
  int? events,
}) {
  final base = <(CalendarStripEvent, int?)>[
    _absence(context, 2, -3, 1),
    _absence(context, 1, 7, 11),
    _absence(context, 0, 31, 37),
    (
      _event(
        context,
        'visit',
        CalendarEventKind.visit,
        16,
        16,
        en: 'Visit, Marta’s parents',
        es: 'Visita, padres de Marta',
      ),
      null,
    ),
    (
      _event(
        context,
        'guest',
        CalendarEventKind.overnight,
        18,
        19,
        en: 'Overnight guest',
        es: 'Invitado a dormir',
      ),
      null,
    ),
    (
      _event(
        context,
        'cleaning',
        CalendarEventKind.other,
        26,
        26,
        en: 'Cleaning day',
        es: 'Día de limpieza',
      ),
      null,
    ),
  ];
  return [
    ...base.take(events ?? base.length),
    for (var i = 0; i < awayTogether; i++)
      _absence(context, (i + 1) % _members.length, _busyIndex - 1, _busyIndex),
    if (dense) ...[
      (
        _event(
          context,
          'party',
          CalendarEventKind.other,
          29,
          29,
          en: 'Birthday',
          es: 'Cumpleaños',
        ),
        null,
      ),
      (
        _event(
          context,
          'cousin',
          CalendarEventKind.visit,
          28,
          30,
          en: 'Visit, Luis’s cousin',
          es: 'Visita, prima de Luis',
        ),
        null,
      ),
      _absence(context, 3, 29, 30),
      (
        _event(
          context,
          'friend',
          CalendarEventKind.overnight,
          29,
          29,
          en: 'Overnight guest',
          es: 'Invitado a dormir',
        ),
        null,
      ),
    ],
  ];
}

/// The six weeks of November 2026 with [events]: each day says who is away and
/// what happens in its spoken label, as the app builds it.
CalendarMonthView _view(
  BuildContext context, {
  int? todayIndex = _todayIndex,
  int? selectedIndex,
  int awayTogether = 0,
  bool dense = false,
  int? events,
  String? firstWeekday,
}) {
  final placed = _events(
    context,
    awayTogether: awayTogether,
    dense: dense,
    events: events,
  );
  final todayWord = context.sample(en: 'today', es: 'hoy');
  final awayWord = context.sample(en: 'Away', es: 'Fuera');
  final days = <CalendarMonthDay>[];
  for (var i = 0; i < _gridDays; i++) {
    final day = _at(i);
    final date = _date(day);
    final covering = [
      for (final (event, member) in placed)
        if (date.compareTo(event.startDate) >= 0 &&
            date.compareTo(event.endDate) <= 0)
          (event, member),
    ];
    final away = [
      for (final (_, member) in covering)
        if (member != null) _member(context, member),
    ];
    final number = '${day.day}';
    final name = context.sample(
      en:
          '${_weekdayName(context, day.weekday)} $number '
          '${_monthName(context, day.month)}',
      es:
          '${_weekdayName(context, day.weekday)} $number de '
          '${_monthName(context, day.month)}',
    );
    days.add(
      CalendarMonthDay(
        date: date,
        dayNumber: number,
        inMonth: day.month == 11,
        away: away,
        semanticLabel: [
          if (i == todayIndex) '$name, $todayWord' else name,
          if (away.isNotEmpty)
            '$awayWord: ${away.map((m) => m.name).join(', ')}',
          for (final (event, member) in covering)
            if (member == null) event.semanticLabel,
        ].join('. '),
      ),
    );
  }
  final weekdays = _weekdays(context);
  return CalendarMonthView(
    weekdays: [firstWeekday ?? weekdays.first, ...weekdays.skip(1)],
    days: days,
    events: [for (final (event, _) in placed) event],
    today: todayIndex == null ? null : days[todayIndex].date,
    selected: selectedIndex == null ? null : days[selectedIndex].date,
  );
}

/// Every prop of [CalendarMonth] as a knob: which day is today and which is
/// selected (-1 for none), how many members are away together on the 17th,
/// how many events of the sample pool it shows, a dense week with more events
/// than lanes, the first weekday of the header and whether the days take taps.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      const last = _gridDays - 1;
      final todayIndex = context.knobs.int
          .slider(
            label: 'todayIndex',
            description: 'Which day of the grid is today, -1 for none',
            initialValue: _todayIndex,
            min: -1,
            max: last,
            divisions: _gridDays,
          )
          .clamp(-1, last);
      final selectedIndex = context.knobs.int
          .slider(
            label: 'selectedIndex',
            description: 'Which day of the grid is selected, -1 for none',
            initialValue: -1,
            min: -1,
            max: last,
            divisions: _gridDays,
          )
          .clamp(-1, last);
      final awayTogether = context.knobs.int
          .slider(
            label: 'awayTogether',
            description: 'How many members are away together on the 17th',
            max: _members.length,
            divisions: _members.length,
          )
          .clamp(0, _members.length);
      final pool = _events(context).length;
      final events = context.knobs.int
          .slider(
            label: 'events',
            description: 'How many events of the sample pool it shows',
            initialValue: pool,
            max: pool,
            divisions: pool,
          )
          .clamp(0, pool);
      final dense = context.knobs.boolean(
        label: 'denseWeek',
        description: 'A week with more events than lanes',
      );
      final sampleWeekday = _weekdays(context).first;
      final firstWeekday = context.textKnob(
        'firstWeekday',
        sampleWeekday,
        description: 'The first label of the header, empty falls back',
      );
      final enabled = context.knobs.boolean(
        label: 'enabled',
        description: 'Whether the days take taps (onDayTap is not null)',
        initialValue: true,
      );
      // A playground can grow taller than the preview, and the organism is not
      // a scrollable: it scrolls as it would inside a screen.
      return SingleChildScrollView(
        child: barFrame(
          child: CalendarMonth(
            view: _view(
              context,
              todayIndex: todayIndex < 0 ? null : todayIndex,
              selectedIndex: selectedIndex < 0 ? null : selectedIndex,
              awayTogether: awayTogether,
              dense: dense,
              events: events,
              firstWeekday: firstWeekday.isEmpty ? null : firstWeekday,
            ),
            onDayTap: enabled ? _ignore : null,
          ),
        ),
      );
    },
  );
}
