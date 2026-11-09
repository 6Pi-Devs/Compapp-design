import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// Width of the card. The golden harness sizes a scenario to its content, so a
/// card that takes the space that is left would be drawn with none.
const _cardWidth = 320.0;

const _sampleCode = '4829 1736';

typedef _Texts = ({String label, String copy, String copied, String share});

_Texts _texts(BuildContext context) => (
  label: context.sample(en: 'Your personal code', es: 'Tu código personal'),
  copy: context.sample(en: 'Copy', es: 'Copiar'),
  copied: context.sample(en: 'Copied', es: 'Copiado'),
  share: context.sample(en: 'Share', es: 'Compartir'),
);

/// One use case per state of the Molecules board: the card as it opens, and
/// the same card after the code was copied.
WidgetbookComponent buildCodeCard() {
  return WidgetbookComponent(
    name: 'CodeCard',
    useCases: [
      _playground(),
      for (final copied in const [false, true])
        WidgetbookUseCase(
          name: copied ? 'card-copied' : 'card-default',
          builder: (context) {
            final texts = _texts(context);
            return useCaseFrame(
              child: SizedBox(
                width: _cardWidth,
                child: CodeCard(
                  code: _sampleCode,
                  label: texts.label,
                  copyLabel: texts.copy,
                  copiedLabel: texts.copied,
                  shareLabel: texts.share,
                  copied: copied,
                  onCopy: () {},
                  onShare: () {},
                ),
              ),
            );
          },
        ),
    ],
  );
}

/// Every prop of [CodeCard] as a knob: the code, the caption and the three
/// button labels, and the copied state. Copying stays interactive: a tap on
/// the copy button turns the state on, held by [SeededState]. Editing any knob
/// rebuilds the preview from the knob values. The callbacks are plumbing: the
/// story owns them.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final sample = _texts(context);
      final code = context.textKnob(
        'code',
        _sampleCode,
        description: 'Must not be empty: an empty one falls back to the sample',
      );
      final label = context.textKnob(
        'label',
        sample.label,
        description: 'Must not be empty: an empty one falls back to the sample',
      );
      final copyLabel = context.textKnob(
        'copyLabel',
        sample.copy,
        description: 'Must not be empty: an empty one falls back to the sample',
      );
      final copiedLabel = context.textKnob(
        'copiedLabel',
        sample.copied,
        description: 'Must not be empty: an empty one falls back to the sample',
      );
      final shareLabel = context.textKnob(
        'shareLabel',
        sample.share,
        description: 'Must not be empty: an empty one falls back to the sample',
      );
      final copied = context.knobs.boolean(
        label: 'copied',
        description: 'The app copied the code: the copy button says so',
      );

      return useCaseFrame(
        child: SizedBox(
          width: _cardWidth,
          child: SeededState<bool>(
            initial: copied,
            builder: (context, current, onChanged) => CodeCard(
              code: code.isEmpty ? _sampleCode : code,
              label: label.isEmpty ? sample.label : label,
              copyLabel: copyLabel.isEmpty ? sample.copy : copyLabel,
              copiedLabel: copiedLabel.isEmpty ? sample.copied : copiedLabel,
              shareLabel: shareLabel.isEmpty ? sample.share : shareLabel,
              copied: current,
              onCopy: () => onChanged(true),
              onShare: () {},
            ),
          ),
        ),
      );
    },
  );
}
