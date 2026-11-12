import 'dart:ui' show Tristate;

import 'package:compapp_design/compapp_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/bundled_fonts.dart';
import '../helpers/contrast.dart';
import '../helpers/host.dart';
import '../helpers/word_breaks.dart';

const _ana = MemberView(
  id: 'ana',
  name: 'Ana Fernández',
  initials: 'A',
  joinOrder: 0,
  isYou: true,
  semanticLabel: 'Ana Fernández, tú, en casa',
);
const _carlos = MemberView(
  id: 'carlos',
  name: 'Carlos',
  initials: 'C',
  joinOrder: 1,
  semanticLabel: 'Carlos, en casa',
);
const _sara = MemberView(
  id: 'sara',
  name: 'Sara',
  initials: 'S',
  joinOrder: 2,
  semanticLabel: 'Sara, en casa',
);

const _marta = MemberView(
  id: 'marta',
  name: 'Marta',
  initials: 'M',
  joinOrder: 3,
  semanticLabel: 'Marta, en casa',
);

RoomAssignOption _option(MemberView member, String room) => RoomAssignOption(
  member: member,
  semanticLabel: 'Mover a ${member.name} a $room',
);

RoomEditorRoom _room(
  String id,
  String name, {
  String? subtitle,
  List<MemberView> occupants = const [],
  List<MemberView> options = const [],
}) => RoomEditorRoom(
  room: RoomView(id: id, name: name),
  subtitle: subtitle,
  occupants: occupants,
  assignOptions: [for (final member in options) _option(member, name)],
  editLabel: 'Editar $name',
  archiveLabel: 'Archivar $name',
  assignLabel: options.isEmpty ? null : 'Asignar a alguien a $name',
);

RoomEditorArchivedRoom _archived(String id, String name) =>
    RoomEditorArchivedRoom(
      room: RoomView(id: id, name: name),
      restoreLabel: 'Restaurar $name',
      subtitle: 'Archivado el 3 mar',
    );

RoomEditorView _view({
  List<RoomEditorRoom>? bedrooms,
  List<RoomEditorRoom>? commonAreas,
  List<RoomEditorArchivedRoom>? archived,
  String? limitMessage,
}) => RoomEditorView(
  bedroomsTitle: 'Dormitorios',
  commonAreasTitle: 'Zonas comunes',
  archivedTitle: 'Archivadas',
  addLabel: 'Añadir estancia',
  assignLabel: 'Asignar',
  bedrooms:
      bedrooms ??
      [
        _room(
          'b1',
          'Dormitorio 1',
          subtitle: 'Ana Fernández · 1 de 2 camas',
          occupants: [_ana],
          options: [_sara],
        ),
        _room('b2', 'Dormitorio 2', subtitle: 'Libre, 2 camas'),
      ],
  commonAreas: commonAreas ?? [_room('k', 'Cocina'), _room('w', 'Baño')],
  archived: archived ?? [_archived('o', 'Despacho')],
  limitMessage: limitMessage,
);

/// The calls the editor made, in order.
class _Log {
  final calls = <String>[];
}

Widget _editor(RoomEditorView view, _Log log, {Set<String> open = const {}}) =>
    RoomEditor(
      view: view,
      initialAssignOpen: open,
      onAdd: () => log.calls.add('add'),
      onEdit: (id) => log.calls.add('edit $id'),
      onArchive: (id) => log.calls.add('archive $id'),
      onRestore: (id) => log.calls.add('restore $id'),
      onAssign: (room, account) => log.calls.add('assign $room $account'),
    );

Future<void> _pump(
  WidgetTester tester,
  RoomEditorView view, {
  _Log? log,
  double width = hostWidth,
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
  ThemeData? theme,
}) async {
  tester.view
    ..physicalSize = const Size(800, 12000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    host(
      _editor(view, log ?? _Log()),
      width: width,
      textScale: textScale,
      direction: direction,
      theme: theme,
    ),
  );
}

Finder _k(String key) => find.byKey(Key(key));
Finder get _add => _k('rooms.add');
Finder _edit(String id) => _k('rooms.edit.$id');
Finder _archive(String id) => _k('rooms.archive.$id');
Finder _assign(String id) => _k('rooms.assign.$id');
Finder _restore(String id) => _k('rooms.restore.$id');
Finder _row(String id) => _k('rooms.$id');
Finder _option_(String room, String account) =>
    _k('rooms.option.$room.$account');

FocusNode _nodeOf(WidgetTester tester, Finder finder) {
  final widget = tester.widget(finder);
  return switch (widget) {
    TextButton(:final focusNode) =>
      focusNode ??
          Focus.of(
            tester.element(
              find.descendant(of: finder, matching: find.byType(AppIcon)),
            ),
          ),
    AppButton(:final focusNode) => focusNode!,
    _ => throw ArgumentError('no focus node on $widget'),
  };
}

