import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// Width of the ribbon. The golden harness sizes a scenario to its content, so
/// a ribbon that takes the width it is given would be drawn with none.
const _ribbonWidth = 240.0;

/// Width of a day of a week strip, where only the compact ribbon fits.
const _dayWidth = 44.0;

/// How the ribbon sits in the days shown: all of the event, or a flat edge
/// where it goes on.
enum _Span {
  single('single', before: false, after: false),
  continuesBefore('continues-before', before: true, after: false),
  continuesAfter('continues-after', before: false, after: true),
  continuesBoth('continues-both', before: true, after: true),
  compact('compact', before: false, after: false);

  new(this.label, {required this.before, required this.after});

  final String label;
  final bool before;
  final bool after;
}

/// One use case per kind and span: the four kinds of the Molecules board, each
/// whole, with a flat start edge, a flat end edge and both, and the compact
/// glyph-only form in the width of a day.
WidgetbookComponent buildEventRibbon() {
  return WidgetbookComponent(
    name: 'EventRibbon',
    useCases: [
      _playground(),
      for (final kind in CalendarEventKind.values)
        for (final span in _Span.values)
          WidgetbookUseCase(
            name: '${kind.name}-${span.label}',
            builder: (context) => useCaseFrame(
              child: SizedBox(
                width: span == _Span.compact ? _dayWidth : _ribbonWidth,
                child: EventRibbon(
                  event: _event(context, kind),
                  semanticLabel: _spoken(context, kind, span),
                  continuesBefore: span.before,
                  continuesAfter: span.after,
                  compact: span == _Span.compact,
                ),
              ),
            ),
          ),
    ],
  );
}

CalendarEventView _event(BuildContext context, CalendarEventKind kind) {
  return CalendarEventView(
    id: kind.name,
    kind: kind,
    title: switch (kind) {
      CalendarEventKind.visit => context.sample(en: 'Visit', es: 'Visita'),
      CalendarEventKind.overnight => context.sample(
        en: 'Overnight',
        es: 'Pernocta',
      ),
      CalendarEventKind.absence => context.sample(
        en: 'Absence · Luis away',
        es: 'Ausencia · Luis fuera',
      ),
      CalendarEventKind.other => context.sample(en: 'Other', es: 'Otro'),
    },
  );
}

String _spoken(BuildContext context, CalendarEventKind kind, _Span span) {
  final base = switch (kind) {
    CalendarEventKind.visit => context.sample(
      en: 'Visit, Marta, Saturday',
      es: 'Visita, Marta, sábado',
    ),
    CalendarEventKind.overnight => context.sample(
      en: 'Overnight, Marta, Saturday',
      es: 'Pernocta, Marta, sábado',
    ),
    CalendarEventKind.absence => context.sample(
      en: 'Absence, Luis, until Fri 6 Nov',
      es: 'Ausencia, Luis, hasta el vie 6 nov',
    ),
    CalendarEventKind.other => context.sample(
      en: 'Other, cleaning day, Saturday',
      es: 'Otro, día de limpieza, sábado',
    ),
  };
  final goes = switch ((span.before, span.after)) {
    (false, false) => '',
    (true, false) => context.sample(
      en: ', started earlier',
      es: ', empezó antes',
    ),
    (false, true) => context.sample(en: ', goes on', es: ', continúa'),
    (true, true) => context.sample(
      en: ', started earlier and goes on',
      es: ', empezó antes y continúa',
    ),
  };
  return '$base$goes';
}

/// Every prop of [EventRibbon] as a knob: the event (its kind and the title to
/// show), the spoken label and the two flat edges.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final kind = context.enumKnob('kind', CalendarEventKind.values);
      final title = context.textKnob(
        'title',
        context.sample(en: 'Visit', es: 'Visita'),
      );
      final sampleLabel = context.sample(
        en: 'Visit, Marta, Saturday',
        es: 'Visita, Marta, sábado',
      );
      final typedLabel = context.textKnob(
        'semanticLabel',
        sampleLabel,
        description: 'Must not be empty: an empty one falls back to the sample',
      );
      final continuesBefore = context.knobs.boolean(
        label: 'continuesBefore',
        description: 'A flat start edge: the event started earlier',
      );
      final continuesAfter = context.knobs.boolean(
        label: 'continuesAfter',
        description: 'A flat end edge: the event goes on',
      );
      final compact = context.knobs.boolean(
        label: 'compact',
        description: 'The glyph alone, in the width of a day',
      );

      return useCaseFrame(
        child: SizedBox(
          width: compact ? _dayWidth : _ribbonWidth,
          child: EventRibbon(
            event: CalendarEventView(
              id: 'playground',
              kind: kind,
              title: title,
            ),
            semanticLabel: typedLabel.isEmpty ? sampleLabel : typedLabel,
            continuesBefore: continuesBefore,
            continuesAfter: continuesAfter,
            compact: compact,
          ),
        ),
      );
    },
  );
}
