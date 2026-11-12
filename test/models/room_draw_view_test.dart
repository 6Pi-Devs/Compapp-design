import 'package:compapp_design/compapp_design.dart';
import 'package:flutter_test/flutter_test.dart';

const _ana = MemberView(
  id: 'ana',
  name: 'Ana',
  initials: 'A',
  joinOrder: 0,
  semanticLabel: 'Ana, at home',
);
const _carlos = MemberView(
  id: 'carlos',
  name: 'Carlos',
  initials: 'C',
  joinOrder: 1,
  semanticLabel: 'Carlos, at home',
);

RoomDrawRoom _room({
  String id = 'b1',
  String name = 'Bedroom 1',
  String caption = 'from Bedroom 3',
  String label = 'Bedroom 1: Carlos, from Bedroom 3',
  List<MemberView> members = const [_carlos],
}) => RoomDrawRoom(
  room: RoomView(id: id, name: name),
  caption: caption,
  semanticLabel: label,
  members: members,
);

RoomDrawView _view({
  String drawId = 'draw-1',
  RoomDrawStatus status = RoomDrawStatus.pending,
  String statusLabel = 'Waiting to be applied',
  List<RoomDrawRoom>? bedrooms,
  String drawAgainLabel = 'Draw again',
  String applyLabel = 'Apply result',
  bool isAdmin = true,
  String? readOnlyNote,
}) => RoomDrawView(
  drawId: drawId,
  status: status,
  statusLabel: statusLabel,
  bedrooms: bedrooms ?? [_room()],
  drawAgainLabel: drawAgainLabel,
  applyLabel: applyLabel,
  isAdmin: isAdmin,
  readOnlyNote: readOnlyNote,
);

void main() {
  group('RoomDrawRoom', () {
    test('compares by value, members included', () {
      expect(_room(), _room());
      expect(_room().hashCode, _room().hashCode);
      for (final other in [
        _room(id: 'b2'),
        _room(name: 'Bedroom 2'),
        _room(caption: 'Stays free'),
        _room(label: 'Bedroom 1, Carlos'),
        _room(members: const [_carlos, _ana]),
        _room(members: const []),
      ]) {
        expect(other, isNot(_room()));
      }
      expect(
        _room(members: const [_carlos, _ana]).hashCode,
        isNot(_room(members: const [_ana, _carlos]).hashCode),
      );
    });

    test('has no members by default', () {
      const room = RoomDrawRoom(
        room: RoomView(id: 'b3', name: 'Bedroom 3'),
        caption: 'Stays free',
        semanticLabel: 'Bedroom 3, stays free',
      );

      expect(room.members, isEmpty);
    });

    test('needs a caption and a spoken label', () {
      expect(() => _room(caption: ''), throwsAssertionError);
      expect(() => _room(label: ''), throwsAssertionError);
    });
  });

  group('RoomDrawView', () {
    test('compares by value, bedrooms included', () {
      expect(_view(), _view());
      expect(_view().hashCode, _view().hashCode);
      for (final other in [
        _view(drawId: 'draw-2'),
        _view(status: RoomDrawStatus.applied),
        _view(statusLabel: 'Applied'),
        _view(
          bedrooms: [
            _room(),
            _room(id: 'b2'),
          ],
        ),
        _view(drawAgainLabel: 'Again'),
        _view(applyLabel: 'Apply'),
        _view(isAdmin: false),
        _view(readOnlyNote: 'Only Ana decides'),
      ]) {
        expect(other, isNot(_view()));
        expect(other.hashCode, isNot(_view().hashCode));
      }
    });

    test('a member is the default, with no note', () {
      final view = RoomDrawView(
        drawId: 'd',
        status: RoomDrawStatus.applied,
        statusLabel: 'Applied',
        bedrooms: [_room()],
        drawAgainLabel: 'Draw again',
        applyLabel: 'Apply result',
      );

      expect(view.isAdmin, isFalse);
      expect(view.readOnlyNote, isNull);
    });

    test('needs an id and its words', () {
      expect(() => _view(drawId: ''), throwsAssertionError);
      expect(() => _view(statusLabel: ''), throwsAssertionError);
      expect(() => _view(drawAgainLabel: ''), throwsAssertionError);
      expect(() => _view(applyLabel: ''), throwsAssertionError);
      expect(() => _view(readOnlyNote: ''), throwsAssertionError);
    });

    test('knows two statuses', () {
      expect(RoomDrawStatus.values, [
        RoomDrawStatus.pending,
        RoomDrawStatus.applied,
      ]);
    });
  });
}
