import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// The most rooms of each list the playground shows: the length of each
/// sample pool.
const _bedroomPool = 3;
const _commonPool = 2;
const _archivedPool = 2;

/// One use case per state of the Organisms board and its contract: the
/// editor as the board draws it, the same with an archived room, the same with
/// the assign list open, and the home that cannot take another room. The
/// editor draws no motion, so none is frozen.
WidgetbookComponent buildRoomEditor() {
  return WidgetbookComponent(
    name: 'RoomEditor',
    useCases: [
      _playground(),
      WidgetbookUseCase(
        name: 'editor-default',
        builder: (context) => barFrame(child: _editor(_view(context))),
      ),
      WidgetbookUseCase(
        name: 'editor-archived-rooms',
        builder: (context) =>
            barFrame(child: _editor(_view(context, archived: 1))),
      ),
      WidgetbookUseCase(
        name: 'editor-assign-open',
        builder: (context) =>
            barFrame(child: _editor(_view(context), open: const {'bedroom-1'})),
      ),
      WidgetbookUseCase(
        name: 'editor-limit-reached',
        builder: (context) => barFrame(
          child: _editor(
            _view(context, archived: 2, limitMessage: _limit(context)),
          ),
        ),
      ),
    ],
  );
}

RoomEditor _editor(RoomEditorView view, {Set<String> open = const {}}) =>
    RoomEditor(
      view: view,
      initialAssignOpen: open,
      onAdd: _noop,
      onEdit: _ignore,
      onArchive: _ignore,
      onRestore: _ignore,
      onAssign: _ignoreAssign,
    );

void _noop() {}

void _ignore(String id) {}

void _ignoreAssign(String roomId, String accountId) {}

/// A sample member: the stable ids and join orders keep the pebble colors the
/// same in every story.
enum _Person {
  ana('ana', 'A', 0),
  carlos('carlos', 'C', 1),
  sara('sara', 'S', 2),
  luis('luis', 'L', 3);

  new(this.id, this.initials, this.joinOrder);

  final String id;
  final String initials;
  final int joinOrder;
}

String _name(BuildContext context, _Person person) => switch (person) {
  _Person.ana => context.sample(en: 'Ana (you)', es: 'Ana (tú)'),
  _Person.carlos => 'Carlos',
  _Person.sara => 'Sara',
  _Person.luis => 'Luis',
};

MemberView _member(BuildContext context, _Person person) {
  final name = _name(context, person);
  return MemberView(
    id: person.id,
    name: name,
    initials: person.initials,
    joinOrder: person.joinOrder,
    isYou: person == _Person.ana,
    semanticLabel: person == _Person.ana
        ? context.sample(en: 'Ana, you, at home', es: 'Ana, tú, en casa')
        : context.sample(en: '$name, at home', es: '$name, en casa'),
  );
}

/// The sample bedrooms. Every member sleeps in one: Ana in the first, Carlos in
/// the second, Sara and Luis in the third. The options are members that sleep
/// elsewhere and could move in, so nobody without a bedroom is offered one.
enum _Bedroom {
  first('bedroom-1', 1, 2, [_Person.ana], [_Person.sara, _Person.luis]),
  second('bedroom-2', 2, 1, [_Person.carlos], []),
  third(
    'bedroom-3',
    3,
    3,
    [_Person.sara, _Person.luis],
    [_Person.ana, _Person.carlos],
  );

  new(this.id, this.number, this.beds, this.occupants, this.options);

  final String id;
  final int number;
  final int beds;
  final List<_Person> occupants;
  final List<_Person> options;
}

String _bedroomName(BuildContext context, _Bedroom bedroom) => context.sample(
  en: 'Bedroom ${bedroom.number}',
  es: 'Dormitorio ${bedroom.number}',
);

/// The line under a bedroom: who sleeps there and how many beds that takes.
String _subtitleFor(BuildContext context, List<_Person> people, int beds) {
  if (people.isEmpty) {
    return context.sample(en: 'Free, $beds beds', es: 'Libre, $beds camas');
  }
  final names = people.map((p) => _name(context, p)).join(', ');
  return context.sample(
    en: '$names · ${people.length} of $beds ${beds == 1 ? 'bed' : 'beds'}',
    es: '$names · ${people.length} de $beds ${beds == 1 ? 'cama' : 'camas'}',
  );
}

