import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// The rooms of the board, in the order they were made.
const _poolSize = 7;

/// The most archived rooms the playground adds to the plan, and the most
/// members it puts in the away tray.
const _maxArchived = 2;
const _maxAbsences = 2;

enum _Room { ana, bathroom, luis, kitchen, living, carlos, bedroom4 }

/// One use case per state of the Organisms board and its contract: the home of
/// the board with a member away, a home with no room yet, and the plan while it
/// loads. The washer breathes and the loading ring turns, so motion is frozen.
WidgetbookComponent buildFloorplanMap() {
  return WidgetbookComponent(
    name: 'FloorplanMap',
    useCases: [
      _playground(),
      WidgetbookUseCase(
        name: 'map-populated',
        builder: (context) => barFrame(
          child: FrozenMotion(child: _map(_view(context, rooms: _poolSize))),
        ),
      ),
      WidgetbookUseCase(
        name: 'map-empty',
        builder: (context) =>
            barFrame(child: _map(_view(context, rooms: 0, absences: 0))),
      ),
      WidgetbookUseCase(
        name: 'map-loading',
        builder: (context) => barFrame(
          child: FrozenMotion(
            child: _map(_view(context, rooms: 0, absences: 0, loading: true)),
          ),
        ),
      ),
    ],
  );
}

void _ignore(String id) {}

FloorplanMap _map(FloorplanView view) => FloorplanMap(
  view: view,
  onRoomTap: _ignore,
  onItemTap: _ignore,
  onMemberTap: _ignore,
);

MemberView _member(
  BuildContext context,
  String id,
  String name,
  int joinOrder, {
  MemberStatus status = MemberStatus.home,
}) {
  return MemberView(
    id: id,
    name: name,
    initials: name[0],
    joinOrder: joinOrder,
    status: status,
    semanticLabel: status == MemberStatus.away
        ? context.sample(en: '$name, away', es: '$name, fuera')
        : name,
  );
}

FloorplanItem _washer(BuildContext context, {required bool inUse}) {
  return FloorplanItem(
    item: ItemView(
      id: 'washer',
      name: context.sample(en: 'Washer', es: 'Lavadora'),
      icon: AppIcons.washer,
    ),
    inUse: inUse,
    statusLabel: inUse
        ? context.sample(en: '34 min', es: '34 min')
        : context.sample(en: 'Free', es: 'Libre'),
    semanticLabel: inUse
        ? context.sample(
            en: 'Washer, in use by Carlos, 34 minutes',
            es: 'Lavadora, en uso por Carlos, 34 minutos',
          )
        : context.sample(en: 'Washer, free', es: 'Lavadora, libre'),
  );
}

