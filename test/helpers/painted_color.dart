import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The color really painted at [point] (in the coordinates of the
/// [RepaintBoundary] with [boundaryKey]), read from the rendered pixels.
///
/// flutter_test draws text with a font whose glyphs are solid squares, so the
/// pixel at the middle of a text is its color after every layer on top of it.
Future<Color> paintedColorAt(
  WidgetTester tester,
  Key boundaryKey,
  Offset point,
) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(boundaryKey),
  );
  final color = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = (await image.toByteData())!;
    final offset = (point.dy.round() * image.width + point.dx.round()) * 4;
    return Color.fromARGB(
      data.getUint8(offset + 3),
      data.getUint8(offset),
      data.getUint8(offset + 1),
      data.getUint8(offset + 2),
    );
  });
  return color!;
}

/// [paintedColorAt] the center of [finder].
Future<Color> paintedColorAtCenter(
  WidgetTester tester,
  Key boundaryKey,
  Finder finder,
) => paintedColorAt(
  tester,
  boundaryKey,
  tester.getCenter(finder) - tester.getTopLeft(find.byKey(boundaryKey)),
);
