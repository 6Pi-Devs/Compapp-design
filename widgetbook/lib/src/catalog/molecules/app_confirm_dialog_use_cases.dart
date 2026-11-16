import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// One use case per variant and text length. The dialog is drawn in place,
/// without a route, so the goldens and the catalog can show it.
WidgetbookComponent buildAppConfirmDialog() {
  return WidgetbookComponent(
    name: 'AppConfirmDialog',
    useCases: [
      _playground(),
      for (final (variant, destructive) in const [
        ('default', false),
        ('destructive', true),
      ])
        for (final (state, long) in const [
          ('default', false),
          ('long-text', true),
        ])
          WidgetbookUseCase(
            name: '$variant-$state',
            builder: (context) => barFrame(
              child: AppConfirmDialog(
                title: _title(context, destructive: destructive, long: long),
                message: _message(
                  context,
                  destructive: destructive,
                  long: long,
                ),
                confirmLabel: _confirm(context, destructive: destructive),
                cancelLabel: _cancel(context),
                onConfirm: _noop,
                onCancel: _noop,
                destructive: destructive,
              ),
            ),
          ),
    ],
  );
}

void _noop() {}

String _title(
  BuildContext context, {
  required bool destructive,
  required bool long,
}) {
  if (destructive) {
    return long
        ? context.sample(
            en: 'Reject all pending invitations to the Maple Street flat?',
            es:
                '¿Rechazar todas las invitaciones pendientes del piso de '
                'la calle Arce?',
          )
        : context.sample(
            en: 'Reject all pending invitations?',
            es: '¿Rechazar todas las invitaciones pendientes?',
          );
  }
  return long
      ? context.sample(
          en: 'Generate a new personal code for joining the Maple Street flat?',
          es:
              '¿Generar un nuevo código personal para unirse al piso de la '
              'calle Arce?',
        )
      : context.sample(
          en: 'Generate a new personal code?',
          es: '¿Generar un nuevo código personal?',
        );
}

String _message(
  BuildContext context, {
  required bool destructive,
  required bool long,
}) {
  if (destructive) {
    return long
        ? context.sample(
            en:
                'Everyone who was invited will lose their invitation and '
                'will need a new one to join. You can invite them again at '
                'any time from the members screen.',
            es:
                'Quienes fueron invitados perderán su invitación y '
                'necesitarán una nueva para unirse. Puedes invitarlos de '
                'nuevo cuando quieras desde la pantalla de miembros.',
          )
        : context.sample(
            en: 'They will need a new invitation to join.',
            es: 'Necesitarán una nueva invitación para unirse.',
          );
  }
  return long
      ? context.sample(
          en:
              'Your current code stops working as soon as the new one is '
              'ready. Share the new code with anyone who still needs to '
              'join your home.',
          es:
              'Tu código actual dejará de funcionar en cuanto el nuevo esté '
              'listo. Comparte el nuevo código con quien aún necesite unirse '
              'a tu hogar.',
        )
      : context.sample(
          en: 'Your current code stops working.',
          es: 'Tu código actual dejará de funcionar.',
        );
}

String _confirm(BuildContext context, {required bool destructive}) =>
    destructive
    ? context.sample(en: 'Reject all', es: 'Rechazar todas')
    : context.sample(en: 'Generate', es: 'Generar');

String _cancel(BuildContext context) =>
    context.sample(en: 'Cancel', es: 'Cancelar');

/// Every prop of [AppConfirmDialog] as a knob. The two callbacks are plumbing
/// the story owns.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final destructive = context.knobs.boolean(
        label: 'destructive',
        description: 'Styles the confirm button as the danger button',
      );
      final title = context.textKnob(
        'title',
        _title(context, destructive: destructive, long: false),
      );
      final message = context.textKnob(
        'message',
        _message(context, destructive: destructive, long: false),
      );
      final confirmLabel = context.textKnob(
        'confirmLabel',
        _confirm(context, destructive: destructive),
      );
      final cancelLabel = context.textKnob('cancelLabel', _cancel(context));

      return useCaseFrame(
        child: AppConfirmDialog(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          onConfirm: _noop,
          onCancel: _noop,
          destructive: destructive,
        ),
      );
    },
  );
}