/// A room of the board by its position in the pool.
FloorplanRoom _room(
  BuildContext context,
  _Room which, {
  required bool washerInUse,
}) {
  return switch (which) {
    _Room.ana => FloorplanRoom(
      room: RoomView(
        id: 'ana',
        name: context.sample(en: "Ana's room", es: 'Cuarto de Ana'),
      ),
      kind: FloorplanRoomKind.bedroom,
      state: RoomTileState.home,
      caption: context.sample(en: 'Home · 3 h', es: 'En casa · 3 h'),
      semanticLabel: context.sample(
        en: "Ana's room, Ana is home, 3 hours",
        es: 'Cuarto de Ana, Ana está en casa, 3 horas',
      ),
      occupants: [_member(context, 'ana', 'Ana', 0)],
    ),
    _Room.bathroom => FloorplanRoom(
      room: RoomView(
        id: 'bathroom',
        name: context.sample(en: 'Bathroom', es: 'Baño'),
      ),
      kind: FloorplanRoomKind.common,
      state: RoomTileState.occupied,
      caption: context.sample(en: 'In use · 12 min', es: 'Ocupado · 12 min'),
      semanticLabel: context.sample(
        en: 'Bathroom, occupied by Carlos, 12 minutes',
        es: 'Baño, ocupado por Carlos, 12 minutos',
      ),
      occupants: [_member(context, 'carlos', 'Carlos', 1)],
    ),
    _Room.luis => FloorplanRoom(
      room: RoomView(
        id: 'luis',
        name: context.sample(en: "Luis's room", es: 'Cuarto de Luis'),
      ),
      kind: FloorplanRoomKind.bedroom,
      state: RoomTileState.away,
      caption: context.sample(en: 'Away', es: 'Fuera'),
      semanticLabel: context.sample(
        en: "Luis's room, Luis is away",
        es: 'Cuarto de Luis, Luis está fuera',
      ),
    ),
    _Room.kitchen => FloorplanRoom(
      room: RoomView(
        id: 'kitchen',
        name: context.sample(en: 'Kitchen', es: 'Cocina'),
      ),
      kind: FloorplanRoomKind.common,
      state: RoomTileState.free,
      caption: context.sample(en: 'Free', es: 'Libre'),
      semanticLabel: context.sample(en: 'Kitchen, free', es: 'Cocina, libre'),
      items: [_washer(context, inUse: washerInUse)],
    ),
    _Room.living => FloorplanRoom(
      room: RoomView(
        id: 'living',
        name: context.sample(en: 'Living room', es: 'Salón'),
      ),
      kind: FloorplanRoomKind.common,
      state: RoomTileState.free,
      caption: context.sample(en: 'Free', es: 'Libre'),
      semanticLabel: context.sample(
        en: 'Living room, free',
        es: 'Salón, libre',
      ),
    ),
    _Room.carlos => FloorplanRoom(
      room: RoomView(
        id: 'carlos',
        name: context.sample(en: "Carlos's room", es: 'Cuarto de Carlos'),
      ),
      kind: FloorplanRoomKind.bedroom,
      state: RoomTileState.home,
      caption: context.sample(en: 'Home · 5 h', es: 'En casa · 5 h'),
      semanticLabel: context.sample(
        en: "Carlos's room, Carlos is home, 5 hours",
        es: 'Cuarto de Carlos, Carlos está en casa, 5 horas',
      ),
      occupants: [_member(context, 'carlos', 'Carlos', 1)],
    ),
    _Room.bedroom4 => FloorplanRoom(
      room: RoomView(
        id: 'bedroom4',
        name: context.sample(en: 'Bedroom 4', es: 'Habitación 4'),
      ),
      kind: FloorplanRoomKind.bedroom,
      state: RoomTileState.free,
      caption: context.sample(en: 'Invite pending', es: 'Invitación pendiente'),
      semanticLabel: context.sample(
        en: 'Bedroom 4, invite pending',
        es: 'Habitación 4, invitación pendiente',
      ),
    ),
  };
}

/// A room that was archived: the plan does not draw it.
FloorplanRoom _archived(BuildContext context, int index) {
  final name = index == 0
      ? context.sample(en: 'Storeroom', es: 'Trastero')
      : context.sample(en: 'Garage', es: 'Garaje');
  return FloorplanRoom(
    room: RoomView(id: 'archived$index', name: name),
    kind: FloorplanRoomKind.common,
    state: RoomTileState.free,
    caption: context.sample(en: 'Free', es: 'Libre'),
    semanticLabel: context.sample(en: '$name, free', es: '$name, libre'),
    archived: true,
  );
}

FloorplanAbsence _absence(BuildContext context, int index) {
  return index == 0
      ? FloorplanAbsence(
          member: _member(
            context,
            'luis',
            'Luis',
            2,
            status: MemberStatus.away,
          ),
          label: context.sample(en: 'until Fri', es: 'hasta el vie'),
        )
      : FloorplanAbsence(
          member: _member(
            context,
            'marta',
            'Marta',
            3,
            status: MemberStatus.away,
          ),
          label: context.sample(en: 'until Sun', es: 'hasta el dom'),
        );
}

String _awayLabel(BuildContext context) =>
    context.sample(en: 'Away', es: 'Fuera');
String _emptyTitle(BuildContext context) =>
    context.sample(en: 'No rooms yet', es: 'Todavía no hay habitaciones');
String _emptyBody(BuildContext context) => context.sample(
  en: 'Add the rooms of the home to see them here.',
  es: 'Añade las habitaciones de la casa para verlas aquí.',
);
String _loadingLabel(BuildContext context) =>
    context.sample(en: 'Loading the plan', es: 'Cargando el plano');

