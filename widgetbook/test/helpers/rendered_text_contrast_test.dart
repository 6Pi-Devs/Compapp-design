import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendered_text_contrast.dart';

const _key = Key('boundary');

const white = Color(0xFFFFFFFF);
const ink = Color(0xFF1C2B22);
const pale = Color(0xFFCFD8CC);

/// A page of [page] with [child] on it, inside the boundary the check reads.
Widget _host(Widget child, {Color page = white, double padding = 24}) =>
    MaterialApp(
      theme: ThemeData(scaffoldBackgroundColor: page),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: _key,
            child: Padding(padding: EdgeInsets.all(padding), child: child),
          ),
        ),
      ),
    );

Widget _chip(Color fill, Color ink, {String text = 'Hello'}) => DecoratedBox(
  decoration: BoxDecoration(color: fill),
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Text(text, style: TextStyle(color: ink, fontSize: 14)),
  ),
);

Widget _badge(Color fill, Color text) => DecoratedBox(
  decoration: BoxDecoration(color: fill),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Text('3', style: TextStyle(color: text, fontSize: 11, height: 1)),
  ),
);

Future<List<String>> _check(WidgetTester tester, {Color page = white}) =>
    lowContrastTexts(tester, _key, page: page);

/// Paints a [color] rectangle behind its child with a custom painter, which
/// the render tree cannot read as a fill.
class _Painted extends CustomPainter {
  const new(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) =>
      canvas.drawRect(Offset.zero & size, Paint()..color = color);

  @override
  bool shouldRepaint(_Painted oldDelegate) => oldDelegate.color != color;
}

