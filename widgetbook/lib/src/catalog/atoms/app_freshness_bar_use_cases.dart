import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
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