FloorplanView _view(
  BuildContext context, {
  required int rooms,
  int absences = 1,
  int archived = 0,
  bool washerInUse = true,
  bool loading = false,
  String? awayLabel,
  String? emptyTitle,
  String? emptyBody,
  String? loadingLabel,
  String? firstName,
  String? firstCaption,
}) {
  final shown = [
    for (final which in _Room.values.take(rooms))
      _room(context, which, washerInUse: washerInUse),
  ];
  if (shown.isNotEmpty && (firstName != null || firstCaption != null)) {
    final first = shown.first;
    final name = firstName ?? first.room.name;
    final caption = firstCaption ?? first.caption;
    shown[0] = FloorplanRoom(
      room: RoomView(id: first.room.id, name: name),
      kind: first.kind,
      state: first.state,
      caption: caption,
      // The spoken label must say the visible name in the same words.
      semanticLabel: name == first.room.name
          ? first.semanticLabel
          : '$name, $caption',
      occupants: first.occupants,
      items: first.items,
    );
  }
  return FloorplanView(
    rooms: [...shown, for (var i = 0; i < archived; i++) _archived(context, i)],
    absences: [for (var i = 0; i < absences; i++) _absence(context, i)],
    awayLabel: awayLabel ?? _awayLabel(context),
    emptyTitle: emptyTitle ?? _emptyTitle(context),
    emptyBody: emptyBody ?? _emptyBody(context),
    loadingLabel: loadingLabel ?? _loadingLabel(context),
    loading: loading,
  );
}

/// Every prop of [FloorplanMap] as a knob. The view is a knob for each part of
/// it: how many of the seven rooms of the board are on the plan, how many
/// archived rooms the home also has (the plan does not draw them), how many of
/// two members are in the away tray, whether the washer of the kitchen is in
/// use, whether the plan is loading, the name and the caption of the first room
/// and the four words around the plan. The callbacks are plumbing: the story
/// owns them.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final rooms = context.knobs.int
          .slider(
            label: 'rooms',
            description: 'How many of the seven rooms of the board',
            initialValue: _poolSize,
            max: _poolSize,
            divisions: _poolSize,
          )
          .clamp(0, _poolSize);
      final archived = context.knobs.int
          .slider(
            label: 'archivedRooms',
            description: 'Archived rooms, which the plan does not draw',
            max: _maxArchived,
            divisions: _maxArchived,
          )
          .clamp(0, _maxArchived);
      final absences = context.knobs.int
          .slider(
            label: 'absences',
            description: 'Members in the away tray',
            initialValue: 1,
            max: _maxAbsences,
            divisions: _maxAbsences,
          )
          .clamp(0, _maxAbsences);
      final washerInUse = context.knobs.boolean(
        label: 'washerInUse',
        description: 'The washer of the kitchen is in use',
        initialValue: true,
      );
      final loading = context.knobs.boolean(
        label: 'loading',
        description: 'The plan is loading: a ring and nothing else',
      );
      final sample = _room(context, _Room.ana, washerInUse: washerInUse);
      final firstName = context.textKnob(
        'firstRoomName',
        sample.room.name,
        description: 'Name of the first room, empty falls back to the sample',
      );
      final firstCaption = context.textKnob(
        'firstRoomCaption',
        sample.caption,
        description: 'Caption of the first room, empty falls back',
      );
      final awayLabel = context.textKnob(
        'awayLabel',
        _awayLabel(context),
        description: 'Heading of the away tray, empty falls back',
      );
      final emptyTitle = context.textKnob(
        'emptyTitle',
        _emptyTitle(context),
        description: 'Title when no room is drawn, empty falls back',
      );
      final emptyBody = context.textKnob(
        'emptyBody',
        _emptyBody(context),
        description: 'Body when no room is drawn, empty falls back',
      );
      final loadingLabel = context.textKnob(
        'loadingLabel',
        _loadingLabel(context),
        description: 'Spoken name of the plan while it loads, empty falls back',
      );
      // A playground can grow taller than the preview, and the organism is not
      // a scrollable: it scrolls as it would inside a screen.
      return SingleChildScrollView(
        child: barFrame(
          child: _map(
            _view(
              context,
              rooms: rooms,
              absences: absences,
              archived: archived,
              washerInUse: washerInUse,
              loading: loading,
              awayLabel: awayLabel.isEmpty ? null : awayLabel,
              emptyTitle: emptyTitle.isEmpty ? null : emptyTitle,
              emptyBody: emptyBody.isEmpty ? null : emptyBody,
              loadingLabel: loadingLabel.isEmpty ? null : loadingLabel,
              firstName: firstName.isEmpty ? null : firstName,
              firstCaption: firstCaption.isEmpty ? null : firstCaption,
            ),
          ),
        ),
      );
    },
  );
}
