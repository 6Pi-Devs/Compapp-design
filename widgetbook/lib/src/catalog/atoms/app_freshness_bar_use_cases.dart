import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// Least width of the column that holds the age text, as on the Atoms board.
/// The column grows with the text scale instead of breaking a word.
const _ageColumnMinWidth = 96.0;

/// Width of the bar. The golden harness sizes a scenario to its content, so a
/// bar that takes the space that is left would be drawn with none.
const _barWidth = 160.0;

/// One use case per step. The bar sits beside the text that names the age, in
/// a column of fixed width, as on the Atoms board: today, yesterday, three
/// days ago and nine days ago.
WidgetbookComponent buildAppFreshnessBar() {
  return WidgetbookComponent(
    name: 'AppFreshnessBar',
    useCases: [
      _playground(),
      for (final (freshness, daysAgo) in const [
        (AppFreshness.fresh, 0),
        (AppFreshness.recent, 1),
        (AppFreshness.fading, 3),
        (AppFreshness.stale, 9),
      ])
        WidgetbookUseCase(
          name: 'bar-${freshness.name}',
          builder: (context) => useCaseFrame(
            child: Row(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: _ageColumnMinWidth,
                  ),
                  child: Text(
                    _age(context, daysAgo),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                SizedBox(
                  width: _barWidth,
                  child: AppFreshnessBar(ageDays: daysAgo, semanticLabel: null),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

String _age(BuildContext context, int daysAgo) => switch (daysAgo) {
  0 => context.sample(en: 'today', es: 'hoy'),
  1 => context.sample(en: 'yesterday', es: 'ayer'),
  _ => context.sample(en: '$daysAgo days ago', es: 'hace $daysAgo días'),
};

const _maxPlaygroundAgeDays = 30;

/// Every prop of [AppFreshnessBar] as a knob, beside the text that names the
/// age, as on the Atoms board.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final ageDays = context.knobs.int
          .slider(
            label: 'ageDays',
            description: 'Calendar days since the task was last done',
            max: _maxPlaygroundAgeDays,
            divisions: _maxPlaygroundAgeDays,
          )
          .clamp(0, _maxPlaygroundAgeDays);
      final semanticLabel = context.textKnobOrNull(
        'semanticLabel',
        context.sample(en: 'Done today', es: 'Hecho hoy'),
      );

      return useCaseFrame(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: _barWidth,
              child: AppFreshnessBar(
                ageDays: ageDays,
                semanticLabel: semanticLabel,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(_ageText(context, ageDays)),
          ],
        ),
      );
    },
  );
}

String _ageText(BuildContext context, int days) => switch (days) {
  0 => context.sample(en: 'Today', es: 'Hoy'),
  1 => context.sample(en: '1 day ago', es: 'Hace 1 día'),
  _ => context.sample(en: '$days days ago', es: 'Hace $days días'),
};
