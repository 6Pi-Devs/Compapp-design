import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// One use case per value and state.
WidgetbookComponent buildAppSwitch() {
  return WidgetbookComponent(
    name: 'AppSwitch',
    useCases: [
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
