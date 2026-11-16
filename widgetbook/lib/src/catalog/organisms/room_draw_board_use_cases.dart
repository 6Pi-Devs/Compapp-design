import 'package:compapp_design/compapp_design.dart';
import 'package:compapp_design_widgetbook/src/catalog/use_case_paths.dart';
import 'package:compapp_design_widgetbook/src/support/localized_sample.dart';
import 'package:compapp_design_widgetbook/src/support/playground_knobs.dart';
import 'package:compapp_design_widgetbook/src/support/story_support.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// One use case per variant and state of the Organisms board and its
/// contract: the pending result and the applied one, each as the admin sees it
/// (both buttons, or Draw again alone once applied) and as a member sees it
/// (the note instead of the buttons). The board draws no motion, so none is
/// frozen.
WidgetbookComponent buildRoomDrawBoard() {
  return WidgetbookComponent(
    name: 'RoomDrawBoard',
    useCases: [
      _playground(),
      for (final admin in [true, false])
        for (final status in RoomDrawStatus.values)
          WidgetbookUseCase(
            name: '${admin ? 'admin' : 'member'}-${status.name}',
            builder: (context) => barFrame(
              child: _board(
                _view(context, status: status, isAdmin: admin),
                canDraw: admin,
                canApply: admin,
              ),
            ),
          ),
    ],
  );
}

RoomDrawBoard _board(
  RoomDrawView view, {
  bool canDraw = true,
  bool canApply = true,
}) => RoomDrawBoard(
  view: view,
  onDrawAgain: canDraw ? _noop : null,
  onApply: canApply ? _noop : null,
);

void _noop() {}

/// The home of the samples. Ana is the admin. Before the draw Ana slept in
/// Bedroom 1, Luis in Bedroom 2 (two beds, shared with Sara when she is in the
/// sample) and Carlos in Bedroom 3, and Bedroom 4 (two beds) was empty. The
/// draw puts every member in a bedroom, each group in a different one that
/// holds it, and leaves Bedroom 3 free. The join orders keep the pebble colors
/// the same in every story.
enum _Person {
  ana('ana', 'Ana', 'A', 0),
  carlos('carlos', 'Carlos', 'C', 1),
  luis('luis', 'Luis', 'L', 2),
  sara('sara', 'Sara', 'S', 3);

  new(this.id, this.name, this.initials, this.joinOrder);

  final String id;
  final String name;
  final String initials;
  final int joinOrder;

  MemberView get member => MemberView(
    id: id,
    name: name,
    initials: initials,
    joinOrder: joinOrder,
    isAdmin: this == ana,
    semanticLabel: name,
  );
}

/// A bedroom of the draw: its id, its number, its beds, where its group comes
/// from (the number of the bedroom they had) and who goes there.
enum _Bedroom {
  first('bedroom-1', 1, 1, 3, [_Person.carlos]),
  second('bedroom-2', 2, 2, 1, [_Person.ana]),
  third('bedroom-3', 3, 1, null, []),
  fourth('bedroom-4', 4, 2, 2, [_Person.luis]);

  new(this.id, this.number, this.beds, this.from, this.people);

  final String id;
  final int number;
  final int beds;
  final int? from;
  final List<_Person> people;
}

String _name(BuildContext context, _Bedroom bedroom) {
  final number = bedroom.number;
  final beds = bedroom.beds;
  if (beds == 1) {
    return context.sample(en: 'Bedroom $number', es: 'Dormitorio $number');
  }
  return context.sample(
    en: 'Bedroom $number · $beds beds',
    es: 'Dormitorio $number · $beds camas',
  );
}

String _caption(BuildContext context, int? from) => from == null
    ? context.sample(en: 'Stays free', es: 'Queda libre')
    : context.sample(en: 'from Bedroom $from', es: 'desde Dormitorio $from');

/// The bedroom as the draw gives it. [people] and [caption] replace the
/// sample ones, and the spoken label is built from what is drawn, so it holds
/// the visible name and caption (label in name).
RoomDrawRoom _room(
  BuildContext context,
  _Bedroom bedroom, {
  List<_Person>? people,
  String? caption,
}) {
  final name = _name(context, bedroom);
  final going = people ?? bedroom.people;
  final line =
      caption ?? _caption(context, going.isEmpty ? null : bedroom.from);
  final who = going
      .map((p) => p.name)
      .join(context.sample(en: ' and ', es: ' y '));
  return RoomDrawRoom(
    room: RoomView(id: bedroom.id, name: name),
    caption: line,
    members: [for (final p in going) p.member],
    semanticLabel: going.isEmpty ? '$name, $line' : '$name: $who, $line',
  );
}

String _pendingLabel(BuildContext context) =>
    context.sample(en: 'Waiting to be applied', es: 'Pendiente de aplicar');

String _appliedLabel(BuildContext context) =>
    context.sample(en: 'Applied', es: 'Aplicado');