RoomEditorRoom _bedroom(
  BuildContext context,
  _Bedroom bedroom, {
  String? subtitle,
  List<_Person>? occupants,
  List<_Person>? options,
  String? editLabel,
  String? archiveLabel,
  String? assignLabel,
}) {
  final name = _bedroomName(context, bedroom);
  final sleeping = occupants ?? bedroom.occupants;
  final offered = options ?? bedroom.options;
  return RoomEditorRoom(
    room: RoomView(id: bedroom.id, name: name),
    subtitle: subtitle ?? _subtitleFor(context, sleeping, bedroom.beds),
    occupants: [for (final p in sleeping) _member(context, p)],
    assignOptions: [
      for (final p in offered)
        RoomAssignOption(
          member: _member(context, p),
          semanticLabel: context.sample(
            en: 'Move ${_name(context, p)} to $name',
            es: 'Mover a ${_name(context, p)} a $name',
          ),
        ),
    ],
    editLabel:
        editLabel ?? context.sample(en: 'Edit $name', es: 'Editar $name'),
    archiveLabel:
        archiveLabel ??
        context.sample(en: 'Archive $name', es: 'Archivar $name'),
    assignLabel: offered.isEmpty
        ? null
        : assignLabel ??
              context.sample(
                en: 'Assign someone to $name',
                es: 'Asignar a alguien a $name',
              ),
  );
}

enum _Common {
  kitchen('kitchen'),
  bathroom('bathroom');

  new(this.id);

  final String id;
}

RoomEditorRoom _common(BuildContext context, _Common area) {
  final name = switch (area) {
    _Common.kitchen => context.sample(en: 'Kitchen', es: 'Cocina'),
    _Common.bathroom => context.sample(en: 'Bathroom', es: 'Baño'),
  };
  return RoomEditorRoom(
    room: RoomView(id: area.id, name: name),
    editLabel: context.sample(en: 'Edit $name', es: 'Editar $name'),
    archiveLabel: context.sample(en: 'Archive $name', es: 'Archivar $name'),
  );
}

enum _Archived {
  office('office'),
  storage('storage');

  new(this.id);

  final String id;
}

RoomEditorArchivedRoom _archivedRoom(
  BuildContext context,
  _Archived room, {
  String? subtitle,
  String? restoreLabel,
}) {
  final name = switch (room) {
    _Archived.office => context.sample(en: 'Office', es: 'Despacho'),
    _Archived.storage => context.sample(en: 'Storage', es: 'Trastero'),
  };
  return RoomEditorArchivedRoom(
    room: RoomView(id: room.id, name: name),
    restoreLabel:
        restoreLabel ??
        context.sample(en: 'Restore $name', es: 'Restaurar $name'),
    subtitle:
        subtitle ??
        context.sample(en: 'Archived 3 Mar', es: 'Archivado el 3 mar'),
  );
}

String _limit(BuildContext context) => context.sample(
  en: 'The home has 30 rooms, archived ones included',
  es: 'La casa tiene 30 estancias, contando las archivadas',
);

RoomEditorView _view(
  BuildContext context, {
  int archived = 0,
  String? limitMessage,
}) => RoomEditorView(
  bedroomsTitle: context.sample(en: 'Bedrooms', es: 'Dormitorios'),
  commonAreasTitle: context.sample(en: 'Common areas', es: 'Zonas comunes'),
  archivedTitle: context.sample(en: 'Archived', es: 'Archivadas'),
  addLabel: context.sample(en: 'Add room', es: 'Añadir estancia'),
  assignLabel: context.sample(en: 'Assign', es: 'Asignar'),
  bedrooms: [for (final b in _Bedroom.values) _bedroom(context, b)],
  commonAreas: [for (final c in _Common.values) _common(context, c)],
  archived: [
    for (final a in _Archived.values.take(archived)) _archivedRoom(context, a),
  ],
  limitMessage: limitMessage,
);

