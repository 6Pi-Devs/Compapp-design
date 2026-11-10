import 'dart:ui';

import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design/src/foundation/dashed_outline_painter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _color = Color(0xFF123456);

List<Paint> _paints(DashedOutlinePainter painter, Size size) {
  final canvas = TestRecordingCanvas();
  painter.paint(canvas, size);
  return [
    for (final call in canvas.invocations)
      if (call.invocation.memberName == #drawPath)
        call.invocation.positionalArguments[1] as Paint,
  ];
}

void main() {
  group('DashedOutlinePainter', () {
    test('draws dashes in the color, as wide as the dashed border token', () {
      final paints = _paints(
        const DashedOutlinePainter(color: _color, radius: 8),
        const Size(80, 60),
      );

      expect(paints.length, greaterThan(8));
      for (final paint in paints) {
        expect(paint.color.toARGB32(), _color.toARGB32());
        expect(paint.style, PaintingStyle.stroke);
        expect(paint.strokeWidth, AppSizes.borderDashed);
      }
    });

    test('needs a positive width', () {
      expect(
        () => DashedOutlinePainter(color: _color, radius: 8, width: 0),
        throwsAssertionError,
      );
    });

    test('draws with the width it is given', () {
      final paints = _paints(
        const DashedOutlinePainter(color: _color, radius: 8, width: 3),
        const Size(80, 60),
      );

      expect(paints, isNotEmpty);
      expect(paints.every((paint) => paint.strokeWidth == 3), isTrue);
    });

    test('stays inside the box: the outer edge of the stroke touches it', () {
      final canvas = TestRecordingCanvas();
      const DashedOutlinePainter(
        color: _color,
        radius: 0,
        width: 2,
      ).paint(canvas, const Size(80, 60));

      final bounds = [
        for (final call in canvas.invocations)
          if (call.invocation.memberName == #drawPath)
            (call.invocation.positionalArguments[0] as Path).getBounds(),
      ].reduce((a, b) => a.expandToInclude(b));

      // The stroke centre is half of the width inside the box.
      expect(bounds, const Rect.fromLTRB(1, 1, 79, 59));
    });

    test('repaints only when the color, the radius or the width change', () {
      const painter = DashedOutlinePainter(color: _color, radius: 8);

      expect(
        painter.shouldRepaint(
          const DashedOutlinePainter(color: _color, radius: 8),
        ),
        isFalse,
      );
      expect(
        painter.shouldRepaint(
          const DashedOutlinePainter(color: Color(0xFF654321), radius: 8),
        ),
        isTrue,
      );
      expect(
        painter.shouldRepaint(
          const DashedOutlinePainter(color: _color, radius: 9),
        ),
        isTrue,
      );
      expect(
        painter.shouldRepaint(
          const DashedOutlinePainter(color: _color, radius: 8, width: 2),
        ),
        isTrue,
      );
    });
  });
}
