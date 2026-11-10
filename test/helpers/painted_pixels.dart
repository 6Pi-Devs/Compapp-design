import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every pixel really painted inside [region] (in the coordinates of the
/// [RepaintBoundary] with [boundaryKey]), or in the whole boundary when
/// [region] is null, read from the rendered image.
///
/// It answers "is this color painted here at all", which a glyph or a border
/// needs: unlike a text drawn with the test font, a stroke has no known pixel
/// to probe.
Future<List<Color>> paintedPixels(
  WidgetTester tester,
  Key boundaryKey, {
  Rect? region,
}) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(boundaryKey),
  );
  final pixels = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = (await image.toByteData())!;
    final area =
        (region ??
                Offset.zero &
                    Size(image.width.toDouble(), image.height.toDouble()))
            .intersect(
              Offset.zero &
                  Size(image.width.toDouble(), image.height.toDouble()),
            );
    return [
      for (var y = area.top.floor(); y < area.bottom.ceil(); y++)
        for (var x = area.left.floor(); x < area.right.ceil(); x++)
          Color.fromARGB(
            data.getUint8((y * image.width + x) * 4 + 3),
            data.getUint8((y * image.width + x) * 4),
            data.getUint8((y * image.width + x) * 4 + 1),
            data.getUint8((y * image.width + x) * 4 + 2),
          ),
    ];
  });
  return pixels!;
}

/// How many of [pixels] are [color], up to a rounding of one level per
/// channel. Only the red, green and blue channels are compared, as read from
/// the image: `toByteData` gives them premultiplied by the alpha, so a pixel
/// that is partly transparent has darker channels and does not match, and a
/// pixel of an opaque fill matches when it is that color. The alpha itself is
/// not compared. Anti-aliasing blends over a fill have another color and never
/// match.
int countPixels(List<Color> pixels, Color color) => pixels
    .where(
      (pixel) =>
          _close(pixel.r, color.r) &&
          _close(pixel.g, color.g) &&
          _close(pixel.b, color.b),
    )
    .length;

bool _close(double a, double b) => (a - b).abs() <= 1.5 / 255;

/// How close the nearest of [pixels] gets to [color], as the distance between
/// the two in the cube of red, green and blue (0 to about 1.7). A thin stroke
/// is anti-aliased and may have no solid pixel, but its core is still near the
/// color it is drawn in.
double closestColorDistance(List<Color> pixels, Color color) => pixels
    .map(
      (pixel) => math.sqrt(
        math.pow(pixel.r - color.r, 2) +
            math.pow(pixel.g - color.g, 2) +
            math.pow(pixel.b - color.b, 2),
      ),
    )
    .reduce(math.min);
