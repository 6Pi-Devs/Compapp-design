import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// Width of the row. The golden harness sizes a scenario to its content, so a
/// row that takes the space that is left would be drawn with none.
const _rowWidth = 320.0;

/// One use case per freshness step of the Molecules board: done today,
/// yesterday, three days ago and nine days ago. The bar is the same as the
/// one of the AppFreshnessBar atom, under the texts that say the age.
WidgetbookComponent buildTaskRow() {
  return WidgetbookComponent(
    name: 'TaskRow',
    useCases: [
      _playground(),
      for (final (freshness, daysAgo) in const [
        (AppFreshness.fresh, 0),
        (AppFreshness.recent, 1),
        (AppFreshness.fading, 3),
        (AppFreshness.stale, 9),
      ])
        WidgetbookUseCase(
          name: 'row-${freshness.name}',
          builder: (context) {
            final title = context.sample(
              en: 'Clean the kitchen',
              es: 'Limpiar la cocina',
            );
            return useCaseFrame(
              child: SizedBox(
                width: _rowWidth,
                child: TaskRow(
                  task: TaskView(id: 'kitchen', title: title, ageDays: daysAgo),
                  subtitle: context.sample(
                    en: 'Carlos · ${_age(daysAgo, es: false)} · Kitchen',
                    es: 'Carlos · ${_age(daysAgo, es: true)} · Cocina',
                  ),
                  logAgainSemanticLabel: context.sample(
                    en: 'Log $title again',
                    es: 'Registrar de nuevo: $title',
                  ),
                  onLogAgain: () {},
                ),
              ),
            );
          },
        ),
    ],
  );
}

String _age(int daysAgo, {required bool es}) => switch (daysAgo) {
  0 => es ? 'hoy' : 'today',
  1 => es ? 'ayer' : 'yesterday',
  _ => es ? 'hace $daysAgo días' : '$daysAgo days ago',
};

const _maxAgeDays = 30;

/// Every prop of [TaskRow] as a knob. The age is the number of days the app
/// counted, so the freshness bar follows it; the subtitle is typed by hand
/// because the design system does not write the age text. The callback is
/// plumbing: the story owns it.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final title = context.textKnob(
        'title',
        context.sample(en: 'Clean the kitchen', es: 'Limpiar la cocina'),
      );
      final ageDays = context.knobs.int
          .slider(
            label: 'ageDays',
            description: 'Calendar days since the task was last done',
            initialValue: 3,
            max: _maxAgeDays,
            divisions: _maxAgeDays,
          )
          .clamp(0, _maxAgeDays);
      final subtitle = context.textKnob(
        'subtitle',
        context.sample(
          en: 'Carlos · 3 days ago · Kitchen',
          es: 'Carlos · hace 3 días · Cocina',
        ),
      );
      final sampleLabel = context.sample(
        en: 'Log Clean the kitchen again',
        es: 'Registrar de nuevo: Limpiar la cocina',
      );
      final typedLabel = context.textKnob(
        'logAgainSemanticLabel',
        sampleLabel,
        description: 'Must not be empty: an empty one falls back to the sample',
      );

      return useCaseFrame(
        child: SizedBox(
          width: _rowWidth,
          child: TaskRow(
            task: TaskView(id: 'playground', title: title, ageDays: ageDays),
            subtitle: subtitle,
            logAgainSemanticLabel: typedLabel.isEmpty
                ? sampleLabel
                : typedLabel,
            onLogAgain: () {},
          ),
        ),
      );
    },
  );
}
