import 'package:compapp_design/compapp_design.dart';
import 'package:flutter_test/flutter_test.dart';

ItemView _view({
  String id = 'washer',
  String name = 'Washer',
  AppIcons icon = AppIcons.washer,
}) => ItemView(id: id, name: name, icon: icon);

void main() {
  test('two views with the same data are equal and hash alike', () {
    expect(_view(), _view());
    expect(_view().hashCode, _view().hashCode);
  });

  test('every field takes part in equality', () {
    for (final other in [
      _view(id: 'dryer'),
      _view(name: 'Dryer'),
      _view(icon: AppIcons.dryer),
    ]) {
      expect(other, isNot(_view()));
    }
  });
}
