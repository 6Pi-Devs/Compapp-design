import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
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
