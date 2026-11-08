import 'package:compapp_design/src/atoms/app_freshness_bar.dart';
import 'package:compapp_design/src/atoms/app_icon.dart';
import 'package:compapp_design/src/models/app_icons.dart';
import 'package:compapp_design/src/models/task_view.dart';
import 'package:compapp_design/src/tokens/app_radius.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:compapp_design/src/tokens/app_spacing.dart';
import 'package:compapp_design/src/tokens/app_typography.dart';
import 'package:flutter/material.dart';

/// A recurring task on one line: its title, a [subtitle] (who did it last,
/// when, where), a freshness bar under them and a button to log it again.
///
/// The bar is the `AppFreshnessBar` of `task.ageDays`, which the app counts in
/// the home's time zone. It sits under the texts that say the age and is never
/// the only cue, so it is left out of semantics. It is calm on purpose: the
/// bar never turns red and the row never says who is behind. The subtitle may
/// say who did the task last, never who has not.
///
/// The title and the subtitle are one node ("Clean the kitchen, Carlos, 3 days
/// ago, Kitchen"). The log button is its own button named by
/// [logAgainSemanticLabel] ("Log Clean the kitchen again"), on top of the
/// themed `OutlinedButton`: a square 44 drawn with a 48 hit area, with
/// keyboard focus. The row itself is not tappable.
///
/// The row is at least `AppSizes.rowTall` tall and grows with large text: the
/// title and the subtitle wrap and the button keeps its size. It needs a
/// bounded width and mirrors in right-to-left, with the button at the start.
class TaskRow extends StatelessWidget {
  const new({
    required this.task,
    required this.subtitle,
    required this.logAgainSemanticLabel,
    required this.onLogAgain,
    super.key,
  }) : assert(
         logAgainSemanticLabel != '',
         'The log button needs a spoken label',
       );

  final TaskView task;
  final String subtitle;
  final String logAgainSemanticLabel;
  final VoidCallback onLogAgain;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      key: Key('task.${task.id}'),
      constraints: const BoxConstraints(minHeight: AppSizes.rowTall),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  MergeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          task.title,
                          style: AppTypography.labelLg.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: AppTypography.caption.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppFreshnessBar(ageDays: task.ageDays, semanticLabel: null),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            OutlinedButton(
              key: Key('task.${task.id}.logAgain'),
              onPressed: onLogAgain,
              style: const ButtonStyle(
                minimumSize: WidgetStatePropertyAll(
                  Size.square(AppSizes.minDrawn),
                ),
                padding: WidgetStatePropertyAll(EdgeInsets.zero),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppRadius.sm),
                    ),
                  ),
                ),
              ),
              child: Semantics(
                label: logAgainSemanticLabel,
                excludeSemantics: true,
                child: const AppIcon(AppIcons.add, size: AppSizes.glyphLg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
