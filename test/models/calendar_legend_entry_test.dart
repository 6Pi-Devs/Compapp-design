import 'package:compapp_design/compapp_design.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('two entries with the same data are equal and hash alike', () {
    const a = CalendarLegendEntry(kind: CalendarEventKind.visit, label: 'V');
    const b = CalendarLegendEntry(kind: CalendarEventKind.visit, label: 'V');
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('every field takes part in equality', () {
    const base = CalendarLegendEntry(kind: CalendarEventKind.visit, label: 'V');
    for (final other in const [
      CalendarLegendEntry(kind: CalendarEventKind.absence, label: 'V'),
      CalendarLegendEntry(kind: CalendarEventKind.visit, label: 'W'),
    ]) {
      expect(other, isNot(base));
    }
  });

  test('needs a label', () {
    expect(
      () => CalendarLegendEntry(kind: CalendarEventKind.visit, label: ''),
      throwsAssertionError,
    );
  });
}
