import 'dart:ui' show Tristate;

import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/host.dart';
import '../helpers/painted_pixels.dart';
import '../helpers/word_breaks.dart';

MemberView _person(
  String id,
  String name,
  int order, {
  MemberStatus status = MemberStatus.home,
  bool spanish = false,
}) => MemberView(
  id: id,
  name: name,
  initials: name[0],
  joinOrder: order,
  status: status,
  semanticLabel: switch (status) {
    MemberStatus.away => spanish ? '$name, fuera' : '$name, away',
    _ => name,
  },
);

FloorplanRoom _ana({bool es = false}) => FloorplanRoom(
  room: RoomView(id: 'ana', name: es ? 'Cuarto de Ana' : "Ana's room"),
  kind: FloorplanRoomKind.bedroom,
  state: RoomTileState.home,
  caption: es ? 'En casa · 3 h' : 'Home · 3 h',
  semanticLabel: es
      ? 'Cuarto de Ana, Ana está en casa, 3 horas'
      : "Ana's room, Ana is home, 3 hours",
  occupants: [_person('ana', 'Ana', 0, spanish: es)],
);

FloorplanRoom _bathroom({bool es = false}) => FloorplanRoom(
  room: RoomView(id: 'bathroom', name: es ? 'Baño' : 'Bathroom'),
  kind: FloorplanRoomKind.common,
  state: RoomTileState.occupied,
  caption: es ? 'Ocupado · 12 min' : 'In use · 12 min',
  semanticLabel: es
      ? 'Baño, ocupado por Carlos, 12 minutos'
      : 'Bathroom, occupied by Carlos, 12 minutes',
  occupants: [_person('carlos', 'Carlos', 1, spanish: es)],
);

FloorplanRoom _luis({bool es = false}) => FloorplanRoom(
  room: RoomView(id: 'luis', name: es ? 'Cuarto de Luis' : "Luis's room"),
  kind: FloorplanRoomKind.bedroom,
  state: RoomTileState.away,
  caption: es ? 'Fuera' : 'Away',
  semanticLabel: es
      ? 'Cuarto de Luis, Luis está fuera'
      : "Luis's room, Luis is away",
);

FloorplanItem _washer({bool es = false, bool inUse = true}) => FloorplanItem(
  item: ItemView(
    id: 'washer',
    name: es ? 'Lavadora' : 'Washer',
    icon: AppIcons.washer,
  ),
  inUse: inUse,
  statusLabel: inUse ? '34 min' : (es ? 'Libre' : 'Free'),
  semanticLabel: inUse
      ? (es
            ? 'Lavadora, en uso por Carlos, 34 minutos'
            : 'Washer, in use by Carlos, 34 minutes')
      : (es ? 'Lavadora, libre' : 'Washer, free'),
);

FloorplanRoom _kitchen({bool es = false, List<FloorplanItem>? items}) =>
    FloorplanRoom(
      room: RoomView(id: 'kitchen', name: es ? 'Cocina' : 'Kitchen'),
      kind: FloorplanRoomKind.common,
      state: RoomTileState.free,
      caption: es ? 'Libre' : 'Free',
      semanticLabel: es ? 'Cocina, libre' : 'Kitchen, free',
      items: items ?? [_washer(es: es)],
    );

FloorplanRoom _living({bool es = false}) => FloorplanRoom(
  room: RoomView(id: 'living', name: es ? 'Salón' : 'Living room'),
  kind: FloorplanRoomKind.common,
  state: RoomTileState.free,
  caption: es ? 'Libre' : 'Free',
  semanticLabel: es ? 'Salón, libre' : 'Living room, free',
);

FloorplanRoom _carlos({bool es = false}) => FloorplanRoom(
  room: RoomView(id: 'carlos', name: es ? 'Cuarto de Carlos' : "Carlos's room"),
  kind: FloorplanRoomKind.bedroom,
  state: RoomTileState.home,
  caption: es ? 'En casa · 5 h' : 'Home · 5 h',
  semanticLabel: es
      ? 'Cuarto de Carlos, Carlos está en casa, 5 horas'
      : "Carlos's room, Carlos is home, 5 hours",
  occupants: [_person('carlos', 'Carlos', 1, spanish: es)],
);

FloorplanRoom _bedroom4({bool es = false}) => FloorplanRoom(
  room: RoomView(id: 'bed4', name: es ? 'Habitación 4' : 'Bedroom 4'),
  kind: FloorplanRoomKind.bedroom,
  state: RoomTileState.free,
  caption: es ? 'Invitación pendiente' : 'Invite pending',
  semanticLabel: es
      ? 'Habitación 4, invitación pendiente'
      : 'Bedroom 4, invite pending',
);

FloorplanAbsence _luisAway({bool es = false, String? label}) =>
    FloorplanAbsence(
      member: _person(
        'luis',
        'Luis',
        2,
        status: MemberStatus.away,
        spanish: es,
      ),
      label: label ?? (es ? 'hasta el vie' : 'until Fri'),
    );

/// The board: seven rooms in the order they were made, one absence.
FloorplanView _view({
  bool es = false,
  List<FloorplanRoom>? rooms,
  List<FloorplanAbsence>? absences,
  bool loading = false,
}) => FloorplanView(
  rooms:
      rooms ??
      [
        _ana(es: es),
        _bathroom(es: es),
        _luis(es: es),
        _kitchen(es: es),
        _living(es: es),
        _carlos(es: es),
        _bedroom4(es: es),
      ],
  absences: absences ?? [_luisAway(es: es)],
  awayLabel: es ? 'Fuera' : 'Away',
  emptyTitle: es ? 'Todavía no hay habitaciones' : 'No rooms yet',
  emptyBody: es
      ? 'Añade las habitaciones de la casa para verlas aquí.'
      : 'Add the rooms of the home to see them here.',
  loadingLabel: es ? 'Cargando el plano' : 'Loading the plan',
  loading: loading,
);

FloorplanMap _map({
  FloorplanView? view,
  ValueChanged<String>? onRoomTap,
  ValueChanged<String>? onItemTap,
  ValueChanged<String>? onMemberTap,
}) => FloorplanMap(
  view: view ?? _view(),
  onRoomTap: onRoomTap ?? (_) {},
  onItemTap: onItemTap ?? (_) {},
  onMemberTap: onMemberTap ?? (_) {},
);

const _roomIds = [
  'ana',
  'bathroom',
  'luis',
  'kitchen',
  'living',
  'carlos',
  'bed4',
];

Finder _room(String id) => find.byKey(Key('floorplan.room.$id'));
Finder _item(String id) => find.byKey(Key('floorplan.item.$id'));
Finder _member(String id) => find.byKey(Key('floorplan.member.$id'));
Finder get _mapFinder => find.byKey(const Key('floorplan.map'));
Finder get _tray => find.byKey(const Key('floorplan.awayTray'));

/// A widget test on a surface tall enough for the whole map: it is not a
/// scrollable, and at large text it is tall.
void _widgets(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (tester) async {
    tester.view
      ..physicalSize = const Size(800, 8000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await body(tester);
  });
}

List<SemanticsNode> _children(SemanticsNode node) {
  final children = <SemanticsNode>[];
  node.visitChildren((child) {
    children.add(child);
    return true;
  });
  return children;
}

SemanticsData _data(WidgetTester tester, Finder finder) =>
    tester.getSemantics(finder).getSemanticsData();

Future<void> _tab(WidgetTester tester, [int times = 1]) async {
  for (var i = 0; i < times; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  }
  // The ring of an item in use breathes for ever, so nothing settles.
  await tester.pump(const Duration(milliseconds: 300));
}

