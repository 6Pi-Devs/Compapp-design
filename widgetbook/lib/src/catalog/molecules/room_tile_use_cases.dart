import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// Width of a tile, one cell of the plan. The golden harness sizes a scenario
/// to its content, so a tile that takes the space that is left would be drawn
/// with none.
const _tileWidth = 168.0;

/// Height of a cell of the plan. It is a least height: the tile grows with
/// large text.
const _cellHeight = 104.0;

/// One use case per state of the Molecules board: a bedroom whose owner is
/// home, one whose owner is away, an occupied bathroom and a free kitchen with
/// an oven pinned to it.
WidgetbookComponent buildRoomTile() {
  return WidgetbookComponent(
    name: 'RoomTile',
    useCases: [
      _playground(),
      for (final state in RoomTileState.values)
        WidgetbookUseCase(
          name: 'tile-${state.name}',
          builder: (context) => useCaseFrame(
            child: FrozenMotion(
              child: SizedBox(
                width: _tileWidth,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: _cellHeight),
                  child: _tile(context, state),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

Widget _tile(BuildContext context, RoomTileState state) {
  return switch (state) {
    RoomTileState.home => RoomTile(
      room: RoomView(
        id: 'ana',
        name: context.sample(en: "Ana's room", es: 'Cuarto de Ana'),
      ),
      state: state,
      caption: context.sample(en: 'home', es: 'en casa'),
      semanticLabel: context.sample(
        en: "Ana's room, Ana is home",
        es: 'Cuarto de Ana, Ana está en casa',
      ),
      occupants: const [
        MemberView(
          id: 'ana',
          name: 'Ana',
          initials: 'A',
          joinOrder: 0,
          semanticLabel: 'Ana',
        ),
      ],
    ),
    RoomTileState.away => RoomTile(
      room: RoomView(
        id: 'luis',
        name: context.sample(en: "Luis's room", es: 'Cuarto de Luis'),
      ),
      state: state,
      caption: context.sample(en: 'away', es: 'fuera'),
      semanticLabel: context.sample(
        en: "Luis's room, Luis is away",
        es: 'Cuarto de Luis, Luis está fuera',
      ),
    ),
    RoomTileState.occupied => RoomTile(
      room: RoomView(
        id: 'bathroom',
        name: context.sample(en: 'Bathroom', es: 'Baño'),
      ),
      state: state,
      caption: context.sample(en: 'occupied · 12 min', es: 'ocupado · 12 min'),
      semanticLabel: context.sample(
        en: 'Bathroom, occupied by Carlos, 12 minutes',
        es: 'Baño, ocupado por Carlos, 12 minutos',
      ),
      occupants: const [
        MemberView(
          id: 'carlos',
          name: 'Carlos',
          initials: 'C',
          joinOrder: 1,
          semanticLabel: 'Carlos',
        ),
      ],
    ),
    RoomTileState.free => RoomTile(
      room: RoomView(
        id: 'kitchen',
        name: context.sample(en: 'Kitchen', es: 'Cocina'),
      ),
      state: state,
      caption: context.sample(en: 'free', es: 'libre'),
      semanticLabel: context.sample(en: 'Kitchen, free', es: 'Cocina, libre'),
      beacons: [
        ItemBeacon(
          item: ItemView(
            id: 'oven',
            name: context.sample(en: 'Oven', es: 'Horno'),
            icon: AppIcons.oven,
          ),
          inUse: false,
          statusLabel: context.sample(en: 'free', es: 'libre'),
          semanticLabel: context.sample(en: 'Oven, free', es: 'Horno, libre'),
          onTap: () {},
        ),
      ],
    ),
  };
}

const _roster = [
  MemberView(
    id: 'ana',
    name: 'Ana',
    initials: 'A',
    joinOrder: 0,
    semanticLabel: 'Ana',
  ),
  MemberView(
    id: 'carlos',
    name: 'Carlos',
    initials: 'C',
    joinOrder: 1,
    semanticLabel: 'Carlos',
  ),
  MemberView(
    id: 'luis',
    name: 'Luis',
    initials: 'L',
    joinOrder: 2,
    semanticLabel: 'Luis',
  ),
];

const List<({String id, AppIcons icon})> _beaconSamples = [
  (id: 'oven', icon: AppIcons.oven),
  (id: 'washer', icon: AppIcons.washer),
  (id: 'dryer', icon: AppIcons.dryer),
];

({String name, String spoken}) _beaconText(BuildContext context, String id) {
  return switch (id) {
    'oven' => (
      name: context.sample(en: 'Oven', es: 'Horno'),
      spoken: context.sample(en: 'Oven, free', es: 'Horno, libre'),
    ),
    'washer' => (
      name: context.sample(en: 'Washer', es: 'Lavadora'),
      spoken: context.sample(en: 'Washer, free', es: 'Lavadora, libre'),
    ),
    _ => (
      name: context.sample(en: 'Dryer', es: 'Secadora'),
      spoken: context.sample(en: 'Dryer, free', es: 'Secadora, libre'),
    ),
  };
}

/// Every prop of [RoomTile] as a knob. The lists are knobs by count: how many
/// of three members stand in the room and how many of three items are pinned
/// to it. The callback is a switch: tappable gives the tile an onTap, off
/// leaves it plain. The tile fills a cell of the plan, as in the board.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final name = context.textKnob(
        'name',
        context.sample(en: "Ana's room", es: 'Cuarto de Ana'),
      );
      final state = context.enumKnob('state', RoomTileState.values);
      final caption = context.textKnob(
        'caption',
        context.sample(en: 'home', es: 'en casa'),
      );
      final sampleLabel = context.sample(
        en: "Ana's room, Ana is home",
        es: 'Cuarto de Ana, Ana está en casa',
      );
      final typedLabel = context.textKnob(
        'semanticLabel',
        sampleLabel,
        description: 'Must not be empty: an empty one falls back to the sample',
      );
      final occupants = context.knobs.int
          .slider(
            label: 'occupants',
            description: 'How many members stand in the room',
            initialValue: 1,
            max: _roster.length,
            divisions: _roster.length,
          )
          .clamp(0, _roster.length);
      final beacons = context.knobs.int
          .slider(
            label: 'beacons',
            description: 'How many items are pinned to the room',
            max: _beaconSamples.length,
            divisions: _beaconSamples.length,
          )
          .clamp(0, _beaconSamples.length);
      final tappable = context.knobs.boolean(
        label: 'tappable',
        description: 'Gives the tile an onTap: a button with a focus ring',
      );

      return useCaseFrame(
        child: SizedBox(
          width: _tileWidth,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _cellHeight),
            child: RoomTile(
              room: RoomView(id: 'playground', name: name),
              state: state,
              caption: caption,
              semanticLabel: typedLabel.isEmpty ? sampleLabel : typedLabel,
              occupants: _roster.take(occupants).toList(),
              onTap: tappable ? () {} : null,
              beacons: [
                for (final sample in _beaconSamples.take(beacons))
                  ItemBeacon(
                    item: ItemView(
                      id: sample.id,
                      name: _beaconText(context, sample.id).name,
                      icon: sample.icon,
                    ),
                    inUse: false,
                    statusLabel: context.sample(en: 'free', es: 'libre'),
                    semanticLabel: _beaconText(context, sample.id).spoken,
                    onTap: () {},
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
