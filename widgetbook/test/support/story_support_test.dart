import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FrozenMotion disables animations for its subtree', (
    tester,
  ) async {
    late bool seen;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: FrozenMotion(
          child: Builder(
            builder: (context) {
              seen = MediaQuery.disableAnimationsOf(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(seen, isTrue);
  });

  testWidgets('StatesControllerHost holds the states it is given', (
    tester,
  ) async {
    late WidgetStatesController seen;
    await tester.pumpWidget(
      StatesControllerHost(
        states: const {WidgetState.pressed},
        builder: (context, controller) {
          seen = controller;
          return const SizedBox();
        },
      ),
    );

    expect(seen.value, {WidgetState.pressed});
  });

  testWidgets('StatesControllerHost disposes its controller', (tester) async {
    late WidgetStatesController seen;
    await tester.pumpWidget(
      StatesControllerHost(
        states: const {WidgetState.pressed},
        builder: (context, controller) {
          seen = controller;
          return const SizedBox();
        },
      ),
    );
    await tester.pumpWidget(const SizedBox());

    expect(() => seen.addListener(() {}), throwsFlutterError);
  });

  testWidgets('useCaseFrame pads by AppSpacing.md', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: useCaseFrame(child: const SizedBox.square(dimension: 10)),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(Padding).first),
      const Size.square(10 + AppSpacing.md * 2),
    );
  });
}
