import 'package:compapp_design/compapp_design.dart';
import 'package:flutter_test/flutter_test.dart';

const _ana = MemberView(
  id: 'ana',
  name: 'Ana',
  initials: 'A',
  joinOrder: 0,
  semanticLabel: 'Ana, at home',
);

RoomEditorRoom _room({
  String id = 'b1',
  String name = 'Bedroom 1',
  String editLabel = 'Edit Bedroom 1',
  String archiveLabel = 'Archive Bedroom 1',
  String? assignLabel = 'Assign someone to Bedroom 1',
  String? subtitle = 'Ana · 1 of 2 beds',
  List<MemberView> occupants = const [_ana],
  List<RoomAssignOption> options = const [],
}) => RoomEditorRoom(
  room: RoomView(id: id, name: name),
  editLabel: editLabel,
  archiveLabel: archiveLabel,
  assignLabel: assignLabel,
  subtitle: subtitle,
  occupants: occupants,
  assignOptions: options,
);

RoomEditorView _view({
  String bedroomsTitle = 'Bedrooms',
  String commonAreasTitle = 'Common areas',
  String addLabel = 'Add room',
  String assignLabel = 'Assign',
  List<RoomEditorRoom>? bedrooms,
  List<RoomEditorRoom> commonAreas = const [],
  String? archivedTitle = 'Archived',
  List<RoomEditorArchivedRoom> archived = const [],
  String? limitMessage,
}) => RoomEditorView(
  bedroomsTitle: bedroomsTitle,
  commonAreasTitle: commonAreasTitle,
  addLabel: addLabel,
  assignLabel: assignLabel,
  bedrooms: bedrooms ?? [_room()],
  commonAreas: commonAreas,
  archivedTitle: archivedTitle,
  archived: archived,
  limitMessage: limitMessage,
);

/// Checks that [a] equals an identical copy and differs from each variant in
/// [others], with the hash code following equality.
void _expectValue<T>(T a, T same, List<T> others) {
  expect(a, same);
  expect(a.hashCode, same.hashCode);
  for (final other in others) {
    expect(a, isNot(other));
  }
}

void main() {
  group('RoomAssignOption', () {
    test('compares by member and spoken label', () {
      const option = RoomAssignOption(member: _ana, semanticLabel: 'Move Ana');
      _expectValue(
        option,
        const RoomAssignOption(member: _ana, semanticLabel: 'Move Ana'),
        [
          const RoomAssignOption(member: _ana, semanticLabel: 'Move Sara'),
          const RoomAssignOption(
            member: MemberView(
              id: 'sara',
              name: 'Sara',
              initials: 'S',
              joinOrder: 1,
              semanticLabel: 'Sara',
            ),
            semanticLabel: 'Move Ana',
          ),
        ],
      );
    });

    test('needs a spoken label', () {
      expect(
        () => RoomAssignOption(member: _ana, semanticLabel: ''),
        throwsAssertionError,
      );
    });
  });

  group('RoomEditorRoom', () {
    test('compares every field', () {
      const option = RoomAssignOption(member: _ana, semanticLabel: 'Move Ana');
      _expectValue(_room(), _room(), [
        _room(id: 'b2'),
        _room(name: 'Bedroom 2'),
        _room(editLabel: 'Edit'),
        _room(archiveLabel: 'Archive'),
        _room(assignLabel: 'Assign'),
        _room(subtitle: null),
        _room(occupants: const []),
        _room(options: const [option]),
        _room(assignLabel: null),
      ]);
    });

    test('needs a spoken label for each of its buttons', () {
      expect(() => _room(editLabel: ''), throwsAssertionError);
      expect(() => _room(archiveLabel: ''), throwsAssertionError);
      expect(() => _room(assignLabel: ''), throwsAssertionError);
      expect(_room(assignLabel: null).assignLabel, isNull);
    });
  });

  group('RoomEditorArchivedRoom', () {
    test('compares the room and the subtitle', () {
      const room = RoomEditorArchivedRoom(
        room: RoomView(id: 'o', name: 'Office'),
        restoreLabel: 'Restore Office',
        subtitle: 'Archived 3 Mar',
      );
      _expectValue(
        room,
        const RoomEditorArchivedRoom(
          room: RoomView(id: 'o', name: 'Office'),
          restoreLabel: 'Restore Office',
          subtitle: 'Archived 3 Mar',
        ),
        [
          const RoomEditorArchivedRoom(
            room: RoomView(id: 'p', name: 'Office'),
            restoreLabel: 'Restore Office',
            subtitle: 'Archived 3 Mar',
          ),
          const RoomEditorArchivedRoom(
            room: RoomView(id: 'o', name: 'Office'),
            restoreLabel: 'Restore Office',
          ),
          const RoomEditorArchivedRoom(
            room: RoomView(id: 'o', name: 'Office'),
            restoreLabel: 'Restore',
            subtitle: 'Archived 3 Mar',
          ),
        ],
      );
    });
  });

  group('RoomEditorArchivedRoom labels', () {
    test('needs a spoken label for its button', () {
      expect(
        () => RoomEditorArchivedRoom(
          room: const RoomView(id: 'o', name: 'Office'),
          restoreLabel: '',
        ),
        throwsAssertionError,
      );
    });
  });

  group('RoomEditorView', () {
    test('compares every field', () {
      const archived = RoomEditorArchivedRoom(
        room: RoomView(id: 'o', name: 'Office'),
        restoreLabel: 'Restore Office',
      );
      _expectValue(_view(), _view(), [
        _view(bedroomsTitle: 'Rooms'),
        _view(commonAreasTitle: 'Areas'),
        _view(addLabel: 'Add'),
        _view(assignLabel: 'Move'),
        _view(bedrooms: [_room(id: 'b2')]),
        _view(commonAreas: [_room(id: 'k')]),
        _view(archivedTitle: null),
        _view(archived: const [archived]),
        _view(limitMessage: 'Full'),
      ]);
    });

    test('compares the rooms by value and in order', () {
      expect(
        _view(
          bedrooms: [
            _room(),
            _room(id: 'b2'),
          ],
        ),
        isNot(
          _view(
            bedrooms: [
              _room(id: 'b2'),
              _room(),
            ],
          ),
        ),
      );
    });

    test('needs a label for the add and assign buttons', () {
      expect(() => _view(addLabel: ''), throwsAssertionError);
      expect(() => _view(assignLabel: ''), throwsAssertionError);
    });
  });
}