/// Every prop of [RoomEditor] as a knob: how many rooms of each list (from the
/// sample pools), the headings and the words of the add and assign buttons,
/// the limit message, and the first bedroom in detail (its subtitle, who
/// sleeps there, who can be moved in, whether its assign list starts open and
/// the spoken names of its three buttons) and the subtitle and the restore
/// label of the first archived room. The callbacks are plumbing: the story
/// owns them.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      int count(String label, int initial, int max, String description) =>
          context.knobs.int
              .slider(
                label: label,
                description: description,
                initialValue: initial,
                max: max,
                divisions: max,
              )
              .clamp(0, max);
      final bedrooms = count('bedrooms', 3, _bedroomPool, 'How many bedrooms');
      final common = count('commonAreas', 2, _commonPool, 'How many areas');
      final archived = count(
        'archived',
        0,
        _archivedPool,
        'How many archived rooms',
      );
      final occupants = count(
        'occupants',
        1,
        2,
        'Members that sleep in the first bedroom',
      );
      final options = count(
        'assignOptions',
        2,
        2,
        'Members that can be moved into the first bedroom, none leaves out '
            'the assign button',
      );
      String text(String label, String initial) {
        final typed = context.textKnob(
          label,
          initial,
          description: 'An empty one falls back to the sample',
        );
        return typed.isEmpty ? initial : typed;
      }

      final first = _bedroom(context, _Bedroom.first);
      final bedroomsTitle = text(
        'bedroomsTitle',
        context.sample(en: 'Bedrooms', es: 'Dormitorios'),
      );
      final commonTitle = text(
        'commonAreasTitle',
        context.sample(en: 'Common areas', es: 'Zonas comunes'),
      );
      final archivedTitle = text(
        'archivedTitle',
        context.sample(en: 'Archived', es: 'Archivadas'),
      );
      final addLabel = text(
        'addLabel',
        context.sample(en: 'Add room', es: 'Añadir estancia'),
      );
      final assignLabel = text(
        'assignLabel',
        context.sample(en: 'Assign', es: 'Asignar'),
      );
      final limit = context.textKnobOrNull(
        'limitMessage',
        null,
        description: 'Disables the add button and says why',
      );
      final subtitle = context.textKnobOrNull(
        'subtitle',
        null,
        description:
            'The line under the name of the first bedroom, null says who '
            'sleeps there and how many beds that takes',
      );
      final assignOpen = context.knobs.boolean(
        label: 'assignOpen',
        description: 'Starts with the assign list of the first bedroom open',
      );
      final editLabel = text('editLabel', first.editLabel);
      final archiveLabel = text('archiveLabel', first.archiveLabel);
      final typedAssign = text('roomAssignLabel', first.assignLabel!);
      // The spoken label holds the visible one (label in name): the editor
      // checks it, so a typed label that lacks it gets it in front.
      String spoken(String label) =>
          label.contains(assignLabel) ? label : '$assignLabel $label';
      final roomAssignLabel = spoken(typedAssign);
      final restoreLabel = text(
        'restoreLabel',
        _archivedRoom(context, _Archived.office).restoreLabel,
      );
      final archivedSubtitle = context.textKnobOrNull(
        'archivedSubtitle',
        context.sample(en: 'Archived 3 Mar', es: 'Archivado el 3 mar'),
        description: 'The line under the first archived room',
      );

      RoomEditorRoom bedroomAt(int i, _Bedroom b) {
        if (i > 0) {
          final label = _bedroom(context, b).assignLabel;
          return _bedroom(
            context,
            b,
            assignLabel: label == null ? null : spoken(label),
          );
        }
        return _bedroom(
          context,
          b,
          subtitle: subtitle,
          occupants: [_Person.ana, _Person.luis].take(occupants).toList(),
          options: [_Person.sara, _Person.carlos].take(options).toList(),
          editLabel: editLabel,
          archiveLabel: archiveLabel,
          assignLabel: roomAssignLabel,
        );
      }

      final bedroomRooms = [
        for (final (i, b) in _Bedroom.values.take(bedrooms).indexed)
          bedroomAt(i, b),
      ];

      // A playground can grow taller than the preview, and the organism is not
      // a scrollable: it scrolls as it would inside a screen.
      return SingleChildScrollView(
        child: barFrame(
          child: _editor(
            RoomEditorView(
              bedroomsTitle: bedroomsTitle,
              commonAreasTitle: commonTitle,
              archivedTitle: archivedTitle,
              addLabel: addLabel,
              assignLabel: assignLabel,
              bedrooms: bedroomRooms,
              commonAreas: [
                for (final c in _Common.values.take(common))
                  _common(context, c),
              ],
              archived: [
                for (final (i, a) in _Archived.values.take(archived).indexed)
                  _archivedRoom(
                    context,
                    a,
                    subtitle: i == 0 ? archivedSubtitle : null,
                    restoreLabel: i == 0 ? restoreLabel : null,
                  ),
              ],
              limitMessage: limit,
            ),
            open: assignOpen ? const {'bedroom-1'} : const {},
          ),
        ),
      );
    },
  );
}
