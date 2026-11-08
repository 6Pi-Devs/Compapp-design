import 'package:compapp_design/compapp_design.dart';
import 'package:flutter_test/flutter_test.dart';

CalendarEventView _view({
  String id = 'a',
  CalendarEventKind kind = CalendarEventKind.visit,
  String title = 'A',
}) => CalendarEventView(id: id, kind: kind, title: title);

void main() {
  test('two views with the same data are equal and hash alike', () {
    expect(_view(), _view());
    expect(_view().hashCode, _view().hashCode);
  });

  test('every field takes part in equality', () {
    for (final other in [
      _view(id: 'b'),
      _view(kind: CalendarEventKind.absence),
      _view(title: 'B'),
    ]) {
      expect(other, isNot(_view()));
    }
  });

  test('the kinds are visit, overnight, absence and other', () {
    expect(CalendarEventKind.values.map((kind) => kind.name), [
      'visit',
      'overnight',
      'absence',
      'other',
    ]);
  });
}
