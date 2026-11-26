import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// The states of the legend: every kind, and the two kinds of a month with
/// only absences and visits.
enum _LegendState {
  allKinds('all-kinds', CalendarEventKind.values),
  twoKinds('two-kinds', [CalendarEventKind.absence, CalendarEventKind.visit]);

  new(this.id, this.kinds);

  final String id;
  final List<CalendarEventKind> kinds;
}

/// One use case per state, in the width of a phone column, so the entries
/// wrap where they would in the app. Nothing moves.
WidgetbookComponent buildCalendarLegend() {
  return WidgetbookComponent(
    name: 'CalendarLegend',
    useCases: [
      _playground(),
      for (final state in _LegendState.values)
        WidgetbookUseCase(
          name: 'legend-${state.id}',
          builder: (context) => barFrame(
            child: CalendarLegend(
              entries: [for (final kind in state.kinds) _entry(context, kind)],
            ),
          ),
        ),
    ],
  );
}

String _label(BuildContext context, CalendarEventKind kind) => switch (kind) {
  CalendarEventKind.absence => context.sample(en: 'Away', es: 'Fuera'),
  CalendarEventKind.visit => context.sample(en: 'Visit', es: 'Visita'),
  CalendarEventKind.overnight => context.sample(
    en: 'Overnight guest',
    es: 'Invitado a dormir',
  ),
  CalendarEventKind.other => context.sample(en: 'Other', es: 'Otro'),
};

CalendarLegendEntry _entry(BuildContext context, CalendarEventKind kind) =>
    CalendarLegendEntry(kind: kind, label: _label(context, kind));

/// The prop of [CalendarLegend] as knobs: how many of the kinds it lists, in
/// order, and the kind and the label of the first entry.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final count = CalendarEventKind.values.length;
      final entries = context.knobs.int
          .slider(
            label: 'entries',
            description: 'How many kinds the legend lists',
            initialValue: count,
            min: 1,
            max: count,
            divisions: count - 1,
          )
          .clamp(1, count);
      final firstKind = context.enumKnob(
        'firstKind',
        CalendarEventKind.values,
        description: 'The kind of the first entry',
      );
      final firstLabel = context.textKnob(
        'firstLabel',
        _label(context, firstKind),
        description: 'The label of the first entry, empty falls back',
      );
      final rest = [
        for (final kind in CalendarEventKind.values)
          if (kind != firstKind) kind,
      ];
      return barFrame(
        child: CalendarLegend(
          entries: [
            CalendarLegendEntry(
              kind: firstKind,
              label: firstLabel.isEmpty
                  ? _label(context, firstKind)
                  : firstLabel,
            ),
            for (final kind in rest.take(entries - 1)) _entry(context, kind),
          ],
        ),
      );
    },
  );
}
