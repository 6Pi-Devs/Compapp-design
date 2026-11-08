import 'package:compapp_design/compapp_design.dart';
import 'package:flutter_test/flutter_test.dart';

TaskView _view({String id = 'a', String title = 'A', int ageDays = 3}) =>
    TaskView(id: id, title: title, ageDays: ageDays);

void main() {
  test('two views with the same data are equal and hash alike', () {
    expect(_view(), _view());
    expect(_view().hashCode, _view().hashCode);
  });

  test('every field takes part in equality', () {
    for (final other in [
      _view(id: 'b'),
      _view(title: 'B'),
      _view(ageDays: 4),
    ]) {
      expect(other, isNot(_view()));
    }
  });
}