String _drawAgain(BuildContext context) =>
    context.sample(en: 'Draw again', es: 'Sortear de nuevo');

String _apply(BuildContext context) =>
    context.sample(en: 'Apply result', es: 'Aplicar resultado');

String _note(BuildContext context) => context.sample(
  en: 'Only Ana can draw again or apply the result',
  es: 'Solo Ana puede sortear de nuevo o aplicar el resultado',
);

RoomDrawView _view(
  BuildContext context, {
  required RoomDrawStatus status,
  required bool isAdmin,
}) => RoomDrawView(
  drawId: 'draw-1',
  status: status,
  statusLabel: status == RoomDrawStatus.pending
      ? _pendingLabel(context)
      : _appliedLabel(context),
  bedrooms: [for (final b in _Bedroom.values) _room(context, b)],
  drawAgainLabel: _drawAgain(context),
  applyLabel: _apply(context),
  isAdmin: isAdmin,
  readOnlyNote: isAdmin ? null : _note(context),
);

/// Every prop of [RoomDrawBoard] as a knob: the status and its word, the draw
/// id, how many of the four bedrooms (only the free one can be left out, since
/// a draw puts every member in a bedroom), who goes to the two-bed Bedroom 4
/// (one person or a group of two that shared Bedroom 2, so the group fits),
/// the caption of the first bedroom, whether the person is the
/// admin, the words of the two buttons and of the note, and one switch for
/// each callback (off means the action is not offered). The callbacks are
/// plumbing: the story owns them. The note shows only while the admin switch
/// is off, and Apply result only while the status is pending, which is a rule
/// of the board, so those knobs have no effect otherwise.
WidgetbookUseCase _playground() {
  return WidgetbookUseCase(
    name: playgroundUseCaseName,
    builder: (context) {
      final status = context.enumKnob('status', RoomDrawStatus.values);
      String text(String label, String initial, [String? description]) {
        final typed = context.textKnob(
          label,
          initial,
          description: description ?? 'An empty one falls back to the sample',
        );
        return typed.isEmpty ? initial : typed;
      }

      final statusLabel = text(
        'statusLabel',
        status == RoomDrawStatus.pending
            ? _pendingLabel(context)
            : _appliedLabel(context),
      );
      final drawId = text(
        'drawId',
        'draw-1',
        'Keys the list of bedrooms: a new id replaces the result',
      );
      final count = context.knobs.int
          .slider(
            label: 'bedrooms',
            description:
                'How many bedrooms the draw has. A draw puts every member in '
                'a bedroom, so only the free Bedroom 3 can be left out',
            initialValue: _Bedroom.values.length,
            min: _Bedroom.values.length - 1,
            max: _Bedroom.values.length,
            divisions: 1,
          )
          .clamp(_Bedroom.values.length - 1, _Bedroom.values.length);
      final group = context.knobs.int
          .slider(
            label: 'groupInFourth',
            description:
                'Who goes to the two-bed Bedroom 4: Luis alone, or Luis and '
                'Sara, who shared Bedroom 2 and go together',
            initialValue: 1,
            min: 1,
            max: 2,
            divisions: 1,
          )
          .clamp(1, 2);
      final caption = text(
        'firstCaption',
        _caption(context, _Bedroom.first.from),
        'The line under the first bedroom. An empty one falls back to the '
            'sample',
      );
      final isAdmin = context.knobs.boolean(
        label: 'isAdmin',
        description: 'Off shows the note instead of the buttons',
        initialValue: true,
      );
      final drawAgain = text('drawAgainLabel', _drawAgain(context));
      final apply = text('applyLabel', _apply(context));
      final note = text('readOnlyNote', _note(context));
      final canDraw = context.knobs.boolean(
        label: 'canDrawAgain',
        description: 'Off passes no onDrawAgain: the button is not offered',
        initialValue: true,
      );
      final canApply = context.knobs.boolean(
        label: 'canApply',
        description: 'Off passes no onApply: the button is not offered',
        initialValue: true,
      );

      final rooms = [
        for (final b in _Bedroom.values)
          if (b.people.isNotEmpty || count == _Bedroom.values.length)
            _room(
              context,
              b,
              people: b == _Bedroom.fourth
                  ? [_Person.luis, _Person.sara].take(group).toList()
                  : null,
              caption: b == _Bedroom.first ? caption : null,
            ),
      ];

      // A playground can grow taller than the preview, and the organism is not
      // a scrollable: it scrolls as it would inside a screen.
      return SingleChildScrollView(
        child: barFrame(
          child: _board(
            RoomDrawView(
              drawId: drawId,
              status: status,
              statusLabel: statusLabel,
              bedrooms: rooms,
              drawAgainLabel: drawAgain,
              applyLabel: apply,
              isAdmin: isAdmin,
              readOnlyNote: isAdmin ? null : note,
            ),
            canDraw: canDraw,
            canApply: canApply,
          ),
        ),
      );
    },
  );
}
