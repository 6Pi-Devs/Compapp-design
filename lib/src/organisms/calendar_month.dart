import 'dart:math' as math;

import 'package:compapp_design/src/atoms/app_pebble.dart';
import 'package:compapp_design/src/foundation/calendar_lanes.dart';
import 'package:compapp_design/src/foundation/widen.dart';
import 'package:compapp_design/src/models/calendar_month_day.dart';
import 'package:compapp_design/src/models/calendar_month_view.dart';
import 'package:compapp_design/src/models/calendar_strip_event.dart';
import 'package:compapp_design/src/molecules/event_ribbon.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';

/// A month on one card: a header of weekdays, then one row per week, each day
/// with its number, who is away and the events that cover it.
///
/// It composes [AppPebble] and [EventRibbon] and takes plain data
/// ([CalendarMonthView]) and one callback, [onDayTap], with the date of the
/// tapped day. Dates are `YYYY-MM-DD` strings in the home's time zone and are
/// only compared as strings: the app owns the calendar and the clock, the grid
/// does no date maths. A null [onDayTap] disables the days.
///
/// A day shows its number (today filled with the primary color, the selected
/// day ringed in ink on a soft primary fill, both when it is both, and a day
/// outside the month muted). Under it, the first member away that day as the
/// smallest pebble, colored by their join order, and `+N` for the others.
/// Under that, every event is drawn as a compact ribbon on each day it covers
/// (the glyph and the fill tell the kind, never the color alone), the pieces
/// of one event joining across the days of a week and keeping a flat edge
/// where it goes on into the next or the previous week, or past the grid.
/// Events are placed per week in the first lane they do not overlap, in the
/// order of [CalendarMonthView.events], and a week shows at most [maxLanes]
/// lanes: a day with events in the lanes left out shows `+N` under them.
///
/// The `+N` counts are numbers, not words: like the `99+` of `AppBadge`, the
/// grid derives them from the count and draws them left to right in every
/// language. Everything else the grid shows comes from the view.
///
/// Each day is one button node named by the app's spoken label of the day,
/// which says who is away and what happens (the grid adds nothing), with a
/// selected state. Its pebble, ribbons and counts say nothing of their own,
/// and the header is excluded: a screen reader reads the days, in order. The
/// whole cell takes a tap, and the button of the number is at least
/// `AppSizes.minTarget` wide and tall: in a phone column narrower than that it
/// spills over its neighbors by a pixel or two, as in `CalendarStrip`.
///
/// It is a plain column that takes its height from its content and needs a
/// bounded width. It grows with large text instead of clipping, never clamps
/// the text scale and mirrors in right-to-left (the first weekday at the
/// right). It has no motion of its own.
class CalendarMonth extends StatelessWidget {
  const new({required this.view, required this.onDayTap, super.key});

  final CalendarMonthView view;

  /// Called with the date of the tapped day; null disables the days.
  final ValueChanged<String>? onDayTap;

  /// The most lanes of ribbons a week shows.
  static const int maxLanes = 2;

  @override
  Widget build(BuildContext context) {
    final days = view.days;
    assert(view.weekdays.length == 7, 'A week has seven weekdays');
    assert(days.isNotEmpty && days.length % 7 == 0, 'The days are whole weeks');
    assert(_datesInOrder(days), 'The dates of the days are unique, in order');
    assert(_uniqueEventIds(view), 'The ids of the events are unique');
    assert(
      view.events.every((e) => e.startDate.compareTo(e.endDate) <= 0),
      'An event does not end before it starts',
    );
    assert(
      days.every((day) => day.semanticLabel.contains(day.dayNumber)),
      'The spoken label of a day contains its number (label in name)',
    );
    final scheme = Theme.of(context).colorScheme;
    final hairline = SizedBox(
      height: AppSizes.hairline,
      child: ColoredBox(color: scheme.outlineVariant),
    );

    return Semantics(
      key: const Key('calendar.month'),
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(child: _Header(weekdays: view.weekdays)),
              for (var start = 0; start < days.length; start += 7) ...[
                if (start > 0) hairline,
                _Week(
                  key: Key('calendar.week.${days[start].date}'),
                  days: days.sublist(start, start + 7),
                  events: view.events,
                  today: view.today,
                  selected: view.selected,
                  onDayTap: onDayTap,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static bool _datesInOrder(List<CalendarMonthDay> days) {
    for (var i = 1; i < days.length; i++) {
      if (days[i - 1].date.compareTo(days[i].date) >= 0) return false;
    }
    return true;
  }

  static bool _uniqueEventIds(CalendarMonthView view) {
    final ids = [for (final e in view.events) e.event.id];
    return ids.length == ids.toSet().length;
  }
}

/// The seven weekdays over the columns, muted.
class _Header extends StatelessWidget {
  const new({required this.weekdays});

  final List<String> weekdays;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final weekday in weekdays)
            Expanded(
              child: Text(
                weekday,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One week: the day buttons, then who is away, the lanes of ribbons and the
/// counts of the events left out, each a row of seven columns.
class _Week extends StatelessWidget {
  const new({
    required this.days,
    required this.events,
    required this.today,
    required this.selected,
    required this.onDayTap,
    super.key,
  });

  final List<CalendarMonthDay> days;
  final List<CalendarStripEvent> events;
  final String? today;
  final String? selected;
  final ValueChanged<String>? onDayTap;

  @override
  Widget build(BuildContext context) {
    final dates = [for (final day in days) day.date];
    final placed = placeCalendarLanes(dates, events);
    final laneCount = placed.isEmpty
        ? 0
        : placed.map((p) => p.lane).reduce(math.max) + 1;
    final lanes = math.min(laneCount, CalendarMonth.maxLanes);
    final hidden = [
      for (var i = 0; i < days.length; i++)
        placed
            .where((p) => p.lane >= CalendarMonth.maxLanes && p.covers(i))
            .length,
    ];

    Widget row(Widget Function(int index) cell) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < days.length; i++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: _tap(days[i].date),
              child: cell(i),
            ),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final day in days)
                Expanded(
                  child: Widen(
                    minWidth: AppSizes.minTarget,
                    child: _DayButton(
                      day: day,
                      isToday: day.date == today,
                      isSelected: day.date == selected,
                      onTap: _tap(day.date),
                    ),
                  ),
                ),
            ],
          ),
          if (days.any((day) => day.away.isNotEmpty))
            row((i) => _Away(day: days[i])),
          for (var lane = 0; lane < lanes; lane++)
            SizedBox(
              height: AppSizes.ribbon,
              child: row((i) => _pieceAt(placed, lane, i, dates)),
            ),
          if (hidden.any((count) => count > 0))
            row(
              (i) => hidden[i] == 0
                  ? const SizedBox.shrink()
                  : _More(
                      key: Key('calendar.more.${dates[i]}'),
                      count: hidden[i],
                    ),
            ),
        ],
      ),
    );
  }

  VoidCallback? _tap(String date) {
    final onDayTap = this.onDayTap;
    return onDayTap == null ? null : () => onDayTap(date);
  }

  static Widget _pieceAt(
    List<CalendarLanePlacement> placed,
    int lane,
    int index,
    List<String> dates,
  ) {
    for (final p in placed) {
      if (p.lane != lane || !p.covers(index)) continue;
      return _Piece(
        key: Key('calendar.ribbon.${p.event.event.id}.${dates[index]}'),
        event: p.event,
        continuesBefore: p.continuesBefore(index, dates),
        continuesAfter: p.continuesAfter(index, dates),
      );
    }
    return const SizedBox.expand();
  }
}

