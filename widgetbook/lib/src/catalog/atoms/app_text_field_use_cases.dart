import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// One use case per variant and state. Text is the email field of the Atoms
/// board, password hides its text and shows the reveal toggle. Default is
/// empty with its hint and helper, filled holds a value, focus holds a value
/// on a focused field, error-focus is an error on a focused field (a
/// danger-soft ring around the red border), and error and disabled are as
/// named. Focus uses a focus node that reports focus (see [FocusedNodeHost]),
/// so every golden scenario shows the focused look.
WidgetbookComponent buildAppTextField() {
  return WidgetbookComponent(
    name: 'AppTextField',
    useCases: [
      for (final password in const [false, true]) ...[
        for (final state in _State.values)
          WidgetbookUseCase(
            name: '${password ? 'password' : 'text'}-${state.slug}',
            builder: (context) => _frame(context, password, state),
          ),
      ],
    ],
  );
}

enum _State {
  empty('default'),
  filled('filled'),
  focus('focus'),
  error('error'),
  errorFocus('error-focus'),
  disabled('disabled');

  new(this.slug);

  /// The state as it is named in the use case path.
  final String slug;
}

Widget _frame(BuildContext context, bool password, _State state) {
  final value = password
      ? context.sample(en: 'hunter2-hunter2', es: 'clave-segura-12')
      : 'ana@compapp.test';
  final text = switch (state) {
    _State.empty => '',
    _State.error || _State.errorFocus => password ? 'hunter2' : 'ana@compapp',
    _ => value,
  };

  return useCaseFrame(
    child: TextControllerHost(
      text: text,
      builder: (context, controller) => _withFocus(
        state == _State.focus || state == _State.errorFocus,
        (focusNode) => AppTextField(
          label: password
              ? context.sample(en: 'Password', es: 'Contraseña')
              : context.sample(en: 'Email', es: 'Correo'),
          controller: controller,
          hint: password
              ? context.sample(
                  en: 'At least 8 characters',
                  es: 'Mínimo 8 caracteres',
                )
              : context.sample(
                  en: 'name@example.com',
                  es: 'nombre@ejemplo.com',
                ),
          helperText: state == _State.empty || state == _State.filled
              ? (password
                    ? context.sample(
                        en: 'Only you can see it',
                        es: 'Solo tú puedes verla',
                      )
                    : context.sample(
                        en: 'We never share it',
                        es: 'Nunca lo compartimos',
                      ))
              : null,
          errorText: state == _State.error || state == _State.errorFocus
              ? (password
                    ? context.sample(
                        en: 'Use at least 8 characters',
                        es: 'Usa al menos 8 caracteres',
                      )
                    : context.sample(
                        en: 'Enter a full email address',
                        es: 'Escribe un correo completo',
                      ))
              : null,
          obscure: password,
          revealSemanticLabel: context.sample(
            en: 'Show password',
            es: 'Mostrar contraseña',
          ),
          concealSemanticLabel: context.sample(
            en: 'Hide password',
            es: 'Ocultar contraseña',
          ),
          keyboardType: password ? null : TextInputType.emailAddress,
          enabled: state != _State.disabled,
          focusNode: focusNode,
        ),
      ),
    ),
  );
}

Widget _withFocus(bool focused, Widget Function(FocusNode?) builder) {
  if (!focused) return builder(null);
  return FocusedNodeHost(builder: (context, node) => builder(node));
}
