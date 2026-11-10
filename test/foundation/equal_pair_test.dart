import 'package:compapp_design/src/foundation/equal_pair.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// The test font draws every glyph as a square of the font size, so the sizes
// below are exact: "ab cd" is 50 wide on one line and 20 wide at its longest
// word, "abcdef ghi" is 100 and 60.
const _fontSize = 10.0;
const _spacing = 8.0;
const _short = 'ab cd';
const _long = 'abcdef ghi';

Widget _text(String text, {Key? key}) => Text(
  text,
  key: key,
  style: const TextStyle(fontSize: _fontSize),
);

Widget _pair({
  required double width,
  TextDirection direction = TextDirection.ltr,
  double spacing = _spacing,
  List<Widget>? children,
}) {
  return Directionality(
    textDirection: direction,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
        child: EqualPair(
          spacing: spacing,
          textDirection: direction,
          children:
              children ??
              [
                _text(_short, key: const Key('first')),
                _text(_long, key: const Key('second')),
              ],
        ),
      ),
    ),
  );
}

Rect _rect(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(Key(key)));

RenderBox _box(WidgetTester tester) =>
    tester.renderObject<RenderBox>(find.byType(EqualPair));

void main() {
  group('layout', () {
    testWidgets('puts the children side by side as equal halves when each '
        'longest word fits its half', (tester) async {
      await tester.pumpWidget(_pair(width: 200));

      const half = (200 - _spacing) / 2;
      expect(_rect(tester, 'first').left, 0);
      expect(_rect(tester, 'first').width, half);
      expect(_rect(tester, 'second').left, half + _spacing);
      expect(_rect(tester, 'second').width, half);
      expect(_rect(tester, 'first').top, _rect(tester, 'second').top);
      expect(_box(tester).size, const Size(200, 2 * _fontSize));
    });

    testWidgets('stacks them, the first on top, when a longest word does not '
        'fit its half', (tester) async {
      await tester.pumpWidget(_pair(width: 100));

      expect(_rect(tester, 'first').top, 0);
      expect(_rect(tester, 'first').width, 100);
      expect(_rect(tester, 'second').width, 100);
      expect(
        _rect(tester, 'second').top,
        _rect(tester, 'first').bottom + _spacing,
      );
      expect(_box(tester).size, const Size(100, 28));
    });

    testWidgets('side by side the first child is at the right when the text '
        'reads right to left', (tester) async {
      await tester.pumpWidget(_pair(width: 200, direction: TextDirection.rtl));

      expect(_rect(tester, 'first').left, greaterThan(100));
      expect(_rect(tester, 'second').left, 0);
    });

    testWidgets('stacked it keeps the first child on top right to left', (
      tester,
    ) async {
      await tester.pumpWidget(_pair(width: 100, direction: TextDirection.rtl));

      expect(_rect(tester, 'first').top, 0);
      expect(_rect(tester, 'second').top, greaterThan(0));
    });

    testWidgets('lays out again when the spacing or the direction changes', (
      tester,
    ) async {
      await tester.pumpWidget(_pair(width: 200));
      await tester.pumpWidget(_pair(width: 200, spacing: 20));
      expect(_rect(tester, 'second').left, (200 - 20) / 2 + 20);

      await tester.pumpWidget(
        _pair(width: 200, spacing: 20, direction: TextDirection.rtl),
      );
      expect(_rect(tester, 'second').left, 0);
    });

    testWidgets('gives a further child the size and place of the child of '
        'its side', (tester) async {
      // At 60 the second side wraps, so the two sides differ in height.
      for (final width in [200.0, 60.0]) {
        await tester.pumpWidget(
          _pair(
            width: width,
            children: [
              _text(_short, key: const Key('first')),
              _text(_long, key: const Key('second')),
              _text('x', key: const Key('third')),
              _text('y', key: const Key('fourth')),
            ],
          ),
        );

        expect(_rect(tester, 'third'), _rect(tester, 'first'));
        expect(_rect(tester, 'fourth'), _rect(tester, 'second'));
      }
    });

    testWidgets('stacks at 127 wide and sits side by side at 128: the half '
        'is the width of the longest word', (tester) async {
      // The longest word is 60 wide, and the half is (width - 8) / 2.
      await tester.pumpWidget(_pair(width: 128));
      expect(_rect(tester, 'first').top, _rect(tester, 'second').top);
      expect(_rect(tester, 'first').width, 60);

      await tester.pumpWidget(_pair(width: 127));
      expect(
        _rect(tester, 'second').top,
        greaterThan(_rect(tester, 'first').top),
      );
      expect(_rect(tester, 'first').width, 127);
    });

    testWidgets('side by side both children get the height of the taller', (
      tester,
    ) async {
      // The short text is one line, the long one wraps to two.
      await tester.pumpWidget(_pair(width: 200));

      expect(_rect(tester, 'first').height, 2 * _fontSize);
      expect(_rect(tester, 'second').height, 2 * _fontSize);
    });

    testWidgets('lays out again when only its direction changes, under an '
        'unchanged Directionality', (tester) async {
      Widget pair(TextDirection direction) => Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 200,
            child: EqualPair(
              spacing: _spacing,
              textDirection: direction,
              children: [
                _text(_short, key: const Key('first')),
                _text(_long, key: const Key('second')),
              ],
            ),
          ),
        ),
      );

      await tester.pumpWidget(pair(TextDirection.ltr));
      expect(_rect(tester, 'first').left, 0);

      await tester.pumpWidget(pair(TextDirection.rtl));
      expect(_rect(tester, 'first').left, greaterThan(100));
      expect(_rect(tester, 'second').left, 0);
    });

    testWidgets('with no width limit each child gets the width of the widest '
        'and they sit side by side', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                EqualPair(
                  spacing: _spacing,
                  textDirection: TextDirection.ltr,
                  children: [
                    _text(_short, key: const Key('first')),
                    _text(_long, key: const Key('second')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(_rect(tester, 'first').width, 100);
      expect(_rect(tester, 'second').left, 100 + _spacing);
      expect(_rect(tester, 'second').width, 100);
      expect(_box(tester).size, const Size(208, _fontSize));
    });

    test('needs two children', () {
      expect(
        () => EqualPair(
          spacing: _spacing,
          textDirection: TextDirection.ltr,
          children: [_text(_short)],
        ),
        throwsAssertionError,
      );
    });

    testWidgets('passes taps to the child under the pointer', (tester) async {
      final taps = <String>[];
      Widget tappable(String key) => GestureDetector(
        key: Key(key),
        behavior: HitTestBehavior.opaque,
        onTap: () => taps.add(key),
        child: const SizedBox(height: 20),
      );
      await tester.pumpWidget(
        _pair(width: 200, children: [tappable('first'), tappable('second')]),
      );

      await tester.tapAt(const Offset(10, 5));
      await tester.tapAt(const Offset(190, 5));

      expect(taps, ['first', 'second']);
    });
  });

  group('intrinsic sizes', () {
    testWidgets('its least width is that of the longest word of either child', (
      tester,
    ) async {
      await tester.pumpWidget(_pair(width: 200));

      expect(_box(tester).getMinIntrinsicWidth(double.infinity), 60);
    });

    testWidgets('its largest width is two of the widest child and the '
        'spacing', (tester) async {
      await tester.pumpWidget(_pair(width: 200));

      expect(_box(tester).getMaxIntrinsicWidth(double.infinity), 208);
    });

    testWidgets('its height at a width is the height it lays out at', (
      tester,
    ) async {
      for (final (width, height) in [
        (200.0, 20.0),
        (100.0, 28.0),
        (60.0, 38.0),
      ]) {
        await tester.pumpWidget(_pair(width: width));
        final box = _box(tester);

        expect(box.size.height, height, reason: 'laid out at $width');
        expect(box.getMinIntrinsicHeight(width), height);
        expect(box.getMaxIntrinsicHeight(width), height);
      }
    });

    testWidgets('its dry layout is the size it lays out at', (tester) async {
      for (final width in [200.0, 150.0, 100.0, 60.0]) {
        await tester.pumpWidget(_pair(width: width));
        final box = _box(tester);

        expect(box.getDryLayout(box.constraints), box.size);
        expect(
          box.getDryLayout(BoxConstraints(maxWidth: width)),
          box.size,
          reason: 'at $width',
        );
      }
    });

    testWidgets('at its largest width it is side by side, at its least '
        'stacked, and more room makes it no shorter', (tester) async {
      await tester.pumpWidget(_pair(width: 400));
      final box = _box(tester);
      final widest = box.getMaxIntrinsicWidth(double.infinity);
      final least = box.getMinIntrinsicWidth(double.infinity);

      await tester.pumpWidget(_pair(width: widest));
      final snug = _box(tester).size.height;
      expect(_rect(tester, 'first').top, _rect(tester, 'second').top);
      expect(snug, _fontSize, reason: 'nothing wraps');

      await tester.pumpWidget(_pair(width: widest + 200));
      expect(_box(tester).size.height, snug);

      await tester.pumpWidget(_pair(width: least));
      expect(
        _rect(tester, 'second').top,
        greaterThanOrEqualTo(_rect(tester, 'first').bottom),
      );
    });

    testWidgets('can be measured by intrinsic sizing', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: IntrinsicWidth(
              child: IntrinsicHeight(
                child: EqualPair(
                  spacing: _spacing,
                  textDirection: TextDirection.ltr,
                  children: [_text(_short), _text(_long)],
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(_box(tester).size, const Size(208, _fontSize));
    });
  });
}
