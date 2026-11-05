import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/contrast.dart';
import '../helpers/painted_color.dart';

const _boundaryKey = Key('bar-boundary');
const _width = 200.0;

Widget _host(
  Widget child, {
  ThemeData? theme,
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
}) {
  return MaterialApp(
    theme: theme ?? CompappTheme.light,
    builder: (context, app) => Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
    ),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SizedBox(
            width: _width,
            child: RepaintBoundary(key: _boundaryKey, child: child),
          ),
        ),
      ),
    ),
  );
}

AppFreshnessBar _bar(int daysAgo, {String? label}) =>
    AppFreshnessBar(ageDays: daysAgo, semanticLabel: label);

Future<Color> _pixel(WidgetTester tester, double x) =>
    paintedColorAt(tester, _boundaryKey, Offset(x, 2));

List<SemanticsNode> _nodes(WidgetTester tester) {
  final nodes = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    nodes.add(node);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.getSemantics(find.byType(Scaffold)));
  return nodes;
}

List<String> _labels(WidgetTester tester) => [
  for (final node in _nodes(tester))
    if (node.label.isNotEmpty) node.label,
];

void main() {
  final themes = [('light', CompappTheme.light), ('dark', CompappTheme.dark)];

  group('AppFreshness.fromAgeDays', () {
    test('today, 1 to 2 days, 3 to 6 days, 7 and more', () {
      for (final (days, expected) in const [
        (0, AppFreshness.fresh),
        (1, AppFreshness.recent),
        (2, AppFreshness.recent),
        (3, AppFreshness.fading),
        (6, AppFreshness.fading),
        (7, AppFreshness.stale),
        (9, AppFreshness.stale),
        (400, AppFreshness.stale),
        (1 << 40, AppFreshness.stale),
      ]) {
        expect(AppFreshness.fromAgeDays(days), expected, reason: '$days days');
      }
    });

    test('a negative age counts as done today', () {
      for (final days in [-1, -30, -(1 << 40)]) {
        expect(AppFreshness.fromAgeDays(days), AppFreshness.fresh);
      }
    });

    test('fills 100, 85, 60 and 25 percent', () {
      expect(
        [for (final freshness in AppFreshness.values) freshness.fill],
        [1, 0.85, 0.6, 0.25],
      );
    });
  });

  group('look', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;
      final away = theme.extension<AppColors>()!.presenceAway;

      testWidgets('each step fills its share from the start in the right '
          'color ($name)', (tester) async {
        for (final (daysAgo, fraction, color) in [
          (0, 1.0, scheme.primary),
          (1, 0.85, scheme.primary),
          (3, 0.6, scheme.primary),
          (9, 0.25, away),
        ]) {
          await tester.pumpWidget(_host(_bar(daysAgo), theme: theme));
          final edge = _width * fraction;
          final reason = '$daysAgo days ago';

          expect(
            await _pixel(tester, 6),
            isSameColorAs(color),
            reason: '$reason: fill start',
          );
          expect(
            await _pixel(tester, edge - 3),
            isSameColorAs(color),
            reason: '$reason: just inside the fill',
          );
          if (fraction < 1) {
            expect(
              await _pixel(tester, edge + 3),
              isSameColorAs(scheme.surfaceContainerHigh),
              reason: '$reason: track after the fill',
            );
          }
        }
      });

      testWidgets('no step ever uses a danger color ($name)', (tester) async {
        for (final daysAgo in [0, 1, 3, 9, 60]) {
          await tester.pumpWidget(_host(_bar(daysAgo), theme: theme));

          for (final x in [6.0, _width - 6]) {
            final pixel = await _pixel(tester, x);
            expect(pixel, isNot(isSameColorAs(scheme.error)));
            expect(pixel, isNot(isSameColorAs(scheme.errorContainer)));
          }
        }
      });
    }

    testWidgets('is 4 tall, as wide as it is given, with rounded ends', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_bar(0)));

      expect(
        tester.getSize(find.byType(AppFreshnessBar)),
        const Size(_width, 4),
      );
      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clip.borderRadius, BorderRadius.circular(2));
      expect(
        (await _pixel(tester, 0)).a,
        lessThan(1),
        reason: 'the corner of the track is cut',
      );
    });

    testWidgets('a negative age is a full bar and a huge one a quarter', (
      tester,
    ) async {
      final scheme = CompappTheme.light.colorScheme;
      await tester.pumpWidget(_host(_bar(-5)));
      expect(await _pixel(tester, _width - 6), isSameColorAs(scheme.primary));

      await tester.pumpWidget(_host(_bar(100000)));
      expect(
        await _pixel(tester, _width * 0.25 - 3),
        isSameColorAs(CompappTheme.light.extension<AppColors>()!.presenceAway),
      );
      expect(
        await _pixel(tester, _width * 0.25 + 3),
        isSameColorAs(scheme.surfaceContainerHigh),
      );
    });

    testWidgets('keeps its height at text scale 2.0', (tester) async {
      await tester.pumpWidget(_host(_bar(3), textScale: 2));

      expect(
        tester.getSize(find.byType(AppFreshnessBar)),
        const Size(_width, 4),
      );
    });
  });

  group('right to left', () {
    testWidgets('fills from the right, the start edge', (tester) async {
      final scheme = CompappTheme.light.colorScheme;
      await tester.pumpWidget(_host(_bar(3), direction: TextDirection.rtl));

      expect(await _pixel(tester, _width - 6), isSameColorAs(scheme.primary));
      expect(
        await _pixel(tester, _width * 0.4 + 3),
        isSameColorAs(scheme.primary),
      );
      expect(
        await _pixel(tester, _width * 0.4 - 3),
        isSameColorAs(scheme.surfaceContainerHigh),
      );
      expect(
        await _pixel(tester, 6),
        isSameColorAs(scheme.surfaceContainerHigh),
      );
    });
  });

  group('semantics', () {
    testWidgets('a label makes it an image in a node of its own', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_bar(0, label: 'Done today')));

      expect(_labels(tester), ['Done today']);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Done today'))
            .flagsCollection
            .isImage,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('without a label it is excluded from semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(Column(children: [const Text('3 days ago'), _bar(3)])),
      );

      expect(_labels(tester), ['3 days ago']);
      handle.dispose();
    });

    testWidgets('an empty label counts as no label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_bar(3, label: '')));

      expect(
        _nodes(tester).any((node) => node.flagsCollection.isImage),
        isFalse,
      );
      handle.dispose();
    });

    testWidgets('keeps its own node inside a labeled container parent', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Semantics(
            container: true,
            label: 'Clean the kitchen',
            child: _bar(3, label: 'Done 3 days ago'),
          ),
        ),
      );

      expect(
        _labels(tester),
        containsAll(['Clean the kitchen', 'Done 3 days ago']),
      );
      expect(
        _labels(tester),
        isNot(contains('Clean the kitchen\nDone 3 days ago')),
      );
      handle.dispose();
    });
  });

  group('contrast', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;
      final away = theme.extension<AppColors>()!.presenceAway;

      test('every fill reaches 3:1 on the track and on every surface '
          '($name)', () {
        final fills = {'primary': scheme.primary, 'away': away};
        final backgrounds = {
          'track': scheme.surfaceContainerHigh,
          'card': scheme.surfaceContainerLowest,
          'page': scheme.surface,
        };
        expectContrast(
          {
            for (final fill in fills.entries)
              for (final background in backgrounds.entries)
                '${fill.key}/${background.key}': (fill.value, background.value),
          },
          minimum: 3,
          reason: name,
        );
      });
    }
  });
}
