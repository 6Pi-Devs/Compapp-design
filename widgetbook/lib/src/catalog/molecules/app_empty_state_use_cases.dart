import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// One use case with the action and one without it.
WidgetbookComponent buildAppEmptyState() {
  return WidgetbookComponent(
    name: 'AppEmptyState',
    useCases: [
      _playground(),
      for (final (variant, withAction) in const [
        ('with-action', true),
        ('without-action', false),
      ])
        WidgetbookUseCase(
          name: '$variant-default',
          builder: (context) => barFrame(
            child: AppEmptyState(
              title: _title(context),
              body: _body(context),
              actionLabel: withAction ? _action(context) : null,
              onAction: withAction ? _noop : null,
            ),
          ),
        ),
    ],
  );
}

void _noop() {}

String _title(BuildContext context) =>
    context.sample(en: 'No shared things yet', es: 'Aún no hay cosas en común');

String _body(BuildContext context) => context.sample(
  en: 'Add the washer, the oven or anything the house takes turns with.',
  es:
      'Añade la lavadora, el horno o cualquier cosa que la casa se turne '
      'para usar.',
);

String _action(BuildContext context) =>
    context.sample(en: 'Add a thing', es: 'Añadir una cosa');

/// Every prop of [AppEmptyState] as a knob. An empty `actionLabel` leaves the
/// action out, and `actionEnabled` off passes a null `onAction`.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final title = context.textKnob('title', _title(context));
      final body = context.textKnob('body', _body(context));
      final actionLabel = context.textKnobOrNull(
        'actionLabel',
        _action(context),
        description: 'Empty leaves the action out',
      );
      final actionEnabled = context.knobs.boolean(
        label: 'actionEnabled',
        description: 'Off means a null onAction',
        initialValue: true,
      );

      return useCaseFrame(
        child: AppEmptyState(
          title: title,
          body: body,
          actionLabel: actionLabel,
          onAction: actionEnabled ? _noop : null,
        ),
      );
    },
  );
}
