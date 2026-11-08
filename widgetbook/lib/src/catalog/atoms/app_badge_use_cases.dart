import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// One use case per form and tone: a count, a count past 99, and a label.
WidgetbookComponent buildAppBadge() {
  return WidgetbookComponent(
    name: 'AppBadge',
    useCases: [
      _playground(),
      for (final form in _Form.values)
        for (final tone in AppBadgeTone.values)
          WidgetbookUseCase(
            name: '${form.name}-${tone.name}',
            builder: (context) => useCaseFrame(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _badge(context, form, tone),
              ),
            ),
          ),
    ],
  );
}

enum _Form { count, overflow, label }

Widget _badge(BuildContext context, _Form form, AppBadgeTone tone) {
  return switch (form) {
    _Form.count => AppBadge.count(3, tone: tone),
    _Form.overflow => AppBadge.count(120, tone: tone),
    _Form.label => AppBadge.label(switch (tone) {
      AppBadgeTone.primary => context.sample(en: 'New', es: 'Nuevo'),
      AppBadgeTone.busy => context.sample(
        en: 'Not applied yet',
        es: 'Sin aplicar',
      ),
      AppBadgeTone.soft => context.sample(en: 'Yours', es: 'Tuyo'),
    }, tone: tone),
  };
}

enum _PlaygroundForm { count, label }

const _maxPlaygroundCount = 150;

/// Every prop of [AppBadge] as a knob. The form picks the count or the label
/// constructor, and only that form's knob shows an effect.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final form = context.enumKnob('form', _PlaygroundForm.values);
      final count = context.knobs.int.slider(
        label: 'count',
        description: 'Count form: 99 shows as it is, more shows 99+',
        initialValue: 3,
        max: _maxPlaygroundCount,
      );
      final label = context.textKnob(
        'label',
        context.sample(en: 'New', es: 'Nuevo'),
        description: 'Label form',
      );
      final tone = context.enumKnob('tone', AppBadgeTone.values);
      final semanticLabel = context.textKnobOrNull('semanticLabel', null);

      return useCaseFrame(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: switch (form) {
            _PlaygroundForm.count => AppBadge.count(
              count,
              tone: tone,
              semanticLabel: semanticLabel,
            ),
            _PlaygroundForm.label => AppBadge.label(
              label,
              tone: tone,
              semanticLabel: semanticLabel,
            ),
          },
        ),
      );
    },
  );
}
