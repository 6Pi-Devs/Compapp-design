import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/catalog.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'helpers/rendered_text_contrast.dart';
import 'helpers/use_case_harness.dart';

const _boundaryKey = Key('contrast.boundary');

Widget _host(WidgetbookUseCase useCase, ThemeData theme) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    locale: const Locale('en'),
    supportedLocales: const [Locale('en'), Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: _boundaryKey,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Builder(builder: useCase.build),
          ),
        ),
      ),
    ),
  );
}

/// The `textContrastGuideline` finds a text by its semantics label, so a
/// merged or replaced label hides the text from it. This reads the rendered
/// paragraphs instead and holds every one to 4.5:1 against what is painted
/// around it, in both themes.
void main() {
  final useCases = collectFixedUseCases(buildCatalog());

  for (final MapEntry(key: path, value: useCase) in useCases.entries) {
    for (final theme in themeVariants) {
      testWidgets('$path draws every text at 4.5:1 (${theme.name})', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_host(useCase, theme.data));
        await tester.pump();

        expect(
          await lowContrastTexts(
            tester,
            _boundaryKey,
            page: theme.data.scaffoldBackgroundColor,
          ),
          isEmpty,
        );
      });
    }
  }
}
