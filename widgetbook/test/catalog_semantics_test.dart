import 'package:compapp_design_widgetbook/src/catalog/catalog.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/use_case_harness.dart';

void main() {
  final useCases = collectUseCases(buildCatalog());

  for (final MapEntry(key: path, value: useCase) in useCases.entries) {
    for (final theme in themeVariants) {
      testWidgets('$path meets the accessibility guidelines (${theme.name})', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pumpUseCase(tester, useCase, theme.data);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  }
}
