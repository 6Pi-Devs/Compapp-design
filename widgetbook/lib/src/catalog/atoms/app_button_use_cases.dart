import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// The variants of the manifest: a button variant and its size. The Atoms
/// board draws primary, secondary and danger at 52 (lg) and ghost at 44 (md),
/// and the manifest lists both sizes, so each size is a story.
const List<(String, AppButtonVariant, AppButtonSize)> _variants = [
  ('primary-lg', AppButtonVariant.primary, AppButtonSize.lg),
  ('primary-md', AppButtonVariant.primary, AppButtonSize.md),
  ('secondary-lg', AppButtonVariant.secondary, AppButtonSize.lg),
  ('secondary-md', AppButtonVariant.secondary, AppButtonSize.md),
  ('ghost-md', AppButtonVariant.ghost, AppButtonSize.md),
  ('danger-lg', AppButtonVariant.danger, AppButtonSize.lg),
  ('danger-md', AppButtonVariant.danger, AppButtonSize.md),
];

/// One use case per variant and state. Pressed and focus hold
/// `WidgetState.pressed` or `WidgetState.focused` in a states controller (see
/// [StatesControllerHost]), so every golden scenario shows them, and loading
/// freezes the spinner (see [FrozenMotion]).
WidgetbookComponent buildAppButton() {
  return WidgetbookComponent(
    name: 'AppButton',
    useCases: [
      _playground(),
      for (final (name, variant, size) in _variants) ...[
        WidgetbookUseCase(
          name: '$name-default',
          builder: (context) => _frame(context, variant, size),
        ),
        WidgetbookUseCase(
          name: '$name-pressed',
          builder: (context) => StatesControllerHost(
            states: const {WidgetState.pressed},
            builder: (context, controller) =>
                _frame(context, variant, size, statesController: controller),
          ),
        ),
        WidgetbookUseCase(
          name: '$name-focus',
          builder: (context) => StatesControllerHost(
            states: const {WidgetState.focused},
            builder: (context, controller) =>
                _frame(context, variant, size, statesController: controller),
          ),
        ),
        WidgetbookUseCase(
          name: '$name-disabled',
          builder: (context) => _frame(context, variant, size, enabled: false),
        ),
        WidgetbookUseCase(
          name: '$name-loading',
          builder: (context) => FrozenMotion(
            child: _frame(context, variant, size, loading: true),
          ),
        ),
      ],
    ],
  );
}

Widget _frame(
  BuildContext context,
  AppButtonVariant variant,
  AppButtonSize size, {
  bool enabled = true,
  bool loading = false,
  WidgetStatesController? statesController,
}) {
  final (idle, busy) = switch (variant) {
    AppButtonVariant.primary => (
      context.sample(en: 'Send request', es: 'Enviar solicitud'),
      context.sample(en: 'Sending', es: 'Enviando'),
    ),
    AppButtonVariant.secondary => (
      context.sample(en: 'Draw again', es: 'Sortear de nuevo'),
      context.sample(en: 'Drawing', es: 'Sorteando'),
    ),
    AppButtonVariant.ghost => (
      context.sample(en: 'Mark all as read', es: 'Marcar todo como leído'),
      context.sample(en: 'Marking', es: 'Marcando'),
    ),
    AppButtonVariant.danger => (
      context.sample(en: 'Delete my account', es: 'Eliminar mi cuenta'),
      context.sample(en: 'Deleting', es: 'Eliminando'),
    ),
  };

  return useCaseFrame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          label: loading ? busy : idle,
          variant: variant,
          size: size,
          onPressed: enabled ? () {} : null,
          loading: loading,
          loadingSemanticLabel: context.sample(en: 'Loading', es: 'Cargando'),
          statesController: statesController,
        ),
      ],
    ),
  );
}

enum _ForcedState {
  none({}),
  pressed({WidgetState.pressed}),
  focused({WidgetState.focused});

  new(this.states);

  final Set<WidgetState> states;
}

/// Every prop of [AppButton] as a knob. The forced state holds a Material
/// state in a states controller, since a knob cannot press or focus a button.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final label = context.textKnob(
        'label',
        context.sample(en: 'Send request', es: 'Enviar solicitud'),
      );
      final enabled = context.knobs.boolean(
        label: 'enabled',
        description: 'A null onPressed disables the button',
        initialValue: true,
      );
      final variant = context.enumKnob('variant', AppButtonVariant.values);
      final size = context.enumKnobOrNull(
        'size',
        AppButtonSize.values,
        description: 'Null uses the default of the variant',
      );
      final icon = context.enumKnobOrNull('icon', AppIcons.values);
      final loading = context.knobs.boolean(label: 'loading');
      final semanticLabel = context.textKnobOrNull('semanticLabel', null);
      final loadingSemanticLabel = context.textKnobOrNull(
        'loadingSemanticLabel',
        context.sample(en: 'Loading', es: 'Cargando'),
      );
      final forced = context.enumKnob('forced state', _ForcedState.values);

      return useCaseFrame(
        child: StatesControllerHost(
          states: forced.states,
          builder: (context, controller) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                label: label,
                variant: variant,
                size: size,
                icon: icon,
                onPressed: enabled ? () {} : null,
                loading: loading,
                semanticLabel: semanticLabel,
                loadingSemanticLabel: loadingSemanticLabel,
                statesController: controller,
              ),
            ],
          ),
        ),
      );
    },
  );
}
