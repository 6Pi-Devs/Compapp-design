import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// Width of the switch. The golden harness sizes a scenario to its content, so
/// a switch that takes the space that is left would be drawn with none.
const _switchWidth = 320.0;

/// One use case per side of the Molecules board: home selected and away
/// selected. The sides change fill with motion, frozen here so the golden is
/// deterministic.
WidgetbookComponent buildPresenceSwitch() {
  return WidgetbookComponent(
    name: 'PresenceSwitch',
    useCases: [
      _playground(),
      for (final side in Presence.values)
        WidgetbookUseCase(
          name: 'switch-${side.name}',
          builder: (context) => useCaseFrame(
            child: FrozenMotion(
              child: SizedBox(
                width: _switchWidth,
                child: PresenceSwitch(
                  value: side,
                  onChanged: (_) {},
                  homeLabel: context.sample(
                    en: "I'm home",
                    es: 'Estoy en casa',
                  ),
                  awayLabel: context.sample(en: "I'm out", es: 'Estoy fuera'),
                  semanticLabel: context.sample(
                    en: 'Your presence',
                    es: 'Tu presencia',
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

/// Every prop of [PresenceSwitch] as a knob: the selected side, both labels
/// and the spoken name of the group. The switch stays interactive: choosing a
/// side drives local state, held by [SeededState]. Editing any knob rebuilds
/// the preview from the knob values. The callback is plumbing: the story owns
/// it.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final value = context.enumKnob(
        'value',
        Presence.values,
        initial: Presence.home,
      );
      final sampleHome = context.sample(en: "I'm home", es: 'Estoy en casa');
      final sampleAway = context.sample(en: "I'm out", es: 'Estoy fuera');
      final sampleLabel = context.sample(
        en: 'Your presence',
        es: 'Tu presencia',
      );
      final homeLabel = context.textKnob(
        'homeLabel',
        sampleHome,
        description: 'Must not be empty: an empty one falls back to the sample',
      );
      final awayLabel = context.textKnob(
        'awayLabel',
        sampleAway,
        description: 'Must not be empty: an empty one falls back to the sample',
      );
      final typedLabel = context.textKnob(
        'semanticLabel',
        sampleLabel,
        description: 'Must not be empty: an empty one falls back to the sample',
      );

      return useCaseFrame(
        child: SizedBox(
          width: _switchWidth,
          child: SeededState<Presence>(
            initial: value,
            builder: (context, current, onChanged) => PresenceSwitch(
              value: current,
              onChanged: onChanged,
              homeLabel: homeLabel.isEmpty ? sampleHome : homeLabel,
              awayLabel: awayLabel.isEmpty ? sampleAway : awayLabel,
              semanticLabel: typedLabel.isEmpty ? sampleLabel : typedLabel,
            ),
          ),
        ),
      );
    },
  );
}
