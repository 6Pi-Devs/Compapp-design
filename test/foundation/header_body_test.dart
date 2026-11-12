import 'package:compapp_design/src/foundation/header_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _headerKey = Key('header');
const _bodyKey = Key('body');

/// A [HeaderBody] of a header [headerHeight] tall over a body [bodyHeight]
/// tall, scrolled by a `Scrollable` as the sheets do, in a box [maxHeight]
/// tall (unbounded when null).
Widget _host({
  required double headerHeight,
  required double bodyHeight,
  double? maxHeight,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 200,
          maxWidth: 200,
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: Scrollable(
          viewportBuilder: (context, position) => HeaderBody(
            offset: position,
            header: SizedBox(key: _headerKey, height: headerHeight),
            body: SingleChildScrollView(
              child: ColoredBox(
                color: const Color(0xFF000000),
                child: SizedBox(key: _bodyKey, height: bodyHeight),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('without a height bound it is a column of its two children', (
    tester,
  ) async {
    await tester.pumpWidget(_host(headerHeight: 80, bodyHeight: 300));

    expect(tester.getSize(find.byType(HeaderBody)), const Size(200, 380));
    expect(tester.getTopLeft(find.byKey(_bodyKey)).dy, 80);
  });

  testWidgets('a header that fits pins and the body takes the rest', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(headerHeight: 100, bodyHeight: 900, maxHeight: 400),
    );

    expect(tester.getSize(find.byType(HeaderBody)).height, 400);
    expect(
      tester.getSize(find.byType(SingleChildScrollView)).height,
      300,
      reason: 'the body gets what the header leaves',
    );

    await tester.dragFrom(const Offset(100, 300), const Offset(0, -150));
    await tester.pump();

    expect(
      tester.getTopLeft(find.byKey(_headerKey)).dy,
      0,
      reason: 'the header stays pinned',
    );
    expect(tester.getTopLeft(find.byKey(_bodyKey)).dy, 100 - 150);
  });

  testWidgets('a header of exactly half is still pinned', (tester) async {
    await tester.pumpWidget(
      _host(headerHeight: 200, bodyHeight: 900, maxHeight: 400),
    );

    expect(tester.getSize(find.byType(SingleChildScrollView)).height, 200);
  });

  testWidgets('a header taller than half scrolls together with the body', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(headerHeight: 250, bodyHeight: 300, maxHeight: 400),
    );

    expect(tester.getSize(find.byType(HeaderBody)).height, 400);
    expect(
      tester.getSize(find.byType(SingleChildScrollView)).height,
      300,
      reason: 'the body takes its own height',
    );

    await tester.dragFrom(const Offset(100, 350), const Offset(0, -100));
    await tester.pump();

    expect(tester.getTopLeft(find.byKey(_headerKey)).dy, -100);
    expect(tester.getTopLeft(find.byKey(_bodyKey)).dy, 250 - 100);
  });

  testWidgets('dry layout and intrinsic sizes agree with the real layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: IntrinsicHeight(
            child: IntrinsicWidth(
              child: Scrollable(
                viewportBuilder: (context, position) => HeaderBody(
                  offset: position,
                  header: const SizedBox(width: 120, height: 40),
                  body: const SizedBox(width: 180, height: 60),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(HeaderBody)), const Size(180, 100));
    final render = tester.renderObject<RenderBox>(find.byType(HeaderBody));
    expect(
      render.getDryLayout(const BoxConstraints(maxWidth: 180)),
      const Size(180, 100),
    );
  });
}
