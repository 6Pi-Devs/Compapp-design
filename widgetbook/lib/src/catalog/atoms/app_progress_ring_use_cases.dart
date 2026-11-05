import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
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
