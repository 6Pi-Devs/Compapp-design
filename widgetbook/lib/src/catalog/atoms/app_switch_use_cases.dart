import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// One use case per value and state.
WidgetbookComponent buildAppSwitch() {
  return WidgetbookComponent(
    name: 'AppSwitch',
    useCases: [
      _playground(),
      for (final (name, value) in const [('on', true), ('off', false)]) ...[
        WidgetbookUseCase(
          name: '$name-default',
          builder: (context) => _frame(context, value: value),
        ),
        WidgetbookUseCase(
          name: '$name-disabled',
          builder: (context) => _frame(context, value: value, enabled: false),
        ),
      ],
    ],
  );
}

Widget _frame(
  BuildContext context, {
  required bool value,
  bool enabled = true,
}) {
  return useCaseFrame(
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: AppSwitch(
        value: value,
        label: context.sample(en: 'All day', es: 'Todo el día'),
        onChanged: enabled ? (_) {} : null,
      ),
    ),
  );
}

/// Every prop of [AppSwitch] as a knob. The value knob is the initial value:
/// toggling the switch then drives it (see [SeededState]).
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final label = context.textKnob(
        'label',
        context.sample(en: 'All day', es: 'Todo el día'),
      );
      final value = context.knobs.boolean(label: 'value');
      final enabled = context.knobs.boolean(
        label: 'enabled',
        description: 'A null onChanged disables the switch',
        initialValue: true,
      );

      return useCaseFrame(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: SeededState<bool>(
            initial: value,
            builder: (context, current, onChanged) => AppSwitch(
              value: current,
              label: label,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
      );
    },
  );
}
