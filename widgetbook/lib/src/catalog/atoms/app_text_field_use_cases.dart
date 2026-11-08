import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
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
      _playground(),
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

enum _Keyboard {
  text(TextInputType.text),
  email(TextInputType.emailAddress),
  number(TextInputType.number),
  phone(TextInputType.phone),
  url(TextInputType.url);

  new(this.type);

  final TextInputType type;
}

enum _Autofill {
  email(AutofillHints.email),
  username(AutofillHints.username),
  password(AutofillHints.password),
  name(AutofillHints.name);

  new(this.hint);

  final String hint;
}

/// Every prop of [AppTextField] as a knob. The text knob is the initial text:
/// typing then edits it (the controller lives in a [TextControllerHost]).
/// Widgetbook rebuilds the use case on every knob change, so a typed text is
/// lost then, and an autofocus field takes focus again: switch autofocus off
/// to edit other knobs. The controller, the callbacks and the focus node are
/// plumbing, so the focus knob only draws the focused look.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final text = context.textKnob('text', '');
      final label = context.textKnob(
        'label',
        context.sample(en: 'Email', es: 'Correo'),
      );
      final hint = context.textKnobOrNull(
        'hint',
        context.sample(en: 'name@example.com', es: 'nombre@ejemplo.com'),
      );
      final helperText = context.textKnobOrNull(
        'helperText',
        context.sample(en: 'We never share it', es: 'Nunca lo compartimos'),
      );
      final errorText = context.textKnobOrNull(
        'errorText',
        null,
        description: 'Any text puts the field in its error look',
      );
      final obscure = context.knobs.boolean(label: 'obscure');
      final revealSemanticLabel = context.textKnobOrNull(
        'revealSemanticLabel',
        context.sample(en: 'Show password', es: 'Mostrar contraseña'),
        description: 'The reveal toggle needs both semantic labels',
      );
      final concealSemanticLabel = context.textKnobOrNull(
        'concealSemanticLabel',
        context.sample(en: 'Hide password', es: 'Ocultar contraseña'),
      );
      final keyboard = context.enumKnobOrNull('keyboardType', _Keyboard.values);
      final autocorrect = context.knobs.booleanOrNull(
        label: 'autocorrect',
        description: 'Unset follows the keyboard: off for email, url, obscure',
      );
      final enableSuggestions = context.knobs.booleanOrNull(
        label: 'enableSuggestions',
        description: 'Unset is off for obscure text, on otherwise',
      );
      final action = context.enumKnobOrNull(
        'textInputAction',
        TextInputAction.values,
      );
      final autofill = context.enumKnobOrNull(
        'autofillHints',
        _Autofill.values,
      );
      final enabled = context.knobs.boolean(
        label: 'enabled',
        initialValue: true,
      );
      final readOnly = context.knobs.boolean(
        label: 'readOnly',
        description: 'Refuses edits but keeps focus and the enabled look',
      );
      final autofocus = context.knobs.boolean(
        label: 'autofocus',
        description: 'Takes focus on every rebuild: turn it off to edit knobs',
      );
      final focused = context.knobs.boolean(
        label: 'focused look',
        description: 'Draws the focused look without taking focus',
      );

      return useCaseFrame(
        child: TextControllerHost(
          text: text,
          builder: (context, controller) => _withFocus(
            focused,
            (focusNode) => AppTextField(
              label: label,
              controller: controller,
              hint: hint,
              helperText: helperText,
              errorText: errorText,
              obscure: obscure,
              revealSemanticLabel: revealSemanticLabel,
              concealSemanticLabel: concealSemanticLabel,
              keyboardType: keyboard?.type,
              autocorrect: autocorrect,
              enableSuggestions: enableSuggestions,
              textInputAction: action,
              autofillHints: autofill == null ? null : [autofill.hint],
              enabled: enabled,
              readOnly: readOnly,
              autofocus: autofocus,
              focusNode: focusNode,
            ),
          ),
        ),
      );
    },
  );
}
