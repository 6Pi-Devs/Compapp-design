import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// One use case per state of a six-digit code, as on the Atoms board. Empty
/// has no digits, partial has three and the next cell focused (a focus node
/// that reports focus, see [FocusedNodeHost], so every golden scenario shows
/// it), filled has all six and error has all six with an error message.
WidgetbookComponent buildAppCodeInput() {
  return WidgetbookComponent(
    name: 'AppCodeInput',
    useCases: [
      _playground(),
      WidgetbookUseCase(
        name: 'digits-empty',
        builder: (context) => _frame(context, ''),
      ),
      WidgetbookUseCase(
        name: 'digits-partial',
        builder: (context) => _frame(context, '481', focused: true),
      ),
      WidgetbookUseCase(
        name: 'digits-filled',
        builder: (context) => _frame(context, '481592'),
      ),
      WidgetbookUseCase(
        name: 'digits-error',
        builder: (context) => _frame(
          context,
          '481592',
          errorText: context.sample(
            en: 'That code is not valid',
            es: 'Ese código no es válido',
          ),
        ),
      ),
    ],
  );
}

Widget _frame(
  BuildContext context,
  String code, {
  bool focused = false,
  String? errorText,
}) {
  Widget input(TextEditingController controller, FocusNode? focusNode) {
    return AppCodeInput(
      label: context.sample(en: 'Reset code', es: 'Código de recuperación'),
      controller: controller,
      focusNode: focusNode,
      onCompleted: (_) {},
      errorText: errorText,
    );
  }

  return useCaseFrame(
    child: TextControllerHost(
      text: code,
      builder: (context, controller) => focused
          ? FocusedNodeHost(builder: (context, node) => input(controller, node))
          : input(controller, null),
    ),
  );
}

const _minCodeLength = 1;
const _maxCodeLength = 8;
const _defaultCodeLength = 6;

/// Every prop of [AppCodeInput] as a knob. The code knob is the initial code:
/// typing then edits it (the controller lives in a [TextControllerHost], which
/// starts over when the knob changes). The controller, the callbacks and the
/// focus node are plumbing, so the focus knob only draws the focused cell.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final code = context.textKnob('code', '');
      final label = context.textKnob(
        'label',
        context.sample(en: 'Reset code', es: 'Código de recuperación'),
      );
      final length = context.knobs.int.slider(
        label: 'length',
        initialValue: _defaultCodeLength,
        min: _minCodeLength,
        max: _maxCodeLength,
        divisions: _maxCodeLength - _minCodeLength,
      );
      final numeric = context.knobs.boolean(
        label: 'numeric',
        initialValue: true,
      );
      final errorText = context.textKnobOrNull(
        'errorText',
        null,
        description: 'Any text puts the input in its error look',
      );
      final autofocus = context.knobs.boolean(label: 'autofocus');
      final focused = context.knobs.boolean(
        label: 'focused look',
        description: 'Draws the focused cell without taking focus',
      );

      Widget input(TextEditingController controller, FocusNode? focusNode) {
        return AppCodeInput(
          label: label,
          controller: controller,
          focusNode: focusNode,
          length: length,
          numeric: numeric,
          errorText: errorText,
          autofocus: autofocus,
          onCompleted: (_) {},
        );
      }

      return useCaseFrame(
        child: TextControllerHost(
          key: ValueKey(code),
          text: code,
          builder: (context, controller) => focused
              ? FocusedNodeHost(
                  builder: (context, node) => input(controller, node),
                )
              : input(controller, null),
        ),
      );
    },
  );
}
