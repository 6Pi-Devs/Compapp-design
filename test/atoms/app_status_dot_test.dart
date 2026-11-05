import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/contrast.dart';
import '../helpers/painted_color.dart';

const _boundaryKey = Key('dot-boundary');

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
          child: RepaintBoundary(key: _boundaryKey, child: child),
        ),
      ),
    ),
  );
}

AppStatusDot _dot(AppDotStatus status) => AppStatusDot(status: status);

Future<Color> _pixel(WidgetTester tester, double x, double y) =>
    paintedColorAt(tester, _boundaryKey, Offset(x, y));

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

bool _hasImage(WidgetTester tester) =>
    _nodes(tester).any((node) => node.flagsCollection.isImage);

void main() {
  final themes = [('light', CompappTheme.light), ('dark', CompappTheme.dark)];

  group('look', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;
      final colors = theme.extension<AppColors>()!;

      testWidgets('each status has its color and shape ($name)', (
        tester,
      ) async {
        final filled = {
          AppDotStatus.home: scheme.primary,
          AppDotStatus.busy: colors.busy,
          AppDotStatus.unread: scheme.primary,
        };
        for (final MapEntry(key: status, value: color) in filled.entries) {
          await tester.pumpWidget(_host(_dot(status), theme: theme));
          final half = tester.getSize(find.byType(AppStatusDot)).width / 2;

          expect(
            await _pixel(tester, half, half),
            isSameColorAs(color),
            reason: '${status.name} is a filled dot',
          );
        }

        await tester.pumpWidget(_host(_dot(AppDotStatus.away), theme: theme));
        expect(
          (await _pixel(tester, 4, 4)).a,
          0,
          reason: 'away is hollow: the shape, not only the color, says away',
        );
        // The ring is anti-aliased, so its pixels are a hair transparent.
        for (final x in [1.0, 6.0]) {
          expect(
            await _pixel(tester, x, 4),
            isSameColorAs(colors.presenceAway, threshold: 0.1),
            reason: 'x = $x',
          );
        }
      });
    }

    testWidgets('home, busy and away are 8 and unread is 10, circles', (
      tester,
    ) async {
      for (final (status, side) in const [
        (AppDotStatus.home, 8.0),
        (AppDotStatus.away, 8.0),
        (AppDotStatus.busy, 8.0),
        (AppDotStatus.unread, 10.0),
      ]) {
        await tester.pumpWidget(_host(_dot(status)));

        expect(tester.getSize(find.byType(AppStatusDot)), Size.square(side));
        final box = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byType(AppStatusDot),
            matching: find.byType(DecoratedBox),
          ),
        );
        expect((box.decoration as BoxDecoration).shape, BoxShape.circle);
      }
    });

    testWidgets('keeps its size at text scale 2.0 and draws the same in '
        'right-to-left', (tester) async {
      await tester.pumpWidget(
        _host(
          _dot(AppDotStatus.unread),
          textScale: 2,
          direction: TextDirection.rtl,
        ),
      );
      expect(tester.getSize(find.byType(AppStatusDot)), const Size.square(10));

      await tester.pumpWidget(
        _host(_dot(AppDotStatus.away), direction: TextDirection.rtl),
      );
      expect((await _pixel(tester, 4, 4)).a, 0);
      expect(
        await _pixel(tester, 1, 4),
        isSameColorAs(
          CompappTheme.light.extension<AppColors>()!.presenceAway,
          threshold: 0.1,
        ),
      );
    });
  });

  group('semantics', () {
    testWidgets('the dot adds no node, only the text beside it is read', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [_dot(AppDotStatus.home), const Text('At home')],
          ),
        ),
      );

      expect(_labels(tester), ['At home']);
      expect(_hasImage(tester), isFalse);
      handle.dispose();
    });

    testWidgets('alone it leaves no semantics node at all', (tester) async {
      final handle = tester.ensureSemantics();
      for (final status in AppDotStatus.values) {
        await tester.pumpWidget(_host(_dot(status)));

        expect(find.byType(AppStatusDot), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AppStatusDot),
            matching: find.byType(ExcludeSemantics),
          ),
          findsOneWidget,
        );
        expect(_labels(tester), isEmpty, reason: status.name);
        expect(_hasImage(tester), isFalse, reason: status.name);
        expect(
          _nodes(tester).where(
            (node) =>
                node.rect.size == tester.getSize(find.byType(AppStatusDot)),
          ),
          isEmpty,
          reason: '${status.name} has no node of its own',
        );
      }
      handle.dispose();
    });
  });

  group('contrast', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;
      final colors = theme.extension<AppColors>()!;

      test('every dot reaches 3:1 on the card, the page and a sunken '
          'surface ($name)', () {
        final dots = {
          'home': scheme.primary,
          'unread': scheme.primary,
          'busy': colors.busy,
          'away ring': colors.presenceAway,
        };
        final surfaces = {
          'card': scheme.surfaceContainerLowest,
          'page': scheme.surface,
          'sunken': scheme.surfaceContainerHigh,
        };
        expectContrast(
          {
            for (final dot in dots.entries)
              for (final surface in surfaces.entries)
                '${dot.key}/${surface.key}': (dot.value, surface.value),
          },
          minimum: 3,
          reason: name,
        );
      });
    }
  });
}
