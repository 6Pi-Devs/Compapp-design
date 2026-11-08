import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// One use case per kind (in use with no known end, or a known value) and
/// tone. The in-use arc breathes, so every use case runs under
/// [FrozenMotion]: it stands still, and goldens can settle.
WidgetbookComponent buildAppProgressRing() {
  return WidgetbookComponent(
    name: 'AppProgressRing',
    useCases: [
      _playground(),
      for (final determinate in const [false, true])
        for (final tone in AppRingTone.values)
          WidgetbookUseCase(
            name:
                '${determinate ? 'determinate' : 'indeterminate'}-${tone.name}',
            builder: (context) => FrozenMotion(
              child: useCaseFrame(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: determinate
                      ? AppProgressRing(
                          value: 0.73,
                          tone: tone,
                          label: '11',
                          semanticLabel: context.sample(
                            en: 'Chores',
                            es: 'Tareas',
                          ),
                          semanticValue: context.sample(
                            en: '11 of 15 done',
                            es: '11 de 15 hechas',
                          ),
                        )
                      : AppProgressRing(tone: tone, semanticLabel: null),
                ),
              ),
            ),
          ),
    ],
  );
}

const double _minRingSize = AppSizes.ring;
const _maxRingSize = 120.0;
const _ringValueDivisions = 20;

/// Every prop of [AppProgressRing] as a knob. "In use" drops the value, which
/// is how a ring with no known end is drawn. The ring breathes unless the
/// device asks to reduce motion.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final inUse = context.knobs.boolean(
        label: 'in use',
        description: 'No value: an arc that breathes',
      );
      final value = context.knobs.double.slider(
        label: 'value',
        initialValue: 0.73,
        max: 1,
        divisions: _ringValueDivisions,
        precision: 2,
      );
      final tone = context.enumKnob('tone', AppRingTone.values);
      final size = context.knobs.double.slider(
        label: 'size',
        description: 'The least side; the ring grows with a large label',
        initialValue: _minRingSize,
        min: _minRingSize,
        max: _maxRingSize,
      );
      final label = context.textKnobOrNull('label', '11');
      final semanticLabel = context.textKnobOrNull(
        'semanticLabel',
        context.sample(en: 'Chores', es: 'Tareas'),
      );
      final semanticValue = context.textKnob(
        'semanticValue',
        context.sample(en: '11 of 15 done', es: '11 de 15 hechas'),
        description: 'Spoken with a value; an in-use ring never exposes it',
      );

      return useCaseFrame(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppProgressRing(
            value: inUse ? null : value,
            tone: tone,
            size: size,
            label: label,
            semanticLabel: semanticLabel,
            semanticValue: inUse ? null : semanticValue,
          ),
        ),
      );
    },
  );
}
