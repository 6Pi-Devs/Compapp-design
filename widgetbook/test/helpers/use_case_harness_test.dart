import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'use_case_harness.dart';

/// Content taller than the default 800x600 surface.
const _belowTheFold = 900.0;

Widget _probe(double size) => Semantics(
  button: true,
  label: 'Probe',
  onTap: () {},
  child: GestureDetector(
    onTap: () {},
    child: SizedBox.square(dimension: size),
  ),
);

WidgetbookUseCase _tappable(double size, {double offset = 0}) =>
    WidgetbookUseCase(
      name: 'probe',
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: offset),
          _probe(size),
        ],
      ),
    );

void main() {
  group('pumpUseCase', () {
    for (final theme in themeVariants) {
      testWidgets('fails a 20 px tap target (${theme.name})', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpUseCase(tester, _tappable(20), theme.data);

        await expectLater(
          tester,
          doesNotMeetGuideline(androidTapTargetGuideline),
        );
        await expectLater(tester, doesNotMeetGuideline(iOSTapTargetGuideline));
        handle.dispose();
      });

      testWidgets('fails a 20 px tap target below the fold (${theme.name})', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pumpUseCase(
          tester,
          _tappable(20, offset: _belowTheFold),
          theme.data,
        );

        expect(
          tester.getTopLeft(find.bySemanticsLabel('Probe')).dy,
          greaterThan(600),
        );
        await expectLater(
          tester,
          doesNotMeetGuideline(androidTapTargetGuideline),
        );
        await expectLater(tester, doesNotMeetGuideline(iOSTapTargetGuideline));
        handle.dispose();
      });

      testWidgets('passes a 48 px tap target (${theme.name})', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpUseCase(tester, _tappable(48), theme.data);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        handle.dispose();
      });
    }
  });
}
