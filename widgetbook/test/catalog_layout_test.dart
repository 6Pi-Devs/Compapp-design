import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:compapp_design_widgetbook/src/catalog/catalog.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/use_case_harness.dart';

/// The least width a molecule or organism use case must be drawn with in a
/// golden scenario. A row that takes "the space that is left" gets none when
/// the harness sizes a scenario to its content, and the golden would show an
/// empty scenario.
const _leastWidth = 100.0;
const _leastHeight = 40.0;

/// The least width of the molecules and organisms that fill their column, by
/// class name. It is an explicit minimum for each of them: the narrow ones (a
/// beacon that is free, a compact ribbon) are narrow on purpose and have none.
const _leastWidthOf = <String, double>{
  'AppTopBar': 300,
  'AppNavBar': 300,
  'SheetHeader': 300,
  'AppEmptyState': 200,
  'AppSnackbar': 300,
  'ActivityList': 300,
  'PresencePanel': 300,
  'CalendarStrip': 300,
  'TaskComposer': 300,
  'FloorplanMap': 300,
  'ItemSheet': 300,
  'RoomEditor': 300,
};

/// Lays every molecule and organism use case out the way the goldens do, with
/// the real fonts, and checks that each of the four scenarios (light and dark,
/// text scale 1.0 and 2.0) draws the component at a visible size and overflows
/// nowhere. An organism can be tall: the scenario is as tall as it is, so the
/// golden shows all of it.
void main() {
  setUpAll(() async {
    Future<void> load(String family, List<String> files) async {
      final loader = FontLoader('packages/compapp_design/$family');
      for (final file in files) {
        final bytes = File('../fonts/$file').readAsBytesSync();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
      }
      await loader.load();
    }

    await load('Bricolage Grotesque', ['BricolageGrotesque-Variable.ttf']);
    await load('Instrument Sans', [
      'InstrumentSans-Regular.ttf',
      'InstrumentSans-SemiBold.ttf',
    ]);
  });

  final useCases = collectFixedUseCases(buildCatalog());
  for (final MapEntry(key: path, value: useCase) in useCases.entries) {
    if (!path.startsWith('Molecules/') && !path.startsWith('Organisms/')) {
      continue;
    }

    testWidgets('$path is drawn in every golden scenario', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GoldenTestGroup(
                columns: 2,
                scenarioConstraints: const BoxConstraints(
                  maxWidth: goldenScenarioWidth,
                ),
                children: goldenScenarios(useCase),
              ),
            ),
          ),
        ),
      );

      final scenarios = find.byType(GoldenTestScenario);
      expect(scenarios, findsNWidgets(4), reason: 'light and dark, 1.0x, 2.0x');
      for (var i = 0; i < 4; i++) {
        final size = tester.getSize(scenarios.at(i));
        expect(size.width, greaterThanOrEqualTo(_leastWidth), reason: '$i');
        expect(size.height, greaterThanOrEqualTo(_leastHeight), reason: '$i');
      }
      final className = path.split('/')[1];
      final least = _leastWidthOf[className];
      if (least != null) {
        final components = find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == className,
        );
        expect(components, findsNWidgets(4), reason: className);
        for (var i = 0; i < 4; i++) {
          expect(
            tester.getSize(components.at(i)).width,
            greaterThanOrEqualTo(least),
            reason: '$className in scenario $i',
          );
        }
      }
      expect(tester.takeException(), isNull, reason: 'no overflow');
    });
  }
}
