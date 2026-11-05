import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/catalog.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/use_case_harness.dart';

/// The golden harness sizes every scenario to its content, so a bar that
/// takes "the space that is left" (an `Expanded`) gets none and the golden
/// shows no bar at all. This lays the use cases out the way the goldens do and
/// checks that the bar is drawn, and that the age text does not break a word.
void main() {
  setUpAll(() async {
    final loader = FontLoader('packages/compapp_design/Instrument Sans');
    for (final file in [
      'InstrumentSans-Regular.ttf',
      'InstrumentSans-SemiBold.ttf',
    ]) {
      final bytes = File('../fonts/$file').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  });

  final useCases = collectUseCases(buildCatalog());
  for (final MapEntry(key: path, value: useCase) in useCases.entries) {
    if (!path.startsWith('Atoms/AppFreshnessBar/')) continue;

    testWidgets('$path draws a bar in every golden scenario', (tester) async {
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

      final bars = find.byType(AppFreshnessBar);
      expect(bars, findsNWidgets(4), reason: 'light and dark, 1.0x and 2.0x');
      for (var i = 0; i < 4; i++) {
        expect(
          tester.getSize(bars.at(i)).width,
          greaterThanOrEqualTo(100),
          reason: 'scenario $i draws a visible bar',
        );
      }
      expect(tester.takeException(), isNull, reason: 'no overflow');

      // The age text stays on one line at every scale.
      final ages = find.descendant(
        of: find.byType(GoldenTestScenario),
        matching: find.byType(Text),
      );
      for (var i = 0; i < ages.evaluate().length; i++) {
        final text = tester.widget<Text>(ages.at(i));
        final context = tester.element(ages.at(i));
        final style = DefaultTextStyle.of(context).style.merge(text.style);
        // One line at the scale of this scenario: the scaler grows the font,
        // and so the line.
        final lineHeight =
            MediaQuery.textScalerOf(context).scale(style.fontSize!) *
            (style.height ?? 1.3);
        expect(
          tester.getSize(ages.at(i)).height,
          lessThanOrEqualTo(lineHeight * 1.5),
          reason: 'text $i fits on one line',
        );
      }
    });
  }
}
