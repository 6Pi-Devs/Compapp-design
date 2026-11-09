import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// One use case per tone, plain and with an action. Motion is frozen, so the
/// bar is fully shown in every golden.
WidgetbookComponent buildAppSnackbar() {
  return WidgetbookComponent(
    name: 'AppSnackbar',
    useCases: [
      _playground(),
      for (final tone in SnackTone.values)
        for (final (state, withAction) in const [
          ('default', false),
          ('with-action', true),
        ])
          WidgetbookUseCase(
            name: '${tone.name}-$state',
            builder: (context) => barFrame(
              child: FrozenMotion(
                child: AppSnackbar(
                  message: _message(context, tone),
                  tone: tone,
                  actionLabel: withAction ? _action(context, tone) : null,
                  onAction: withAction ? _noop : null,
                ),
              ),
            ),
          ),
    ],
  );
}

void _noop() {}

String _message(BuildContext context, SnackTone tone) => switch (tone) {
  SnackTone.info => context.sample(
    en: 'Request sent to Carlos',
    es: 'Solicitud enviada a Carlos',
  ),
  SnackTone.error => context.sample(
    en: "Can't reach the server",
    es: 'No se puede conectar con el servidor',
  ),
};

String _action(BuildContext context, SnackTone tone) => switch (tone) {
  SnackTone.info => context.sample(en: 'Undo', es: 'Deshacer'),
  SnackTone.error => context.sample(en: 'Retry', es: 'Reintentar'),
};

/// The snackbar asserts a message, so a hand-edited empty one falls back.
String _nonEmpty(String value, String fallback) =>
    value.isEmpty ? fallback : value;

/// Every prop of [AppSnackbar] as a knob. An empty `actionLabel` leaves the
/// action out and `actionEnabled` off passes a null `onAction`. Motion is live
/// here, so `visible` shows the enter and the exit: turn on the system's
/// reduce motion setting to see it skip.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final tone = context.enumKnob('tone', SnackTone.values);
      final message = _nonEmpty(
        context.textKnob(
          'message',
          _message(context, tone),
          description: 'An empty text falls back to the sample',
        ),
        _message(context, tone),
      );
      final actionLabel = context.textKnobOrNull(
        'actionLabel',
        _action(context, tone),
        description: 'Empty leaves the action out',
      );
      final actionEnabled = context.knobs.boolean(
        label: 'actionEnabled',
        description: 'Off means a null onAction',
        initialValue: true,
      );
      final visible = context.knobs.boolean(
        label: 'visible',
        description: 'Off hides the bar after the exit',
        initialValue: true,
      );

      return useCaseFrame(
        child: AppSnackbar(
          message: message,
          tone: tone,
          actionLabel: actionLabel,
          onAction: actionEnabled ? _noop : null,
          visible: visible,
        ),
      );
    },
  );
}
