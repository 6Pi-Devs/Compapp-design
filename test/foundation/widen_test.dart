import 'package:compapp_design/src/foundation/widen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _column(double width) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      key: const Key('column'),
      width: width,
      child: const Widen(
        minWidth: 48,
        child: SizedBox(key: Key('child'), height: 20),
      ),
    ),
  ),
);

void main() {
  testWidgets('a narrow column gives its child the least width, centered', (
    tester,
  ) async {
    await tester.pumpWidget(_column(40));

    final column = tester.getRect(find.byKey(const Key('column')));
    final child = tester.getRect(find.byKey(const Key('child')));
    expect(column.width, 40);
    expect(child.width, 48);
    expect(child.center.dx, column.center.dx);
    expect(tester.getSize(find.byType(Widen)), const Size(40, 20));
  });

  testWidgets('a wide column gives its child its whole width', (tester) async {
    await tester.pumpWidget(_column(60));

    expect(tester.getSize(find.byKey(const Key('child'))).width, 60);
  });

  testWidgets('measures the intrinsic widths of its child', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: IntrinsicWidth(
            child: Widen(
              minWidth: 48,
              child: SizedBox(key: Key('child'), width: 30, height: 10),
            ),
          ),
        ),
      ),
    );

    final widen = tester.renderObject<RenderBox>(find.byType(Widen));
    expect(widen.getMaxIntrinsicWidth(double.infinity), 30);
    expect(widen.getMinIntrinsicHeight(10), 10);
  });
}
