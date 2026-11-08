import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(bool initial) => MaterialApp(
  home: Scaffold(
    body: SeededState<bool>(
      initial: initial,
      builder: (context, value, onChanged) =>
          Switch(value: value, onChanged: onChanged),
    ),
  ),
);

bool _switchValue(WidgetTester tester) =>
    tester.widget<Switch>(find.byType(Switch)).value;

void main() {
  testWidgets('SeededState starts with the initial value', (tester) async {
    await tester.pumpWidget(_host(true));

    expect(_switchValue(tester), isTrue);
  });

  testWidgets('interaction drives the state', (tester) async {
    await tester.pumpWidget(_host(false));
    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(_switchValue(tester), isTrue);
  });

  testWidgets('a rebuild with the same initial keeps the interaction', (
    tester,
  ) async {
    await tester.pumpWidget(_host(false));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pumpWidget(_host(false));

    expect(_switchValue(tester), isTrue);
  });

  testWidgets('a new initial value from the knob resets the state', (
    tester,
  ) async {
    await tester.pumpWidget(_host(false));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pumpWidget(_host(true));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(_switchValue(tester), isFalse);

    await tester.pumpWidget(_host(false));
    expect(_switchValue(tester), isFalse, reason: 'reset to the new initial');
  });
}
