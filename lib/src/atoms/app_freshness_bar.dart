import 'package:compapp_design/src/tokens/app_colors_context.dart';
import 'package:compapp_design/src/tokens/app_progress.dart';
import 'package:compapp_design/src/tokens/app_sizes.dart';
import 'package:flutter/material.dart';

/// How long ago a task was last done, in four steps. Each step fills more or
/// less of the bar, so the age never relies on color alone.
enum AppFreshness {
  /// Done today.
  fresh(AppProgress.freshnessFresh),

  /// Done one or two calendar days ago.
  recent(AppProgress.freshnessRecent),

  /// Done three to six days ago.
  fading(AppProgress.freshnessFading),

  /// Done a week or more ago.
  stale(AppProgress.freshnessStale);

  new(this.fill);

  /// The step for a task last done [ageDays] calendar days ago. Zero or less
  /// (a clock a little ahead) is fresh; any number of days past the last
  /// threshold is stale.
  factory fromAgeDays(int ageDays) {
    if (ageDays <= AppProgress.freshMaxAgeDays) return fresh;
    if (ageDays <= AppProgress.recentMaxAgeDays) return recent;
    if (ageDays <= AppProgress.fadingMaxAgeDays) return fading;
    return stale;
  }

  /// The part of the bar that is filled, from 0 to 1.
  final double fill;
}

/// A thin bar that shows how recently a task was done: full when it was done
/// today, shorter as it ages.
///
/// The bar takes the age as plain data: [ageDays] is the number of calendar
/// days since the task was last done, counted by the app in the home's time
/// zone (the design system does not know it). [AppFreshness.fromAgeDays]
/// turns it into one of four steps.
///
/// It is informational and always sits beside the text that says the age
/// ("today", "3 days ago"), in a column of fixed width, so the bars of a list
/// line up. It is never the only cue: the track is the sunken surface, so the
/// end of the bar is not visible, and the text is what says how long ago.
///
/// It is calm on purpose: the fill is primary until the task is stale, then the
/// quiet away gray. Never a danger color, never a person, and no word like
/// "overdue". The bar fills the width it is given, from the start edge in
/// either reading direction, and keeps its height at every text scale.
///
/// The text beside it names the age, so [semanticLabel] is required but may be
/// null: pass a label ("Done today") when the bar stands alone, and null when
/// the neighbouring text says it, which leaves the bar out of semantics. A
/// given label is an image with `container: true`, a node of its own under a
/// parent that does not merge; like any semantic child it merges into a parent
/// that merges its children.
class AppFreshnessBar extends StatelessWidget {
  const new({required this.ageDays, required this.semanticLabel, super.key});

  /// Calendar days since the task was last done, in the home's time zone.
  final int ageDays;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final freshness = AppFreshness.fromAgeDays(ageDays);
    final fill = freshness == AppFreshness.stale
        ? context.appColors.presenceAway
        : scheme.primary;

    final bar = SizedBox(
      height: AppSizes.freshnessBar,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.freshnessBar / 2),
        child: ColoredBox(
          color: scheme.surfaceContainerHigh,
          child: FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: freshness.fill,
            child: ColoredBox(color: fill),
          ),
        ),
      ),
    );

    final label = semanticLabel;
    if (label == null || label.isEmpty) return ExcludeSemantics(child: bar);
    return Semantics(
      container: true,
      image: true,
      label: label,
      excludeSemantics: true,
      child: bar,
    );
  }
}
