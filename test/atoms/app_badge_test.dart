import 'dart:io';

import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/contrast.dart';
import '../helpers/painted_color.dart';

const _boundaryKey = Key('badge-boundary');

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

Finder get _text =>
    find.descendant(of: find.byType(AppBadge), matching: find.byType(Text));

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

(Color fill, Color ink) _colors(ThemeData theme, AppBadgeTone tone) {
  final scheme = theme.colorScheme;
  return switch (tone) {
    AppBadgeTone.primary => (scheme.primary, scheme.onPrimary),
    AppBadgeTone.busy => (
      theme.extension<AppColors>()!.busySoft,
      scheme.onSurface,
    ),
    AppBadgeTone.soft => (scheme.primaryContainer, scheme.onSurface),
  };
}

void main() {
  final themes = [('light', CompappTheme.light), ('dark', CompappTheme.dark)];

  group('look', () {
    for (final (name, theme) in themes) {
      for (final tone in AppBadgeTone.values) {
        testWidgets('count and label paint the ${tone.name} fill and ink '
            '($name)', (tester) async {
          final (fill, ink) = _colors(theme, tone);
          for (final badge in [
            AppBadge.count(3, tone: tone),
            AppBadge.label('Yours', tone: tone),
          ]) {
            await tester.pumpWidget(_host(badge, theme: theme));
            final height = tester.getSize(find.byType(AppBadge)).height;

            expect(
              await paintedColorAt(tester, _boundaryKey, Offset(2, height / 2)),
              isSameColorAs(fill),
              reason: '${badge.count ?? badge.label} fill',
            );
            expect(
              await paintedColorAtCenter(tester, _boundaryKey, _text),
              isSameColorAs(ink),
              reason: '${badge.count ?? badge.label} text',
            );
          }
        });
      }
    }

    testWidgets('defaults: a count is primary, a label is soft', (
      tester,
    ) async {
      expect(const AppBadge.count(1).tone, AppBadgeTone.primary);
      expect(const AppBadge.label('Yours').tone, AppBadgeTone.soft);
    });
  });

  group('count', () {
    testWidgets('shows the number up to 99 and 99+ beyond', (tester) async {
      for (final (count, shown) in const [
        (0, '0'),
        (7, '7'),
        (99, '99'),
        (100, '99+'),
        (1000, '99+'),
      ]) {
        await tester.pumpWidget(_host(AppBadge.count(count)));

        expect(find.text(shown), findsOneWidget, reason: '$count');
      }
    });

    testWidgets('rejects a negative count in debug and shows 0 in release', (
      tester,
    ) async {
      expect(() => AppBadge.count(-1), throwsAssertionError);
      expect(AppBadge.countText(-5), '0');
      expect(AppBadge.countText(0), '0');
      expect(AppBadge.countText(99), '99');
      expect(AppBadge.countText(100), '99+');
    });

    testWidgets('is a stadium at least 18 square that grows with its text', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const AppBadge.count(3)));
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: find.byType(AppBadge),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as ShapeDecoration;
      expect(decoration.shape, const StadiumBorder());

      for (final (count, digits) in const [(3, 1), (42, 2), (100, 3)]) {
        await tester.pumpWidget(_host(AppBadge.count(count)));

        // flutter_test draws a glyph as a square as wide as the font size,
        // wider than a real digit, so no badge here hits the 18 minimum.
        final text = digits * AppTypography.badgeCount.fontSize!;
        expect(
          tester.getSize(find.byType(AppBadge)),
          Size(text + AppSizes.badgeCountPadding * 2, 18),
          reason: '$count',
        );
      }
    });
  });

  group('text style', () {
    TextStyle painted(WidgetTester tester) =>
        tester.renderObject<RenderParagraph>(_text).text.style!;

    testWidgets('a label uses font.badge-label: 12, 600, 16 line', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const AppBadge.label('Yours')));

      final style = painted(tester);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.fontSize, 12);
      expect(style.height! * style.fontSize!, closeTo(16, 1e-9));
      expect(style.fontFamily, AppTypography.badgeLabel.fontFamily);
    });

    testWidgets('a count uses font.badge-count: 11, 600, 18 line', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const AppBadge.count(3)));

      final style = painted(tester);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.fontSize, 11);
      expect(style.height! * style.fontSize!, closeTo(18, 1e-9));
      expect(style.fontFamily, AppTypography.badgeCount.fontFamily);
    });
  });

  group('label', () {
    testWidgets('is a rounded rectangle with 8 px padding and a 4 px edge', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const AppBadge.label('Yours')));

      final text = tester.getSize(_text);
      expect(
        tester.getSize(find.byType(AppBadge)),
        Size(text.width + AppSpacing.sm * 2, text.height + AppSpacing.xs * 2),
      );
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: find.byType(AppBadge),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(8));
    });
  });

  group('right to left', () {
    testWidgets('count and label keep their size and the text stays '
        'centered', (tester) async {
      for (final badge in const [
        AppBadge.count(120),
        AppBadge.label('Not applied yet'),
      ]) {
        await tester.pumpWidget(_host(badge));
        final ltr = tester.getSize(find.byType(AppBadge));

        await tester.pumpWidget(_host(badge, direction: TextDirection.rtl));

        expect(tester.getSize(find.byType(AppBadge)), ltr);
        expect(
          tester.getCenter(_text).dx,
          closeTo(tester.getCenter(find.byType(AppBadge)).dx, 0.01),
        );
      }
    });

    testWidgets('a count reads 99+ in the same order', (tester) async {
      await tester.pumpWidget(
        _host(const AppBadge.count(120), direction: TextDirection.rtl),
      );

      expect(tester.widget<Text>(_text).textDirection, TextDirection.ltr);
    });
  });

  group('semantics', () {
    String merged(WidgetTester tester) =>
        tester.getSemantics(find.text('Activity')).getSemanticsData().label;

    Widget row(AppBadge badge) => MergeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [const Text('Activity'), badge],
      ),
    );

    testWidgets('without a label the visible text is the node', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const AppBadge.count(3)));

      expect(_labels(tester), ['3']);
      handle.dispose();
    });

    testWidgets('merges into a parent that merges its children', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(row(const AppBadge.count(3))));

      expect(merged(tester), 'Activity\n3');
      handle.dispose();
    });

    testWidgets('a semanticLabel replaces the text, also when merged', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(row(const AppBadge.count(3, semanticLabel: '3 unread'))),
      );

      expect(merged(tester), 'Activity\n3 unread');
      expect(find.bySemanticsLabel('3'), findsNothing);
      handle.dispose();
    });

    testWidgets('a label badge merges the same way', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(row(const AppBadge.label('Yours'))));

      expect(merged(tester), 'Activity\nYours');
      handle.dispose();
    });

    testWidgets('a semanticLabel makes one labeled node and excludes the '
        'text', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const AppBadge.count(3, semanticLabel: '3 unread')),
      );

      expect(_labels(tester), ['3 unread']);
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
            label: 'Activity',
            child: const AppBadge.count(3, semanticLabel: '3 unread'),
          ),
        ),
      );

      expect(_labels(tester), containsAll(['Activity', '3 unread']));
      expect(_labels(tester), isNot(contains('Activity\n3 unread')));
      handle.dispose();
    });

    testWidgets('an empty semanticLabel counts as none', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const AppBadge.label('Yours', semanticLabel: '')),
      );

      expect(_labels(tester), ['Yours']);
      handle.dispose();
    });
  });

  group('contrast', () {
    for (final (name, theme) in themes) {
      test('the text reaches 4.5:1 on every fill ($name)', () {
        expectContrast(
          {
            for (final tone in AppBadgeTone.values)
              '${tone.name} ink/fill': (
                _colors(theme, tone).$2,
                _colors(theme, tone).$1,
              ),
          },
          minimum: 4.5,
          reason: name,
        );
      });
    }
  });

  group('large text', () {
    setUpAll(() async {
      // The real glyphs: without the bundled fonts a test draws every glyph
      // as a solid em square, which proves nothing about the fit.
      final loader = FontLoader('packages/compapp_design/Instrument Sans');
      for (final file in [
        'InstrumentSans-Regular.ttf',
        'InstrumentSans-SemiBold.ttf',
      ]) {
        final bytes = File('fonts/$file').readAsBytesSync();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
      }
      await loader.load();
    });

    testWidgets('a single digit fits the 18 square minimum', (tester) async {
      await tester.pumpWidget(_host(const AppBadge.count(3)));

      expect(tester.getSize(find.byType(AppBadge)), const Size.square(18));
    });

    testWidgets('the text is never scaled down and the badge grows around it', (
      tester,
    ) async {
      for (final badge in const [
        AppBadge.count(3),
        AppBadge.count(120),
        AppBadge.label('Not applied yet'),
      ]) {
        await tester.pumpWidget(_host(badge));
        final base = tester.getSize(_text);
        final baseBadge = tester.getSize(find.byType(AppBadge));

        for (final scale in [1.5, 2.0]) {
          await tester.pumpWidget(_host(badge, textScale: scale));

          final reason = '${badge.count ?? badge.label} at ${scale}x';
          final text = tester.getRect(_text);
          final box = tester.getRect(find.byType(AppBadge));
          expect(text.height, closeTo(base.height * scale, 1), reason: reason);
          expect(text.width, closeTo(base.width * scale, 1.5), reason: reason);
          if (scale == 2.0) {
            expect(box.height, greaterThan(baseBadge.height), reason: reason);
            expect(box.width, greaterThan(baseBadge.width), reason: reason);
          }
          expect(box.height, greaterThanOrEqualTo(text.height));
          if (badge.count != null) {
            // The digits keep a line taller than the glyphs: room above and
            // below at every scale.
            expect(
              text.height,
              greaterThan(AppTypography.badgeCount.fontSize! * scale * 1.4),
              reason: '$reason: breathing room',
            );
          }
          expect(text.top, greaterThanOrEqualTo(box.top), reason: reason);
          expect(text.bottom, lessThanOrEqualTo(box.bottom), reason: reason);
          final padding = badge.count != null
              ? AppSizes.badgeCountPadding
              : AppSpacing.sm;
          expect(
            text.left - box.left,
            greaterThanOrEqualTo(padding - 0.01),
            reason: reason,
          );
          expect(
            box.right - text.right,
            greaterThanOrEqualTo(padding - 0.01),
            reason: reason,
          );
          expect(
            box.height,
            greaterThanOrEqualTo(AppSizes.badgeCount),
            reason: reason,
          );
        }
      }
      expect(
        find.descendant(
          of: find.byType(AppBadge),
          matching: find.byType(ClipRect),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
