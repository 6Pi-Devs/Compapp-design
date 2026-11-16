import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

const _ringDivisions = 20;

/// The ring and the texts of the board's wait: 11 of 15 minutes left.
const _boardRemaining = 0.73;

KnockCooldown _boardCooldown(BuildContext context) => KnockCooldown(
  remaining: _boardRemaining,
  label: context.sample(en: 'Asked', es: 'Preguntado'),
  remainingLabel: context.sample(en: '11 min', es: '11 min'),
  semanticLabel: context.sample(
    en: "Asked who's home. You can ask again in 11 minutes",
    es:
        'Preguntaste quién está en casa. '
        'Puedes volver a preguntar en 11 minutos',
  ),
);

/// One use case per state of the Molecules board: ready, and waiting with 11
/// minutes left. The ring does not move, so no motion is frozen.
WidgetbookComponent buildKnockButton() {
  return WidgetbookComponent(
    name: 'KnockButton',
    useCases: [
      _playground(),
      WidgetbookUseCase(
        name: 'button-ready',
        builder: (context) => useCaseFrame(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: KnockButton(
              label: context.sample(en: "Who's home?", es: '¿Quién está?'),
              onKnock: () {},
            ),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'button-cooldown',
        builder: (context) => useCaseFrame(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: KnockButton(
              label: context.sample(en: "Who's home?", es: '¿Quién está?'),
              onKnock: () {},
              cooldown: _boardCooldown(context),
            ),
          ),
        ),
      ),
    ],
  );
}

/// Every prop of [KnockButton] as a knob: the label and the wait, which is
/// off while the home can be asked. The wait takes the share left, its label,
/// the time left and the spoken sentence. The callback is plumbing: the story
/// owns it.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final sampleLabel = context.sample(en: "Who's home?", es: '¿Quién está?');
      final label = context.textKnob(
        'label',
        sampleLabel,
        description: 'Must not be empty: an empty one falls back to the sample',
      );
      final waiting = context.knobs.boolean(
        label: 'cooldown',
        description: 'The home was asked a short time ago: wait',
      );
      final rawRemaining = context.knobs.double.slider(
        label: 'remaining',
        description: 'The share of the wait that is left',
        initialValue: _boardRemaining,
        max: 1,
        divisions: _ringDivisions,
        precision: 2,
      );
      final board = _boardCooldown(context);
      final cooldownLabel = context.textKnob(
        'cooldownLabel',
        board.label,
        description: 'Must not be empty: an empty one falls back to the sample',
      );
      final remainingLabel = context.textKnob(
        'remainingLabel',
        board.remainingLabel,
        description: 'Must not be empty: an empty one falls back to the sample',
      );
      final semanticLabel = context.textKnob(
        'cooldownSemanticLabel',
        board.semanticLabel,
        description: 'Must not be empty: an empty one falls back to the sample',
      );

      return useCaseFrame(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: KnockButton(
            label: label.isEmpty ? sampleLabel : label,
            onKnock: () {},
            cooldown: waiting
                ? KnockCooldown(
                    remaining: rawRemaining.isNaN ? 0 : rawRemaining,
                    label: cooldownLabel.isEmpty ? board.label : cooldownLabel,
                    remainingLabel: remainingLabel.isEmpty
                        ? board.remainingLabel
                        : remainingLabel,
                    semanticLabel: semanticLabel.isEmpty
                        ? board.semanticLabel
                        : semanticLabel,
                  )
                : null,
          ),
        ),
      );
    },
  );
}
