import 'dart:io';
import 'dart:math' as math;

import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/contrast.dart';
import '../helpers/painted_color.dart';

const _boundaryKey = Key('ring-boundary');

Widget _host(
  Widget child, {
  ThemeData? theme,
  double textScale = 1,
  bool disableAnimations = false,
  TextDirection direction = TextDirection.ltr,
}) {
  return MaterialApp(
    theme: theme ?? CompappTheme.light,
    builder: (context, app) => Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
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

AppProgressRing _ring({
  double? value,
  AppRingTone tone = AppRingTone.primary,
  String? label,
  String? semanticLabel = 'Chores',
  String? semanticValue,
}) => AppProgressRing(
  value: value,
  tone: tone,
  label: label,
  semanticLabel: semanticLabel,
  semanticValue: value == null ? null : semanticValue ?? '${value * 100}%',
);

/// The ring is 56 square: the four points are the middle of each edge,
/// inside the 4 px stroke.
const _top = Offset(28, 2);
const _right = Offset(54, 28);
const _bottom = Offset(28, 54);
const _left = Offset(2, 28);

/// The middle of the stroke at [degrees] clockwise from the top: the ring is
/// 56 square with a 4 px stroke, so its radius is 26.
Offset _at(double degrees) {
  final radians = degrees * math.pi / 180;
  return Offset(28 + 26 * math.sin(radians), 28 - 26 * math.cos(radians));
}

Future<Color> _pixel(WidgetTester tester, Offset at) =>
    paintedColorAt(tester, _boundaryKey, at);

(Color track, Color arc) _colors(ThemeData theme, AppRingTone tone) {
  final scheme = theme.colorScheme;
  final extras = theme.extension<AppColors>()!;
  return switch (tone) {
    AppRingTone.busy => (extras.busySoft, extras.busy),
    AppRingTone.primary => (scheme.surfaceContainerHigh, scheme.primary),
  };
}

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

  group('determinate', () {
    for (final (name, theme) in themes) {
      for (final tone in AppRingTone.values) {
        testWidgets('half a ring is the arc clockwise from the top on the '
            '${tone.name} track ($name)', (tester) async {
          final (track, arc) = _colors(theme, tone);
          await tester.pumpWidget(
            _host(_ring(value: 0.5, tone: tone), theme: theme),
          );

          expect(await _pixel(tester, _top), isSameColorAs(arc));
          expect(await _pixel(tester, _right), isSameColorAs(arc));
          expect(await _pixel(tester, _left), isSameColorAs(track));
          expect(
            await _pixel(tester, const Offset(28, 28)),
            predicate<Color>((color) => color.a == 0),
            reason: 'the middle is empty',
          );
        });
      }
    }

    testWidgets('a quarter ends at the right, three quarters at the left', (
      tester,
    ) async {
      final (track, arc) = _colors(CompappTheme.light, AppRingTone.primary);

      await tester.pumpWidget(_host(_ring(value: 0.25)));
      expect(await _pixel(tester, _at(45)), isSameColorAs(arc));
      expect(await _pixel(tester, _at(135)), isSameColorAs(track));
      expect(await _pixel(tester, _bottom), isSameColorAs(track));

      await tester.pumpWidget(_host(_ring(value: 0.75)));
      expect(await _pixel(tester, _bottom), isSameColorAs(arc));
      expect(await _pixel(tester, _at(225)), isSameColorAs(arc));
      expect(await _pixel(tester, _at(315)), isSameColorAs(track));
    });

    testWidgets('zero draws no arc, not even a dot, and one closes the ring', (
      tester,
    ) async {
      final (track, arc) = _colors(CompappTheme.light, AppRingTone.primary);

      await tester.pumpWidget(_host(_ring(value: 0)));
      for (final point in [_top, _right, _bottom, _left]) {
        expect(await _pixel(tester, point), isSameColorAs(track));
      }

      await tester.pumpWidget(_host(_ring(value: 1)));
      for (final point in [_top, _right, _bottom, _left]) {
        expect(await _pixel(tester, point), isSameColorAs(arc));
      }
    });

    testWidgets('a value outside 0 to 1 is clamped', (tester) async {
      final (track, arc) = _colors(CompappTheme.light, AppRingTone.primary);

      await tester.pumpWidget(_host(_ring(value: -0.5)));
      expect(await _pixel(tester, _top), isSameColorAs(track));

      await tester.pumpWidget(_host(_ring(value: 1.5)));
      expect(await _pixel(tester, _left), isSameColorAs(arc));
    });

    testWidgets('is 56 square by default and takes a size', (tester) async {
      await tester.pumpWidget(_host(_ring(value: 0.5)));
      expect(
        tester.getSize(find.byType(AppProgressRing)),
        const Size.square(56),
      );

      await tester.pumpWidget(
        _host(
          const AppProgressRing(
            value: 0.5,
            size: 72,
            semanticLabel: 'Chores',
            semanticValue: '50%',
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(AppProgressRing)),
        const Size.square(72),
      );
    });

    testWidgets('the arc has a repaint boundary of its own', (tester) async {
      await tester.pumpWidget(_host(_ring(value: 0.5)));

      expect(
        find.descendant(
          of: find.byType(AppProgressRing),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is RepaintBoundary && widget.child is CustomPaint,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the middle label uses font.ring-label', (tester) async {
      await tester.pumpWidget(_host(_ring(value: 0.5, label: '11')));

      final style = tester
          .renderObject<RenderParagraph>(find.text('11'))
          .text
          .style!;
      expect(style.fontWeight, FontWeight.w600);
      expect(style.fontSize, 15);
      expect(style.height, 1);
    });

    testWidgets('does not animate', (tester) async {
      await tester.pumpWidget(_host(_ring(value: 0.5)));

      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('needs a semanticValue with a value and a label', (
      tester,
    ) async {
      expect(
        () => AppProgressRing(value: 0.5, semanticLabel: 'Chores'),
        throwsAssertionError,
      );
      expect(
        () => const AppProgressRing(value: 0.5, semanticLabel: null),
        returnsNormally,
      );
    });

    testWidgets('an empty label is no label, so it needs no semanticValue', (
      tester,
    ) async {
      expect(
        () => const AppProgressRing(value: 0.5, semanticLabel: ''),
        returnsNormally,
      );
    });

    testWidgets('a value that is not finite fails in debug', (tester) async {
      for (final value in [
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => AppProgressRing(
            value: value,
            semanticLabel: 'Chores',
            semanticValue: 'x',
          ),
          throwsAssertionError,
          reason: '$value',
        );
      }
    });

    test('and is shown as 0 where asserts are off', () {
      expect(AppProgressRing.sweepOf(double.nan), 0);
      expect(AppProgressRing.sweepOf(double.infinity), 0);
      expect(AppProgressRing.sweepOf(double.negativeInfinity), 0);
      expect(AppProgressRing.sweepOf(0.4), 0.4);
      expect(AppProgressRing.sweepOf(-3), 0);
      expect(AppProgressRing.sweepOf(3), 1);
    });
  });

  group('indeterminate', () {
    testWidgets('is a 30% arc from the top: not a full ring and not a dot', (
      tester,
    ) async {
      final (track, arc) = _colors(CompappTheme.light, AppRingTone.busy);
      await tester.pumpWidget(
        _host(_ring(tone: AppRingTone.busy), disableAnimations: true),
      );

      expect(await _pixel(tester, _top), isSameColorAs(arc));
      expect(await _pixel(tester, _right), isSameColorAs(arc));
      expect(await _pixel(tester, _at(100)), isSameColorAs(arc));
      expect(await _pixel(tester, _at(120)), isSameColorAs(track));
      expect(await _pixel(tester, _bottom), isSameColorAs(track));
      expect(await _pixel(tester, _left), isSameColorAs(track));
    });

    testWidgets('breathes from full to 40% and back over four seconds, '
        'eased', (tester) async {
      final (track, arc) = _colors(CompappTheme.light, AppRingTone.busy);
      await tester.pumpWidget(_host(_ring(tone: AppRingTone.busy)));
      await tester.pump();

      // 500 ms in, the ease-in-out curve has covered about 13% of the way to
      // the low point (opacity 0.92), where a linear fade would be at 0.85.
      for (final (elapsed, opacity) in const [
        (0, 1.0),
        (500, 0.9225),
        (500, 0.7),
        (1000, 0.4),
        (1000, 0.7),
        (1000, 1.0),
        (1000, 0.7),
      ]) {
        await tester.pump(Duration(milliseconds: elapsed));

        expect(
          await _pixel(tester, _top),
          isSameColorAs(Color.lerp(track, arc, opacity)!, threshold: 0.01),
          reason: 'after ${elapsed}ms step, opacity $opacity',
        );
      }
      expect(AppMotion.inUse, const Duration(seconds: 4));
    });

    testWidgets('keeps the track steady while the arc breathes', (
      tester,
    ) async {
      final (track, _) = _colors(CompappTheme.light, AppRingTone.busy);
      await tester.pumpWidget(_host(_ring(tone: AppRingTone.busy)));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(await _pixel(tester, _left), isSameColorAs(track));
    });

    testWidgets('stands still at full opacity when animations are disabled', (
      tester,
    ) async {
      final (_, arc) = _colors(CompappTheme.light, AppRingTone.busy);
      await tester.pumpWidget(
        _host(_ring(tone: AppRingTone.busy), disableAnimations: true),
      );

      expect(tester.binding.transientCallbackCount, 0);
      await tester.pump(const Duration(seconds: 2));
      expect(await _pixel(tester, _top), isSameColorAs(arc));
      await tester.pumpAndSettle();
    });

    testWidgets('follows the setting while it is shown', (tester) async {
      await tester.pumpWidget(_host(_ring()));
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      await tester.pumpWidget(_host(_ring(), disableAnimations: true));
      expect(tester.binding.transientCallbackCount, 0);

      await tester.pumpWidget(_host(_ring()));
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));
    });

    testWidgets('stops breathing once it has a value', (tester) async {
      await tester.pumpWidget(_host(_ring()));
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      await tester.pumpWidget(_host(_ring(value: 0.5)));
      expect(tester.binding.transientCallbackCount, 0);

      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });
  });

  group('right to left', () {
    testWidgets('the arc still runs clockwise from the top, like a clock', (
      tester,
    ) async {
      final (track, arc) = _colors(CompappTheme.light, AppRingTone.primary);
      await tester.pumpWidget(
        _host(_ring(value: 0.5), direction: TextDirection.rtl),
      );

      expect(await _pixel(tester, _right), isSameColorAs(arc));
      expect(await _pixel(tester, _left), isSameColorAs(track));
    });
  });

  group('semantics', () {
    testWidgets('one node with the label and the value, the drawing and the '
        'middle label excluded', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(_ring(value: 0.73, label: '11', semanticValue: '11 of 15 done')),
      );

      expect(_labels(tester), ['Chores']);
      final node = tester.getSemantics(find.bySemanticsLabel('Chores'));
      expect(node.value, '11 of 15 done');
      expect(find.bySemanticsLabel('11'), findsNothing);
      handle.dispose();
    });

    testWidgets('an in-use ring never exposes a value', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const AppProgressRing(semanticLabel: 'In use', semanticValue: '50%'),
          disableAnimations: true,
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('In use')).value,
        isEmpty,
      );
      handle.dispose();
    });

    testWidgets('a null label leaves the ring out of semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Semantics(
            container: true,
            label: 'Task in use',
            child: _ring(value: 0.5, label: '11', semanticLabel: null),
          ),
          disableAnimations: true,
        ),
      );

      expect(_labels(tester), ['Task in use']);
      expect(find.bySemanticsLabel('11'), findsNothing);
      handle.dispose();
    });

    testWidgets('merges into a parent that merges its children', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          MergeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Today'),
                _ring(value: 0.5, semanticValue: 'Half'),
              ],
            ),
          ),
        ),
      );

      final data = tester.getSemantics(find.text('Today')).getSemanticsData();
      expect(data.label, 'Today${String.fromCharCode(10)}Chores');
      expect(data.value, 'Half');
      handle.dispose();
    });

    testWidgets('in use has a label and no value', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(_ring(semanticLabel: 'In use'), disableAnimations: true),
      );

      final node = tester.getSemantics(find.bySemanticsLabel('In use'));
      expect(node.value, isEmpty);
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
            label: 'Today',
            child: _ring(value: 0.5, semanticValue: 'Half'),
          ),
        ),
      );

      expect(_labels(tester), containsAll(['Today', 'Chores']));
      expect(_labels(tester), isNot(contains('Today\nChores')));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Chores')).value,
        'Half',
      );
      handle.dispose();
    });
  });

  group('contrast', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;
      final surfaces = {
        'card': scheme.surfaceContainerLowest,
        'page': scheme.surface,
        'sunken': scheme.surfaceContainerHigh,
      };

      test('the arc reaches 3:1 on its track and on every surface ($name)', () {
        expectContrast(
          {
            for (final tone in AppRingTone.values) ...{
              '${tone.name} arc/track': (
                _colors(theme, tone).$2,
                _colors(theme, tone).$1,
              ),
              for (final surface in surfaces.entries)
                '${tone.name} arc/${surface.key}': (
                  _colors(theme, tone).$2,
                  surface.value,
                ),
            },
          },
          minimum: 3,
          reason: name,
        );
      });

      test('the middle label reaches 4.5:1 on every surface ($name)', () {
        expectContrast(
          {
            for (final surface in surfaces.entries)
              'onSurface/${surface.key}': (scheme.onSurface, surface.value),
          },
          minimum: 4.5,
          reason: name,
        );
      });
    }
  });

  group('large text', () {
    setUpAll(() async {
      // The real glyphs: without the bundled font a test draws every glyph
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

    testWidgets('the label is never scaled down and stays inside the ring', (
      tester,
    ) async {
      for (final label in ['5', '11', '100']) {
        await tester.pumpWidget(
          _host(_ring(value: 0.5, label: label), disableAnimations: true),
        );
        final base = tester.getSize(find.text(label));
        expect(
          tester.getSize(find.byType(AppProgressRing)),
          const Size.square(56),
        );

        for (final scale in [1.5, 2.0]) {
          await tester.pumpWidget(
            _host(
              _ring(value: 0.5, label: label),
              textScale: scale,
              disableAnimations: true,
            ),
          );

          final reason = '"$label" at ${scale}x';
          final ring = tester.getRect(find.byType(AppProgressRing));
          final text = tester.getRect(find.text(label));
          expect(text.height, closeTo(base.height * scale, 1), reason: reason);
          expect(text.width, closeTo(base.width * scale, 1.5), reason: reason);
          expect(ring.width, ring.height, reason: '$reason: still a circle');
          expect(
            ring.width,
            greaterThanOrEqualTo(AppSizes.ring),
            reason: reason,
          );
          final inner = ring.width / 2 - AppSizes.ringStroke;
          for (final corner in [
            text.topLeft,
            text.topRight,
            text.bottomLeft,
            text.bottomRight,
          ]) {
            expect(
              (corner - ring.center).distance,
              lessThanOrEqualTo(inner),
              reason: '$reason: $corner is inside the stroke',
            );
          }
        }
      }
    });

    testWidgets('the ring grows at 2.0 for a long label and nothing clips', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          _ring(value: 0.5, label: '100'),
          textScale: 2,
          disableAnimations: true,
        ),
      );

      expect(
        tester.getSize(find.byType(AppProgressRing)).width,
        greaterThan(AppSizes.ring),
      );
      expect(
        find.descendant(
          of: find.byType(AppProgressRing),
          matching: find.byType(ClipRect),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
