import 'package:compapp_design/compapp_design.dart';
import 'package:flutter_test/flutter_test.dart';

MemberView _view({
  String id = 'ana',
  String name = 'Ana',
  String initials = 'A',
  int joinOrder = 0,
  String label = 'Ana',
  MemberStatus status = MemberStatus.home,
  bool isYou = false,
  bool isAdmin = false,
}) => MemberView(
  id: id,
  name: name,
  initials: initials,
  joinOrder: joinOrder,
  semanticLabel: label,
  status: status,
  isYou: isYou,
  isAdmin: isAdmin,
);

void main() {
  test('is home, not you and not admin by default', () {
    final member = _view();

    expect(member.status, MemberStatus.home);
    expect(member.isYou, isFalse);
    expect(member.isAdmin, isFalse);
  });

  test('two views with the same data are equal and hash alike', () {
    expect(_view(), _view());
    expect(_view().hashCode, _view().hashCode);
  });

  test('every field takes part in equality', () {
    final others = [
      _view(id: 'luis'),
      _view(name: 'Luis'),
      _view(initials: 'L'),
      _view(joinOrder: 1),
      _view(label: 'Luis'),
      _view(status: MemberStatus.away),
      _view(isYou: true),
      _view(isAdmin: true),
    ];

    for (final other in others) {
      expect(other, isNot(_view()));
    }
  });

  test('needs a spoken label', () {
    expect(() => _view(label: ''), throwsAssertionError);
  });
}