/// The number of a day as a button named by the spoken label of the day.
class _DayButton extends StatelessWidget {
  const new({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final CalendarMonthDay day;
  final bool isToday;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color fill, Color ink) = switch ((isToday, isSelected)) {
      (true, _) => (scheme.primary, scheme.onPrimary),
      (false, true) => (scheme.primaryContainer, scheme.onSurface),
      (false, false) => (
        Colors.transparent,
        day.inMonth ? scheme.onSurface : scheme.onSurfaceVariant,
      ),
    };

    return TextButton(
      key: Key('calendar.day.${day.date}'),
      onPressed: onTap,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, AppSizes.minTarget)),
        // The tap target is the 48 of the button itself: the padded one would
        // make a day need 48 of width in its column.
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: AppSpacing.xs / 2,
            vertical: AppSpacing.xs,
          ),
        ),
        backgroundColor: WidgetStatePropertyAll(fill),
        foregroundColor: WidgetStatePropertyAll(ink),
        side: WidgetStatePropertyAll(
          isSelected
              ? BorderSide(
                  color: scheme.onSurface,
                  width: AppSizes.borderEmphasis,
                )
              : BorderSide.none,
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
          ),
        ),
      ),
      child: Semantics(
        label: day.semanticLabel,
        selected: isSelected,
        excludeSemantics: true,
        child: Text(
          day.dayNumber,
          textAlign: TextAlign.center,
          style: AppTypography.labelLg.copyWith(
            color: ink,
            fontWeight: day.inMonth || isToday || isSelected
                ? null
                : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// Who is away on a day: the first member as the smallest pebble and `+N` for
/// the others, wrapping onto a second line when the column is too narrow for
/// both. It says nothing: the spoken label of the day does.
class _Away extends StatelessWidget {
  const new({required this.day});

  final CalendarMonthDay day;

  @override
  Widget build(BuildContext context) {
    final away = day.away;
    if (away.isEmpty) return const SizedBox.shrink();
    final first = away.first;
    return ExcludeSemantics(
      child: Wrap(
        key: Key('calendar.away.${day.date}'),
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.xs / 2,
        runSpacing: AppSpacing.xs / 2,
        children: [
          AppPebble(
            key: Key('calendar.away.${day.date}.${first.id}'),
            initials: first.initials,
            joinOrder: first.joinOrder,
            semanticLabel: first.semanticLabel,
            size: AppPebbleSize.s28,
            isYou: first.isYou,
          ),
          if (away.length > 1) _Count(count: away.length - 1),
        ],
      ),
    );
  }
}

/// The count of the events of a day left out of its lanes.
class _More extends StatelessWidget {
  const new({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Center(heightFactor: 1, child: _Count(count: count)),
    );
  }
}

/// `+N`, muted, left to right in every language.
class _Count extends StatelessWidget {
  const new({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      '+$count',
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      style: AppTypography.caption.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// One piece of an event ribbon, on one day: the compact ribbon, inset where
/// the event starts or ends so two events side by side do not touch. It says
/// nothing to assistive technology: the day does.
class _Piece extends StatelessWidget {
  const new({
    required this.event,
    required this.continuesBefore,
    required this.continuesAfter,
    super.key,
  });

  final CalendarStripEvent event;
  final bool continuesBefore;
  final bool continuesAfter;

  @override
  Widget build(BuildContext context) {
    const inset = AppSpacing.xs / 2;
    return ExcludeSemantics(
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: continuesBefore ? 0 : inset,
          end: continuesAfter ? 0 : inset,
        ),
        child: EventRibbon(
          event: event.event,
          semanticLabel: event.semanticLabel,
          continuesBefore: continuesBefore,
          continuesAfter: continuesAfter,
          compact: true,
        ),
      ),
    );
  }
}