/// The key, among the ones this map sets, nearest to what holds the focus.
String? _focusedKey() {
  final context = FocusManager.instance.primaryFocus?.context;
  String? found;
  context?.visitAncestorElements((element) {
    final key = element.widget.key;
    if (key is ValueKey<String> && key.value.startsWith('floorplan.')) {
      found = key.value;
      return false;
    }
    return true;
  });
  return found;
}

/// Tabs until the focus is on the widget with [key].
Future<void> _focusKey(WidgetTester tester, String key) async {
  for (var i = 0; i < 40 && _focusedKey() != key; i++) {
    await _tab(tester);
  }
  expect(_focusedKey(), key, reason: 'tabbed to it');
}

Future<void> _focusRoom(WidgetTester tester, String id) =>
    _focusKey(tester, 'floorplan.room.$id');

void main() {
  final themes = [('light', CompappTheme.light), ('dark', CompappTheme.dark)];

  group('content', () {
    _widgets('has its keys', (tester) async {
      await tester.pumpWidget(host(_map()));

      for (final key in [
        'floorplan.map',
        for (final id in _roomIds) 'floorplan.room.$id',
        'floorplan.item.washer',
        'floorplan.awayTray',
        'floorplan.member.luis',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget, reason: key);
      }
    });

    _widgets('puts the bedrooms in the top and bottom rows and the common '
        'areas between them, in the order they were made', (tester) async {
      await tester.pumpWidget(host(_map(), width: 600));

      Offset at(String id) => tester.getTopLeft(_room(id));
      // Top: the first half of the bedrooms.
      expect(at('ana').dy, at('luis').dy);
      expect(at('ana').dx, lessThan(at('luis').dx));
      // Middle: the common areas, in creation order.
      expect(at('bathroom').dy, greaterThan(at('ana').dy));
      expect(at('bathroom').dy, at('kitchen').dy);
      expect(at('bathroom').dy, at('living').dy);
      expect(at('bathroom').dx, lessThan(at('kitchen').dx));
      expect(at('kitchen').dx, lessThan(at('living').dx));
      // Bottom: the other half of the bedrooms.
      expect(at('carlos').dy, greaterThan(at('bathroom').dy));
      expect(at('carlos').dy, at('bed4').dy);
      expect(at('carlos').dx, lessThan(at('bed4').dx));
    });

    _widgets('splits an odd number of bedrooms with the extra one on top', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _map(view: _view(rooms: [_ana(), _luis(), _carlos(), _living()])),
          width: 600,
        ),
      );

      expect(
        tester.getTopLeft(_room('luis')).dy,
        tester.getTopLeft(_room('ana')).dy,
      );
      expect(
        tester.getTopLeft(_room('carlos')).dy,
        greaterThan(tester.getTopLeft(_room('living')).dy),
        reason: 'two on top, one at the bottom',
      );
    });

    _widgets('lays out only the kinds that exist', (tester) async {
      await tester.pumpWidget(
        host(_map(view: _view(rooms: [_bathroom(), _kitchen()])), width: 600),
      );

      expect(_room('bathroom'), findsOneWidget);
      expect(_room('kitchen'), findsOneWidget);
      expect(
        tester.getTopLeft(_room('bathroom')).dx,
        lessThan(tester.getTopLeft(_room('kitchen')).dx),
      );
    });

    _widgets('the tiles of a row share its width and are as tall as the '
        'tallest', (tester) async {
      await tester.pumpWidget(host(_map(), width: 600));

      for (final row in [
        ['ana', 'luis'],
        ['bathroom', 'kitchen', 'living'],
        ['carlos', 'bed4'],
      ]) {
        final rects = [for (final id in row) tester.getRect(_room(id))];
        for (final rect in rects) {
          expect(rect.width, closeTo(rects.first.width, 0.01), reason: '$row');
          expect(
            rect.height,
            closeTo(rects.first.height, 0.01),
            reason: '$row',
          );
          expect(rect.height, greaterThanOrEqualTo(AppSizes.rowTall));
        }
        for (var i = 1; i < rects.length; i++) {
          expect(
            rects[i].left - rects[i - 1].right,
            closeTo(AppSpacing.sm, 0.01),
            reason: 'the gap between $row',
          );
        }
      }
    });

    _widgets('a row is at least as tall as a row of the list: a bare room is '
        'not squashed to its text', (tester) async {
      await tester.pumpWidget(
        host(
          _map(
            view: _view(rooms: [_living()], absences: const []),
          ),
        ),
      );

      expect(tester.getSize(_room('living')).height, AppSizes.rowTall);
    });

    _widgets('a tile is never narrower than 48, however short its words', (
      tester,
    ) async {
      FloorplanRoom small(String id) => FloorplanRoom(
        room: RoomView(id: id, name: 'W'),
        kind: FloorplanRoomKind.common,
        state: RoomTileState.free,
        caption: 'a',
        semanticLabel: 'W, a',
      );
      await tester.pumpWidget(
        host(
          _map(
            view: _view(
              rooms: [small('a'), small('b'), small('c')],
              absences: const [],
            ),
          ),
          width: 152,
        ),
      );

      for (final id in ['a', 'b', 'c']) {
        expect(
          tester.getSize(_room(id)).width,
          greaterThanOrEqualTo(AppSizes.minTarget),
          reason: id,
        );
      }
      expect(
        tester.getTopLeft(_room('c')).dy,
        greaterThan(tester.getTopLeft(_room('a')).dy),
        reason: 'two across, not three',
      );
    });

    _widgets('the rows fill the plan from edge to edge', (tester) async {
      await tester.pumpWidget(host(_map(), width: 600));

      final lefts = [for (final id in _roomIds) tester.getRect(_room(id)).left];
      final rights = [
        for (final id in _roomIds) tester.getRect(_room(id)).right,
      ];
      expect(
        lefts.reduce((a, b) => a < b ? a : b),
        closeTo(
          tester.getTopLeft(_mapFinder).dx + AppSpacing.sm + AppSpacing.sm,
          0.01,
        ),
        reason: 'card padding, plan padding',
      );
      expect(
        rights.reduce((a, b) => a > b ? a : b),
        closeTo(
          tester.getTopRight(_mapFinder).dx - AppSpacing.sm - AppSpacing.sm,
          0.01,
        ),
      );
    });

    _widgets('draws the occupants and the beacon of a room inside its tile', (
      tester,
    ) async {
      await tester.pumpWidget(host(_map()));

      expect(
        find.descendant(
          of: _room('ana'),
          matching: find.byKey(const Key('roomTile.pebble.ana')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _room('kitchen'), matching: _item('washer')),
        findsOneWidget,
      );
      final beacon = tester.widget<ItemBeacon>(
        find.descendant(
          of: _room('kitchen'),
          matching: find.byType(ItemBeacon),
        ),
      );
      expect(beacon.inUse, isTrue);
      expect(beacon.statusLabel, '34 min');
    });

    _widgets('gives each tile its state, caption and label', (tester) async {
      await tester.pumpWidget(host(_map()));

      for (final room in _view().rooms) {
        final tile = tester.widget<RoomTile>(
          find.byWidgetPredicate(
            (w) => w is RoomTile && w.room.id == room.room.id,
          ),
        );
        expect(tile.state, room.state, reason: room.room.id);
        expect(tile.caption, room.caption, reason: room.room.id);
        expect(tile.semanticLabel, room.semanticLabel, reason: room.room.id);
        expect(tile.onTap, isNotNull, reason: room.room.id);
      }
    });

    _widgets('does not draw an archived room, or what is pinned to it', (
      tester,
    ) async {
      const archived = FloorplanRoom(
        room: RoomView(id: 'old', name: 'Storeroom'),
        kind: FloorplanRoomKind.common,
        state: RoomTileState.free,
        caption: 'Free',
        semanticLabel: 'Storeroom, free',
        archived: true,
        items: [
          FloorplanItem(
            item: ItemView(id: 'vacuum', name: 'Vacuum', icon: AppIcons.washer),
            inUse: false,
            statusLabel: 'Free',
            semanticLabel: 'Vacuum, free',
          ),
        ],
      );
      await tester.pumpWidget(
        host(_map(view: _view(rooms: [_ana(), archived, _living()]))),
      );

      expect(_room('old'), findsNothing);
      expect(_item('vacuum'), findsNothing);
      expect(find.text('Storeroom'), findsNothing);
      expect(_room('ana'), findsOneWidget);
      expect(_room('living'), findsOneWidget);
    });

    _widgets('with only archived rooms it is the empty state', (tester) async {
      const archived = FloorplanRoom(
        room: RoomView(id: 'old', name: 'Storeroom'),
        kind: FloorplanRoomKind.common,
        state: RoomTileState.free,
        caption: 'Free',
        semanticLabel: 'Storeroom, free',
        archived: true,
      );
      await tester.pumpWidget(host(_map(view: _view(rooms: [archived]))));

      expect(find.text('No rooms yet'), findsOneWidget);
      expect(find.byType(RoomTile), findsNothing);
    });

    _widgets('with no rooms it says the empty state and draws no tray', (
      tester,
    ) async {
      await tester.pumpWidget(host(_map(view: _view(rooms: const []))));

      expect(find.text('No rooms yet'), findsOneWidget);
      expect(
        find.text('Add the rooms of the home to see them here.'),
        findsOneWidget,
      );
      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.byType(RoomTile), findsNothing);
      expect(_tray, findsNothing);
      expect(_mapFinder, findsOneWidget);
    });

    _widgets('while loading it draws a ring and nothing else', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_map(view: _view(loading: true))));

      expect(find.byType(AppProgressRing), findsOneWidget);
      expect(find.byType(RoomTile), findsNothing);
      expect(_tray, findsNothing);
      expect(find.byType(AppEmptyState), findsNothing);
      expect(semanticsLabels(tester), ['Loading the plan']);
      handle.dispose();
    });

    _widgets('while loading with no rooms it is still loading, not empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(_map(view: _view(rooms: const [], loading: true))),
      );

      expect(find.byType(AppProgressRing), findsOneWidget);
      expect(find.byType(AppEmptyState), findsNothing);
    });

    _widgets('the away tray is there only while someone is away', (
      tester,
    ) async {
      await tester.pumpWidget(host(_map()));
      expect(_tray, findsOneWidget);
      expect(
        find.descendant(of: _tray, matching: find.text('Away')),
        findsOneWidget,
      );
      expect(find.text('until Fri'), findsOneWidget);

      await tester.pumpWidget(host(_map(view: _view(absences: const []))));
      expect(_tray, findsNothing);
      expect(_member('luis'), findsNothing);
    });

    _widgets('the tray holds a pebble and the words of each absent member', (
      tester,
    ) async {
      final view = _view(
        absences: [
          _luisAway(),
          FloorplanAbsence(member: _person('marta', 'Marta', 3)),
        ],
      );
      await tester.pumpWidget(host(_map(view: view)));

      expect(
        find.descendant(of: _member('luis'), matching: find.byType(AppPebble)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _member('luis'), matching: find.text('until Fri')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _member('marta'), matching: find.byType(AppPebble)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _member('marta'), matching: find.byType(Text)),
        findsOneWidget,
        reason: 'the initial only: no label, no words',
      );
      expect(
        find.descendant(of: _member('luis'), matching: find.byType(Text)),
        findsNWidgets(2),
        reason: 'the initial and the words',
      );
      expect(
        tester
            .widget<AppPebble>(
              find.descendant(
                of: _member('luis'),
                matching: find.byType(AppPebble),
              ),
            )
            .status,
        AppPebbleStatus.away,
      );
    });

    _widgets('the tray is under the plan', (tester) async {
      await tester.pumpWidget(host(_map()));

      expect(
        tester.getTopLeft(_tray).dy,
        greaterThan(tester.getBottomLeft(_room('bed4')).dy),
      );
    });

    test('the models compare by value and need their words', () {
      expect(_ana(), _ana());
      expect(_ana().hashCode, _ana().hashCode);
      expect(_ana(), isNot(_ana(es: true)));
      expect(_view(), _view());
      expect(_view().hashCode, _view().hashCode);
      expect(_view(), isNot(_view(loading: true)));
      expect(_view(), isNot(_view(absences: const [])));
      expect(_luisAway(), _luisAway());
      expect(_luisAway(), isNot(_luisAway(label: 'until Sun')));
      expect(_washer(), _washer());
      expect(_washer(), isNot(_washer(inUse: false)));
      expect(_view().visibleRooms, _view().rooms);

      expect(
        () => FloorplanView(
          rooms: const [],
          awayLabel: '',
          emptyTitle: 'a',
          emptyBody: 'b',
          loadingLabel: 'c',
        ),
        throwsAssertionError,
      );
      expect(
        () => FloorplanView(
          rooms: const [],
          awayLabel: 'a',
          emptyTitle: '',
          emptyBody: 'b',
          loadingLabel: 'c',
        ),
        throwsAssertionError,
      );
      expect(
        () => FloorplanView(
          rooms: const [],
          awayLabel: 'a',
          emptyTitle: 'b',
          emptyBody: '',
          loadingLabel: 'c',
        ),
        throwsAssertionError,
      );
      expect(
        () => FloorplanView(
          rooms: const [],
          awayLabel: 'a',
          emptyTitle: 'b',
          emptyBody: 'c',
          loadingLabel: '',
        ),
        throwsAssertionError,
      );
      expect(
        () => FloorplanRoom(
          room: const RoomView(id: 'a', name: 'A'),
          kind: FloorplanRoomKind.common,
          state: RoomTileState.free,
          caption: '',
          semanticLabel: 'A',
        ),
        throwsAssertionError,
      );
      expect(
        () => FloorplanItem(
          item: const ItemView(id: 'a', name: 'A', icon: AppIcons.oven),
          inUse: false,
          statusLabel: 'free',
          semanticLabel: '',
        ),
        throwsAssertionError,
      );
    });

    _widgets('flags what would break the keys or the names, in debug', (
      tester,
    ) async {
      FloorplanView withRooms(List<FloorplanRoom> rooms) => _view(rooms: rooms);

      Future<Object?> pump(FloorplanView view) async {
        await tester.pumpWidget(host(_map(view: view)));
        return tester.takeException();
      }

      expect(await pump(withRooms([_ana(), _ana()])), isAssertionError);
      expect(
        await pump(
          withRooms(
            [_kitchen(), _bathroom(), _luis(), _living()].map((r) {
              return r.room.id == 'living'
                  ? FloorplanRoom(
                      room: r.room,
                      kind: r.kind,
                      state: r.state,
                      caption: r.caption,
                      semanticLabel: r.semanticLabel,
                      items: [_washer()],
                    )
                  : r;
            }).toList(),
          ),
        ),
        isAssertionError,
        reason: 'the same item in two rooms',
      );
      expect(
        await pump(_view(absences: [_luisAway(), _luisAway()])),
        isAssertionError,
      );
      expect(
        await pump(
          withRooms([
            const FloorplanRoom(
              room: RoomView(id: 'a', name: 'Kitchen'),
              kind: FloorplanRoomKind.common,
              state: RoomTileState.free,
              caption: 'Free',
              semanticLabel: 'The room that is free',
            ),
          ]),
        ),
        isAssertionError,
        reason: 'the label does not say the visible name',
      );
      expect(
        await pump(
          withRooms([
            _kitchen(
              items: [
                const FloorplanItem(
                  item: ItemView(id: 'o', name: 'Oven', icon: AppIcons.oven),
                  inUse: false,
                  statusLabel: 'Free',
                  semanticLabel: 'The appliance',
                ),
              ],
            ),
          ]),
        ),
        isAssertionError,
      );
    });
  });

  group('callbacks', () {
    /// A point inside the top start corner of [id]'s tile, over its name.
    Offset corner(WidgetTester tester, String id) =>
        tester.getTopLeft(_room(id)) + const Offset(6, 6);

    _widgets('a tap on a room calls onRoomTap with its id, and only that', (
      tester,
    ) async {
      final rooms = <String>[];
      final items = <String>[];
      final members = <String>[];
      await tester.pumpWidget(
        host(
          _map(
            onRoomTap: rooms.add,
            onItemTap: items.add,
            onMemberTap: members.add,
          ),
          width: 600,
        ),
      );

      for (final id in _roomIds) {
        await tester.tapAt(corner(tester, id));
      }

      expect(rooms, _roomIds);
      expect(items, isEmpty);
      expect(members, isEmpty);
    });

    _widgets('a tap on a beacon calls onItemTap with its id and not '
        'onRoomTap', (tester) async {
      final rooms = <String>[];
      final items = <String>[];
      await tester.pumpWidget(
        host(_map(onRoomTap: rooms.add, onItemTap: items.add)),
      );

      await tester.tap(_item('washer'));

      expect(items, ['washer']);
      expect(rooms, isEmpty);
    });

    _widgets('a tap on a member of the tray calls onMemberTap with its id', (
      tester,
    ) async {
      final rooms = <String>[];
      final members = <String>[];
      await tester.pumpWidget(
        host(_map(onRoomTap: rooms.add, onMemberTap: members.add)),
      );

      await tester.tap(_member('luis'));

      expect(members, ['luis']);
      expect(rooms, isEmpty);
    });

    _widgets('a tap on the tray outside its members calls nothing', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        host(
          _map(
            onRoomTap: (_) => calls++,
            onItemTap: (_) => calls++,
            onMemberTap: (_) => calls++,
          ),
        ),
      );

      await tester.tapAt(tester.getTopRight(_tray) + const Offset(-6, 6));

      expect(calls, 0);
    });

    _widgets('Enter on a focused room calls onRoomTap, on a focused beacon '
        'onItemTap, on a focused member onMemberTap', (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        host(
          _map(
            onRoomTap: (id) => calls.add('room $id'),
            onItemTap: (id) => calls.add('item $id'),
            onMemberTap: (id) => calls.add('member $id'),
          ),
        ),
      );

      for (final key in [
        'floorplan.room.kitchen',
        'floorplan.item.washer',
        'floorplan.member.luis',
      ]) {
        await _focusKey(tester, key);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      }

      expect(calls, ['room kitchen', 'item washer', 'member luis']);
    });

    _widgets('calls the callbacks of the latest build', (tester) async {
      final first = <String>[];
      final second = <String>[];
      await tester.pumpWidget(
        host(
          _map(
            onRoomTap: (id) => first.add('room $id'),
            onItemTap: (id) => first.add('item $id'),
            onMemberTap: (id) => first.add('member $id'),
          ),
        ),
      );
      await tester.pumpWidget(
        host(
          _map(
            onRoomTap: (id) => second.add('room $id'),
            onItemTap: (id) => second.add('item $id'),
            onMemberTap: (id) => second.add('member $id'),
          ),
        ),
      );

      await tester.tapAt(corner(tester, 'ana'));
      await tester.tap(_item('washer'));
      await tester.tap(_member('luis'));

      expect(first, isEmpty);
      expect(second, ['room ana', 'item washer', 'member luis']);
    });
  });

  group('semantics', () {
    _widgets('a room is one focusable button named by its spoken label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_map(), width: 600));

      for (final room in _view().rooms) {
        expect(
          tester.getSemantics(_room(room.room.id)),
          isSemantics(
            label: room.semanticLabel,
            isButton: true,
            isFocusable: true,
            hasTapAction: true,
          ),
          reason: room.room.id,
        );
      }
      handle.dispose();
    });

    _widgets('the plan is a list, each room is an item and the beacon is a '
        'button inside its room', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_map(), width: 600));

      final roles = {
        for (final node in semanticsNodes(tester))
          node.id: node.getSemanticsData().role,
      };
      expect(roles.values.where((r) => r == SemanticsRole.list), hasLength(1));
      expect(
        roles.values.where((r) => r == SemanticsRole.listItem),
        hasLength(7),
      );
      final root = tester.getSemantics(_mapFinder);
      final parts = _children(root);
      expect(parts, hasLength(2), reason: 'the plan, then the tray');
      expect(parts.first.getSemanticsData().role, SemanticsRole.list);
      final items = _children(parts.first);
      expect(items, hasLength(7));
      for (final item in items) {
        expect(item.getSemanticsData().role, SemanticsRole.listItem);
        expect(_children(item), hasLength(1), reason: 'the room button');
      }
      final kitchen = tester.getSemantics(_room('kitchen'));
      expect(_children(kitchen), hasLength(1));
      expect(
        _children(kitchen).single,
        isSemantics(
          label: 'Washer, in use by Carlos, 34 minutes',
          isButton: true,
          hasTapAction: true,
        ),
      );
      expect(kitchen.label, isNot(contains('Washer')));
      handle.dispose();
    });

    _widgets('reads the rooms, the beacon and the tray once each, in order', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_map(), width: 600));

      expect(semanticsLabels(tester), [
        "Ana's room, Ana is home, 3 hours",
        "Luis's room, Luis is away",
        'Bathroom, occupied by Carlos, 12 minutes',
        'Kitchen, free',
        'Washer, in use by Carlos, 34 minutes',
        'Living room, free',
        "Carlos's room, Carlos is home, 5 hours",
        'Bedroom 4, invite pending',
        'Away',
        'Luis, away\nuntil Fri',
      ], reason: 'no caption, name, pebble or ring says anything twice');
      handle.dispose();
    });

    _widgets('keeps the same reading order in right to left', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(_map(), width: 600, direction: TextDirection.rtl),
      );

      expect(semanticsLabels(tester).take(8), [
        "Ana's room, Ana is home, 3 hours",
        "Luis's room, Luis is away",
        'Bathroom, occupied by Carlos, 12 minutes',
        'Kitchen, free',
        'Washer, in use by Carlos, 34 minutes',
        'Living room, free',
        "Carlos's room, Carlos is home, 5 hours",
        'Bedroom 4, invite pending',
      ]);
      handle.dispose();
    });

    _widgets('the tray is a group named by its heading, holding a button '
        'for each member', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_map()));

      expect(
        tester.getSemantics(_tray),
        isSemantics(label: 'Away', isButton: false),
      );
      final buttons = _children(tester.getSemantics(_tray));
      expect(buttons, hasLength(1));
      expect(
        buttons.single,
        isSemantics(
          label: 'Luis, away\nuntil Fri',
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    _widgets('every accessible name contains the text that is shown (label '
        'in name)', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_map(view: _view(es: true)), width: 600));

      final view = _view(es: true);
      for (final room in view.rooms) {
        expect(
          _data(tester, _room(room.room.id)).label,
          contains(room.room.name),
        );
        expect(find.text(room.room.name), findsOneWidget);
        for (final item in room.items) {
          expect(
            _data(tester, _item(item.item.id)).label,
            contains(item.item.name),
          );
          expect(find.text(item.item.name), findsOneWidget);
        }
      }
      for (final absence in view.absences) {
        expect(
          _data(tester, _member(absence.member.id)).label,
          contains(absence.label),
        );
        expect(find.text(absence.label!), findsOneWidget);
      }
      expect(_data(tester, _tray).label, contains('Fuera'));
      handle.dispose();
    });

    _widgets('while loading the map is named by the loading label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_map(view: _view(loading: true, es: true))));

      expect(semanticsLabels(tester), ['Cargando el plano']);
      handle.dispose();
    });

    _widgets('empty it reads its title and body as the empty state does', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_map(view: _view(rooms: const []))));

      expect(
        semanticsLabels(tester).join(' '),
        allOf(
          contains('No rooms yet'),
          contains('Add the rooms of the home to see them here.'),
        ),
      );
      handle.dispose();
    });

    _widgets('a room is enabled and a room node never claims to be selected', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(_map()));

      final flags = _data(tester, _room('ana')).flagsCollection;
      expect(flags.isEnabled, isNot(Tristate.isFalse));
      expect(flags.isSelected, isNot(Tristate.isTrue));
      handle.dispose();
    });
  });

  group('look', () {
    for (final (name, theme) in themes) {
      final scheme = theme.colorScheme;

      _widgets('the card is the surface with a hairline edge and the plan '
          'sits on the page color ($name)', (tester) async {
        await tester.pumpWidget(host(_map(), theme: theme));

        final boxes = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: _mapFinder,
                matching: find.byType(DecoratedBox),
              ),
            )
            .map((box) => box.decoration)
            .whereType<BoxDecoration>()
            .toList();
        final card = boxes.first;
        expect(card.color, scheme.surfaceContainerLowest);
        expect((card.border! as Border).top.color, scheme.outlineVariant);
        expect(card.borderRadius, BorderRadius.circular(AppRadius.md));
        expect(boxes[1].color, scheme.surface);
        expect(boxes[1].borderRadius, BorderRadius.circular(AppRadius.sm));
      });

      _widgets('the tray has a dashed hairline outline and words in the '
          'muted and plain inks ($name)', (tester) async {
        await tester.pumpWidget(host(_map(), theme: theme));

        final outline = tester
            .widgetList<DecoratedBox>(
              find.descendant(of: _tray, matching: find.byType(DecoratedBox)),
            )
            .map((box) => box.decoration)
            .whereType<ShapeDecoration>()
            .first;
        final shape = outline.shape as RoundedRectangleBorder;
        expect(shape.runtimeType.toString(), 'DashedBorder');
        expect(shape.side.color, scheme.outlineVariant);
        expect(shape.side.width, AppSizes.borderRoom);

        Color? color(String text) => tester
            .widget<Text>(find.descendant(of: _tray, matching: find.text(text)))
            .style
            ?.color;
        expect(color('Away'), scheme.onSurfaceVariant);
        expect(color('until Fri'), scheme.onSurface);
        final moon = tester.widget<AppIcon>(
          find.descendant(of: _tray, matching: find.byType(AppIcon)),
        );
        expect(moon.icon, AppIcons.away, reason: 'a moon, not color alone');
        expect(moon.color, scheme.onSurfaceVariant);
      });

      test('the texts of the map keep their contrast ($name)', () {
        expectContrast(
          {
            'tray heading': (
              scheme.onSurfaceVariant,
              scheme.surfaceContainerLowest,
            ),
            'tray words': (scheme.onSurface, scheme.surfaceContainerLowest),
          },
          minimum: 4.5,
          reason: 'the floor plan map ($name)',
        );
        expectContrast(
          {
            'ring on the card': (
              scheme.onSurface,
              scheme.surfaceContainerLowest,
            ),
            'ring on the plan': (scheme.onSurface, scheme.surface),
          },
          minimum: 3,
          reason: 'the focus ring of the floor plan map ($name)',
        );
      });

      _widgets('a focused room keeps its 2 px ring beside the glow of the '
          'room next to it ($name)', (tester) async {
        final homes = _view(
          rooms: [_ana(), _carlos(), _bedroom4()],
          absences: const [],
        );
        await tester.pumpWidget(
          host(_map(view: homes), theme: theme, width: 600),
        );
        final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));
        Future<int> inkRight() async {
          final tile = tester.getRect(_room('ana')).shift(-boundary);
          final strip = await paintedPixels(
            tester,
            hostBoundaryKey,
            region: Rect.fromLTWH(
              tile.right,
              tile.top + 24,
              AppSizes.borderEmphasis,
              tile.height - 48,
            ),
          );
          return countPixels(strip, scheme.onSurface);
        }

        expect(await inkRight(), 0);
        await _focusRoom(tester, 'ana');
        final ink = await inkRight();

        final tile = tester.getRect(_room('ana'));
        expect(
          ink,
          greaterThan(tile.height - 48),
          reason:
              'at least a full column of the 2 px ring is ink, the glow '
              'of the next room is outside it',
        );
        expect(
          tester.getRect(_room('carlos')).left - tile.right,
          AppSpacing.sm,
        );
      });
    }

    _widgets('has no danger color', (tester) async {
      await tester.pumpWidget(host(_map()));
      final scheme = CompappTheme.light.colorScheme;

      final boundary = tester.getTopLeft(find.byKey(hostBoundaryKey));
      final all = await paintedPixels(
        tester,
        hostBoundaryKey,
        region: tester.getRect(_mapFinder).shift(-boundary),
      );
      expect(countPixels(all, scheme.error), 0);
      expect(countPixels(all, scheme.errorContainer), 0);
    });
  });

  group('motion', () {
    Widget still(Widget child) => Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child,
      ),
    );

    _widgets('an item in use breathes, and stands still when animations are '
        'off', (tester) async {
      await tester.pumpWidget(host(_map()));
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpWidget(host(still(_map())));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });

    _widgets('has no motion of its own without an item in use', (tester) async {
      final calm = _view(
        rooms: [
          _ana(),
          _kitchen(items: [_washer(inUse: false)]),
        ],
      );
      await tester.pumpWidget(host(_map(view: calm)));
      await tester.pump();

      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('large text and narrow columns', () {
    setUpAll(loadBundledFonts);

    FloorplanRoom stressRoom(
      String id,
      String name,
      FloorplanRoomKind kind,
      RoomTileState state,
      String caption, {
      List<MemberView> occupants = const [],
      List<FloorplanItem> items = const [],
    }) => FloorplanRoom(
      room: RoomView(id: id, name: name),
      kind: kind,
      state: state,
      caption: caption,
      semanticLabel: '$name, $caption',
      occupants: occupants,
      items: items,
    );

    FloorplanItem stressItem(String id, String name, String status) =>
        FloorplanItem(
          item: ItemView(id: id, name: name, icon: AppIcons.washer),
          inUse: true,
          statusLabel: status,
          semanticLabel: '$name, $status',
        );

    /// Long Spanish words: the longest the plan will meet in a name.
    FloorplanView stress() => FloorplanView(
      rooms: [
        stressRoom(
          'max',
          'Habitación de Maximiliano',
          FloorplanRoomKind.bedroom,
          RoomTileState.home,
          'En casa desde hace 3 horas',
          occupants: [_person('max', 'Maximiliano', 0, spanish: true)],
        ),
        stressRoom(
          'bano',
          'Cuarto de baño',
          FloorplanRoomKind.common,
          RoomTileState.occupied,
          'Ocupado por Cristina · 12 minutos',
          occupants: [_person('cris', 'Cristina', 1, spanish: true)],
        ),
        stressRoom(
          'cris',
          'Dormitorio de Cristina',
          FloorplanRoomKind.bedroom,
          RoomTileState.away,
          'Fuera hasta el viernes',
        ),
        stressRoom(
          'cocina',
          'Cocina comedor',
          FloorplanRoomKind.common,
          RoomTileState.free,
          'Libre',
          items: [
            stressItem('lavavajillas', 'Lavavajillas', 'En uso · 34 minutos'),
            stressItem('lavadora', 'Lavadora', 'En uso · 12 minutos'),
          ],
        ),
        stressRoom(
          'sala',
          'Sala de estar',
          FloorplanRoomKind.common,
          RoomTileState.free,
          'Libre',
        ),
        stressRoom(
          'hab4',
          'Habitación de invitados',
          FloorplanRoomKind.bedroom,
          RoomTileState.free,
          'Invitación pendiente',
        ),
      ],
      absences: [
        FloorplanAbsence(
          member: _person(
            'cris',
            'Cristina',
            1,
            status: MemberStatus.away,
            spanish: true,
          ),
          label: 'hasta el viernes 6 de noviembre',
        ),
        FloorplanAbsence(
          member: _person(
            'max',
            'Maximiliano',
            0,
            status: MemberStatus.away,
            spanish: true,
          ),
          label: 'hasta el domingo',
        ),
      ],
      awayLabel: 'Fuera de casa',
      emptyTitle: 'Todavía no hay habitaciones',
      emptyBody: 'Añade las habitaciones de la casa para verlas aquí.',
      loadingLabel: 'Cargando el plano',
    );

    final stressIds = ['max', 'bano', 'cris', 'cocina', 'sala', 'hab4'];

    for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
      for (final width in [320.0, 360.0]) {
        for (final scale in [1.0, 1.3, 1.5, 2.0]) {
          final where = '${direction.name}, $width wide, ${scale}x';

          _widgets('keeps everything inside and shows every word ($where)', (
            tester,
          ) async {
            await tester.pumpWidget(
              host(
                _map(view: stress()),
                textScale: scale,
                width: width,
                direction: direction,
              ),
            );

            expect(tester.takeException(), isNull, reason: where);
            final map = tester.getRect(_mapFinder);
            expect(map.width, width, reason: where);

            final tiles = {
              for (final id in stressIds) id: tester.getRect(_room(id)),
            };
            for (final MapEntry(key: id, value: tile) in tiles.entries) {
              expect(tile.left, greaterThanOrEqualTo(map.left), reason: id);
              expect(tile.right, lessThanOrEqualTo(map.right), reason: id);
              expect(tile.width, greaterThanOrEqualTo(AppSizes.minTarget));
              expect(tile.height, greaterThanOrEqualTo(AppSizes.minTarget));
            }
            // The tiles of a row are as tall as each other.
            for (final a in tiles.values) {
              for (final b in tiles.values) {
                if ((a.top - b.top).abs() < 0.01) {
                  expect(a.height, closeTo(b.height, 0.01), reason: where);
                }
              }
            }
            for (final beacon in find.byType(ItemBeacon).evaluate()) {
              final box = tester.getRect(find.byWidget(beacon.widget));
              final tile = tiles.values.firstWhere(
                (t) => t.contains(box.center),
              );
              expect(box.left, greaterThanOrEqualTo(tile.left), reason: where);
              expect(box.right, lessThanOrEqualTo(tile.right), reason: where);
              expect(box.bottom, lessThanOrEqualTo(tile.bottom), reason: where);
            }
            final tray = tester.getRect(_tray);
            expect(tray.bottom, lessThanOrEqualTo(map.bottom), reason: where);
            for (final id in ['cris', 'max']) {
              final button = tester.getRect(_member(id));
              expect(button.left, greaterThanOrEqualTo(tray.left));
              expect(button.right, lessThanOrEqualTo(tray.right));
              expect(button.top, greaterThanOrEqualTo(tray.top));
              expect(button.bottom, lessThanOrEqualTo(tray.bottom));
            }

            // Text grows, and nothing hides it.
            final element = tester.element(_mapFinder);
            expect(
              MediaQuery.textScalerOf(element).scale(10),
              closeTo(10 * scale, 0.001),
              reason: 'the scale is not clamped',
            );
            final texts = find.descendant(
              of: _mapFinder,
              matching: find.byType(Text),
            );
            final pebbles = find.descendant(
              of: find.byType(AppPebble),
              matching: find.byType(Text),
            );
            final pebbleTexts = pebbles.evaluate().map((e) => e.widget).toSet();
            final all = texts.evaluate().toList();
            for (var i = 0; i < all.length; i++) {
              final text = all[i].widget as Text;
              // The initial of a pebble is one line by design.
              if (pebbleTexts.contains(text)) continue;
              expect(text.maxLines, isNull, reason: '${text.data} $where');
              expect(
                text.overflow,
                isNot(TextOverflow.ellipsis),
                reason: '${text.data} $where',
              );
              expectNoMidWordBreaks(tester, texts.at(i), reason: where);
            }
          });
        }
      }
    }

    _widgets('moves to fewer tiles in a row as the text grows, down to one', (
      tester,
    ) async {
      Future<int> perRow(double scale) async {
        await tester.pumpWidget(host(_map(view: stress()), textScale: scale));
        final top = tester.getTopLeft(_room('bano')).dy;
        return [
          for (final id in stressIds)
            if ((tester.getTopLeft(_room(id)).dy - top).abs() < 0.01) id,
        ].length;
      }

      final counts = [
        for (final s in [1.0, 1.3, 1.5, 2.0]) await perRow(s),
      ];
      expect(counts.first, greaterThan(1));
      expect(counts.last, 1, reason: 'one column at 200%');
      for (var i = 1; i < counts.length; i++) {
        expect(counts[i], lessThanOrEqualTo(counts[i - 1]), reason: '$counts');
      }
    });

    _widgets('takes three across in a wide column and never more', (
      tester,
    ) async {
      await tester.pumpWidget(host(_map(), width: 900));

      final top = tester.getTopLeft(_room('bathroom')).dy;
      final across = [
        for (final id in _roomIds)
          if ((tester.getTopLeft(_room(id)).dy - top).abs() < 0.01) id,
      ];
      expect(across, ['bathroom', 'kitchen', 'living']);

      final many = _view(
        rooms: [
          for (var i = 0; i < 7; i++)
            FloorplanRoom(
              room: RoomView(id: 'r$i', name: 'Room $i'),
              kind: FloorplanRoomKind.common,
              state: RoomTileState.free,
              caption: 'Free',
              semanticLabel: 'Room $i, free',
            ),
        ],
        absences: const [],
      );
      await tester.pumpWidget(host(_map(view: many), width: 900));
      final rows = <double, int>{};
      for (var i = 0; i < 7; i++) {
        final y = tester.getTopLeft(_room('r$i')).dy;
        rows[y] = (rows[y] ?? 0) + 1;
      }
      expect(rows.values.toList(), [3, 2, 2], reason: 'spread evenly');
    });

    _widgets('mirrors in right to left, the first room at the right', (
      tester,
    ) async {
      await tester.pumpWidget(host(_map(), width: 600));
      final ltrMap = tester.getRect(_mapFinder);
      final ltr = {for (final id in _roomIds) id: tester.getRect(_room(id))};
      await tester.pumpWidget(
        host(_map(), width: 600, direction: TextDirection.rtl),
      );

      final map = tester.getRect(_mapFinder);
      for (final id in _roomIds) {
        final rtl = tester.getRect(_room(id));
        expect(rtl.top, ltr[id]!.top, reason: id);
        expect(rtl.width, ltr[id]!.width, reason: id);
        expect(
          rtl.left - map.left,
          closeTo(ltrMap.right - ltr[id]!.right, 0.01),
          reason: id,
        );
      }
      expect(
        tester.getTopLeft(_room('ana')).dx,
        greaterThan(tester.getTopLeft(_room('luis')).dx),
      );
      final tray = tester.getRect(_tray);
      expect(
        tester
            .getTopLeft(
              find.descendant(of: _tray, matching: find.byType(AppIcon)),
            )
            .dx,
        greaterThan(tray.center.dx),
        reason: 'the moon starts the tray at the right',
      );
    });

    _widgets('can be measured by intrinsic sizing, as the goldens do', (
      tester,
    ) async {
      await tester.pumpWidget(host(_map()));
      final plain = tester.getSize(_mapFinder);

      await tester.pumpWidget(host(IntrinsicHeight(child: _map())));
      expect(tester.takeException(), isNull);
      expect(tester.getSize(_mapFinder), plain);

      await tester.pumpWidget(
        host(Align(child: IntrinsicWidth(child: _map()))),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(_mapFinder).height, greaterThan(0));
    });

    _widgets('lays out the same size when measured dry', (tester) async {
      for (final scale in [1.0, 2.0]) {
        await tester.pumpWidget(host(_map(view: stress()), textScale: scale));
        final plan = tester.renderObject<RenderBox>(
          find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == '_PlanLayout',
          ),
        );
        expect(
          plan.getDryLayout(BoxConstraints(maxWidth: plan.size.width)),
          plan.size,
        );
        expect(plan.getMinIntrinsicHeight(plan.size.width), plan.size.height);
      }
    });
  });

  group('the touch area', () {
    _widgets('every tile answers a touch anywhere inside it', (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(host(_map(onRoomTap: tapped.add), width: 600));

      for (final id in _roomIds) {
        final rect = tester.getRect(_room(id));
        for (final point in [
          rect.topLeft + const Offset(1, 1),
          rect.topRight + const Offset(-1, 1),
          rect.bottomLeft + const Offset(1, -1),
          rect.bottomRight + const Offset(-1, -1),
        ]) {
          tapped.clear();
          await tester.tapAt(point);
          expect(tapped, [id], reason: '$id at $point');
        }
      }
    });

    _widgets('every tile is at least 48 by 48', (tester) async {
      await tester.pumpWidget(host(_map(), textScale: 2));

      for (final id in _roomIds) {
        final rect = tester.getRect(_room(id));
        expect(
          rect.width,
          greaterThanOrEqualTo(AppSizes.minTarget),
          reason: id,
        );
        expect(
          rect.height,
          greaterThanOrEqualTo(AppSizes.minTarget),
          reason: id,
        );
      }
    });

    _widgets('a beacon answers a touch over its whole 48 tall area, and a '
        'touch past it is the tile', (tester) async {
      final rooms = <String>[];
      final items = <String>[];
      await tester.pumpWidget(
        host(_map(onRoomTap: rooms.add, onItemTap: items.add)),
      );
      final beacon = tester.getRect(_item('washer'));
      expect(beacon.height, greaterThanOrEqualTo(AppSizes.minDrawn));

      for (final dy in [-23.5, 23.5]) {
        await tester.tapAt(beacon.center + Offset(0, dy));
      }
      expect(items, ['washer', 'washer']);
      expect(rooms, isEmpty);

      await tester.tapAt(beacon.center + const Offset(0, 28));
      expect(rooms, ['kitchen'], reason: 'past the beacon is the room');
      expect(items, hasLength(2));
    });

    _widgets('a member of the tray is a button at least 48 by 48 and the '
        'whole of it answers a touch', (tester) async {
      final members = <String>[];
      await tester.pumpWidget(host(_map(onMemberTap: members.add)));
      final rect = tester.getRect(_member('luis'));

      expect(rect.width, greaterThanOrEqualTo(AppSizes.minTarget));
      expect(rect.height, greaterThanOrEqualTo(AppSizes.minTarget));
      for (final point in [
        rect.topLeft + const Offset(1, 1),
        rect.topRight + const Offset(-1, 1),
        rect.bottomLeft + const Offset(1, -1),
        rect.bottomRight + const Offset(-1, -1),
      ]) {
        await tester.tapAt(point);
      }
      expect(members, ['luis', 'luis', 'luis', 'luis']);
    });

    _widgets('a member with no words is still 48 by 48', (tester) async {
      await tester.pumpWidget(
        host(
          _map(
            view: _view(
              absences: [
                FloorplanAbsence(member: _person('marta', 'Marta', 3)),
              ],
            ),
          ),
        ),
      );

      final rect = tester.getRect(_member('marta'));
      expect(rect.width, greaterThanOrEqualTo(AppSizes.minTarget));
      expect(rect.height, greaterThanOrEqualTo(AppSizes.minTarget));
    });

    _widgets('the 48 holds at 320 wide and 200% text: nothing shrinks a '
        'target and the tiles do not overlap', (tester) async {
      await tester.pumpWidget(host(_map(), textScale: 2));

      final rects = [for (final id in _roomIds) tester.getRect(_room(id))];
      for (var i = 0; i < rects.length; i++) {
        for (var j = i + 1; j < rects.length; j++) {
          expect(rects[i].overlaps(rects[j]), isFalse, reason: '$i and $j');
        }
      }
      final beacon = tester.getRect(_item('washer'));
      expect(beacon.height, greaterThanOrEqualTo(AppSizes.minDrawn));
    });
  });

  group('identity and focus across updates', () {
    Future<void> pumpView(WidgetTester tester, FloorplanView view) =>
        tester.pumpWidget(host(_map(view: view), width: 600));

    bool attached() {
      final focus = FocusManager.instance.primaryFocus;
      return focus == null || (focus.parent != null && focus.context != null);
    }

    _widgets('keeps the focus on a room when the same view is built again', (
      tester,
    ) async {
      await pumpView(tester, _view());
      await _focusRoom(tester, 'luis');
      final element = tester.element(_room('luis'));

      await pumpView(tester, _view());

      expect(_focusedKey(), 'floorplan.room.luis');
      expect(tester.element(_room('luis')), same(element));
    });

    _widgets('keeps a room, its focus and its element when the rooms change '
        'order', (tester) async {
      await pumpView(tester, _view());
      await _focusRoom(tester, 'luis');
      final element = tester.element(_room('luis'));
      final before = tester.getTopLeft(_room('luis'));

      final reversed = _view().rooms.reversed.toList();
      await pumpView(tester, _view(rooms: reversed));

      expect(_focusedKey(), 'floorplan.room.luis');
      expect(tester.element(_room('luis')), same(element));
      expect(tester.getTopLeft(_room('luis')), isNot(before));
    });

    _widgets('keeps the focus on a room that moves between the bedrooms and '
        'the common areas', (tester) async {
      await pumpView(tester, _view());
      await _focusRoom(tester, 'luis');
      final element = tester.element(_room('luis'));
      final before = tester.getTopLeft(_room('luis'));

      final moved = FloorplanRoom(
        room: _luis().room,
        kind: FloorplanRoomKind.common,
        state: _luis().state,
        caption: _luis().caption,
        semanticLabel: _luis().semanticLabel,
      );
      await pumpView(
        tester,
        _view(
          rooms: [
            for (final room in _view().rooms)
              if (room.room.id == 'luis') moved else room,
          ],
        ),
      );

      expect(_focusedKey(), 'floorplan.room.luis');
      expect(tester.element(_room('luis')), same(element));
      expect(tester.getTopLeft(_room('luis')), isNot(before));
    });

    _widgets('keeps the focus on a beacon through a rebuild, and nothing '
        'stale when its item goes away', (tester) async {
      await pumpView(tester, _view());
      await _focusKey(tester, 'floorplan.item.washer');

      await pumpView(tester, _view());
      expect(_focusedKey(), 'floorplan.item.washer');

      await pumpView(
        tester,
        _view(
          rooms: [
            _ana(),
            _kitchen(items: const []),
            _living(),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      expect(_item('washer'), findsNothing);
      expect(
        attached(),
        isTrue,
        reason: 'the focus is not on an unmounted node',
      );

      await tester.pump(const Duration(milliseconds: 300));
      await _tab(tester);
      expect(attached(), isTrue);
    });

    _widgets('a beacon keeps its element and its focus node when an item '
        'before it in the same room goes away', (tester) async {
      FloorplanItem item(String id, String name) => FloorplanItem(
        item: ItemView(id: id, name: name, icon: AppIcons.washer),
        inUse: false,
        statusLabel: 'Free',
        semanticLabel: '$name, free',
      );
      FloorplanView kitchen(List<FloorplanItem> items) => _view(
        rooms: [
          _ana(),
          _kitchen(items: items),
        ],
      );

      await pumpView(
        tester,
        kitchen([item('oven', 'Oven'), item('washer', 'Washer')]),
      );
      await _focusKey(tester, 'floorplan.item.washer');
      final element = tester.element(_item('washer'));
      final node = FocusManager.instance.primaryFocus;

      await pumpView(tester, kitchen([item('washer', 'Washer')]));

      expect(_item('oven'), findsNothing);
      expect(tester.element(_item('washer')), same(element));
      expect(FocusManager.instance.primaryFocus, same(node));
      expect(_focusedKey(), 'floorplan.item.washer');
    });

    _widgets('an item that moves to another room is drawn there and the '
        'map keeps working', (tester) async {
      await pumpView(tester, _view());

      await pumpView(
        tester,
        _view(
          rooms: [
            _ana(),
            _kitchen(items: const []),
            FloorplanRoom(
              room: _living().room,
              kind: _living().kind,
              state: _living().state,
              caption: _living().caption,
              semanticLabel: _living().semanticLabel,
              items: [_washer()],
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.descendant(of: _room('living'), matching: _item('washer')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _room('kitchen'), matching: _item('washer')),
        findsNothing,
      );
    });

    _widgets('a member of the tray keeps its focus and its element when the '
        'others come and go, and leaves no stale focus when it goes', (
      tester,
    ) async {
      final marta = FloorplanAbsence(
        member: _person('marta', 'Marta', 3, status: MemberStatus.away),
        label: 'until Sun',
      );
      await pumpView(tester, _view(absences: [_luisAway(), marta]));
      await _focusKey(tester, 'floorplan.member.marta');
      final element = tester.element(_member('marta'));

      await pumpView(tester, _view(absences: [marta]));
      expect(_focusedKey(), 'floorplan.member.marta');
      expect(tester.element(_member('marta')), same(element));

      await pumpView(tester, _view(absences: const []));
      expect(tester.takeException(), isNull);
      expect(_tray, findsNothing);
      expect(attached(), isTrue);
    });

    _widgets('a press in progress survives a rebuild of the same view', (
      tester,
    ) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        host(_map(view: _view(), onRoomTap: tapped.add), width: 600),
      );
      final gesture = await tester.startGesture(
        tester.getTopLeft(_room('luis')) + const Offset(6, 6),
      );
      await tester.pump(kPressTimeout);

      await tester.pumpWidget(
        host(_map(view: _view(), onRoomTap: tapped.add), width: 600),
      );
      await gesture.up();

      expect(tapped, ['luis']);
    });

    _widgets('going from loading to the plan builds it, and back', (
      tester,
    ) async {
      await pumpView(tester, _view(loading: true));
      expect(find.byType(RoomTile), findsNothing);

      await pumpView(tester, _view());
      expect(find.byType(RoomTile), findsNWidgets(7));

      await pumpView(tester, _view(loading: true));
      expect(tester.takeException(), isNull);
      expect(find.byType(RoomTile), findsNothing);
    });
  });

  group('the arithmetic of a row', () {
    FloorplanRoom common(String id, String name) => FloorplanRoom(
      room: RoomView(id: id, name: name),
      kind: FloorplanRoomKind.common,
      state: RoomTileState.free,
      caption: 'Free',
      semanticLabel: '$name, free',
    );

    FloorplanView threeCommon() => _view(
      rooms: [
        common('a', 'Kitchen'),
        common('b', 'Bathroom'),
        common('c', 'Storeroom'),
      ],
      absences: const [],
    );

    List<RenderBox> tiles(WidgetTester tester) => [
      for (final element in find.byType(RoomTile).evaluate())
        element.renderObject! as RenderBox,
    ];

    RenderBox plan(WidgetTester tester) => tester.renderObject<RenderBox>(
      find.byWidgetPredicate((w) => w.runtimeType.toString() == '_PlanLayout'),
    );

    _widgets('a row takes only as many tiles as leave each its longest word, '
        'the gaps between them included', (tester) async {
      await tester.pumpWidget(host(_map(view: threeCommon()), width: 900));
      var need = AppSizes.minTarget;
      for (final box in tiles(tester)) {
        need = need < box.getMinIntrinsicWidth(double.infinity)
            ? box.getMinIntrinsicWidth(double.infinity)
            : need;
      }
      // Three tiles fit without their two gaps and do not fit with them: the
      // plan is 3 * need + 8 wide, which is under 3 * need + 16.
      const around = 2 * (AppSpacing.sm + AppSpacing.sm);
      await tester.pumpWidget(
        host(
          _map(view: threeCommon()),
          width: 3 * need + AppSpacing.sm + around,
        ),
      );

      expect(
        tester.getTopLeft(_room('c')).dy,
        greaterThan(tester.getTopLeft(_room('a')).dy),
        reason: 'two across, then one',
      );
      expect(
        tester.getTopLeft(_room('b')).dy,
        tester.getTopLeft(_room('a')).dy,
      );
      for (final id in ['a', 'b', 'c']) {
        expect(
          tester.getSize(_room(id)).width,
          greaterThanOrEqualTo(need - 0.01),
          reason: '$id keeps the width of its longest word',
        );
      }

      // And one pixel of room for the two gaps puts all three in a row.
      await tester.pumpWidget(
        host(
          _map(view: threeCommon()),
          width: 3 * need + 2 * AppSpacing.sm + around,
        ),
      );
      expect(
        tester.getTopLeft(_room('c')).dy,
        tester.getTopLeft(_room('a')).dy,
      );
    });

    _widgets('measures its widest as the tiles side by side with the gaps '
        'between them, and its narrowest as the longest word', (tester) async {
      await tester.pumpWidget(host(_map(view: threeCommon()), width: 900));

      var widest = 0.0;
      var narrowest = AppSizes.minTarget;
      for (final box in tiles(tester)) {
        widest = widest > box.getMaxIntrinsicWidth(double.infinity)
            ? widest
            : box.getMaxIntrinsicWidth(double.infinity);
        narrowest = narrowest > box.getMinIntrinsicWidth(double.infinity)
            ? narrowest
            : box.getMinIntrinsicWidth(double.infinity);
      }
      final render = plan(tester);

      expect(
        render.getMaxIntrinsicWidth(double.infinity),
        closeTo(3 * widest + 2 * AppSpacing.sm, 0.01),
      );
      expect(render.getMinIntrinsicWidth(double.infinity), narrowest);
      expect(
        render.getMaxIntrinsicWidth(double.infinity),
        greaterThan(render.getMinIntrinsicWidth(double.infinity)),
      );
    });

    _widgets('relays out when the reading direction flips on a live map', (
      tester,
    ) async {
      await tester.pumpWidget(host(_map(view: threeCommon()), width: 900));
      await tester.pumpWidget(
        host(
          _map(view: threeCommon()),
          width: 900,
          direction: TextDirection.rtl,
        ),
      );
      final flipped = tester.getRect(_mapFinder);

      expect(
        tester.getTopRight(_room('a')).dx,
        closeTo(flipped.right - AppSpacing.sm - AppSpacing.sm, 0.01),
        reason: 'the first room is now at the right edge of the plan',
      );
    });
  });
}
