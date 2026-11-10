import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// One use case per title: a short one and a long one that has to wrap. The
/// header sits in a stand-in for the sheet that owns the surface.
WidgetbookComponent buildSheetHeader() {
  return WidgetbookComponent(
    name: 'SheetHeader',
    useCases: [
      _playground(),
      for (final (state, long) in const [
        ('default', false),
        ('long-title', true),
      ])
        WidgetbookUseCase(
          name: 'default-$state',
          builder: (context) => barFrame(
            child: _sheet(
              SheetHeader(
                title: long
                    ? context.sample(
                        en:
                            'Ask Carlos to free the washing machine before '
                            'the evening?',
                        es:
                            '¿Pedirle a Carlos que libere la lavadora antes '
                            'de la noche?',
                      )
                    : context.sample(
                        en: 'Ask Carlos to free the washer?',
                        es: '¿Pedirle a Carlos que libere la lavadora?',
                      ),
                onClose: _noop,
                closeLabel: context.sample(en: 'Close', es: 'Cerrar'),
              ),
            ),
          ),
        ),
    ],
  );
}

void _noop() {}

/// The sheet surface around the header: the sheet fill, top corners and shadow
/// the real sheet draws.
Widget _sheet(Widget child) {
  return Builder(
    builder: (context) => DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        boxShadow: AppShadows.sheet,
      ),
      child: child,
    ),
  );
}

/// The close button asserts a spoken label, so a hand-edited empty one falls
/// back.
String _nonEmpty(String value, String fallback) =>
    value.isEmpty ? fallback : value;

/// Every prop of [SheetHeader] as a knob. `onClose` is plumbing the story
/// owns.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final title = context.textKnob(
        'title',
        context.sample(
          en: 'Ask Carlos to free the washer?',
          es: '¿Pedirle a Carlos que libere la lavadora?',
        ),
      );
      final closeSample = context.sample(en: 'Close', es: 'Cerrar');
      final closeLabel = _nonEmpty(
        context.textKnob(
          'closeLabel',
          closeSample,
          description:
              'Spoken name of the close button. An empty text falls '
              'back to the sample',
        ),
        closeSample,
      );

      return useCaseFrame(
        child: _sheet(
          SheetHeader(title: title, onClose: _noop, closeLabel: closeLabel),
        ),
      );
    },
  );
}
