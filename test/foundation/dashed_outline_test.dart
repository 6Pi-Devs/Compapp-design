import 'dart:ui';

import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design/src/foundation/dashed_outline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _color = Color(0xFF123456);

/// What [paintDashedOutline] draws for [outline]: the paths and their paints.
List<(Path, Paint)> _draw(RRect outline, {required double width}) {
  final canvas = TestRecordingCanvas();
  paintDashedOutline(canvas, outline, color: _color, width: width);
  return [
    for (final call in canvas.invocations)
      if (call.invocation.memberName == #drawPath)
        (
          call.invocation.positionalArguments[0] as Path,
          call.invocation.positionalArguments[1] as Paint,
        ),
  ];
}

double _length(Path path) =>
    path.computeMetrics().fold<double>(0, (sum, metric) => sum + metric.length);

void main() {
  group('paintDashedOutline', () {
    test('draws one segment of a dash every period along the outline', () {
      // 98 x 48 around the centre of a 2 wide stroke: 292 long, a dash of 8
      // and a period of 14, so the last dash starts at 280 and is whole.
      final drawn = _draw(
        RRect.fromRectAndRadius(const Rect.fromLTWH(1, 1, 98, 48), Radius.zero),
        width: 2,
      );

      expect(drawn, hasLength(21));
      for (final (path, _) in drawn) {
        expect(
          _length(path),
          moreOrLessEquals(2 * AppSizes.dash, epsilon: 1e-3),
        );
      }
    });

    test('cuts the last dash at the end of the outline', () {
      // 99 x 49 around a 1 wide stroke: 296 long, a dash of 4 and a period
      // of 7, so the last dash starts at 294 and has 2 left.
      final drawn = _draw(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0.5, 0.5, 99, 49),
          Radius.zero,
        ),
        width: 1,
      );

      expect(drawn, hasLength(43));
      expect(_length(drawn.last.$1), moreOrLessEquals(2, epsilon: 1e-3));
      expect(
        drawn.fold<double>(0, (sum, segment) => sum + _length(segment.$1)),
        moreOrLessEquals(42 * AppSizes.dash + 2, epsilon: 1e-3),
      );
    });

    test('draws no empty segment when the outline is a whole number of '
        'periods long', () {
      // 98 x 49 sharp rect: 294 long, 42 periods of 7 (width 1).
      final drawn = _draw(
        RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 98, 49), Radius.zero),
        width: 1,
      );

      expect(drawn, hasLength(42));
    });

    test('scales the dash and the gap with the width of the stroke', () {
      final outline = RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 100, 50),
        const Radius.circular(10),
      );

      final thin = _draw(outline, width: 1);
      final thick = _draw(outline, width: 2);

      expect(thick.length, lessThan(thin.length));
      expect(
        _length(thick.first.$1),
        moreOrLessEquals(2 * AppSizes.dash, epsilon: 1e-3),
      );
      expect(
        _length(thin.first.$1),
        moreOrLessEquals(AppSizes.dash, epsilon: 1e-3),
      );
    });

    test('strokes every segment with the color and the width', () {
      final drawn = _draw(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 100, 50),
          const Radius.circular(10),
        ),
        width: AppSizes.borderDashed,
      );

      expect(drawn, isNotEmpty);
      for (final (_, paint) in drawn) {
        expect(paint.color.toARGB32(), _color.toARGB32());
        expect(paint.style, PaintingStyle.stroke);
        expect(paint.strokeCap, StrokeCap.butt, reason: 'dashes end square');
        expect(paint.strokeWidth, AppSizes.borderDashed);
      }
    });

    test('leaves a gap between two segments', () {
      final drawn = _draw(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 200, 40),
          Radius.zero,
        ),
        width: 2,
      );

      // The first two dashes lie on the same straight edge: 8 long, then a
      // gap of 6 before the next.
      final first = drawn[0].$1.getBounds();
      final second = drawn[1].$1.getBounds();
      final gap = first.top >= second.bottom
          ? first.top - second.bottom
          : second.top - first.bottom;
      expect(gap, moreOrLessEquals(2 * AppSizes.dashGap, epsilon: 1e-3));
    });
  });
}
