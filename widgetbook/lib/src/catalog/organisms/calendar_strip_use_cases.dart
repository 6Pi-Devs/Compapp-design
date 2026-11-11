import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// The Sunday the board's week starts on (1 November 2026).
final _boardStart = DateTime.utc(2026, 11);

/// The most days the playground moves the week from the board's.
const _maxStartOffset = 30;

/// The most events of the sample pool.
const _poolSize = 3;

/// The states of the Organisms board and its contract: a week with events and
/// a week without.
enum _StripState {
  withEvents('with-events', events: _poolSize),
  emptyWeek('empty-week', events: 0);

  new(this.id, {required this.events});

  final String id;
  final int events;
}

/// One use case per state of the board: the week with an absence, a visit and
/// an overnight stay, and the week with nothing in it. Nothing moves, so no
/// motion is frozen.
WidgetbookComponent buildCalendarStrip() {
  return WidgetbookComponent(
    name: 'CalendarStrip',
    useCases: [
      _playground(),
      for (final state in _StripState.values)
        WidgetbookUseCase(
          name: 'strip-${state.id}',
          builder: (context) => barFrame(
            child: CalendarStrip(
              view: _view(context, events: state.events),
              onDayTap: _ignore,
              onEventTap: _ignore,
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

/// The short and the full weekday, in the language of the story, for a
/// `DateTime.weekday` (Monday is 1).
(String, String) _weekday(BuildContext context, int weekday) {
  final (shortEn, longEn, shortEs, longEs) = switch (weekday) {
    DateTime.monday => ('Mon', 'Monday', 'lun', 'lunes'),
    DateTime.tuesday => ('Tue', 'Tuesday', 'mar', 'martes'),
    DateTime.wednesday => ('Wed', 'Wednesday', 'mié', 'miércoles'),
    DateTime.thursday => ('Thu', 'Thursday', 'jue', 'jueves'),
    DateTime.friday => ('Fri', 'Friday', 'vie', 'viernes'),
    DateTime.saturday => ('Sat', 'Saturday', 'sáb', 'sábado'),
    _ => ('Sun', 'Sunday', 'dom', 'domingo'),
  };
  return (
    context.sample(en: shortEn, es: shortEs),
    context.sample(en: longEn, es: longEs),
  );
}

String _month(BuildContext context, DateTime day) {
  const en = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  const es = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  return context.sample(en: en[day.month - 1], es: es[day.month - 1]);
}

String _today(BuildContext context) => context.sample(en: 'today', es: 'hoy');

/// The seven days from [start], the spoken label of each with [todayWord]
/// after the one at [todayIndex]. [longWeekdays] shows the full weekday in
/// place of the short one.
List<CalendarStripDay> _days(
  BuildContext context,
  DateTime start, {
  required int todayIndex,
  required String todayWord,
  bool longWeekdays = false,
}) {
  return [
    for (var i = 0; i < 7; i++)
      _day(
        context,
        start.add(Duration(days: i)),
        isToday: i == todayIndex,
        todayWord: todayWord,
        longWeekdays: longWeekdays,
      ),
  ];
}

CalendarStripDay _day(
  BuildContext context,
  DateTime day, {
  required bool isToday,
  required String todayWord,
  required bool longWeekdays,
}) {
  final (short, long) = _weekday(context, day.weekday);
  final number = '${day.day}';
  final spoken = context.sample(
    en: '$long $number ${_month(context, day)}',
    es: '$long $number de ${_month(context, day)}',
  );
  return CalendarStripDay(
    date: _date(day),
    weekday: longWeekdays ? long : short,
    dayNumber: number,
    semanticLabel: isToday ? '$spoken, $todayWord' : spoken,
  );
}

/// A sample event of the week, by its position in the pool: the absence of a
/// member over the first six days, a visit and an overnight stay that goes on
/// past the week.
CalendarStripEvent _event(
  BuildContext context,
  DateTime start,
  int index, {
  String? title,
  String? spoken,
}) {
  final (id, kind, first, last, sampleTitle, sampleSpoken) = switch (index) {
    0 => (
      'luis-away',
      CalendarEventKind.absence,
      0,
      5,
      context.sample(
        en: 'Luis away · until Fri',
        es: 'Luis fuera · hasta el vie',
      ),
      context.sample(
        en: 'Absence. Luis away · until Fri 6 Nov',
        es: 'Ausencia. Luis fuera · hasta el vie 6 nov',
      ),
    ),
    1 => (
      'marta-visit',
      CalendarEventKind.visit,
      3,
      3,
      context.sample(en: 'Visit', es: 'Visita'),
      context.sample(en: 'Visit, Wed 4 Nov', es: 'Visita, mié 4 nov'),
    ),
    _ => (
      'guest-night',
      CalendarEventKind.overnight,
      6,
      7,
      context.sample(en: 'Overnight guest', es: 'Invitado a dormir'),
      context.sample(
        en: 'Overnight guest, Sat 7 to Sun 8 Nov',
        es: 'Invitado a dormir, del sáb 7 al dom 8 nov',
      ),
    ),
  };
  final shownTitle = title ?? sampleTitle;
  final shownSpoken = spoken ?? sampleSpoken;
  return CalendarStripEvent(
    event: CalendarEventView(id: id, kind: kind, title: shownTitle),
    startDate: _date(start.add(Duration(days: first))),
    endDate: _date(start.add(Duration(days: last))),
    // The label must say the title in the same words.
    semanticLabel: shownSpoken.contains(shownTitle)
        ? shownSpoken
        : '$shownTitle. $shownSpoken',
  );
}

CalendarStripView _view(
  BuildContext context, {
  required int events,
  DateTime? start,
  int todayIndex = 0,
  String? todayWord,
  bool longWeekdays = false,
  String? firstTitle,
  String? firstSpoken,
}) {
  final from = start ?? _boardStart;
  final days = _days(
    context,
    from,
    todayIndex: todayIndex,
    todayWord: todayWord ?? _today(context),
    longWeekdays: longWeekdays,
  );
  return CalendarStripView(
    days: days,
    events: [
      for (var i = 0; i < events; i++)
        _event(
          context,
          from,
          i,
          title: i == 0 ? firstTitle : null,
          spoken: i == 0 ? firstSpoken : null,
        ),
    ],
    today: todayIndex < 0 || todayIndex > 6 ? null : days[todayIndex].date,
  );
}

/// Every prop of [CalendarStrip] as a knob: where the week starts, which day
/// is today (none leaves nobody highlighted), how many events of the sample
/// pool it has, full weekdays in place of short ones (to see the days move to
/// two rows), the title and the spoken label of the first event and the word
/// the spoken label of today ends with. The callbacks are plumbing: the story
/// owns them.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final offset = context.knobs.int
          .slider(
            label: 'startOffset',
            description: 'Days after 1 November 2026 the week starts on',
            max: _maxStartOffset,
            divisions: _maxStartOffset,
          )
          .clamp(0, _maxStartOffset);
      final todayIndex = context.knobs.int
          .slider(
            label: 'todayIndex',
            description: 'Which day is today, -1 for none of them',
            min: -1,
            max: 6,
            divisions: 7,
          )
          .clamp(-1, 6);
      final events = context.knobs.int
          .slider(
            label: 'events',
            description: 'How many events of the sample pool',
            initialValue: _poolSize,
            max: _poolSize,
            divisions: _poolSize,
          )
          .clamp(0, _poolSize);
      final longWeekdays = context.knobs.boolean(
        label: 'longWeekdays',
        description: 'The full weekday in place of the short one',
      );
      final todayWord = context.textKnob(
        'todayLabel',
        _today(context),
        description:
            'The word the spoken label of today ends with, empty falls '
            'back to the sample',
      );
      final from = _boardStart.add(Duration(days: offset));
      final sample = _event(context, from, 0);
      final firstTitle = context.textKnob(
        'firstEventTitle',
        sample.event.title,
        description: 'Visible title of the first event, empty falls back',
      );
      final firstSpoken = context.textKnob(
        'firstEventLabel',
        sample.semanticLabel,
        description:
            'Spoken label of the first event, it says the title in '
            'the same words',
      );
      // A playground can grow taller than the preview, and the organism is not
      // a scrollable: it scrolls as it would inside a screen.
      return SingleChildScrollView(
        child: barFrame(
          child: CalendarStrip(
            view: _view(
              context,
              events: events,
              start: from,
              todayIndex: todayIndex,
              todayWord: todayWord.isEmpty ? null : todayWord,
              longWeekdays: longWeekdays,
              firstTitle: firstTitle.isEmpty ? null : firstTitle,
              firstSpoken: firstSpoken.isEmpty ? null : firstSpoken,
            ),
            onDayTap: _ignore,
            onEventTap: _ignore,
          ),
        ),
      );
    },
  );
}