void main() {
  group('passes', () {
    testWidgets('a dark text on a light fill', (tester) async {
      await tester.pumpWidget(_host(_chip(white, ink)));

      expect(await _check(tester), isEmpty);
    });

    testWidgets('a pale text on a dark page', (tester) async {
      await tester.pumpWidget(
        _host(
          const Text('Plain', style: TextStyle(color: pale, fontSize: 14)),
          page: ink,
        ),
      );

      expect(await _check(tester, page: ink), isEmpty);
    });

    testWidgets('an ink text on a light page', (tester) async {
      await tester.pumpWidget(
        _host(const Text('Plain', style: TextStyle(color: ink, fontSize: 14))),
      );

      expect(await _check(tester), isEmpty);
    });

    testWidgets('a text on a dark fill', (tester) async {
      await tester.pumpWidget(_host(_chip(ink, white)));

      expect(await _check(tester), isEmpty);
    });

    testWidgets('a tight badge is read on its fill, not on the page', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_badge(ink, white)));

      expect(await _check(tester), isEmpty);
    });

    testWidgets('texts one under the other', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Title', style: TextStyle(color: ink, fontSize: 14)),
              Text('Below', style: TextStyle(color: ink, fontSize: 14)),
            ],
          ),
        ),
      );

      expect(await _check(tester), isEmpty);
    });

    testWidgets('a text painted with a foreground paint', (tester) async {
      await tester.pumpWidget(
        _host(
          Text(
            'Painted',
            style: TextStyle(foreground: Paint()..color = ink, fontSize: 14),
          ),
        ),
      );

      expect(await _check(tester), isEmpty);
    });

    testWidgets('an ink text under an opacity of 0 is judged as opaque', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Opacity(
            opacity: 0,
            child: Text('Hidden', style: TextStyle(color: ink, fontSize: 14)),
          ),
        ),
      );

      expect(await _check(tester), isEmpty);
    });

    testWidgets('a pale text on a dark colored box', (tester) async {
      await tester.pumpWidget(
        _host(
          const ColoredBox(
            color: ink,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Text('Hello', style: TextStyle(color: pale, fontSize: 14)),
            ),
          ),
        ),
      );

      expect(await _check(tester), isEmpty);
    });

    testWidgets('a text that is fully opaque', (tester) async {
      await tester.pumpWidget(
        _host(
          const Opacity(
            opacity: 1,
            child: Text('Plain', style: TextStyle(color: ink, fontSize: 14)),
          ),
        ),
      );

      expect(await _check(tester), isEmpty);
    });

    testWidgets('a text on a custom painted fill, read from the pixels', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CustomPaint(
            painter: _Painted(ink),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Hello',
                style: TextStyle(color: white, fontSize: 14),
              ),
            ),
          ),
        ),
      );

      expect(await _check(tester), isEmpty);
    });
  });

  group('fails', () {
    testWidgets('a pale text on a light fill', (tester) async {
      await tester.pumpWidget(_host(_chip(white, pale)));

      final failures = await _check(tester);

      expect(failures, hasLength(1));
      expect(failures.single, contains('Hello'));
    });

    testWidgets('a text whose semantics label hides it', (tester) async {
      await tester.pumpWidget(
        _host(
          Semantics(
            label: 'Spoken',
            excludeSemantics: true,
            child: _chip(white, pale),
          ),
        ),
      );

      expect(await _check(tester), hasLength(1));
    });

    testWidgets('an ink text on an ink fill', (tester) async {
      await tester.pumpWidget(_host(_chip(ink, ink)));

      expect(await _check(tester), hasLength(1));
    });

    testWidgets('a text with a faint alpha', (tester) async {
      await tester.pumpWidget(_host(_chip(white, ink.withValues(alpha: 0.2))));

      expect(await _check(tester), hasLength(1));
    });

    testWidgets('a pale text on a tight white badge on a dark page', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_badge(white, pale), page: ink));

      final failures = await _check(tester, page: ink);

      expect(failures, hasLength(1));
      expect(failures.single, contains('fill'));
    });

    testWidgets('a pale text right after an ink glyph', (tester) async {
      await tester.pumpWidget(
        _host(
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('A', style: TextStyle(color: ink, fontSize: 14)),
              Text('b', style: TextStyle(color: pale, fontSize: 14)),
            ],
          ),
        ),
      );

      final failures = await _check(tester);

      expect(failures, hasLength(1));
      expect(failures.single, contains('"b"'));
    });

    testWidgets('a pale caption right under a 2 px ink rule', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 80, height: 2, child: ColoredBox(color: ink)),
              Text('Caption', style: TextStyle(color: pale, fontSize: 14)),
            ],
          ),
        ),
      );

      final failures = await _check(tester);

      expect(failures, hasLength(1));
      expect(failures.single, contains('Caption'));
    });

    testWidgets('an ink text under an opacity of 0.2', (tester) async {
      await tester.pumpWidget(
        _host(
          const Opacity(
            opacity: 0.2,
            child: Text('Faded', style: TextStyle(color: ink, fontSize: 14)),
          ),
        ),
      );

      expect(await _check(tester), hasLength(1));
    });

    testWidgets('an ink text under an animated opacity of 0.2', (tester) async {
      await tester.pumpWidget(
        _host(
          const AnimatedOpacity(
            opacity: 0.2,
            duration: Duration.zero,
            child: Text('Faded', style: TextStyle(color: ink, fontSize: 14)),
          ),
        ),
      );
      await tester.pump();

      expect(await _check(tester), hasLength(1));
    });

    testWidgets('a pale text painted with a foreground paint', (tester) async {
      await tester.pumpWidget(
        _host(
          Text(
            'Painted',
            style: TextStyle(foreground: Paint()..color = pale, fontSize: 14),
          ),
        ),
      );

      final failures = await _check(tester);

      expect(failures, hasLength(1));
      expect(failures.single, contains('Painted'));
    });

    testWidgets('a text painted with a shader: its color is unknown', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Text(
            'Shaded',
            style: TextStyle(
              foreground: Paint()
                ..shader = const LinearGradient(colors: [ink, pale])
                    .createShader(const Rect.fromLTWH(0, 0, 40, 10)),
              fontSize: 14,
            ),
          ),
        ),
      );

      final failures = await _check(tester);

      expect(failures, hasLength(1));
      expect(failures.single, contains('cannot be determined'));
    });

    testWidgets('a text with no color: it is reported, not skipped', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const DefaultTextStyle(
            style: TextStyle(),
            child: Text('Bare', style: TextStyle(inherit: false, fontSize: 14)),
          ),
        ),
      );

      final failures = await _check(tester);

      expect(failures, hasLength(1));
      expect(failures.single, contains('cannot be determined'));
    });

    testWidgets('a text with no fill and no usable sample is reported, not '
        'skipped', (tester) async {
      await tester.pumpWidget(
        _host(
          const CustomPaint(
            painter: _Painted(ink),
            child: Text('Hello', style: TextStyle(color: white, fontSize: 14)),
          ),
          padding: 0,
        ),
      );

      final failures = await _check(tester);

      expect(failures, hasLength(1));
      expect(failures.single, contains('cannot be determined'));
    });

    testWidgets('a pale text under a fully transparent ancestor', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Opacity(
            opacity: 0,
            child: Text('Hidden', style: TextStyle(color: pale, fontSize: 14)),
          ),
        ),
      );

      final failures = await _check(tester);

      expect(failures, hasLength(1));
      expect(failures.single, contains('Hidden'));
    });

    testWidgets('a pale text that is about to fade in, at its first frame', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FadeTransition(
            opacity: AlwaysStoppedAnimation<double>(0),
            child: Text('Fading', style: TextStyle(color: pale, fontSize: 14)),
          ),
        ),
      );

      final failures = await _check(tester);

      expect(failures, hasLength(1));
      expect(failures.single, contains('Fading'));
    });

    testWidgets('an ink text on a dark colored box: pins the detection of the '
        'colored box', (tester) async {
      await tester.pumpWidget(
        _host(
          const ColoredBox(
            color: ink,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Text('Hello', style: TextStyle(color: ink, fontSize: 14)),
            ),
          ),
        ),
      );

      final failures = await _check(tester);

      expect(failures, hasLength(1));
      expect(failures.single, contains('fill'));
    });

    testWidgets('an ink text over a colored box that a sibling paints in a '
        'stack', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 120,
            height: 40,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: ink)),
                Positioned(
                  left: 20,
                  top: 8,
                  child: Text(
                    'Over',
                    style: TextStyle(color: ink, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final failures = await _check(tester);

      expect(failures, hasLength(1));
      expect(failures.single, contains('pixels'));
    });

    testWidgets('a pale hint over a field fill that a sibling painter draws', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 120,
            height: 40,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _Painted(white))),
                Positioned(
                  left: 20,
                  top: 8,
                  child: Text(
                    'Hint',
                    style: TextStyle(color: pale, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          page: ink,
        ),
      );

      final failures = await _check(tester, page: ink);

      expect(failures, hasLength(1));
      expect(failures.single, contains('Hint'));
    });

    testWidgets('a pale text on a custom painted fill', (tester) async {
      await tester.pumpWidget(
        _host(
          const CustomPaint(
            painter: _Painted(white),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Text('Hello', style: TextStyle(color: pale, fontSize: 14)),
            ),
          ),
        ),
      );

      final failures = await _check(tester);

      expect(failures, hasLength(1));
      expect(failures.single, contains('pixels'));
    });

    testWidgets(
      'a pale text with the dark page on one side and a white fill on the '
      'other reads the worse one',
      (tester) async {
        await tester.pumpWidget(
          _host(
            const CustomPaint(
              painter: _Painted(white),
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 4, 40, 4),
                child: Text(
                  'Hello',
                  style: TextStyle(color: pale, fontSize: 14),
                ),
              ),
            ),
            page: ink,
          ),
        );

        expect(await _check(tester, page: ink), hasLength(1));
      },
    );
  });

  testWidgets('checks every text of a tree', (tester) async {
    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _chip(white, ink),
            _chip(white, pale, text: 'Second'),
          ],
        ),
      ),
    );

    final failures = await _check(tester);

    expect(failures, hasLength(1));
    expect(failures.single, contains('Second'));
  });
}
