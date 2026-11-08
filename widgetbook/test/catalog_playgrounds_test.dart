import 'dart:convert';
import 'dart:io';

import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/catalog.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/catalog_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

const _knobsGroup = 'knobs';

/// Opens [path] in preview mode with [knobs] in the URL, as Widgetbook does
/// when a link carries knob values.
Future<void> _open(
  WidgetTester tester,
  String path, {
  Map<String, String> knobs = const {},
}) async {
  final route = Uri(
    path: '/',
    queryParameters: {
      'path': path,
      'preview': '',
      if (knobs.isNotEmpty) _knobsGroup: FieldCodec.encodeQueryGroup(knobs),
    },
  ).toString();
  await tester.pumpWidget(CatalogApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Sets a knob the way the knobs panel does and rebuilds the use case.
Future<void> _setKnob(
  WidgetTester tester,
  Finder anchor,
  String knob,
  String value,
) async {
  WidgetbookState.of(tester.element(anchor))
      .updateQueryField(group: _knobsGroup, field: knob, value: value);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

String _pathOf(String component) =>
    collectPlaygrounds(buildCatalog()).entries
        .firstWhere((entry) => entry.key.endsWith('/$component/playground'))
        .value
        .path;

void main() {
  final manifest =
      (jsonDecode(File('../components.json').readAsStringSync())
              as Map<String, dynamic>)['components']
          as List<dynamic>;
  final playgrounds = collectPlaygrounds(buildCatalog());

  group('every playground builds with its default knobs', () {
    for (final entry in manifest.cast<Map<String, dynamic>>()) {
      final className = entry['class'] as String;
      final path = entry['playground'] as String;

      testWidgets('$path shows $className', (tester) async {
        await _open(tester, playgrounds[path]!.path);

        expect(
          find.byWidgetPredicate(
            (widget) => widget.runtimeType.toString() == className,
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('the knobs panel builds for every playground', () {
    for (final path in playgrounds.keys) {
      testWidgets('$path in the full catalog', (tester) async {
        tester.view.physicalSize = const Size(1600, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          CatalogApp(
            initialRoute: Uri(
              path: '/',
              queryParameters: {'path': playgrounds[path]!.path},
            ).toString(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        expect(find.text('Knobs'), findsWidgets);
      });
    }
  });

  group('knobs drive the component', () {
    testWidgets('the URL gives the initial knob values', (tester) async {
      await _open(
        tester,
        _pathOf('AppButton'),
        knobs: {
          'label': 'Hello there',
          'enabled': 'false',
          'variant': 'danger',
        },
      );

      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(find.text('Hello there'), findsOneWidget);
      expect(button.onPressed, isNull);
      expect(button.variant, AppButtonVariant.danger);
    });

    testWidgets('changing a knob updates the component', (tester) async {
      await _open(tester, _pathOf('AppButton'));
      expect(find.text('Hello there'), findsNothing);

      await _setKnob(tester, find.byType(AppButton), 'label', 'Hello there');
      await _setKnob(tester, find.byType(AppButton), 'loading', 'true');

      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.label, 'Hello there');
      expect(button.loading, isTrue);
    });

    testWidgets('a pebble below s44 takes the badge knobs but draws none', (
      tester,
    ) async {
      await _open(
        tester,
        _pathOf('AppPebble'),
        knobs: {'size': 's36', 'isAdmin': 'true', 'status': 'away'},
      );

      final pebble = tester.widget<AppPebble>(find.byType(AppPebble));
      expect(pebble.size, AppPebbleSize.s36);
      expect(pebble.isAdmin, isTrue);
      expect(find.byType(AppIcon), findsNothing, reason: 'no badges below s44');

      await _setKnob(tester, find.byType(AppPebble), 'size', 's44');

      expect(find.byType(AppIcon), findsWidgets, reason: 'badges from s44 up');
    });
  });

  group('stateful atoms stay interactive', () {
    testWidgets('a switch toggles, and its knob resets it', (tester) async {
      await _open(tester, _pathOf('AppSwitch'));
      bool value() => tester.widget<AppSwitch>(find.byType(AppSwitch)).value;
      expect(value(), isFalse);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(value(), isTrue);

      await _setKnob(tester, find.byType(AppSwitch), 'value', 'true');
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(value(), isFalse, reason: 'the knob seeded true, the tap flipped');
    });

    testWidgets('a chip selects when tapped', (tester) async {
      await _open(tester, _pathOf('AppChip'));
      bool selected() => tester.widget<AppChip>(find.byType(AppChip)).selected;
      expect(selected(), isFalse);

      await tester.tap(find.byType(AppChip));
      await tester.pump();

      expect(selected(), isTrue);
    });

    testWidgets('a text field takes typing', (tester) async {
      await _open(tester, _pathOf('AppTextField'));

      await tester.enterText(find.byType(EditableText), 'ana@compapp.test');
      await tester.pump();

      expect(find.text('ana@compapp.test'), findsOneWidget);
    });

    testWidgets('a text field starts with the text knob', (tester) async {
      await _open(
        tester,
        _pathOf('AppTextField'),
        knobs: {'text': 'luis@compapp.test'},
      );

      expect(find.text('luis@compapp.test'), findsOneWidget);
    });

    testWidgets('a code input takes digits and follows its length knob', (
      tester,
    ) async {
      await _open(tester, _pathOf('AppCodeInput'), knobs: {'length': '4'});
      expect(find.byKey(const Key('codeInput.digit.3')), findsOneWidget);
      expect(find.byKey(const Key('codeInput.digit.4')), findsNothing);

      await tester.enterText(find.byType(EditableText), '12');
      await tester.pump();

      expect(
        find.descendant(
          of: find.byKey(const Key('codeInput.digit.1')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
    });
  });
}