void _traditional() {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

List<SemanticsNode> _children(SemanticsNode node) {
  final children = <SemanticsNode>[];
  node.visitChildren((child) {
    children.add(child);
    return true;
  });
  return children;
}

void main() {
  final themes = [('light', CompappTheme.light), ('dark', CompappTheme.dark)];

  group('content', () {
    testWidgets('lists the bedrooms, the common areas and the archived rooms '
        'under their headings, in that order', (tester) async {
      await _pump(tester, _view());

      for (final id in ['bedrooms', 'commonAreas', 'archived']) {
        expect(_k('rooms.section.$id'), findsOneWidget, reason: id);
      }
      final tops = [
        for (final id in ['b1', 'b2', 'k', 'w', 'o'])
          tester.getTopLeft(_row(id)).dy,
      ];
      expect(tops, [...tops]..sort());
      expect(tops.toSet(), hasLength(5));
      expect(find.text('Dormitorios'), findsOneWidget);
      expect(find.text('Zonas comunes'), findsOneWidget);
      expect(find.text('Archivadas'), findsOneWidget);
      expect(find.text('Ana Fernández · 1 de 2 camas'), findsOneWidget);
      expect(find.text('Archivado el 3 mar'), findsOneWidget);
    });

    testWidgets('leaves out the common areas and the archived rooms when there '
        'are none', (tester) async {
      await _pump(tester, _view(commonAreas: [], archived: []));

      expect(_k('rooms.section.bedrooms'), findsOneWidget);
      expect(_k('rooms.section.commonAreas'), findsNothing);
      expect(_k('rooms.section.archived'), findsNothing);
      expect(find.text('Zonas comunes'), findsNothing);
    });

    testWidgets('keeps the add button when there are no bedrooms', (
      tester,
    ) async {
      await _pump(tester, _view(bedrooms: [], commonAreas: [], archived: []));

      expect(_add, findsOneWidget);
      expect(find.byType(DecoratedBox), findsNothing);
    });

    testWidgets('draws one pebble for each occupant and none for a room with '
        'nobody', (tester) async {
      await _pump(
        tester,
        _view(
          bedrooms: [
            _room('b1', 'Dormitorio 1', occupants: [_ana, _carlos, _sara]),
            _room('b2', 'Dormitorio 2'),
          ],
        ),
      );

      expect(find.byType(AppPebble), findsNWidgets(3));
      for (final member in ['ana', 'carlos', 'sara']) {
        expect(_k('rooms.pebble.b1.$member'), findsOneWidget);
      }
    });

    testWidgets('wraps the pebbles of a crowded room inside three pebbles of '
        'width', (tester) async {
      final crowd = [
        for (var i = 0; i < 5; i++)
          MemberView(
            id: 'm$i',
            name: 'M$i',
            initials: 'M',
            joinOrder: i,
            semanticLabel: 'M$i',
          ),
      ];
      await _pump(
        tester,
        _view(bedrooms: [_room('b1', 'Dormitorio 1', occupants: crowd)]),
      );

      final first = tester.getRect(_k('rooms.pebble.b1.m0'));
      final fourth = tester.getRect(_k('rooms.pebble.b1.m3'));
      expect(fourth.top, greaterThan(first.top));
      expect(tester.getRect(_k('rooms.pebble.b1.m2')).top, first.top);
    });

    testWidgets('shows the limit message and disables the add button', (
      tester,
    ) async {
      final log = _Log();
      await _pump(
        tester,
        _view(limitMessage: 'La casa tiene 30 estancias'),
        log: log,
      );

      expect(_k('rooms.limit'), findsOneWidget);
      expect(find.text('La casa tiene 30 estancias'), findsOneWidget);
      expect(tester.widget<AppButton>(_add).onPressed, isNull);
      await tester.tap(_add, warnIfMissed: false);
      expect(log.calls, isEmpty);
    });

    testWidgets('has no limit message and an enabled add button by default', (
      tester,
    ) async {
      await _pump(tester, _view());

      expect(_k('rooms.limit'), findsNothing);
      expect(tester.widget<AppButton>(_add).onPressed, isNotNull);
    });
  });

  group('callbacks', () {
    testWidgets('add, edit and archive call back with the room id', (
      tester,
    ) async {
      final log = _Log();
      await _pump(tester, _view(), log: log);

      await tester.tap(_add);
      await tester.tap(_edit('b2'));
      await tester.tap(_archive('b2'));
      await tester.tap(_edit('k'));
      await tester.tap(_archive('w'));

      expect(log.calls, [
        'add',
        'edit b2',
        'archive b2',
        'edit k',
        'archive w',
      ]);
    });

    testWidgets('archive is enabled for a bedroom someone sleeps in and calls '
        'back', (tester) async {
      final log = _Log();
      await _pump(tester, _view(), log: log);

      expect(tester.widget<TextButton>(_archive('b1')).onPressed, isNotNull);
      await tester.tap(_archive('b1'));
      expect(log.calls, ['archive b1']);
    });

    testWidgets('the callbacks of a new widget replace the old ones', (
      tester,
    ) async {
      final first = _Log();
      final second = _Log();
      await _pump(tester, _view(), log: first);
      await tester.pumpWidget(host(_editor(_view(), second)));
      await tester.tap(_edit('k'));

      expect(first.calls, isEmpty);
      expect(second.calls, ['edit k']);
    });
  });

  group('assign list', () {
    testWidgets('has an assign button only for a bedroom with options', (
      tester,
    ) async {
      await _pump(tester, _view());

      expect(_assign('b1'), findsOneWidget);
      for (final id in ['b2', 'k', 'w']) {
        expect(_assign(id), findsNothing, reason: id);
      }
    });

    testWidgets('opens one button for each option and calls back with the '
        'room and the member', (tester) async {
      final log = _Log();
      await _pump(
        tester,
        _view(
          bedrooms: [
            _room(
              'b1',
              'Dormitorio 1',
              occupants: [_ana],
              options: [_carlos, _sara],
            ),
          ],
        ),
        log: log,
      );

      expect(_option_('b1', 'carlos'), findsNothing);
      await tester.tap(_assign('b1'));
      await tester.pump();
      expect(_option_('b1', 'carlos'), findsOneWidget);
      expect(_option_('b1', 'sara'), findsOneWidget);
      expect(find.text('Carlos'), findsOneWidget);

      await tester.tap(_option_('b1', 'sara'));
      await tester.tap(_option_('b1', 'carlos'));
      expect(log.calls, ['assign b1 sara', 'assign b1 carlos']);
    });

    testWidgets('closes again when the button is tapped twice', (tester) async {
      await _pump(tester, _view());

      await tester.tap(_assign('b1'));
      await tester.pump();
      expect(_option_('b1', 'sara'), findsOneWidget);
      await tester.tap(_assign('b1'));
      await tester.pump();
      expect(_option_('b1', 'sara'), findsNothing);
    });

    testWidgets('says on the button node whether the list is shown', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _view());
      Tristate expanded() => tester
          .getSemantics(
            find.bySemanticsLabel('Asignar a alguien a Dormitorio 1'),
          )
          .getSemanticsData()
          .flagsCollection
          .isExpanded;

      expect(expanded(), Tristate.isFalse);
      await tester.tap(_assign('b1'));
      await tester.pump();
      expect(expanded(), Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('stays open when the same view is built again', (tester) async {
      await _pump(tester, _view());
      await tester.tap(_assign('b1'));
      await tester.pump();

      await tester.pumpWidget(host(_editor(_view(), _Log())));
      await tester.pumpWidget(host(_editor(_view(), _Log())));
      expect(_option_('b1', 'sara'), findsOneWidget);
    });

    testWidgets('closes when the options go and opens as it was when they '
        'return', (tester) async {
      await _pump(tester, _view());
      await tester.tap(_assign('b1'));
      await tester.pump();

      await tester.pumpWidget(
        host(
          _editor(
            _view(
              bedrooms: [
                _room('b1', 'Dormitorio 1', occupants: [_ana, _sara]),
              ],
            ),
            _Log(),
          ),
        ),
      );
      expect(_assign('b1'), findsNothing);
      expect(_option_('b1', 'sara'), findsNothing);

      await tester.pumpWidget(host(_editor(_view(), _Log())));
      expect(_assign('b1'), findsOneWidget);
      expect(_option_('b1', 'sara'), findsNothing, reason: 'closed on return');
    });

    testWidgets('an option is a 48 tall button that wraps a long name', (
      tester,
    ) async {
      await _pump(
        tester,
        _view(
          bedrooms: [
            _room(
              'b1',
              'Dormitorio 1',
              options: [
                const MemberView(
                  id: 'long',
                  name: 'María de los Ángeles Fernández de la Vega',
                  initials: 'M',
                  joinOrder: 4,
                  semanticLabel: 'María de los Ángeles Fernández de la Vega',
                ),
              ],
            ),
          ],
        ),
        textScale: 2,
      );
      await tester.tap(_assign('b1'));
      await tester.pump();

      final option = _option_('b1', 'long');
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(option).height,
        greaterThanOrEqualTo(AppSizes.minTarget),
      );
      expect(tester.getSize(option).height, greaterThan(AppSizes.minTarget));
    });
  });

  group('semantics', () {
    testWidgets('a room is a list item with its texts as one node and every '
        'button named after its room', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _view());

      final row = tester.getSemantics(_row('b1'));
      expect(row.getSemanticsData().role, SemanticsRole.listItem);
      final children = _children(row);
      expect(children.map((node) => node.label), [
        'Dormitorio 1\nAna Fernández · 1 de 2 camas',
        'Editar Dormitorio 1',
        'Archivar Dormitorio 1',
        'Asignar a alguien a Dormitorio 1',
      ]);
      final edit = children[1].getSemanticsData();
      expect(edit.flagsCollection.isButton, isTrue);
      expect(edit.hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });

    testWidgets('every edit and archive button is an enabled button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _view());

      for (final label in [
        'Editar Dormitorio 1',
        'Archivar Dormitorio 1',
        'Archivar Cocina',
        'Restaurar Despacho',
      ]) {
        final data = tester
            .getSemantics(find.bySemanticsLabel(label))
            .getSemanticsData();
        expect(data.flagsCollection.isEnabled, Tristate.isTrue, reason: label);
        expect(data.hasAction(SemanticsAction.tap), isTrue, reason: label);
      }
      handle.dispose();
    });

    testWidgets('has a heading and a list for each section', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _view());

      for (final (id, title, items) in [
        ('bedrooms', 'Dormitorios', 2),
        ('commonAreas', 'Zonas comunes', 2),
        ('archived', 'Archivadas', 1),
      ]) {
        final section = tester.getSemantics(_k('rooms.section.$id'));
        final parts = _children(section);
        final heading = parts.firstWhere(
          (node) => node.getSemanticsData().flagsCollection.isHeader,
        );
        expect(heading.label, title);
        final list = parts.firstWhere(
          (node) => node.getSemanticsData().role == SemanticsRole.list,
        );
        expect(_children(list), hasLength(items), reason: id);
      }
      handle.dispose();
    });

    testWidgets('an archived room is a list item with its texts as one node '
        'and a restore button named after the room', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _view());

      final row = tester.getSemantics(_row('o'));
      expect(row.getSemanticsData().role, SemanticsRole.listItem);
      expect(_children(row).map((node) => node.label), [
        'Despacho\nArchivado el 3 mar',
        'Restaurar Despacho',
      ]);
      expect(
        find.descendant(of: _row('o'), matching: find.byType(TextButton)),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('the options are a list of items, each one button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        _view(
          bedrooms: [
            _room(
              'b1',
              'Dormitorio 1',
              occupants: [_ana],
              options: [_carlos, _sara],
            ),
          ],
        ),
      );
      await tester.tap(_assign('b1'));
      await tester.pump();

      final list = tester.getSemantics(_k('rooms.options.b1'));
      expect(list.getSemanticsData().role, SemanticsRole.list);
      final items = _children(list);
      expect(items, hasLength(2));
      for (final item in items) {
        expect(item.getSemanticsData().role, SemanticsRole.listItem);
        expect(
          _children(item).single.getSemanticsData().flagsCollection.isButton,
          isTrue,
        );
      }
      expect(items.map((i) => _children(i).single.label), [
        'Mover a Carlos a Dormitorio 1',
        'Mover a Sara a Dormitorio 1',
      ]);
      handle.dispose();
    });

    testWidgets('the pebbles add nothing to the spoken row', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _view());

      expect(
        semanticsLabels(tester).where((label) => label.contains('en casa')),
        isEmpty,
      );
      handle.dispose();
    });

    testWidgets('names every button with a label that holds its visible '
        'words (label in name)', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _view());

      final labels = semanticsLabels(tester);
      expect(labels, contains('Añadir estancia'));
      expect(labels.where((l) => l.contains('Asignar')), [
        'Asignar a alguien a Dormitorio 1',
      ]);
      expect(labels, contains('Editar Cocina'));
      expect(labels, contains('Archivar Baño'));
      handle.dispose();
    });
  });

  group('targets', () {
    testWidgets('every button has a hit area of 48 and the icon buttons are '
        '44 drawn', (tester) async {
      await _pump(tester, _view());
      await tester.tap(_assign('b1'));
      await tester.pump();

      for (final finder in [
        _add,
        _edit('b1'),
        _archive('b1'),
        _edit('k'),
        _archive('w'),
        _assign('b1'),
        _option_('b1', 'sara'),
      ]) {
        final size = tester.getSize(finder);
        expect(size.width, greaterThanOrEqualTo(AppSizes.minTarget));
        expect(size.height, greaterThanOrEqualTo(AppSizes.minTarget));
      }
      final drawn = tester.getSize(
        find.descendant(
          of: _edit('k'),
          matching: find.byWidgetPredicate(
            (w) => w is Material && w.type == MaterialType.button,
          ),
        ),
      );
      expect(drawn, const Size.square(AppSizes.minDrawn));
    });

    testWidgets('no button lights up its neighbor or the row', (tester) async {
      await _pump(tester, _view());

      expect(
        find.ancestor(of: _edit('k'), matching: find.byType(InkWell)),
        findsNothing,
      );
      expect(
        find.ancestor(of: _archive('k'), matching: find.byType(InkResponse)),
        findsNothing,
      );
      expect(
        tester.getRect(_edit('k')).overlaps(tester.getRect(_archive('k'))),
        isFalse,
      );
    });
  });

  group('layout', () {
    setUpAll(loadBundledFonts);

    final spanish = _view(
      bedrooms: [
        _room(
          'b1',
          'Dormitorio principal con baño integrado',
          subtitle: 'Ana Fernández · 1 de 2 camas, la cama grande',
          occupants: [_ana, _carlos, _sara],
          options: [_marta],
        ),
        _room('b2', 'Dormitorio 2', subtitle: 'Libre, 2 camas'),
      ],
      commonAreas: [
        _room('k', 'Cocina'),
        _room('l', 'Cuarto de la lavadora y el tendedero'),
      ],
    );

    for (final width in const [320.0, 360.0]) {
      for (final scale in const [1.0, 1.3, 1.5, 2.0]) {
        for (final direction in TextDirection.values) {
          testWidgets('fits and cuts nothing at $width, ${scale}x, '
              '$direction', (tester) async {
            await _pump(
              tester,
              spanish,
              width: width,
              textScale: scale,
              direction: direction,
            );
            await tester.tap(_assign('b1'));
            await tester.pump();
            final reason = '$width wide, ${scale}x, $direction';

            expect(tester.takeException(), isNull, reason: reason);
            final editor = tester.getRect(_k('rooms.editor'));
            expect(editor.width, width, reason: reason);
            for (final finder in [
              _add,
              ..._rowsFinders(),
              _option_('b1', 'marta'),
            ]) {
              final box = tester.getRect(finder);
              expect(box.left, greaterThanOrEqualTo(editor.left - 0.01));
              expect(box.right, lessThanOrEqualTo(editor.right + 0.01));
            }
            for (final text in [
              'Dormitorios',
              'Zonas comunes',
              'Archivadas',
              'Añadir estancia',
              'Dormitorio principal con baño integrado',
              'Ana Fernández · 1 de 2 camas, la cama grande',
              'Cuarto de la lavadora y el tendedero',
              'Despacho',
            ]) {
              final finder = find.text(text);
              expect(finder, findsOneWidget, reason: '$text $reason');
              expect(
                tester.renderObject<RenderParagraph>(finder).didExceedMaxLines,
                isFalse,
                reason: '$text $reason',
              );
              expectNoMidWordBreaks(tester, finder, reason: reason);
            }
            // The buttons are always whole, never squeezed under 44.
            for (final id in ['b1', 'k', 'l']) {
              expect(
                tester.getSize(_edit(id)).width,
                AppSizes.minTarget,
                reason: '$id $reason',
              );
            }
          });
        }
      }
    }

    for (final direction in TextDirection.values) {
      testWidgets('puts the buttons at the end of the row in $direction', (
        tester,
      ) async {
        await _pump(tester, spanish, width: 360, direction: direction);
        final ltr = direction == TextDirection.ltr;

        final name = tester.getRect(find.text('Cocina'));
        final edit = tester.getRect(_edit('k'));
        final archive = tester.getRect(_archive('k'));
        if (ltr) {
          expect(edit.left, greaterThanOrEqualTo(name.right));
          expect(archive.left, edit.right);
          expect(tester.getRect(_row('k')).right, archive.right);
        } else {
          expect(edit.right, lessThanOrEqualTo(name.left));
          expect(archive.right, edit.left);
          expect(tester.getRect(_row('k')).left, archive.left);
        }
        final pebble = tester.getRect(_k('rooms.pebble.b1.ana'));
        final title = tester.getRect(
          find.text('Dormitorio principal con baño integrado'),
        );
        expect(
          ltr ? pebble.right <= title.left : pebble.left >= title.right,
          isTrue,
        );
      });
    }

    testWidgets('puts the buttons under the texts when they do not fit '
        'beside them', (tester) async {
      await _pump(tester, spanish, textScale: 2);

      final name = tester.getRect(
        find.text('Cuarto de la lavadora y el tendedero'),
      );
      expect(tester.getRect(_edit('l')).top, greaterThanOrEqualTo(name.bottom));
      expect(tester.getRect(_edit('l')).left, tester.getRect(_row('l')).left);
    });

    testWidgets('puts the add button under the heading when it does not fit '
        'beside it', (tester) async {
      await _pump(tester, spanish, textScale: 2);

      final heading = tester.getRect(find.text('Dormitorios'));
      expect(tester.getRect(_add).top, greaterThanOrEqualTo(heading.bottom));
    });

    testWidgets('takes its height from its content and has no scrollable', (
      tester,
    ) async {
      await _pump(tester, spanish);

      expect(find.byType(Scrollable), findsNothing);
      expect(find.byType(LayoutBuilder), findsNothing);
      final small = tester.getSize(_k('rooms.editor')).height;
      await _pump(tester, spanish, textScale: 2);
      expect(tester.getSize(_k('rooms.editor')).height, greaterThan(small));
    });
  });

  group('colors', () {
    for (final (name, theme) in themes) {
      testWidgets('keeps the texts at 4.5:1 and the icons at 3:1 in $name', (
        tester,
      ) async {
        await _pump(tester, _view(), theme: theme);
        final scheme = theme.colorScheme;
        Color colorOf(String text) {
          return tester.widget<Text>(find.text(text)).style!.color!;
        }

        expectContrast(
          {
            'heading': (colorOf('Dormitorios'), scheme.surface),
            'name': (colorOf('Dormitorio 1'), scheme.surfaceContainerLowest),
            'subtitle': (
              colorOf('Libre, 2 camas'),
              scheme.surfaceContainerLowest,
            ),
            'archived name': (
              colorOf('Despacho'),
              scheme.surfaceContainerLowest,
            ),
            'archived subtitle': (
              colorOf('Archivado el 3 mar'),
              scheme.surfaceContainerLowest,
            ),
          },
          minimum: 4.5,
          reason: name,
        );
        expect(colorOf('Dormitorios'), scheme.onSurface);
        expect(colorOf('Dormitorio 1'), scheme.onSurface);
        expect(colorOf('Despacho'), scheme.onSurfaceVariant);
        expectContrast(
          {
            'icon': (scheme.onSurface, scheme.surfaceContainerLowest),
            'card edge': (scheme.outline, scheme.surfaceContainerLowest),
          },
          minimum: 3,
          reason: name,
        );
      });
    }

    testWidgets('draws the card with the card color and a hairline edge', (
      tester,
    ) async {
      await _pump(tester, _view());
      final scheme = CompappTheme.light.colorScheme;

      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .ancestor(
                          of: _row('k'),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.color, scheme.surfaceContainerLowest);
      expect(decoration.border!.top.color, scheme.outlineVariant);
      final dividers = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == scheme.outlineVariant,
      );
      // One hairline between the two bedrooms, one between the two areas.
      expect(dividers, findsNWidgets(2));
    });
  });

  group('focus', () {
    testWidgets('moves to the edit button of the next room when the room that '
        'holds it is archived', (tester) async {
      _traditional();
      await _pump(tester, _view());
      _nodeOf(tester, _archive('k')).requestFocus();
      await tester.pump();

      await tester.pumpWidget(
        host(_editor(_view(commonAreas: [_room('w', 'Baño')]), _Log())),
      );
      await tester.pump();

      expect(_nodeOf(tester, _edit('w')).hasPrimaryFocus, isTrue);
    });

    testWidgets('moves to the previous room when the last one is archived', (
      tester,
    ) async {
      _traditional();
      await _pump(tester, _view());
      _nodeOf(tester, _edit('w')).requestFocus();
      await tester.pump();

      await tester.pumpWidget(
        host(_editor(_view(commonAreas: [_room('k', 'Cocina')]), _Log())),
      );
      await tester.pump();

      expect(_nodeOf(tester, _edit('k')).hasPrimaryFocus, isTrue);
    });

    testWidgets('moves to the add button when no room is left', (tester) async {
      _traditional();
      final only = _view(
        bedrooms: [],
        commonAreas: [_room('k', 'Cocina')],
        archived: [],
      );
      await _pump(tester, only);
      _nodeOf(tester, _archive('k')).requestFocus();
      await tester.pump();

      await tester.pumpWidget(
        host(
          _editor(_view(bedrooms: [], commonAreas: [], archived: []), _Log()),
        ),
      );
      await tester.pump();

      expect(_nodeOf(tester, _add).hasPrimaryFocus, isTrue);
    });

    testWidgets('skips the neighbors that left too', (tester) async {
      _traditional();
      await _pump(tester, _view());
      _nodeOf(tester, _edit('b2')).requestFocus();
      await tester.pump();

      await tester.pumpWidget(
        host(
          _editor(
            _view(bedrooms: [_room('b1', 'Dormitorio 1')], commonAreas: []),
            _Log(),
          ),
        ),
      );
      await tester.pump();

      expect(_nodeOf(tester, _edit('b1')).hasPrimaryFocus, isTrue);
    });

    testWidgets('leaves focus alone when the room that left did not hold it', (
      tester,
    ) async {
      _traditional();
      await _pump(tester, _view());
      _nodeOf(tester, _edit('b2')).requestFocus();
      await tester.pump();

      await tester.pumpWidget(
        host(_editor(_view(commonAreas: [_room('w', 'Baño')]), _Log())),
      );
      await tester.pump();

      expect(_nodeOf(tester, _edit('b2')).hasPrimaryFocus, isTrue);
    });

    testWidgets('does not move focus for someone who is not using a '
        'keyboard', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await _pump(tester, _view());
      final node = _nodeOf(tester, _archive('k'))..requestFocus();
      await tester.pump();

      await tester.pumpWidget(
        host(_editor(_view(commonAreas: [_room('w', 'Baño')]), _Log())),
      );
      await tester.pump();

      expect(node.hasPrimaryFocus, isFalse);
      expect(_nodeOf(tester, _edit('w')).hasPrimaryFocus, isFalse);
    });

    testWidgets('keeps focus through a rebuild with the same view', (
      tester,
    ) async {
      _traditional();
      await _pump(tester, _view());
      final node = _nodeOf(tester, _archive('k'))..requestFocus();
      await tester.pump();

      for (var i = 0; i < 3; i++) {
        await tester.pumpWidget(host(_editor(_view(), _Log())));
        await tester.pump();
      }

      expect(node.hasPrimaryFocus, isTrue);
      expect(_nodeOf(tester, _archive('k')), same(node));
    });

    testWidgets('moves to the edit button of the first room when the add '
        'button that holds focus is disabled by a limit', (tester) async {
      _traditional();
      await _pump(tester, _view());
      _nodeOf(tester, _add).requestFocus();
      await tester.pump();

      await tester.pumpWidget(
        host(_editor(_view(limitMessage: 'La casa está llena'), _Log())),
      );
      await tester.pump();

      expect(_nodeOf(tester, _edit('b1')).hasPrimaryFocus, isTrue);
    });

    testWidgets('moves to the restore button of the first archived room when '
        'every room is archived and a limit disables add', (tester) async {
      _traditional();
      final both = [_archived('o', 'Despacho'), _archived('t', 'Trastero')];
      final none = _view(bedrooms: [], commonAreas: [], archived: both);
      await _pump(tester, none);
      _nodeOf(tester, _add).requestFocus();
      await tester.pump();

      await tester.pumpWidget(
        host(
          _editor(
            _view(
              bedrooms: [],
              commonAreas: [],
              archived: both,
              limitMessage: 'La casa está llena',
            ),
            _Log(),
          ),
        ),
      );
      await tester.pump();

      expect(_nodeOf(tester, _restore('o')).hasPrimaryFocus, isTrue);
    });

    testWidgets('leaves the add button alone when it keeps its limit, or '
        'when it did not hold focus', (tester) async {
      _traditional();
      final limited = _view(limitMessage: 'La casa está llena');
      await _pump(tester, limited);
      _nodeOf(tester, _edit('k')).requestFocus();
      await tester.pump();
      await tester.pumpWidget(host(_editor(_view(), _Log())));
      await tester.pumpWidget(host(_editor(limited, _Log())));
      await tester.pump();

      expect(_nodeOf(tester, _edit('k')).hasPrimaryFocus, isTrue);
    });

    testWidgets('does not move focus from the add button when a limit arrives '
        'for someone who is not using a keyboard', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await _pump(tester, _view());
      _nodeOf(tester, _add).requestFocus();
      await tester.pump();

      await tester.pumpWidget(
        host(_editor(_view(limitMessage: 'La casa está llena'), _Log())),
      );
      await tester.pump();

      expect(_nodeOf(tester, _edit('b1')).hasPrimaryFocus, isFalse);
    });

    testWidgets('moves from the assign list to the edit button when the last '
        'option goes, and to the assign button when only the focused one '
        'goes', (tester) async {
      _traditional();
      RoomEditorView withOptions(List<MemberView> options) => _view(
        bedrooms: [
          _room('b1', 'Dormitorio 1', occupants: [_ana], options: options),
        ],
      );
      await _pump(tester, withOptions([_carlos, _sara]));
      await tester.tap(_assign('b1'));
      await tester.pump();
      _nodeOf(tester, _option_('b1', 'carlos')).requestFocus();
      await tester.pump();

      await tester.pumpWidget(host(_editor(withOptions([_sara]), _Log())));
      await tester.pump();
      expect(_nodeOf(tester, _assign('b1')).hasPrimaryFocus, isTrue);

      _nodeOf(tester, _option_('b1', 'sara')).requestFocus();
      await tester.pump();
      await tester.pumpWidget(host(_editor(withOptions([]), _Log())));
      await tester.pump();
      expect(_nodeOf(tester, _edit('b1')).hasPrimaryFocus, isTrue);
    });

    testWidgets('survives the neighbor that was going to take focus leaving '
        'in the next frame', (tester) async {
      _traditional();
      await _pump(tester, _view());
      _nodeOf(tester, _archive('k')).requestFocus();
      await tester.pump();

      await tester.pumpWidget(
        host(_editor(_view(commonAreas: [_room('w', 'Baño')]), _Log())),
      );
      await tester.pumpWidget(
        host(_editor(_view(commonAreas: [], archived: []), _Log())),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('identity', () {
    testWidgets('a room keeps its element and its open list when another '
        'room is added above it', (tester) async {
      await _pump(tester, _view());
      await tester.tap(_assign('b1'));
      await tester.pump();
      final element = tester.element(_row('b1'));

      await tester.pumpWidget(
        host(
          _editor(
            _view(bedrooms: [_room('b0', 'Dormitorio 0'), ..._view().bedrooms]),
            _Log(),
          ),
        ),
      );

      expect(tester.element(_row('b1')), same(element));
      expect(_option_('b1', 'sara'), findsOneWidget);
    });

    testWidgets('a room keeps its focus node when the list is reordered', (
      tester,
    ) async {
      await _pump(tester, _view());
      final node = _nodeOf(tester, _edit('k'));

      await tester.pumpWidget(
        host(
          _editor(
            _view(commonAreas: [_room('w', 'Baño'), _room('k', 'Cocina')]),
            _Log(),
          ),
        ),
      );

      expect(_nodeOf(tester, _edit('k')), same(node));
    });

    testWidgets('disposes the nodes of the rooms that left', (tester) async {
      await _pump(tester, _view());
      final node = _nodeOf(tester, _edit('k'));

      await tester.pumpWidget(
        host(_editor(_view(commonAreas: [_room('w', 'Baño')]), _Log())),
      );
      await tester.pump();

      expect(
        () => node.addListener(() {}),
        throwsA(isA<AssertionError>()),
        reason: 'a disposed node cannot be listened to',
      );
    });

    testWidgets('disposes the nodes of the options that left', (tester) async {
      await _pump(tester, _view());
      await tester.tap(_assign('b1'));
      await tester.pump();
      final node = _nodeOf(tester, _option_('b1', 'sara'));

      await tester.pumpWidget(
        host(
          _editor(
            _view(
              bedrooms: [
                _room(
                  'b1',
                  'Dormitorio 1',
                  occupants: [_ana],
                  options: [_carlos],
                ),
              ],
            ),
            _Log(),
          ),
        ),
      );
      await tester.pump();

      expect(() => node.addListener(() {}), throwsA(isA<AssertionError>()));
    });
  });

  group('restore', () {
    testWidgets('calls back with the room id', (tester) async {
      final log = _Log();
      await _pump(tester, _view(), log: log);

      await tester.tap(_restore('o'));
      expect(log.calls, ['restore o']);
    });

    testWidgets('is a 48 hit area, 44 drawn, named after the room', (
      tester,
    ) async {
      await _pump(tester, _view());

      final size = tester.getSize(_restore('o'));
      expect(size.width, greaterThanOrEqualTo(AppSizes.minTarget));
      expect(size.height, greaterThanOrEqualTo(AppSizes.minTarget));
      expect(
        tester.getSize(
          find.descendant(
            of: _restore('o'),
            matching: find.byWidgetPredicate(
              (w) => w is Material && w.type == MaterialType.button,
            ),
          ),
        ),
        const Size.square(AppSizes.minDrawn),
      );
    });

    testWidgets('is not blocked by the limit of rooms', (tester) async {
      final log = _Log();
      await _pump(tester, _view(limitMessage: 'La casa está llena'), log: log);

      expect(tester.widget<TextButton>(_restore('o')).onPressed, isNotNull);
      await tester.tap(_restore('o'));
      expect(log.calls, ['restore o']);
    });

    testWidgets('has one button for each archived room, keyed by id', (
      tester,
    ) async {
      await _pump(
        tester,
        _view(
          archived: [_archived('o', 'Despacho'), _archived('t', 'Trastero')],
        ),
      );

      expect(_restore('o'), findsOneWidget);
      expect(_restore('t'), findsOneWidget);
      expect(
        tester.getRect(_restore('t')).top,
        greaterThan(tester.getRect(_restore('o')).top),
      );
    });

    testWidgets('moves focus to the next archived room when its room is '
        'restored', (tester) async {
      _traditional();
      final two = _view(
        archived: [_archived('o', 'Despacho'), _archived('t', 'Trastero')],
      );
      await _pump(tester, two);
      _nodeOf(tester, _restore('o')).requestFocus();
      await tester.pump();

      await tester.pumpWidget(
        host(
          _editor(
            _view(
              bedrooms: [..._view().bedrooms, _room('o', 'Despacho')],
              archived: [_archived('t', 'Trastero')],
            ),
            _Log(),
          ),
        ),
      );
      await tester.pump();

      expect(_nodeOf(tester, _restore('t')).hasPrimaryFocus, isTrue);
    });

    testWidgets('moves focus to the previous archived room when the last one '
        'is restored', (tester) async {
      _traditional();
      await _pump(
        tester,
        _view(
          archived: [_archived('o', 'Despacho'), _archived('t', 'Trastero')],
        ),
      );
      _nodeOf(tester, _restore('t')).requestFocus();
      await tester.pump();

      await tester.pumpWidget(
        host(
          _editor(
            _view(
              commonAreas: [..._view().commonAreas, _room('t', 'Trastero')],
              archived: [_archived('o', 'Despacho')],
            ),
            _Log(),
          ),
        ),
      );
      await tester.pump();

      expect(_nodeOf(tester, _restore('o')).hasPrimaryFocus, isTrue);
    });

    testWidgets('moves focus to the edit button of the restored room when it '
        'was the last archived one, even when the limit disables add', (
      tester,
    ) async {
      _traditional();
      await _pump(tester, _view(limitMessage: 'La casa está llena'));
      _nodeOf(tester, _restore('o')).requestFocus();
      await tester.pump();

      await tester.pumpWidget(
        host(
          _editor(
            _view(
              limitMessage: 'La casa está llena',
              commonAreas: [_room('k', 'Cocina'), _room('o', 'Despacho')],
              archived: [],
            ),
            _Log(),
          ),
        ),
      );
      await tester.pump();

      expect(_nodeOf(tester, _edit('o')).hasPrimaryFocus, isTrue);
    });

    testWidgets('disposes the restore node of a room that left', (
      tester,
    ) async {
      await _pump(
        tester,
        _view(
          archived: [_archived('o', 'Despacho'), _archived('t', 'Trastero')],
        ),
      );
      final node = _nodeOf(tester, _restore('o'));

      await tester.pumpWidget(
        host(_editor(_view(archived: [_archived('t', 'Trastero')]), _Log())),
      );
      await tester.pump();

      expect(() => node.addListener(() {}), throwsA(isA<AssertionError>()));
    });

    testWidgets('disposes every node when the editor leaves', (tester) async {
      await _pump(tester, _view());
      final nodes = [
        _nodeOf(tester, _restore('o')),
        _nodeOf(tester, _edit('k')),
        _nodeOf(tester, _add),
      ];

      await tester.pumpWidget(host(const SizedBox()));

      for (final node in nodes) {
        expect(() => node.addListener(() {}), throwsA(isA<AssertionError>()));
      }
    });

    testWidgets('draws the icon of each action', (tester) async {
      await _pump(tester, _view());

      AppIcons iconOf(Finder button) => tester
          .widget<AppIcon>(
            find.descendant(of: button, matching: find.byType(AppIcon)),
          )
          .icon;
      expect(iconOf(_restore('o')), AppIcons.history);
      expect(iconOf(_archive('k')), AppIcons.archive);
      expect(iconOf(_edit('k')), AppIcons.edit);
    });

    testWidgets('leaves focus alone when another archived room is restored', (
      tester,
    ) async {
      _traditional();
      await _pump(
        tester,
        _view(
          archived: [_archived('o', 'Despacho'), _archived('t', 'Trastero')],
        ),
      );
      _nodeOf(tester, _restore('t')).requestFocus();
      await tester.pump();

      await tester.pumpWidget(
        host(_editor(_view(archived: [_archived('t', 'Trastero')]), _Log())),
      );
      await tester.pump();

      expect(_nodeOf(tester, _restore('t')).hasPrimaryFocus, isTrue);
    });

    testWidgets('does not move focus for someone who is not using a '
        'keyboard', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await _pump(
        tester,
        _view(
          archived: [_archived('o', 'Despacho'), _archived('t', 'Trastero')],
        ),
      );
      _nodeOf(tester, _restore('o')).requestFocus();
      await tester.pump();

      await tester.pumpWidget(
        host(_editor(_view(archived: [_archived('t', 'Trastero')]), _Log())),
      );
      await tester.pump();

      expect(_nodeOf(tester, _restore('t')).hasPrimaryFocus, isFalse);
    });
  });

  group('assign list keyboard and seed', () {
    testWidgets('Escape closes the list and focuses the assign button', (
      tester,
    ) async {
      _traditional();
      await _pump(tester, _view());
      await tester.tap(_assign('b1'));
      await tester.pump();
      _nodeOf(tester, _option_('b1', 'sara')).requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump();

      expect(_option_('b1', 'sara'), findsNothing);
      expect(_nodeOf(tester, _assign('b1')).hasPrimaryFocus, isTrue);
    });

    testWidgets('Escape does nothing to the list while focus is outside it', (
      tester,
    ) async {
      _traditional();
      await _pump(tester, _view());
      await tester.tap(_assign('b1'));
      await tester.pump();
      _nodeOf(tester, _edit('k')).requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(_option_('b1', 'sara'), findsOneWidget);
    });

    testWidgets('opens the lists of initialAssignOpen when first built', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 12000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(_editor(_view(), _Log(), open: const {'b1'})),
      );

      expect(_option_('b1', 'sara'), findsOneWidget);
      await tester.tap(_assign('b1'));
      await tester.pump();
      expect(_option_('b1', 'sara'), findsNothing, reason: 'tapping owns it');
    });

    testWidgets('does not read initialAssignOpen again after the first build', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 12000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(_editor(_view(), _Log())));
      await tester.pumpWidget(
        host(_editor(_view(), _Log(), open: const {'b1'})),
      );

      expect(_option_('b1', 'sara'), findsNothing);
    });

    testWidgets('keeps closed a room added or restored after the first view '
        'even when its id is in initialAssignOpen', (tester) async {
      tester.view
        ..physicalSize = const Size(800, 12000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const open = {'b1', 'b3'};
      await tester.pumpWidget(host(_editor(_view(), _Log(), open: open)));
      expect(_option_('b1', 'sara'), findsOneWidget);

      await tester.pumpWidget(
        host(
          _editor(
            _view(
              bedrooms: [
                ..._view().bedrooms,
                _room(
                  'b3',
                  'Dormitorio 3',
                  occupants: [_ana],
                  options: [_sara],
                ),
              ],
            ),
            _Log(),
            open: open,
          ),
        ),
      );

      expect(_assign('b3'), findsOneWidget);
      expect(_option_('b3', 'sara'), findsNothing);
      expect(_option_('b1', 'sara'), findsOneWidget, reason: 'b1 is unchanged');

      await tester.pumpWidget(
        host(
          _editor(
            _view(bedrooms: [_room('b2', 'Dormitorio 2')]),
            _Log(),
            open: open,
          ),
        ),
      );
      await tester.pumpWidget(host(_editor(_view(), _Log(), open: open)));
      expect(_assign('b1'), findsOneWidget);
      expect(_option_('b1', 'sara'), findsNothing, reason: 'back, closed');
    });

    testWidgets('draws no list for a seeded room that has no options', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 12000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(_editor(_view(), _Log(), open: const {'b2'})),
      );

      expect(_k('rooms.options.b2'), findsNothing);
      expect(_k('rooms.options.b1'), findsNothing);
    });
  });

  group('more debug checks', () {
    testWidgets('rejects a common area with occupants or options', (
      tester,
    ) async {
      await _pump(
        tester,
        _view(
          commonAreas: [
            _room('k', 'Cocina', occupants: [_ana]),
          ],
        ),
      );
      expect(tester.takeException(), isA<AssertionError>());

      await _pump(
        tester,
        _view(
          commonAreas: [
            _room('k', 'Cocina', options: [_sara]),
          ],
        ),
      );
      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('rejects a member offered twice in a room', (tester) async {
      await _pump(
        tester,
        _view(
          bedrooms: [
            _room('b1', 'Dormitorio 1', options: [_sara, _sara]),
          ],
        ),
      );

      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('rejects an assign label that lacks the visible one', (
      tester,
    ) async {
      final room = _room('b1', 'Dormitorio 1', options: [_sara]);
      await _pump(
        tester,
        _view(
          bedrooms: [
            RoomEditorRoom(
              room: room.room,
              editLabel: room.editLabel,
              archiveLabel: room.archiveLabel,
              assignLabel: 'Mover a alguien a Dormitorio 1',
              assignOptions: room.assignOptions,
            ),
          ],
        ),
      );

      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('rejects options without an assign label', (tester) async {
      final room = _room('b1', 'Dormitorio 1', options: [_sara]);
      await _pump(
        tester,
        _view(
          bedrooms: [
            RoomEditorRoom(
              room: room.room,
              editLabel: room.editLabel,
              archiveLabel: room.archiveLabel,
              assignOptions: room.assignOptions,
            ),
          ],
        ),
      );

      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('rejects an option whose spoken label lacks the name', (
      tester,
    ) async {
      final room = _room('b1', 'Dormitorio 1');
      await _pump(
        tester,
        _view(
          bedrooms: [
            RoomEditorRoom(
              room: room.room,
              editLabel: room.editLabel,
              archiveLabel: room.archiveLabel,
              assignLabel: 'Asignar a alguien',
              assignOptions: const [
                RoomAssignOption(member: _sara, semanticLabel: 'Mover aquí'),
              ],
            ),
          ],
        ),
      );

      expect(tester.takeException(), isA<AssertionError>());
    });
  });

  group('debug checks', () {
    testWidgets('rejects a room id that repeats across the lists', (
      tester,
    ) async {
      await _pump(tester, _view(commonAreas: [_room('b1', 'Cocina')]));

      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('rejects archived rooms without a heading', (tester) async {
      final view = _view();
      await _pump(
        tester,
        RoomEditorView(
          bedroomsTitle: view.bedroomsTitle,
          commonAreasTitle: view.commonAreasTitle,
          addLabel: view.addLabel,
          assignLabel: view.assignLabel,
          bedrooms: view.bedrooms,
          commonAreas: view.commonAreas,
          archived: view.archived,
        ),
      );

      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('rejects offering a member the room they sleep in', (
      tester,
    ) async {
      await _pump(
        tester,
        _view(
          bedrooms: [
            _room('b1', 'Dormitorio 1', occupants: [_sara], options: [_sara]),
          ],
        ),
      );

      expect(tester.takeException(), isA<AssertionError>());
    });
  });
}

List<Finder> _rowsFinders() => [
  for (final id in ['b1', 'b2', 'k', 'l', 'o']) _row(id),
];
