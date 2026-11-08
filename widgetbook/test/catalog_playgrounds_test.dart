import 'dart:convert';
import 'dart:io';

import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/catalog.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/catalog_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'helpers/playground_knob_cases.dart';

const _knobsGroup = 'knobs';

String _route(String path, Map<String, String> knobs, {bool preview = true}) {
  return Uri(
    path: '/',
    queryParameters: {
      'path': path,
      if (preview) 'preview': '',
      if (knobs.isNotEmpty) _knobsGroup: FieldCodec.encodeQueryGroup(knobs),
    },
  ).toString();
}

/// Opens [path] in preview mode with [knobs] in the URL, as Widgetbook does
/// when a link carries knob values. The app is keyed by the route, so a second
/// call in the same test navigates.
Future<void> _open(
  WidgetTester tester,
  String path, {
  Map<String, String> knobs = const {},
}) async {
  final route = _route(path, knobs);
  await tester.pumpWidget(
    CatalogApp(key: ValueKey(route), initialRoute: route),
  );
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

Set<String> _registeredKnobs(WidgetTester tester, Finder anchor) =>
    WidgetbookState.of(tester.element(anchor)).knobs.keys.toSet();

Finder _byClassName(String className) => find.byWidgetPredicate(
  (widget) => widget.runtimeType.toString() == className,
);

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
  final classes = [
    for (final entry in manifest.cast<Map<String, dynamic>>())
      entry['class'] as String,
  ];

  group('every playground builds with its default knobs', () {
    for (final entry in manifest.cast<Map<String, dynamic>>()) {
      final className = entry['class'] as String;
      final path = entry['playground'] as String;

      testWidgets('$path shows $className', (tester) async {
        await _open(tester, playgrounds[path]!.path);

        expect(_byClassName(className), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('the full catalog builds a knobs panel for every playground', () {
    for (final path in playgrounds.keys) {
      testWidgets(path, (tester) async {
        tester.view.physicalSize = const Size(1600, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          CatalogApp(
            initialRoute: _route(playgrounds[path]!.path, {}, preview: false),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        expect(find.text('No Knobs available'), findsNothing);
        expect(find.text('Knobs'), findsWidgets);
      });
    }
  });

  group('every knob is connected to its component', () {
    test('the table covers every component', () {
      expect(playgroundKnobCases.keys.toSet(), classes.toSet());
    });

    for (final MapEntry(key: className, value: cases)
        in playgroundKnobCases.entries) {
      testWidgets('$className registers exactly the knobs the table covers', (
        tester,
      ) async {
        await _open(tester, _pathOf(className));

        expect(
          _registeredKnobs(tester, _byClassName(className)),
          cases.map((knobCase) => knobCase.knob).toSet(),
          reason: 'a knob without a table row, or a row without a knob',
        );
      });

      for (final knobCase in cases) {
        testWidgets(
          '$className knob "${knobCase.knob}" reaches the component',
          (tester) async {
            await _open(tester, _pathOf(className));
            expect(
              () => knobCase.check(tester),
              throwsA(isA<TestFailure>()),
              reason: 'the default must not already satisfy the check',
            );

            await _open(
              tester,
              _pathOf(className),
              knobs: {...knobCase.also, knobCase.knob: knobCase.value},
            );
            knobCase.check(tester);
            expect(tester.takeException(), isNull);

            await _open(tester, _pathOf(className));
            final anchor = _byClassName(className);
            await _setKnob(tester, anchor, knobCase.knob, knobCase.value);
            for (final MapEntry(:key, :value) in knobCase.also.entries) {
              await _setKnob(tester, anchor, key, value);
            }
            knobCase.check(tester);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });

  group('hand-edited values cannot trip a component assert', () {
    for (final (component, knobs) in [
      ('AppCodeInput', {'length': '0'}),
      ('AppCodeInput', {'length': '99'}),
      ('AppBadge', {'count': '-3'}),
      ('AppPebble', {'joinOrder': '-1'}),
      ('AppPebble', {'semanticLabel': ''}),
      ('AppProgressRing', {'value': 'NaN'}),
      ('AppProgressRing', {'value': '7', 'size': '1000'}),
      ('AppFreshnessBar', {'ageDays': '-5'}),
      ('AppIcon', {'size': '0'}),
    ]) {
      testWidgets('$component $knobs', (tester) async {
        await _open(tester, _pathOf(component), knobs: knobs);

        expect(_byClassName(component), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('an empty pebble label falls back to the sample', (
      tester,
    ) async {
      await _open(tester, _pathOf('AppPebble'), knobs: {'semanticLabel': ''});

      expect(
        tester.widget<AppPebble>(find.byType(AppPebble)).semanticLabel,
        'Ana',
      );
    });
  });

  group('knobs drive the component', () {
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

    testWidgets('a badge tone follows its form until the knob is set', (
      tester,
    ) async {
      await _open(tester, _pathOf('AppBadge'), knobs: {'form': 'label'});

      expect(
        tester.widget<AppBadge>(find.byType(AppBadge)).tone,
        AppBadgeTone.soft,
      );
    });

    testWidgets('a freshness age reads right for one day and for many', (
      tester,
    ) async {
      await _open(tester, _pathOf('AppFreshnessBar'), knobs: {'ageDays': '1'});
      expect(find.text('1 day ago'), findsOneWidget);

      await _setKnob(tester, find.byType(AppFreshnessBar), 'ageDays', '4');
      expect(find.text('4 days ago'), findsOneWidget);
    });
  });

  group('stateful atoms stay interactive', () {
    testWidgets('a switch toggles when tapped', (tester) async {
      await _open(tester, _pathOf('AppSwitch'));
      bool value() => tester.widget<AppSwitch>(find.byType(AppSwitch)).value;
      expect(value(), isFalse);

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(value(), isTrue);
    });

    testWidgets('a switch knob set before any tap shows at once', (
      tester,
    ) async {
      await _open(tester, _pathOf('AppSwitch'));

      await _setKnob(tester, find.byType(AppSwitch), 'value', 'true');

      expect(tester.widget<AppSwitch>(find.byType(AppSwitch)).value, isTrue);
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

  group('editing the text knob keeps focus in the knobs panel', () {
    for (final (component, knob) in [
      ('AppTextField', 'text'),
      ('AppCodeInput', 'code'),
    ]) {
      testWidgets('$component with autofocus off', (tester) async {
        tester.view.physicalSize = const Size(1600, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          CatalogApp(
            initialRoute: _route(_pathOf(component), {}, preview: false),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final panelField = find.ancestor(
          of: find.text(knob),
          matching: find.byType(Column),
        );
        final editable = find.descendant(
          of: panelField.first,
          matching: find.byType(EditableText),
        );
        expect(editable, findsOneWidget, reason: 'the "$knob" knob field');

        await tester.enterText(editable, '1');
        await tester.pump();
        await tester.enterText(editable, '12');
        await tester.pump();

        expect(
          tester.widget<EditableText>(editable).focusNode.hasFocus,
          isTrue,
          reason: 'the next keystroke still goes to the knob field',
        );
        final controller = component == 'AppTextField'
            ? tester.widget<AppTextField>(find.byType(AppTextField)).controller
            : tester.widget<AppCodeInput>(find.byType(AppCodeInput)).controller;
        expect(controller!.text, '12', reason: 'the preview shows the text');
      });
    }
  });
}
