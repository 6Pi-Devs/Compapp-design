import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:compapp_design_widgetbook/src/catalog/catalog.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:flutter/widgets.dart';

import 'helpers/use_case_harness.dart';

void main() {
  final useCases = collectUseCases(buildCatalog());

  for (final MapEntry(key: path, value: useCase) in useCases.entries) {
    unawaited(
      goldenTest(
        path,
        fileName: path,
        builder: () => GoldenTestGroup(
          columns: 2,
          scenarioConstraints: const BoxConstraints(
            maxWidth: goldenScenarioWidth,
          ),
          children: goldenScenarios(useCase),
        ),
      ),
    );
  }
}
