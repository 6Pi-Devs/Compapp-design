import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_parsing/path_parsing.dart';

void main() {
  test('defines the 30 glyphs of the Atoms board', () {
    expect(AppIcons.values, hasLength(30));
  });

  test('every glyph has its own path data', () {
    final paths = AppIcons.values.map((icon) => icon.pathData).toSet();
    expect(paths, hasLength(AppIcons.values.length));
  });

  test('only the directional glyphs mirror in right-to-left text', () {
    final mirrored = AppIcons.values
        .where((icon) => icon.matchTextDirection)
        .toSet();

    expect(mirrored, {AppIcons.back, AppIcons.forward, AppIcons.signOut});
  });

  for (final icon in AppIcons.values) {
    test('${icon.name} parses and stays inside the grid', () {
      final builder = _PathBuilder();
      writeSvgPathDataToPath(icon.pathData, builder);

      final bounds = builder.path.getBounds();
      expect(bounds.isEmpty, isFalse);
      expect(
        bounds,
        _within(
          const Rect.fromLTWH(0, 0, AppIcons.gridSize, AppIcons.gridSize),
        ),
      );
    });
  }
}

Matcher _within(Rect grid) => predicate<Rect>(
  (bounds) =>
      bounds.left >= grid.left &&
      bounds.top >= grid.top &&
      bounds.right <= grid.right &&
      bounds.bottom <= grid.bottom,
  'inside $grid',
);

class _PathBuilder implements PathProxy {
  final Path path = Path();

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}
