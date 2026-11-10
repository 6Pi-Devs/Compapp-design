import 'package:compapp_design/src/foundation/dashed_border.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _side = BorderSide(color: Color(0xFF123456), width: 1.5);
const _radius = BorderRadius.all(Radius.circular(12));

List<Paint> _paints(ShapeBorder border, {TextDirection? textDirection}) {
  final canvas = TestRecordingCanvas();
  border.paint(
    canvas,
    const Rect.fromLTWH(0, 0, 120, 60),
    textDirection: textDirection,
  );
  return [
    for (final call in canvas.invocations)
      if (call.invocation.memberName == #drawPath)
        call.invocation.positionalArguments[1] as Paint,
  ];
}

/// The bounds of every dash [border] draws in a 120 x 60 box.
List<Rect> _dashes(ShapeBorder border, {TextDirection? textDirection}) {
  final canvas = TestRecordingCanvas();
  border.paint(
    canvas,
    const Rect.fromLTWH(0, 0, 120, 60),
    textDirection: textDirection,
  );
  return [
    for (final call in canvas.invocations)
      if (call.invocation.memberName == #drawPath)
        (call.invocation.positionalArguments[0] as Path).getBounds(),
  ];
}

void main() {
  group('DashedBorder', () {
    test('draws its side in dashes, not as one solid line', () {
      final paints = _paints(
        const DashedBorder(borderRadius: _radius, side: _side),
      );

      expect(paints.length, greaterThan(8));
      for (final paint in paints) {
        expect(paint.color.toARGB32(), _side.color.toARGB32());
        expect(paint.strokeWidth, _side.width);
        expect(paint.style, PaintingStyle.stroke);
      }
    });

    test('draws nothing when the side has no style', () {
      final paints = _paints(
        const DashedBorder(
          borderRadius: _radius,
          side: BorderSide(style: BorderStyle.none),
        ),
      );

      expect(paints, isEmpty);
    });

    test('copyWith keeps the dashes and changes only what it is given', () {
      const border = DashedBorder(borderRadius: _radius, side: _side);

      final other = border.copyWith(side: const BorderSide(width: 3));
      final same = border.copyWith();

      expect(other, isA<DashedBorder>());
      expect(other.side.width, 3);
      expect(other.borderRadius, _radius);
      expect(same, isA<DashedBorder>());
      expect(same.side, _side);
      expect(same.borderRadius, _radius);
    });

    test('scale keeps the dashes and scales the side and the radius', () {
      const border = DashedBorder(borderRadius: _radius, side: _side);

      final scaled = border.scale(2);

      expect(scaled, isA<DashedBorder>());
      expect((scaled as DashedBorder).side.width, 3);
      expect(scaled.borderRadius, _radius * 2);
    });

    test('stays inside its box: the outer edge of the stroke touches it', () {
      final dashes = _dashes(
        const DashedBorder(
          side: BorderSide(color: Color(0xFF123456), width: 2),
        ),
      );

      // The stroke centre is half of the width inside the box.
      expect(
        dashes.reduce((a, b) => a.expandToInclude(b)),
        const Rect.fromLTRB(1, 1, 119, 59),
      );
    });

    test('resolves a directional radius in the reading direction', () {
      const border = DashedBorder(
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(20),
        ),
        side: _side,
      );

      final ltr = _dashes(border, textDirection: TextDirection.ltr);
      final rtl = _dashes(border, textDirection: TextDirection.rtl);

      expect(ltr, isNotEmpty);
      expect(rtl, isNotEmpty);
      expect(
        rtl,
        isNot(ltr),
        reason: 'the rounded corner is on the other side',
      );
    });
  });
}
