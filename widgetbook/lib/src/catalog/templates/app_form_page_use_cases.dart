import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// The height of the page in a use case: a page fills the height it is given,
/// so a use case gives it a short phone screen, and the form scrolls.
const _pageHeight = 560.0;

/// The most extra fields the playground offers after the two of the sample.
const _maxFields = 8;

/// One use case per state of the form that renames the home: filled in, with
/// the name missing (the button waits until it is given) and while it is
/// being saved. The page holds two real atoms as fields, and shows the
/// business rules of the home: the admin renames it, and the time zone cannot
/// be changed yet.
WidgetbookComponent buildAppFormPage() {
  return WidgetbookComponent(
    name: 'AppFormPage',
    useCases: [
      _playground(),
      WidgetbookUseCase(
        name: 'form-filled',
        builder: (context) => _pageFrame(
          context,
          _sample(
            context,
            name: 'Calle Luna 12',
            onSubmit: _noop,
            submitting: false,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'form-error',
        builder: (context) => _pageFrame(
          context,
          _sample(
            context,
            name: '',
            error: context.sample(
              en: 'Give the home a name',
              es: 'Ponle un nombre a la casa',
            ),
            onSubmit: null,
            submitting: false,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'form-submitting',
        builder: (context) => FrozenMotion(
          child: _pageFrame(
            context,
            _sample(
              context,
              name: 'Calle Luna 12',
              onSubmit: _noop,
              submitting: true,
            ),
          ),
        ),
      ),
    ],
  );
}

void _noop() {}

/// The page on a short phone screen, with a hairline so a golden shows where
/// the page ends.
Widget _pageFrame(BuildContext context, Widget page) {
  return useCaseFrame(
    child: SizedBox(
      width: barStoryWidth,
      height: _pageHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: page,
      ),
    ),
  );
}

String _title(BuildContext context) =>
    context.sample(en: 'Home settings', es: 'Ajustes de la casa');

String _backLabel(BuildContext context) =>
    context.sample(en: 'Back', es: 'Atrás');

String _submitLabel(BuildContext context) =>
    context.sample(en: 'Save changes', es: 'Guardar cambios');

String _savingLabel(BuildContext context) =>
    context.sample(en: 'Saving', es: 'Guardando');

Widget _nameField(
  BuildContext context,
  TextEditingController controller, {
  String? error,
}) => AppTextField(
  key: const Key('sample.name'),
  label: context.sample(en: 'Home name', es: 'Nombre de la casa'),
  controller: controller,
  helperText: context.sample(
    en: 'It titles every notification of the home.',
    es: 'Titula cada notificación de la casa.',
  ),
  errorText: error,
  textInputAction: TextInputAction.done,
);

Widget _zoneField(BuildContext context, TextEditingController controller) =>
    AppTextField(
      key: const Key('sample.zone'),
      label: context.sample(en: 'Time zone', es: 'Zona horaria'),
      controller: controller,
      helperText: context.sample(
        en: 'It cannot be changed yet.',
        es: 'Todavía no se puede cambiar.',
      ),
      readOnly: true,
    );

Widget _sample(
  BuildContext context, {
  required String name,
  required VoidCallback? onSubmit,
  required bool submitting,
  String? error,
}) {
  return TextControllerHost(
    text: name,
    builder: (context, nameController) => TextControllerHost(
      text: 'Europe/Madrid',
      builder: (context, zoneController) => AppFormPage(
        title: _title(context),
        backLabel: _backLabel(context),
        onBack: _noop,
        fields: [
          _nameField(context, nameController, error: error),
          _zoneField(context, zoneController),
        ],
        submitLabel: _submitLabel(context),
        onSubmit: onSubmit,
        submitting: submitting,
        submittingLabel: _savingLabel(context),
      ),
    ),
  );
}

/// Every prop of [AppFormPage] as a knob: the title and the back label, how
/// many fields fill the slot (the name and the time zone of the sample, then
/// up to eight more), the error under the name (empty draws none), the submit
/// label, whether the button is enabled (null `onSubmit` otherwise), whether
/// the form is submitting and what is spoken then. The callbacks are plumbing:
/// the story owns them. A title or a label must not be empty, so an empty one
/// falls back to the sample.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      String text(String label, String initial) {
        final typed = context.textKnob(
          label,
          initial,
          description:
              'Must not be empty: an empty one falls back to the sample',
        );
        return typed.isEmpty ? initial : typed;
      }

      final title = text('title', _title(context));
      final backLabel = text('backLabel', _backLabel(context));
      final fieldCount = context.knobs.int
          .slider(
            label: 'fields',
            description:
                'How many fields fill the slot: the name, the time zone, then '
                'extra ones. Enough make the form scroll',
            initialValue: 2,
            min: 1,
            max: _maxFields + 2,
            divisions: _maxFields + 1,
          )
          .clamp(1, _maxFields + 2);
      final nameError = context.textKnobOrNull(
        'nameError',
        null,
        description: 'The error under the name field. Empty or null draws none',
      );
      final submitLabel = text('submitLabel', _submitLabel(context));
      final enabled = context.knobs.boolean(
        label: 'submitEnabled',
        description: 'Off means a null onSubmit',
        initialValue: true,
      );
      final submitting = context.knobs.boolean(
        label: 'submitting',
        description: 'The button shows its spinner and ignores taps',
      );
      final submittingLabel = text('submittingLabel', _savingLabel(context));

      return FrozenMotion(
        child: _pageFrame(
          context,
          TextControllerHost(
            text: 'Calle Luna 12',
            builder: (context, nameController) => TextControllerHost(
              text: 'Europe/Madrid',
              builder: (context, zoneController) => AppFormPage(
                title: title,
                backLabel: backLabel,
                onBack: _noop,
                fields: [
                  for (var i = 0; i < fieldCount; i++)
                    switch (i) {
                      0 => _nameField(
                        context,
                        nameController,
                        error: nameError == null || nameError.isEmpty
                            ? null
                            : nameError,
                      ),
                      1 => _zoneField(context, zoneController),
                      _ => TextControllerHost(
                        key: Key('sample.extra.$i'),
                        text: '',
                        builder: (context, controller) => AppTextField(
                          label: context.sample(
                            en: 'Extra field ${i - 1}',
                            es: 'Campo extra ${i - 1}',
                          ),
                          controller: controller,
                        ),
                      ),
                    },
                ],
                submitLabel: submitLabel,
                onSubmit: enabled ? _noop : null,
                submitting: submitting,
                submittingLabel: submittingLabel,
              ),
            ),
          ),
        ),
      );
    },
  );
}
